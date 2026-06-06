import logging
import re
from typing import Any

from app.services.goal_completion_service import (
    GOAL_COMPLETION_RULES,
    build_lenient_goal_eval_prompt,
    normalize_goal_completion,
)
from app.services.korean_text_service import KOREAN_FIELD_RULES, normalize_message_fields
from app.services.llm_service import try_generate_json
from app.services.voice_service import resolve_tts_voice

logger = logging.getLogger(__name__)

MAX_RECOMMENDATIONS = 3
MAX_HISTORY_TURNS = 8


def _try_generate_json(prompt: str, *, temperature: float = 0.85) -> dict[str, Any] | None:
    return try_generate_json(prompt, temperature=temperature)


def _fix_korean_fields(japanese_text: str) -> dict[str, str]:
    """발음·번역이 비었거나 잘못됐을 때 한국어 필드만 재생성."""
    prompt = f"""아래 일본어 문장에 대한 한국어 보조 필드만 생성한다.
{KOREAN_FIELD_RULES}

일본어 text: {japanese_text}

JSON:
{{
  "pronunciation": "",
  "translation": ""
}}"""
    data = _try_generate_json(prompt, temperature=0.2)
    if not data:
        return {}
    return {
        "pronunciation": str(data.get("pronunciation", "")),
        "translation": str(data.get("translation", "")),
    }


def _normalize_message_block(message: dict[str, Any]) -> dict[str, str]:
    return normalize_message_fields(message, fix_missing=True, fix_fn=_fix_korean_fields)


def _apply_goal_completion(
    data: dict[str, Any],
    *,
    goals: list[str],
    completed_indices: list[int],
    user_text: str,
    history: list[dict[str, Any]],
) -> dict[str, Any]:
    """목표 달성 판정을 정리하고, 필요 시 관대한 재평가를 수행."""
    data = normalize_goal_completion(data, goals, completed_indices)

    remaining = [i for i in range(len(goals)) if i not in completed_indices]
    if not remaining:
        return data

    merged = sorted(set(completed_indices) | set(data.get("newlyCompletedGoalIndices", [])))
    if merged and len(merged) == len(goals):
        data["allGoalsCompleted"] = True
        return data

    if data.get("newlyCompletedGoalIndices"):
        return data

    ai_message = data.get("aiMessage")
    if not isinstance(ai_message, dict):
        return data

    eval_prompt = build_lenient_goal_eval_prompt(
        goals=goals,
        completed_indices=completed_indices,
        user_text=user_text,
        ai_message=ai_message,
        history=history,
    )
    eval_data = _try_generate_json(eval_prompt, temperature=0.2)
    if not eval_data:
        return data

    eval_data = normalize_goal_completion(
        {
            "newlyCompletedGoalIndices": eval_data.get("newlyCompletedGoalIndices", []),
            "allGoalsCompleted": eval_data.get("allGoalsCompleted", False),
        },
        goals,
        completed_indices,
    )
    if eval_data.get("newlyCompletedGoalIndices"):
        data["newlyCompletedGoalIndices"] = eval_data["newlyCompletedGoalIndices"]
        data["allGoalsCompleted"] = eval_data["allGoalsCompleted"]
    return data


def _limit_recommendations(items: list[str]) -> list[str]:
    return [str(item) for item in items[:MAX_RECOMMENDATIONS]]


_SOLO_TOPIC_KEYWORDS = (
    "편지",
    "일기",
    "글쓰",
    "독백",
    "혼자",
    "메모",
    "독서",
    "영상 시청",
    "유튜브",
)


def _is_conversation_topic(topic: str) -> bool:
    normalized = topic.strip()
    if len(normalized) < 4:
        return False
    lowered = normalized.lower()
    if any(keyword in lowered for keyword in _SOLO_TOPIC_KEYWORDS):
        return False
    if "에게" in lowered and any(
        verb in lowered for verb in ("쓰기", "보내기", "적기", "남기기")
    ):
        return False
    return True


def _filter_conversation_topics(topics: list[str]) -> list[str]:
    return [topic for topic in topics if _is_conversation_topic(topic)]


def _slim_profile(profile: dict[str, Any]) -> str:
    purposes = ", ".join(profile.get("purposes") or [])
    return f"수준:{profile.get('level', '중급')}, 목적:{purposes or '없음'}"


