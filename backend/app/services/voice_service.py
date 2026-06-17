from app.config import get_settings

OPENAI_TTS_VOICES = frozenset({"alloy", "echo", "fable", "onyx", "nova", "shimmer"})


def normalize_voice(voice: str | None) -> str:
    settings = get_settings()
    default = settings.openai_tts_voice or "nova"
    if not voice:
        return default
    normalized = voice.strip().lower()
    if normalized in OPENAI_TTS_VOICES:
        return normalized
    return default


def resolve_tts_voice(raw_voice: str | None, ai_role: str) -> str:
    """Gemini가 준 voice를 우선 사용하고, 없거나 잘못되면 역할 기반으로 폴백."""
    if raw_voice:
        normalized = raw_voice.strip().lower()
        if normalized in OPENAI_TTS_VOICES:
            return normalized
    return pick_voice_for_ai_role(ai_role)


def pick_voice_for_gender(ai_gender: str | None) -> str:
    """사용자가 선택한 AI 성별에 맞는 OpenAI TTS 목소리."""
    if not ai_gender:
        return normalize_voice(None)
    normalized = ai_gender.strip().lower()
    if normalized in {"male", "m", "man", "남", "남성"}:
        return "onyx"
    if normalized in {"female", "f", "woman", "여", "여성"}:
        return "shimmer"
    return normalize_voice(None)


def suggest_gender_from_role(ai_role: str) -> str:
    """역할 설명에서 AI 성별 기본값을 추정합니다."""
    role = ai_role.strip()
    if any(keyword in role for keyword in ("여성", "여자", "아가씨", "언니", "누나", "어머니", "할머니", "아줌마")):
        return "female"
    if any(keyword in role for keyword in ("남성", "남자", "아저씨", "오빠", "형", "아버지", "할아버지")):
        return "male"
    return "female"


def speed_from_ai_speed_setting(ai_speed: str | None) -> float:
    """사용자 프로필 aiSpeed → OpenAI TTS speed."""
    if ai_speed and "천천히" in ai_speed:
        return 0.8
    return 1.0


def pick_voice_for_ai_role(ai_role: str, ai_gender: str | None = None) -> str:
    """AI 역할·성별에 맞는 OpenAI TTS 목소리."""
    if ai_gender:
        return pick_voice_for_gender(ai_gender)
    role = ai_role.strip()
    if not role:
        return normalize_voice(None)
    return pick_voice_for_gender(suggest_gender_from_role(role))
