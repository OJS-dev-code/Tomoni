from typing import Annotated

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile, status

from app.config import get_settings
from app.dependencies.auth import AuthenticatedUser, get_current_user
from app.models.audio import SttResponse, TtsRequest, TtsResponse
from app.services import openai_audio_service

router = APIRouter(prefix="/audio", tags=["audio"])

MAX_AUDIO_BYTES = 10 * 1024 * 1024


@router.post("/stt", response_model=SttResponse)
async def speech_to_text(
    current_user: Annotated[AuthenticatedUser, Depends(get_current_user)],
    file: UploadFile = File(...),
    language: str = Query(default="ja", min_length=2, max_length=5),
) -> SttResponse:
    _ = current_user
    settings = get_settings()
    if not settings.openai_enabled:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="OpenAI API key is not configured",
        )

    audio_bytes = await file.read()
    if not audio_bytes:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Empty audio file",
        )
    if len(audio_bytes) > MAX_AUDIO_BYTES:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail="Audio file too large (max 10MB)",
        )

    filename = file.filename or "audio.m4a"
    try:
        text = openai_audio_service.transcribe_audio(
            audio_bytes, filename=filename, language=language
        )
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Speech recognition failed: {exc}",
        ) from exc

    return SttResponse(text=text)


@router.post("/tts", response_model=TtsResponse)
async def text_to_speech(
    current_user: Annotated[AuthenticatedUser, Depends(get_current_user)],
    body: TtsRequest,
) -> TtsResponse:
    _ = current_user
    settings = get_settings()
    if not settings.openai_enabled:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="OpenAI API key is not configured",
        )

    try:
        audio_url, cached = openai_audio_service.synthesize_speech(
            body.text, speed=body.speed, voice=body.voice
        )
    except Exception as exc:
        logger.warning("TTS failed: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail="음성 생성에 실패했습니다. 잠시 후 다시 시도해주세요.",
        ) from exc

    return TtsResponse(audio_url=audio_url, cached=cached)
