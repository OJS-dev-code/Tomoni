import logging
import re
from typing import Any

logger = logging.getLogger(__name__)

_HANGUL = re.compile(r"[가-힣]")
# pronunciation·translation에 허용할 문자 (한글 + 구두점·숫자)
_KOREAN_FIELD_ALLOWED = re.compile(r"[^가-힣\s.,!?~·…\-?'\"()0-9%]")

KOREAN_FIELD_RULES = """
[한국어 필드 규칙 — 반드시 준수]
- text / japanese: 일본어만 (히라가나·카atakana·한자). 한글·영문 금지.
- pronunciation: 해당 일본어 문장의 **한글 발음**만. **뜻·번역·설명 금지.**
  · 예: すみません → "스미마센" (O) / "죄송합니다" (X, 이건 translation)
- translation: 해당 일본어 문장의 **한국어 뜻**만. **발음 표기 금지.**
  · 예: すみません → "죄송합니다" (O) / "스미마센" (X, 이건 pronunciation)
- pronunciation과 translation에 **같은 내용을 넣지 말 것**.
"""

FEEDBACK_FIELD_RULES = """
[피드백 item 필드 — japanese 기준]
- pronunciation = japanese를 한글로 읽은 소리 (발음)
- translation = japanese의 한국어 의미 (번역)
- pronunciation ≠ translation (절대 동일하게 쓰지 말 것)
"""


def _to_korean_only_field(value: str) -> str:
    """발음·번역 필드를 한글(+구두점)만 남기도록 정리."""
    if not value:
        return ""
    cleaned = _KOREAN_FIELD_ALLOWED.sub("", value.strip())
    cleaned = re.sub(r"\s+", " ", cleaned).strip()
    if len(_HANGUL.findall(cleaned)) == 0:
        return ""
    return cleaned


def sanitize_pronunciation(value: str, japanese_text: str = "") -> str:
    _ = japanese_text
    return _to_korean_only_field(value)


def sanitize_translation(value: str, japanese_text: str = "") -> str:
    _ = japanese_text
    return _to_korean_only_field(value)


def normalize_message_fields(
    message: dict[str, Any], *, fix_missing: bool = False, fix_fn=None
) -> dict[str, str]:
    """LLM이 반환한 메시지의 text/pronunciation/translation을 정규화."""
    text = str(message.get("text", "")).strip()
    pronunciation = sanitize_pronunciation(str(message.get("pronunciation", "")), text)
    translation = sanitize_translation(str(message.get("translation", "")), text)

    if fix_missing and text and fix_fn and (not pronunciation or not translation):
        fixed = fix_fn(text)
        if not pronunciation and fixed.get("pronunciation"):
            pronunciation = sanitize_pronunciation(fixed["pronunciation"], text)
        if not translation and fixed.get("translation"):
            translation = sanitize_translation(fixed["translation"], text)

    if text and (not pronunciation or not translation):
        logger.debug(
            "Korean fields incomplete for text=%r (pron=%s, trans=%s)",
            text[:40],
            bool(pronunciation),
            bool(translation),
        )

    return {
        "text": text,
        "pronunciation": pronunciation,
        "translation": translation,
    }
