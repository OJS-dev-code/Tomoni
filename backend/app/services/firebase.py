import json
import logging
from typing import Any

import firebase_admin
from firebase_admin import auth, credentials, firestore

from app.config import get_settings

logger = logging.getLogger(__name__)

_firestore_client: firestore.Client | None = None


def init_firebase() -> None:
    if firebase_admin._apps:
        return

    settings = get_settings()
    cred: credentials.Base | None = None

    if settings.firebase_service_account_json:
        service_account = json.loads(settings.firebase_service_account_json)
        cred = credentials.Certificate(service_account)
    elif settings.firebase_credentials_path:
        cred = credentials.Certificate(settings.resolved_credentials_path)

    if cred is not None:
        options: dict[str, str] = {}
        if settings.firebase_project_id:
            options["projectId"] = settings.firebase_project_id
        if settings.firebase_storage_bucket:
            options["storageBucket"] = settings.firebase_storage_bucket
        firebase_admin.initialize_app(cred, options or None)
        logger.info("Firebase initialized with service account credentials")
        return

    if settings.firebase_project_id:
        firebase_admin.initialize_app(options={"projectId": settings.firebase_project_id})
        logger.info("Firebase initialized with project ID only")
        return

    if settings.allow_mock_auth:
        logger.warning(
            "Firebase credentials not configured; running in mock-auth mode only"
        )
        return

    raise RuntimeError(
        "Firebase credentials are required. Set FIREBASE_SERVICE_ACCOUNT_JSON "
        "or FIREBASE_CREDENTIALS_PATH, or enable ALLOW_MOCK_AUTH for local dev."
    )


def get_firestore() -> firestore.Client:
    global _firestore_client
    if _firestore_client is None:
        if not firebase_admin._apps:
            init_firebase()
        if not firebase_admin._apps:
            raise RuntimeError("Firestore is unavailable without Firebase credentials")
        _firestore_client = firestore.client()
    return _firestore_client


def verify_id_token(token: str) -> dict[str, Any]:
    return auth.verify_id_token(token)
