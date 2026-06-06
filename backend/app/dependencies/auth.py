from dataclasses import dataclass
from typing import Annotated

import firebase_admin
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.config import get_settings
from app.services.firebase import verify_id_token

security = HTTPBearer(auto_error=False)

MOCK_DEV_TOKEN = "mock-dev-token"
MOCK_DEV_UID = "mock-dev-user"


@dataclass(frozen=True)
class AuthenticatedUser:
    uid: str
    email: str | None = None


def _extract_bearer_token(
    credentials: HTTPAuthorizationCredentials | None,
) -> str | None:
    if credentials is None or credentials.scheme.lower() != "bearer":
        return None
    return credentials.credentials


async def get_current_user(
    credentials: Annotated[
        HTTPAuthorizationCredentials | None, Depends(security)
    ],
) -> AuthenticatedUser:
    settings = get_settings()
    token = _extract_bearer_token(credentials)

    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authorization header with Bearer token is required",
        )

    if settings.allow_mock_auth and token == MOCK_DEV_TOKEN:
        return AuthenticatedUser(uid=MOCK_DEV_UID, email="dev@tomoni.local")

    if not firebase_admin._apps:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Firebase is not configured for token verification",
        )

    try:
        decoded = verify_id_token(token)
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired Firebase ID token",
        ) from exc

    return AuthenticatedUser(
        uid=decoded["uid"],
        email=decoded.get("email"),
    )
