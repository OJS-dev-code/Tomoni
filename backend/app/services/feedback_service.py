import logging
import uuid
from datetime import datetime, timezone
from typing import Any

from google.cloud.firestore_v1 import SERVER_TIMESTAMP

from app.services.firebase import get_firestore
from app.services.korean_text_service import (
    FEEDBACK_FIELD_RULES,
    KOREAN_FIELD_RULES,
    sanitize_pronunciation,
    sanitize_translation,
)
# Phase 5 (보류): 오답 패턴 Firestore 누적
# from app.services import mistake_service
from app.services.llm_service import try_generate_json

logger = logging.getLogger(__name__)

NOTES_COLLECTION = "feedbackNotes"


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _format_history(history: list[dict[str, Any]]) -> str:
    lines: list[str] = []
    for item in history:
        role = "AI" if item.get("isAI") else "사용자"
        text = str(item.get("text", "")).strip()
        if not text:
            continue
        translation = str(item.get("translation", "")).strip()
        recommended = " (추천답변)" if item.get("isRecommended") else ""
        suffix = f" / {translation}" if translation else ""
        lines.append(f"{role}{recommended}: {text}{suffix}")
    return "\n".join(lines) if lines else "(대화 없음)"


def _format_user_only_history(history: list[dict[str, Any]]) -> str:
    lines: list[str] = []
    for i, item in enumerate(history, start=1):
        if item.get("isAI"):
            continue
        text = str(item.get("text", "")).strip()
        if not text or item.get("isRecommended"):
            continue
        lines.append(f"사용자발화#{len(lines)+1}: {text}")
    return "\n".join(lines) if lines else "(사용자 발화 없음)"


def _collect_message_texts(history: list[dict[str, Any]], *, is_ai: bool) -> set[str]:
    texts: set[str] = set()
    for item in history:
        if bool(item.get("isAI")) != is_ai:
            continue
        text = str(item.get("text", "")).strip()
        if text:
            texts.add(text)
    return texts


def _fix_feedback_korean_fields(japanese_text: str) -> dict[str, str]:
    prompt = f"""아래 일본어 문장에 대한 pronunciation(한글 발음)과 translation(한국어 뜻)만 생성.
{KOREAN_FIELD_RULES}
{FEEDBACK_FIELD_RULES}

일본어: {japanese_text}

JSON:
{{
  "pronunciation": "",
  "translation": ""
}}"""
    data = try_generate_json(prompt, temperature=0.2)
    if not data:
        return {}
    return {
        "pronunciation": str(data.get("pronunciation", "")),
        "translation": str(data.get("translation", "")),
    }


def _needs_korean_field_fix(pronunciation: str, translation: str) -> bool:
    if not pronunciation and not translation:
        return True
    if not pronunciation or not translation:
        return True
    if pronunciation.strip() == translation.strip():
        return True
    return False


def _normalize_feedback_item(raw: dict[str, Any]) -> dict[str, str] | None:
    title = str(raw.get("title", "")).strip()
    japanese = str(raw.get("japanese", "")).strip()
    if not title or not japanese:
        return None

    pronunciation = sanitize_pronunciation(str(raw.get("pronunciation", "")), japanese)
    translation = sanitize_translation(str(raw.get("translation", "")), japanese)

    if _needs_korean_field_fix(pronunciation, translation):
        fixed = _fix_feedback_korean_fields(japanese)
        if _needs_korean_field_fix(pronunciation, translation):
            pronunciation = sanitize_pronunciation(
                fixed.get("pronunciation", pronunciation), japanese
            )
            translation = sanitize_translation(
                fixed.get("translation", translation), japanese
            )

    description = str(raw.get("description", "")).strip() or None
    return {
        "title": title,
        "japanese": japanese,
        "pronunciation": pronunciation,
        "translation": translation,
        "description": description,
    }


def _filter_feedback_items(
    items: list[dict[str, str]], history: list[dict[str, Any]]
) -> list[dict[str, str]]:
    """AI 대사를 사용자 발화로 칭찬·평가하는 항목을 제거."""
    ai_texts = _collect_message_texts(history, is_ai=True)
    user_texts = _collect_message_texts(history, is_ai=False)
    praise_keywords = ("잘", "훌륭", "좋았", "적절", "자연스", "완벽", "훌륭")

    filtered: list[dict[str, str]] = []
    for item in items:
        japanese = item["japanese"].strip()
        title = item["title"]
        description = item.get("description") or ""

        is_ai_only_line = japanese in ai_texts and japanese not in user_texts
        looks_like_praise = any(k in title for k in praise_keywords) or any(
            k in description for k in praise_keywords
        )

        if is_ai_only_line and looks_like_praise:
            logger.debug("Dropped feedback item praising AI line: %s", title)
            continue

        filtered.append(item)
    return filtered


