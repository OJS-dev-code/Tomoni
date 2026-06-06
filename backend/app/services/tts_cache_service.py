import base64
import hashlib
import logging

from app.services import storage_service

logger = logging.getLogger(__name__)

_MAX_MEMORY_CACHE = 200
_memory_tts_cache: dict[str, str] = {}


def _cache_key(text: str, voice: str, model: str, speed: float) -> str:
    raw = f"{text.strip()}|{voice}|{model}|{speed:.2f}"
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


def _to_data_url(audio_bytes: bytes) -> str:
    encoded = base64.b64encode(audio_bytes).decode("ascii")
    return f"data:audio/mpeg;base64,{encoded}"


def get_cached_tts(text: str, voice: str, model: str, speed: float) -> str | None:
    key = _cache_key(text, voice, model, speed)
    if key in _memory_tts_cache:
        return _memory_tts_cache[key]

    return storage_service.get_cached_tts_url(text, voice, model, speed)


def store_tts_audio(
    audio_bytes: bytes, text: str, voice: str, model: str, speed: float
) -> str:
    key = _cache_key(text, voice, model, speed)
    data_url = _to_data_url(audio_bytes)

    try:
        url = storage_service.upload_tts_audio(
            audio_bytes, text, voice, model, speed
        )
    except Exception as exc:
        logger.warning(
            "Firebase Storage unavailable, serving inline audio: %s", exc
        )
        url = data_url

    if len(_memory_tts_cache) >= _MAX_MEMORY_CACHE:
        _memory_tts_cache.clear()
    _memory_tts_cache[key] = url
    return url