def _short_history(history: list[dict[str, Any]]) -> str:
    lines = []
    for msg in history[-MAX_HISTORY_TURNS:]:
        role = "AI" if msg.get("isAI") else "U"
        text = (msg.get("text") or "").replace("\n", " ")
        lines.append(f"{role}:{text}")
    return "\n".join(lines)


def _goals_indexed(goals: list[str]) -> str:
    return "\n".join(f"{i}:{g}" for i, g in enumerate(goals))


def generate_topics(profile: dict[str, Any]) -> list[str]:
    weak_block = ""
    if profile.get("weakAreas"):
        weak_block = f"\n학습자의 반복 약점(있으면 1~2개 주제에 반영):\n{profile['weakAreas']}\n"

    prompt = f"""학습자 {_slim_profile(profile)}
{weak_block}
일본어 경어 상황극 주제 3개(한국어).

조건:
1. 반드시 상대방(점원·상사·동료·친구·손님 등)과 직접 대화하는 역할극
2. 대면·전화·화상 등 실시간 대화 상황만 허용
3. 금지: 편지쓰기, 일기, 혼자 하는 활동, 상대 없는 행위
4. 형식 예: "편의점에서 점원에게 물건 구매하기", "상사에게 출장 결과 보고하기"

JSON: {{"topics":["","",""]}}"""
    data = _try_generate_json(prompt)
    if data and data.get("topics"):
        filtered = _filter_conversation_topics(
            [str(item) for item in data["topics"]]
        )
        if filtered:
            return _limit_recommendations(filtered)
    return _mock_topics(profile)


def generate_goals(topic: str, profile: dict[str, Any]) -> list[str]:
    prompt = f"""주제: {topic}
학습자: {_slim_profile(profile)}

이 주제의 역할극에서 학습자가 대화를 통해 실제로 해내야 할 목표 3개(한국어)를 작성.

목표 형식:
- "~하기" 형태의 행동·의사소통 목표
- 이 대화에서 하고 싶은 일·요청·확인·전달을 한국어로 간결하게
- 일본어 문장·표현·경어 설명은 넣지 말 것

좋은 예 (주제: 편의점에서 오뎅 포장하기):
- "포장 요청하기"
- "윈나 오뎅, 두부, 유부모찌주머니 넣어달라하기"
- "영수증 요청하기"
- "일회용 젓가락도 넣어달라하기"

좋은 예 (주제: 상사에게 출장 결과 보고하기):
- "출장 보고 시작하기"
- "주요 성과와 숫자 전달하기"
- "다음 액션 확인하기"

나쁜 예 (금지):
- "경어 사용하기", "丁寧語 쓰기" (추상적)
- "『お願いします』라고 말하기" (일본어 표현 나열)
- 주제와 무관한 목표

주제와 직접 관련된 실용적 목표만 1~3개. 애매하거나 뻔한 목표는 넣지 말고, 좋은 것만 적을 것(3개 미만도 OK).

나쁜 예 (절대 금지):
- "대화 마무리하기", "필요한 정보 전달하기", "관련 요청·질문하기" (너무 뻔함)

JSON: {{"goals":[]}}"""
    data = _try_generate_json(prompt)
    if data and data.get("goals"):
        filtered = _filter_action_goals([str(item) for item in data["goals"]])
        if filtered:
            return filtered[:MAX_RECOMMENDATIONS]
    mock = _mock_goals(topic)
    return mock[:MAX_RECOMMENDATIONS] if mock else []


def _is_bad_goal(goal: str) -> bool:
    abstract_patterns = (
        "경어 사용",
        "경어 선택",
        "丁寧語",
        "尊敬語",
        "謙譲語",
        "자연스럽게",
        "표현 선택",
        "요청·응답",
        "상황에 맞는",
        "적절한",
        "대화 마무리",
        "필요한 정보",
        "정보 전달",
        "관련 요청",
        "관련 질문",
    )
    banned_exact = {
        "대화 마무리하기",
        "필요한 정보 전달하기",
        "정보 전달하기",
        "요청·질문하기",
        "질문하기",
        "인사하기",
        "결제하기",
    }
    normalized = goal.strip()
    if len(normalized) < 5:
        return True
    if normalized in banned_exact:
        return True
    if any(pattern in normalized for pattern in abstract_patterns):
        return True
    if re.search(r"[ぁ-んァ-ン一-龯『』]", normalized):
        return True
    if normalized.endswith(" 관련 요청·질문하기"):
        return True
    return not normalized.endswith("하기")