def _normalize_items(
    raw_items: Any, history: list[dict[str, Any]]
) -> list[dict[str, str]]:
    if not isinstance(raw_items, list):
        return []

    items: list[dict[str, str]] = []
    for raw in raw_items[:5]:
        if not isinstance(raw, dict):
            continue
        normalized = _normalize_feedback_item(raw)
        if normalized:
            items.append(normalized)

    return _filter_feedback_items(items, history)


def _generate_feedback(session: dict[str, Any], history: list[dict[str, Any]]) -> dict[str, Any]:
    topic = session.get("topic", "")
    goals = session.get("goals", [])
    goals_text = "\n".join(f"- {goal}" for goal in goals) or "- (없음)"
    completed = session.get("completedGoalIndices", [])
    history_text = _format_history(history)
    user_only_text = _format_user_only_history(history)

    prompt = f"""일본어 경어 역할극 세션이 끝났다. **학습자(사용자)의 일본어 발화**에 대한 피드백 노트를 작성한다.

주제: {topic}
AI 역할: {session.get("aiRole", "")}
사용자 역할: {session.get("userRole", "")}
장소: {session.get("location", "")}

대화 목표:
{goals_text}
달성한 목표 인덱스: {completed}

[역할 구분 — 매우 중요]
- 대화 기록에서 "AI:"는 상대방(AI)이 한 말이다. **학습자 발화가 아니다.**
- "사용자:"만 학습자가 직접 말한 일본어다.
- 피드백·점수·칭찬·교정은 **사용자 발화만** 대상으로 한다.
- AI 대사를 사용자가 잘했다고 평가하지 말 것.
- AI가 한 문장을 그대로 넣고 사용자를 칭찬하지 말 것.

학습자 발화만:
{user_only_text}

전체 대화 기록 (맥락 참고용):
{history_text}

작성 규칙:
1. score: 1~5 정수. **학습자**의 목표 달성·경어·자연스러움을 평가 (AI 말하기 실력은 평가하지 않음).
2. items: 1~4개. **학습자 발화**를 기준으로 교정·개선점만.
   - 사용자가 말한 표현의 문제점, 더 나은 경어 표현, 놓친 요청 등
   - japanese: **학습자가 다음에 쓸 교정·추천 일본어** (AI가 이미 한 대사 복사 금지)
   - userQuote(선택): 사용자가 실제로 말한 일본어 원문 (있을 때만)
   - title: 짧은 한국어 제목 (예: "주문 표현 다듬기")
   - description: 왜 이렇게 말하면 좋은지 (한국어, 선택)
3. AI 대사 칭찬 항목, AI 대사만 있는 칭찬형 피드백은 만들지 말 것.
{KOREAN_FIELD_RULES}
{FEEDBACK_FIELD_RULES}

JSON:
{{
  "score": 3,
  "items": [
    {{
      "title": "",
      "userQuote": "",
      "japanese": "",
      "pronunciation": "",
      "translation": "",
      "description": ""
    }}
  ]
}}"""
    data = try_generate_json(prompt, temperature=0.4)
    if data:
        score = data.get("score", 3)
        try:
            score = max(1, min(5, int(score)))
        except (TypeError, ValueError):
            score = 3
        items = _normalize_items(data.get("items"), history)
        if items:
            return {"score": score, "items": items}

    return _mock_feedback(session, history)


def _mock_feedback(session: dict[str, Any], history: list[dict[str, Any]]) -> dict[str, Any]:
    topic = str(session.get("topic", "상황극"))
    completed = session.get("completedGoalIndices", [])
    goals = session.get("goals", [])
    score = 3
    if goals:
        ratio = len(completed) / len(goals)
        score = max(1, min(5, round(ratio * 5) or 1))

    user_lines = [
        str(item.get("text", "")).strip()
        for item in history
        if not item.get("isAI") and item.get("text") and not item.get("isRecommended")
    ]
    last_user = user_lines[-1] if user_lines else "ありがとうございます。"

    better = "恐れ入りますが、もう一度お願いできますでしょうか。"
    raw_items = [
        {
            "title": "표현 다듬기",
            "japanese": better,
            "pronunciation": "오소레이리마스가, 모우 이치도 오네가이 데키마스데쇼우카.",
            "translation": "죄송하지만, 한 번 더 부탁드려도 될까요?",
            "description": "상황에 맞게 좀 더 부드러운 경어 표현을 연습해 보세요.",
        },
        {
            "title": "내가 말한 표현",
            "japanese": last_user,
            "pronunciation": "",
            "translation": "",
            "description": "이번 대화에서 학습자가 실제로 말한 표현입니다. 위 교정 예시와 비교해 보세요.",
        },
    ]
    items = [
        item
        for raw in raw_items
        if (item := _normalize_feedback_item(raw)) is not None
    ]
    return {"score": score, "items": items}


def _serialize_timestamp(value: Any) -> str:
    parsed = _parse_created_dt(value)
    if parsed is None:
        return _now_iso()
    return parsed.isoformat()


