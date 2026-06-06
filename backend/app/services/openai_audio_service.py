import logging

from openai import OpenAI

from app.config import get_settings
from app.services import tts_cache_service

logger = logging.getLogger(__name__)


def _client() -> OpenAI:
    settings = get_settings()
    if not settings.openai_api_key:
        raise RuntimeError("OpenAI API key is not configured")
    return OpenAI(api_key=settings.openai_api_key)


def transcribe_audio(audio_bytes: bytes, filename: str, language: str = "ja") -> str:
    settings = get_settings()
    client = _client()

    response = client.audio.transcriptions.create(
        model=settings.openai_whisper_model,
        file=(filename, audio_bytes),
        language=language,
    )
    return (response.text or "").strip()


def synthesize_speech(
    text: str, speed: float = 1.0, voice: str | None = None
) -> tuple[str, bool]:
    from app.services.voice_service import normalize_voice

    settings = get_settings()
    resolved_voice = normalize_voice(voice)
    model = settings.openai_tts_model

    cached_url = tts_cache_service.get_cached_tts(
        text, resolved_voice, model, speed
    )
    if cached_url:
        return cached_url, True

    client = _client()
    response = client.audio.speech.create(
        model=model,
        voice=resolved_voice,
        input=text,
        speed=speed,
        response_format="mp3",
    )
    audio_bytes = response.content
    url = tts_cache_service.store_tts_audio(
        audio_bytes, text, resolved_voice, model, speed
    )
    logger.info(
        "TTS generated (voice=%s) for %d chars",
        resolved_voice,
        len(text),
    )
    return url, False
