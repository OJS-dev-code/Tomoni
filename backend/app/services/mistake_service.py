import hashlib
import logging
from datetime import datetime, timezone
from typing import Any

from google.cloud.firestore_v1 import SERVER_TIMESTAMP

from app.services.firebase import get_firestore
from app.services.llm_service import try_generate_json

logger = logging.getLogger(__name__)

PATTERNS_COLLECTION = "mistakePatterns"

_CATEGORY_KEYWORDS = {
    "경어": "경어",
    "敬語": "경어",
    "존댓말": "경어",
    "표현": "표현",
    "어휘": "표현",
    "문법": "문법",
    "발음": "발음",
    "뉘앙스": "뉘앙스",
    "상황": "상황",
}


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _parse_timestamp(value: Any) -> str:
    if value is None:
        return _now_iso()
    if isinstance(value, datetime):
        return value.astimezone(timezone.utc).isoformat()
    if hasattr(value, "timestamp"):
        return datetime.fromtimestamp(value.timestamp(), tz=timezone.utc).isoformat()
    return str(value)


def _infer_category(title: str, description: str = "") -> str:
    text = f"{title} {description}"
    for keyword, category in _CATEGORY_KEYWORDS.items():
        if keyword in text:
            return category
    return "표현"


def _pattern_key(label: str, better_japanese: str) -> str:
    raw = f"{label.strip().lower()}|{better_japanese.strip()}"
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()[:20]


def _is_reference_item(title: str) -> bool:
    lowered = title.strip()
    return any(keyword in lowered for keyword in ("내가 말한", "이번 대화에서 쓴", "사용자 발화"))


def _guess_user_example(title: str, history: list[dict[str, Any]]) -> str:
    user_lines = [
        str(item.get("text", "")).strip()
        for item in history
        if not item.get("isAI") and item.get("text") and not item.get("isRecommended")
    ]
    return user_lines[-1] if user_lines else ""


