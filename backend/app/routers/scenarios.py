from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.dependencies.auth import AuthenticatedUser, get_current_user
from app.models.scenario import (
    SendMessageRequest,
    SendMessageResponse,
    SessionCreateRequest,
    SessionCreateResponse,
    SessionEndResponse,
    SessionPreviewRequest,
    SessionPreviewResponse,
)
from app.services import session_service

MAX_RECOMMENDATIONS = 3

router = APIRouter(prefix="/scenarios", tags=["scenarios"])


@router.get("/topics")
async def get_topics(
    current_user: Annotated[AuthenticatedUser, Depends(get_current_user)],
) -> dict[str, list[str]]:
    try:
        topics = session_service.get_recommended_topics(current_user.uid)
        return {"topics": topics[:MAX_RECOMMENDATIONS]}
    except RuntimeError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(exc),
        ) from exc


@router.get("/goals")
async def get_goals(
    current_user: Annotated[AuthenticatedUser, Depends(get_current_user)],
    topic: str = Query(..., min_length=1),
) -> dict[str, list[str]]:
    try:
        goals = session_service.get_recommended_goals(current_user.uid, topic)
        return {"goals": goals[:MAX_RECOMMENDATIONS]}
    except RuntimeError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(exc),
        ) from exc


@router.post("/preview", response_model=SessionPreviewResponse)
async def preview_session(
    payload: SessionPreviewRequest,
    current_user: Annotated[AuthenticatedUser, Depends(get_current_user)],
) -> SessionPreviewResponse:
    try:
        preview = session_service.get_session_preview(
            current_user.uid,
            payload.topic.strip(),
            payload.goals,
        )
        return SessionPreviewResponse(**preview)
    except RuntimeError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(exc),
        ) from exc


@router.post("/sessions", response_model=SessionCreateResponse)
async def create_session(
    payload: SessionCreateRequest,
    current_user: Annotated[AuthenticatedUser, Depends(get_current_user)],
) -> SessionCreateResponse:
    try:
        return session_service.create_session(
            current_user.uid,
            payload.topic,
            payload.goals,
            payload.ai_gender,
        )
    except RuntimeError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(exc),
        ) from exc


@router.post(
    "/sessions/{session_id}/messages",
    response_model=SendMessageResponse,
)
async def send_message(
    session_id: str,
    payload: SendMessageRequest,
    current_user: Annotated[AuthenticatedUser, Depends(get_current_user)],
) -> SendMessageResponse:
    try:
        return session_service.send_message(
            current_user.uid,
            session_id,
            payload.text.strip(),
            used_hint=payload.used_hint,
            hint_text=payload.hint_text,
            hint_pronunciation=payload.hint_pronunciation,
            hint_translation=payload.hint_translation,
        )
    except LookupError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(exc),
        ) from exc
    except PermissionError as exc:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=str(exc),
        ) from exc
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc),
        ) from exc
    except RuntimeError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(exc),
        ) from exc


@router.post("/sessions/{session_id}/end", response_model=SessionEndResponse)
async def end_session(
    session_id: str,
    current_user: Annotated[AuthenticatedUser, Depends(get_current_user)],
) -> SessionEndResponse:
    try:
        result = session_service.end_session(current_user.uid, session_id)
        return SessionEndResponse(**result)
    except LookupError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(exc),
        ) from exc
    except PermissionError as exc:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=str(exc),
        ) from exc