def _filter_action_goals(goals: list[str]) -> list[str]:
    return [goal for goal in goals if not _is_bad_goal(goal)]


def generate_session_start(
    topic: str, goals: list[str], profile: dict[str, Any]
) -> dict[str, Any]:
    goals_text = "\n".join(f"- {goal}" for goal in goals)
    prompt = f"""주제: {topic}
대화 목표:
{goals_text}
학습자: {_slim_profile(profile)}

일본어 경어 역할극의 시작 설정을 만든다.

1) aiRole, userRole, location (한국어)
2) ttsVoice: AI 역할에 맞는 OpenAI TTS (alloy/echo/fable/onyx/nova/shimmer 중 1개)
3) speakerFirst: 기본값 "user" (학습자가 먼저 말함)
   - "user": 원칙 — 편의점 주문, 보고, 질문, 예약 등 대부분
   - "ai": 예외 — AI가 수신 전화를 받는 경우 등 극히 드문 상황만
4) sceneNote: 학습자에게 보여줄 상황 설명 1문장 (한국어). speakerFirst가 user이면 필수.
5) openingMessage:
   - speakerFirst가 "user"이면 null
   - speakerFirst가 "ai"일 때만 AI 첫 대사

openingMessage 작성 시:
- いらっしゃいませ/こんにちは 같은 상투구만 반복하지 말 것
- 장소·역할·주제에 맞는 구체적 상황 반영
{KOREAN_FIELD_RULES}

JSON:
{{
  "aiRole":"",
  "userRole":"",
  "location":"",
  "ttsVoice":"",
  "speakerFirst":"user",
  "sceneNote":"",
  "openingMessage": {{"text":"","pronunciation":"","translation":""}}
}}"""
    data = _try_generate_json(prompt)
    if data:
        return _parse_session_start(data, topic)
    return _mock_session_start(topic, goals)


def _parse_session_start(data: dict[str, Any], topic: str) -> dict[str, Any]:
    ai_role = str(data.get("aiRole", "상대방"))
    speaker_first = str(data.get("speakerFirst", "user")).strip().lower()
    if speaker_first not in ("ai", "user"):
        speaker_first = "user"
    speaker_first = _resolve_speaker_first(speaker_first, topic)

    opening_raw = data.get("openingMessage")
    opening_message = None
    if speaker_first == "ai" and isinstance(opening_raw, dict):
        text = str(opening_raw.get("text", "")).strip()
        if text:
            opening_message = _normalize_message_block(opening_raw)

    if speaker_first == "ai" and not opening_message:
        opening_message = _mock_opening_message(topic, ai_role)

    scene_note = str(data.get("sceneNote", "")).strip()
    if speaker_first == "user" and not scene_note:
        scene_note = _mock_scene_note(topic)

    return {
        "aiRole": ai_role,
        "userRole": str(data.get("userRole", "학습자")),
        "location": str(data.get("location", "일본")),
        "ttsVoice": resolve_tts_voice(
            str(data.get("ttsVoice", "")) or None, ai_role
        ),
        "speakerFirst": speaker_first,
        "sceneNote": scene_note,
        "openingMessage": opening_message,
    }


def _resolve_speaker_first(raw: str, topic: str) -> str:
    """학습자 먼저가 원칙. 수신 전화 등 극히 드문 경우만 AI 선행."""
    if raw == "ai" and _is_ai_first_scenario(topic):
        return "ai"
    return "user"


def _is_ai_first_scenario(topic: str) -> bool:
    return "전화" in topic and any(k in topic for k in ("받", "수신", "응대"))


def _default_speaker_first(topic: str, ai_role: str) -> str:
    _ = ai_role
    if _is_ai_first_scenario(topic):
        return "ai"
    return "user"


def generate_session_setup(
    topic: str, goals: list[str], profile: dict[str, Any]
) -> dict[str, str]:
    start = generate_session_start(topic, goals, profile)
    return {
        "aiRole": start["aiRole"],
        "userRole": start["userRole"],
        "location": start["location"],
        "ttsVoice": start["ttsVoice"],
    }


def generate_opening_message(
    topic: str,
    goals: list[str],
    ai_role: str,
    user_role: str,
    location: str,
) -> dict[str, Any]:
    start = generate_session_start(
        topic,
        goals,
        {"level": "중급", "purposes": []},
    )
    if start.get("openingMessage"):
        return start["openingMessage"]
    return _mock_opening_message(topic, ai_role)


