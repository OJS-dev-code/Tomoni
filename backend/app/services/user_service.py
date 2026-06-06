from datetime import datetime, timezone

import firebase_admin
from google.cloud.firestore_v1 import SERVER_TIMESTAMP

from app.models.user_profile import UserProfileResponse, UserProfileUpdate
from app.services.firebase import get_firestore

USERS_COLLECTION = "users"
_mock_profiles: dict[str, dict] = {}

_PROFILE_FIELDS = (
    "gender",
    "birthDate",
    "level",
    "duration",
    "purposes",
    "hobbies",
    "aiSpeed",
    "showContentFromStart",
    "showKoreanTranslation",
    "showKoreanPronunciation",
)


def _default_profile_data() -> dict:
    return {
        "gender": "",
        "birthDate": "",
        "level": "입문",
        "duration": "",
        "purposes": [],
        "hobbies": [],
        "aiSpeed": "현지인 속도로",
        "showContentFromStart": "예",
        "showKoreanTranslation": "예",
        "showKoreanPronunciation": "아니오",
    }


def _to_response(uid: str, data: dict) -> UserProfileResponse:
    return UserProfileResponse(
        uid=uid,
        gender=data.get("gender", ""),
        birthDate=data.get("birthDate", ""),
        level=data.get("level", "입문"),
        duration=data.get("duration", ""),
        purposes=data.get("purposes", []),
        hobbies=data.get("hobbies", []),
        aiSpeed=data.get("aiSpeed", "현지인 속도로"),
        showContentFromStart=data.get("showContentFromStart", "예"),
        showKoreanTranslation=data.get("showKoreanTranslation", "예"),
        showKoreanPronunciation=data.get("showKoreanPronunciation", "아니오"),
        createdAt=data.get("createdAt"),
        updatedAt=data.get("updatedAt"),
    )


def _use_mock_store() -> bool:
    return not firebase_admin._apps


def _get_mock_profile(uid: str) -> dict:
    if uid not in _mock_profiles:
        now = datetime.now(timezone.utc)
        data = _default_profile_data()
        data["createdAt"] = now
        data["updatedAt"] = now
        _mock_profiles[uid] = data
    return _mock_profiles[uid]


def get_user_profile(uid: str) -> UserProfileResponse:
    if _use_mock_store():
        return _to_response(uid, _get_mock_profile(uid))

    doc_ref = get_firestore().collection(USERS_COLLECTION).document(uid)
    snapshot = doc_ref.get()

    if not snapshot.exists:
        defaults = _default_profile_data()
        now = datetime.now(timezone.utc)
        defaults["createdAt"] = now
        defaults["updatedAt"] = now
        return _to_response(uid, defaults)

    return _to_response(uid, snapshot.to_dict() or {})


def upsert_user_profile(uid: str, profile: UserProfileUpdate) -> UserProfileResponse:
    payload = profile.model_dump(by_alias=True)
    now = datetime.now(timezone.utc)
    payload["updatedAt"] = now

    if _use_mock_store():
        existing = _get_mock_profile(uid)
        if "createdAt" not in existing:
            payload["createdAt"] = now
        else:
            payload["createdAt"] = existing["createdAt"]
        _mock_profiles[uid] = payload
        return _to_response(uid, payload)

    doc_ref = get_firestore().collection(USERS_COLLECTION).document(uid)
    snapshot = doc_ref.get()
    payload["updatedAt"] = SERVER_TIMESTAMP

    if snapshot.exists:
        doc_ref.update(payload)
    else:
        payload["createdAt"] = SERVER_TIMESTAMP
        doc_ref.set(payload)

    updated = doc_ref.get()
    data = updated.to_dict() or {}
    return _to_response(uid, data)
