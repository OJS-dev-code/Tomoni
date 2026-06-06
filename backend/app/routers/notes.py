from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.dependencies.auth import AuthenticatedUser, get_current_user
from app.models.feedback_note import FeedbackNoteListResponse, FeedbackNoteResponse
from app.services import feedback_service

router = APIRouter(prefix="/notes", tags=["notes"])


@router.get("", response_model=FeedbackNoteListResponse)
async def list_notes(
    current_user: Annotated[AuthenticatedUser, Depends(get_current_user)],
    year: int = Query(..., ge=2020, le=2100),
    month: int = Query(..., ge=1, le=12),
) -> FeedbackNoteListResponse:
    try:
        notes = feedback_service.list_notes(current_user.uid, year, month)
        return FeedbackNoteListResponse(
            notes=[FeedbackNoteResponse(**note) for note in notes]
        )
    except RuntimeError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(exc),
        ) from exc


@router.get("/{note_id}", response_model=FeedbackNoteResponse)
async def get_note(
    note_id: str,
    current_user: Annotated[AuthenticatedUser, Depends(get_current_user)],
) -> FeedbackNoteResponse:
    try:
        note = feedback_service.get_note(current_user.uid, note_id)
        return FeedbackNoteResponse(**note)
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
    except RuntimeError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(exc),
        ) from exc
