import hashlib
import logging
import uuid
from urllib.parse import quote

from firebase_admin import storage

from app.config import get_settings

logger = logging.getLogger(__name__)


def _cache_key(text: str, voice: str, model: str, speed: float) -> str:
    raw = f"{text.strip()}|{voice}|{model}|{speed:.2f}"
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


def _bucket_candidates() -> list[str]:
    settings = get_settings()
    names: list[str] = []
    if settings.firebase_storage_bucket:
        names.append(settings.firebase_storage_bucket)
    if settings.firebase_project_id:
        legacy = f"{settings.firebase_project_id}.appspot.com"
        if legacy not in names:
            names.append(legacy)
    return names


def _download_url(bucket_name: str, blob_path: str, token: str) -> str:
    encoded = quote(blob_path, safe="")
    return (
        f"https://firebasestorage.googleapis.com/v0/b/{bucket_name}/o/"
        f"{encoded}?alt=media&token={token}"
    )


def get_cached_tts_url(text: str, voice: str, model: str, speed: float) -> str | None:
    key = _cache_key(text, voice, model, speed)
    blob_path = f"tts/{key}.mp3"
    for bucket_name in _bucket_candidates():
        try:
            bucket = storage.bucket(bucket_name)
            blob = bucket.blob(blob_path)
            if not blob.exists():
                continue
            blob.reload()
            token = (blob.metadata or {}).get("firebaseStorageDownloadTokens")
            if not token:
                continue
            return _download_url(bucket.name, blob_path, token)
        except Exception as exc:
            logger.debug("TTS cache miss on bucket %s: %s", bucket_name, exc)
    return None


def upload_tts_audio(
    audio_bytes: bytes, text: str, voice: str, model: str, speed: float
) -> str:
    key = _cache_key(text, voice, model, speed)
    blob_path = f"tts/{key}.mp3"
    token = str(uuid.uuid4())
    last_error: Exception | None = None

    for bucket_name in _bucket_candidates():
        try:
            bucket = storage.bucket(bucket_name)
            blob = bucket.blob(blob_path)
            blob.metadata = {"firebaseStorageDownloadTokens": token}
            blob.upload_from_string(audio_bytes, content_type="audio/mpeg")
            return _download_url(bucket.name, blob_path, token)
        except Exception as exc:
            last_error = exc
            logger.debug("TTS upload failed on bucket %s: %s", bucket_name, exc)

    if last_error:
        raise last_error
    raise RuntimeError("No Firebase Storage bucket configured")