def generate_reply(
    topic: str,
    goals: list[str],
    ai_role: str,
    user_role: str,
    location: str,
    history: list[dict[str, Any]],
    user_text: str,
    completed_goal_indices: list[int],
    scene_note: str = "",
) -> dict[str, Any]:
    remaining = [i for i in range(len(goals)) if i not in completed_goal_indices]
    goals_block = _goals_indexed(goals)
    history_block = _short_history(history)

    scene_block = f"상황 시작: {scene_note}\n" if scene_note else ""

    prompt = f"""역할극 대화 진행.

설정: 주제={topic}, 장소={location}, AI={ai_role}, 사용자={user_role}
{scene_block}AI는 {ai_role}로 연기. 사용자는 {user_role}.

대화 규칙:
1. 사용자 발화에 맥락에 맞게 자연스럽게 반응 (무시·엉뚱한 답 금지)
2. AI 대사 1~3문장, 구어체. 역할·관계에 맞는 경어(丁寧語/尊敬語/謙譲語) 사용
3. 같은 문장·표현 반복 금지. 질문에는 답하고, 요청에는 응대
4. recommendedAnswer는 사용자(학습자)가 다음에 말할 경어 예시 1~2문장
5. 첫 사용자 발화라면 sceneNote·주제에 맞게 AI가 자연스럽게 대화를 이어갈 것
{GOAL_COMPLETION_RULES}
{KOREAN_FIELD_RULES}

목표(인덱스):
{goals_block}
이미달성:{completed_goal_indices}
남은목표:{remaining}

최근 대화:
{history_block}
사용자:{user_text}

JSON:
{{
  "aiMessage": {{"text":"","pronunciation":"","translation":""}},
  "recommendedAnswer": {{"text":"","pronunciation":"","translation":""}},
  "newlyCompletedGoalIndices": [],
  "allGoalsCompleted": false
}}"""
    data = _try_generate_json(prompt)
    if data and data.get("aiMessage"):
        ai_raw = data.get("aiMessage")
        if isinstance(ai_raw, dict):
            data["aiMessage"] = _normalize_message_block(ai_raw)
        rec_raw = data.get("recommendedAnswer")
        if isinstance(rec_raw, dict) and rec_raw.get("text"):
            data["recommendedAnswer"] = _normalize_message_block(rec_raw)
        return _apply_goal_completion(
            data,
            goals=goals,
            completed_indices=completed_goal_indices,
            user_text=user_text,
            history=history,
        )
    logger.warning("LLM unavailable or invalid reply — using mock fallback")
    return _mock_reply(user_text, goals, completed_goal_indices, len(history))


def _mock_topics(profile: dict[str, Any]) -> list[str]:
    purposes = profile.get("purposes") or []
    if any("비즈니스" in p or "취업" in p for p in purposes):
        return [
            "상사에게 출장 보고하기",
            "거래처에 첫 인사 전화하기",
            "회의에서 의견 말하기",
        ]
    return [
        "편의점에서 물건 사기",
        "식당에서 예약하기",
        "동료와 아침 인사 나누기",
    ]


def _mock_goals(topic: str) -> list[str]:
    if "오뎅" in topic or "어묵" in topic:
        return [
            "포장 요청하기",
            "윈나 오뎅, 두부, 유부모찌주머니 넣어달라하기",
            "영수증 요청하기",
        ]
    if "편의점" in topic:
        return [
            "포장 요청하기",
            "봉투·영수증 요청하기",
            "데울지 여부 답하기",
        ]
    if "상사" in topic or "보고" in topic or "출장" in topic:
        return [
            "출장 보고 시작하기",
            "주요 성과와 숫자 전달하기",
            "다음 액션 확인하기",
        ]
    if "예약" in topic or "식당" in topic:
        return [
            "예약 요청하기",
            "인원·시간·날짜 전달하기",
            "예약 내용 확인하기",
        ]
    return []


