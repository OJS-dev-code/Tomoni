from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status

from app.dependencies.auth import AuthenticatedUser, get_current_user
from app.models.user_profile import UserProfileResponse, UserProfileUpdate
from app.services import user_service

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/profile", response_model=UserProfileResponse)
async def get_profile(
    current_user: Annotated[AuthenticatedUser, Depends(get_current_user)],
) -> UserProfileResponse:
    try:
        return user_service.get_user_profile(current_user.uid)
    except RuntimeError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(exc),
        ) from exc


@router.put("/profile", response_model=UserProfileResponse)
async def update_profile(
    profile: UserProfileUpdate,
    current_user: Annotated[AuthenticatedUser, Depends(get_current_user)],
) -> UserProfileResponse:
    try:
        return user_service.upsert_user_profile(current_user.uid, profile)
    except RuntimeError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(exc),
        ) from exc
