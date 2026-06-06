from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.dependencies.auth import AuthenticatedUser, get_current_user
from app.models.mistake_pattern import MistakePatternListResponse, MistakePatternResponse
from app.services import mistake_service

router = APIRouter(prefix="/mistakes", tags=["mistakes"])


@router.get("/patterns", response_model=MistakePatternListResponse)
async def list_mistake_patterns(
    current_user: Annotated[AuthenticatedUser, Depends(get_current_user)],
    limit: int = Query(default=10, ge=1, le=20),
) -> MistakePatternListResponse:
    try:
        patterns = mistake_service.list_patterns(current_user.uid, limit=limit)
        return MistakePatternListResponse(
            patterns=[MistakePatternResponse(**item) for item in patterns]
        )
    except RuntimeError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(exc),
        ) from exc


@router.get("/recommendations")
async def get_practice_recommendations(
    current_user: Annotated[AuthenticatedUser, Depends(get_current_user)],
    limit: int = Query(default=3, ge=1, le=5),
) -> dict[str, list[str]]:
    try:
        topics = mistake_service.generate_practice_recommendations(
            current_user.uid, limit=limit
        )
        return {"topics": topics}
    except RuntimeError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(exc),
        ) from exc