def _mock_session_start(topic: str, goals: list[str]) -> dict[str, Any]:
    if "편의점" in topic:
        setup = {
            "aiRole": "점원",
            "userRole": "손님",
            "location": "편의점",
            "speakerFirst": "user",
            "sceneNote": "편의점 카운터 앞입니다. 점원에게 말을 걸어보세요.",
        }
    elif "상사" in topic or "보고" in topic or "출장" in topic:
        setup = {
            "aiRole": "상사",
            "userRole": "부하 직원",
            "location": "회사 부장실",
            "speakerFirst": "user",
            "sceneNote": "부장실 문을 두드린 뒤, 출장 보고를 시작하세요.",
        }
    elif "예약" in topic:
        setup = {
            "aiRole": "레스토랑 직원",
            "userRole": "손님",
            "location": "일식 레스토랑",
            "speakerFirst": "user",
            "sceneNote": "전화를 걸었습니다. 예약을 요청하세요.",
        }
    else:
        setup = {
            "aiRole": "대화 상대",
            "userRole": "학습자",
            "location": "일본",
            "speakerFirst": _default_speaker_first(topic, "대화 상대"),
            "sceneNote": f"{topic} 상황입니다. 마이크를 눌러 먼저 말해보세요.",
        }
    setup["ttsVoice"] = resolve_tts_voice(None, setup["aiRole"])
    if setup["speakerFirst"] == "ai":
        setup["openingMessage"] = _mock_opening_message(topic, setup["aiRole"])
    else:
        setup["openingMessage"] = None
    return setup


def _mock_scene_note(topic: str) -> str:
    if "편의점" in topic:
        return "편의점 카운터 앞입니다. 점원에게 말을 걸어보세요."
    if "상사" in topic or "보고" in topic:
        return "상사 앞에서 먼저 인사하고 보고를 시작하세요."
    if "예약" in topic:
        return "전화를 걸었습니다. 예약을 요청하세요."
    return f"{topic} 상황입니다. 마이크를 눌러 먼저 말해보세요."


def _mock_session_setup(topic: str) -> dict[str, str]:
    start = _mock_session_start(topic, [])
    return {
        "aiRole": start["aiRole"],
        "userRole": start["userRole"],
        "location": start["location"],
        "ttsVoice": start["ttsVoice"],
    }


def _mock_opening_message(topic: str, ai_role: str) -> dict[str, Any]:
    if "편의점" in topic:
        return {
            "text": "いらっしゃいませ。お弁当、温めますか？",
            "pronunciation": "이랏샤이마세. 오벤토, 아타타메마스카?",
            "translation": "어서오세요. 도시락, 데울까요?",
        }
    if "식당" in topic or "카페" in topic:
        return {
            "text": "いらっしゃいませ。何名様でしょうか？",
            "pronunciation": "이랏샤이마세. 난메사마 데쇼카?",
            "translation": "어서오세요. 몇 분이세요?",
        }
    return {
        "text": "お待たせしました。どうぞ、お座りください。",
        "pronunciation": "오마타세 시마시타. 도우조, 오스와리 쿠다사이.",
        "translation": "기다리게 했습니다. 어서 앉으세요.",
    }


def _mock_reply(
    user_text: str,
    goals: list[str],
    completed_goal_indices: list[int],
    turn_count: int,
) -> dict[str, Any]:
    newly = []
    if turn_count >= 1 and 0 not in completed_goal_indices and len(goals) > 0:
        newly.append(0)
    if turn_count >= 2 and 1 not in completed_goal_indices and len(goals) > 1:
        newly.append(1)
    if turn_count >= 3 and 2 not in completed_goal_indices and len(goals) > 2:
        newly.append(2)

    all_done = len(goals) > 0 and set(completed_goal_indices) | set(newly) == set(
        range(len(goals))
    )

    ai_text = (
        "ありがとうございました。お疲れ様でした。"
        if all_done
        else "かしこまりました。ほかにございますか。"
    )
    ai_pron = (
        "아리가토 고자이마시타. 오츠카레사마 데시타."
        if all_done
        else "카시코마리마시타. 호카니 고자이마스카."
    )
    ai_trans = (
        "감사했습니다. 수고하셨습니다."
        if all_done
        else "알겠습니다. 다른 것은 없으십니까?"
    )

    result: dict[str, Any] = {
        "aiMessage": {
            "text": ai_text,
            "pronunciation": ai_pron,
            "translation": ai_trans,
        },
        "newlyCompletedGoalIndices": newly,
        "allGoalsCompleted": all_done,
    }
    if not all_done:
        result["recommendedAnswer"] = {
            "text": "大丈夫です。ありがとうございます。",
            "pronunciation": "다이조부데스. 아리가토 고자이마스.",
            "translation": "괜찮습니다. 감사합니다.",
        }
    return result
