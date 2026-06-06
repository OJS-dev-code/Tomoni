import firebase_admin
from fastapi import APIRouter

from app.config import get_settings

router = APIRouter(tags=["health"])


@router.get("/health")
async def health_check() -> dict:
    settings = get_settings()
    return {
        "status": "ok",
        "environment": settings.environment,
        "firebase_initialized": bool(firebase_admin._apps),
        "mock_auth_enabled": settings.allow_mock_auth,
    }