def _parse_created_dt(value: Any) -> datetime | None:
    if value is None:
        return None
    if isinstance(value, datetime):
        if value.tzinfo is None:
            return value.replace(tzinfo=timezone.utc)
        return value.astimezone(timezone.utc)
    if hasattr(value, "timestamp"):
        return datetime.fromtimestamp(value.timestamp(), tz=timezone.utc)
    try:
        text = str(value).replace("Z", "+00:00")
        return datetime.fromisoformat(text).astimezone(timezone.utc)
    except ValueError:
        return None


def _extract_hint_responses(history: list[dict[str, Any]]) -> list[dict[str, str]]:
    responses: list[dict[str, str]] = []
    for item in history:
        if item.get("isAI") or item.get("isRecommended"):
            continue
        if not item.get("usedHint"):
            continue
        hint_text = str(item.get("hintText", "")).strip()
        user_text = str(item.get("text", "")).strip()
        if not hint_text or not user_text:
            continue
        responses.append(
            {
                "userText": user_text,
                "hintText": hint_text,
                "hintPronunciation": str(item.get("hintPronunciation", "")).strip(),
                "hintTranslation": str(item.get("hintTranslation", "")).strip(),
            }
        )
    return responses


def _to_note_response(note_id: str, data: dict[str, Any]) -> dict[str, Any]:
    return {
        "id": note_id,
        "sessionId": data.get("sessionId", ""),
        "topic": data.get("topic", ""),
        "score": int(data.get("score", 3)),
        "items": data.get("items", []),
        "hintResponses": data.get("hintResponses", []),
        "createdAt": _serialize_timestamp(data.get("createdAt")),
    }


def _assert_note_owner(note: dict[str, Any], uid: str) -> None:
    if note.get("uid") != uid:
        raise PermissionError("Not allowed to access this note")


def _get_session_history(session_id: str) -> list[dict[str, Any]]:
    docs = (
        get_firestore()
        .collection("sessions")
        .document(session_id)
        .collection("messages")
        .order_by("createdAt")
        .stream()
    )
    return [doc.to_dict() or {} for doc in docs]


def create_note_for_session(uid: str, session_id: str) -> dict[str, Any]:
    db = get_firestore()
    session_ref = db.collection("sessions").document(session_id)
    session_snap = session_ref.get()
    if not session_snap.exists:
        raise LookupError("Session not found")

    session = session_snap.to_dict() or {}
    if session.get("uid") != uid:
        raise PermissionError("Not allowed to access this session")

    existing_note_id = session.get("feedbackNoteId")
    if existing_note_id:
        existing = db.collection(NOTES_COLLECTION).document(existing_note_id).get()
        if existing.exists:
            return _to_note_response(existing_note_id, existing.to_dict() or {})

    history = _get_session_history(session_id)
    generated = _generate_feedback(session, history)
    hint_responses = _extract_hint_responses(history)
    note_id = uuid.uuid4().hex
    note_payload = {
        "uid": uid,
        "sessionId": session_id,
        "topic": session.get("topic", ""),
        "score": generated["score"],
        "items": generated["items"],
        "hintResponses": hint_responses,
        "createdAt": SERVER_TIMESTAMP,
    }
    db.collection(NOTES_COLLECTION).document(note_id).set(note_payload)
    session_ref.update({"feedbackNoteId": note_id, "updatedAt": SERVER_TIMESTAMP})

    # Phase 5 (보류): 피드백 노트 → 오답 패턴 기록
    # try:
    #     mistake_service.record_from_feedback_note(
    #         uid=uid,
    #         session_id=session_id,
    #         topic=str(session.get("topic", "")),
    #         items=generated["items"],
    #         history=history,
    #     )
    # except Exception as exc:
    #     logger.warning("Failed to record mistake patterns: %s", exc)

    saved = db.collection(NOTES_COLLECTION).document(note_id).get()
    return _to_note_response(note_id, saved.to_dict() or note_payload)


def list_notes(uid: str, year: int, month: int) -> list[dict[str, Any]]:
    db = get_firestore()
    docs = (
        db.collection(NOTES_COLLECTION)
        .where("uid", "==", uid)
        .stream()
    )

    notes: list[dict[str, Any]] = []
    for doc in docs:
        data = doc.to_dict() or {}
        created_raw = data.get("createdAt")
        created_dt = _parse_created_dt(created_raw)
        if created_dt is None:
            continue
        if created_dt.year != year or created_dt.month != month:
            continue
        notes.append(_to_note_response(doc.id, data))

    notes.sort(key=lambda item: item["createdAt"], reverse=True)
    return notes


def get_note(uid: str, note_id: str) -> dict[str, Any]:
    snap = get_firestore().collection(NOTES_COLLECTION).document(note_id).get()
    if not snap.exists:
        raise LookupError("Note not found")
    data = snap.to_dict() or {}
    _assert_note_owner(data, uid)
    return _to_note_response(note_id, data)