def extract_patterns_from_feedback(
    *,
    uid: str,
    session_id: str,
    topic: str,
    items: list[dict[str, Any]],
    history: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    """피드백 노트 항목에서 오답 패턴 후보를 추출."""
    patterns: list[dict[str, Any]] = []
    for item in items:
        title = str(item.get("title", "")).strip()
        japanese = str(item.get("japanese", "")).strip()
        if not title or not japanese or _is_reference_item(title):
            continue

        description = str(item.get("description", "")).strip()
        patterns.append(
            {
                "uid": uid,
                "patternKey": _pattern_key(title, japanese),
                "category": _infer_category(title, description),
                "label": title,
                "description": description,
                "userExample": _guess_user_example(title, history),
                "betterJapanese": japanese,
                "betterPronunciation": str(item.get("pronunciation", "")).strip(),
                "betterTranslation": str(item.get("translation", "")).strip(),
                "lastSessionId": session_id,
                "lastTopic": topic,
            }
        )
    return patterns


def record_patterns(patterns: list[dict[str, Any]]) -> None:
    if not patterns:
        return

    db = get_firestore()
    for pattern in patterns:
        uid = pattern["uid"]
        key = pattern["patternKey"]
        existing = (
            db.collection(PATTERNS_COLLECTION)
            .where("uid", "==", uid)
            .where("patternKey", "==", key)
            .limit(1)
            .stream()
        )
        doc = next(iter(existing), None)
        if doc and doc.exists:
            data = doc.to_dict() or {}
            count = int(data.get("count", 0)) + 1
            doc.reference.update(
                {
                    "count": count,
                    "description": pattern.get("description") or data.get("description", ""),
                    "userExample": pattern.get("userExample") or data.get("userExample", ""),
                    "betterPronunciation": pattern.get("betterPronunciation")
                    or data.get("betterPronunciation", ""),
                    "betterTranslation": pattern.get("betterTranslation")
                    or data.get("betterTranslation", ""),
                    "lastSessionId": pattern.get("lastSessionId", ""),
                    "lastTopic": pattern.get("lastTopic", ""),
                    "updatedAt": SERVER_TIMESTAMP,
                }
            )
        else:
            db.collection(PATTERNS_COLLECTION).add(
                {
                    **pattern,
                    "count": 1,
                    "createdAt": SERVER_TIMESTAMP,
                    "updatedAt": SERVER_TIMESTAMP,
                }
            )


def record_from_feedback_note(
    *,
    uid: str,
    session_id: str,
    topic: str,
    items: list[dict[str, Any]],
    history: list[dict[str, Any]],
) -> None:
    patterns = extract_patterns_from_feedback(
        uid=uid,
        session_id=session_id,
        topic=topic,
        items=items,
        history=history,
    )
    record_patterns(patterns)
    logger.info("Recorded %d mistake pattern(s) for uid=%s", len(patterns), uid)


def list_patterns(uid: str, *, limit: int = 10) -> list[dict[str, Any]]:
    docs = (
        get_firestore()
        .collection(PATTERNS_COLLECTION)
        .where("uid", "==", uid)
        .stream()
    )
    patterns: list[dict[str, Any]] = []
    for doc in docs:
        data = doc.to_dict() or {}
        patterns.append(
            {
                "id": doc.id,
                "category": data.get("category", "표현"),
                "label": data.get("label", ""),
                "description": data.get("description", ""),
                "userExample": data.get("userExample", ""),
                "betterJapanese": data.get("betterJapanese", ""),
                "betterPronunciation": data.get("betterPronunciation", ""),
                "betterTranslation": data.get("betterTranslation", ""),
                "count": int(data.get("count", 1)),
                "lastTopic": data.get("lastTopic", ""),
                "updatedAt": _parse_timestamp(data.get("updatedAt")),
            }
        )

    patterns.sort(key=lambda item: (item["count"], item["updatedAt"]), reverse=True)
    return patterns[:limit]


def get_weak_area_summary(uid: str, *, limit: int = 5) -> str:
    patterns = list_patterns(uid, limit=limit)
    if not patterns:
        return ""
    lines = []
    for pattern in patterns:
        lines.append(
            f"- [{pattern['category']}] {pattern['label']} (누적 {pattern['count']}회)"
        )
    return "\n".join(lines)


def generate_practice_recommendations(uid: str, *, limit: int = 3) -> list[str]:
    patterns = list_patterns(uid, limit=5)
    if not patterns:
        return []

    summary = get_weak_area_summary(uid)
    prompt = f"""학습자의 반복 오답 패턴을 바탕으로 연습하면 좋을 일본어 경어 상황극 주제를 {limit}개 추천.

약한 영역:
{summary}

규칙:
- 한국어로 "~하기" 형태의 구체적 역할극 주제
- 반복 실수와 직접 연관된 상황
- 상대방이 있는 대화 주제만

JSON: {{"topics": []}}"""
    data = try_generate_json(prompt, temperature=0.5)
    if data and data.get("topics"):
        topics = [str(item).strip() for item in data["topics"] if str(item).strip()]
        return topics[:limit]
    return _fallback_recommendations(patterns, limit)


def _fallback_recommendations(patterns: list[dict[str, Any]], limit: int) -> list[str]:
    category_map = {
        "경어": ["상사에게 출장 보고하기", "거래처에 첫 인사 전화하기"],
        "표현": ["편의점에서 물건 사기", "식당에서 예약하기"],
        "문법": ["동료와 아침 인사 나누기", "회의에서 의견 말하기"],
        "발음": ["카페에서 음료 주문하기", "호텔 체크인하기"],
        "뉘앙스": ["손님으로 식당 방문하기", "동료와 점심 약속 잡기"],
        "상황": ["병원에서 증상 설명하기", "전화로 문의하기"],
    }
    top_category = patterns[0].get("category", "표현")
    return category_map.get(top_category, category_map["표현"])[:limit]
