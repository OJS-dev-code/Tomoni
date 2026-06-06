import uuid
from datetime import datetime, timezone
from typing import Any

from google.cloud.firestore_v1 import SERVER_TIMESTAMP

from app.models.scenario import ChatMessage, SendMessageResponse, SessionCreateResponse
from app.services import feedback_service, gemini_service, user_service
# Phase 5 (보류): mistake_service — 약점 기반 주제 추천
# from app.services import mistake_service
from app.services.goal_completion_service import normalize_goal_completion
from app.services.firebase import get_firestore
from app.services.hint_match import texts_match_hint
from app.services.voice_service import pick_voice_for_gender, suggest_gender_from_role

SESSIONS_COLLECTION = "sessions"
MESSAGES_SUBCOLLECTION = "messages"


def _now() -> datetime:
    return datetime.now(timezone.utc)


def _profile_as_dict(uid: str) -> dict[str, Any]:
    profile = user_service.get_user_profile(uid)
    return profile.model_dump(by_alias=True)


def _to_chat_message(
    data: dict[str, Any], *, is_ai: bool, is_recommended: bool | None = None
) -> ChatMessage:
    return ChatMessage(
        isAI=is_ai,
        text=data.get("text", ""),
        pronunciation=data.get("pronunciation", ""),
        translation=data.get("translation", ""),
        isRecommended=is_recommended,
        usedHint=data.get("usedHint"),
        hintText=data.get("hintText", ""),
        hintPronunciation=data.get("hintPronunciation", ""),
        hintTranslation=data.get("hintTranslation", ""),
    )


def _save_message(session_id: str, message: ChatMessage) -> None:
    payload = message.model_dump(by_alias=True)
    payload["createdAt"] = SERVER_TIMESTAMP
    get_firestore().collection(SESSIONS_COLLECTION).document(session_id).collection(
        MESSAGES_SUBCOLLECTION
    ).add(payload)


def _get_history(session_id: str) -> list[dict[str, Any]]:
    docs = (
        get_firestore()
        .collection(SESSIONS_COLLECTION)
        .document(session_id)
        .collection(MESSAGES_SUBCOLLECTION)
        .order_by("createdAt")
        .stream()
    )
    return [doc.to_dict() or {} for doc in docs]


def _get_session_doc(session_id: str) -> dict[str, Any]:
    snapshot = (
        get_firestore().collection(SESSIONS_COLLECTION).document(session_id).get()
    )
    if not snapshot.exists:
        raise LookupError("Session not found")
    return snapshot.to_dict() or {}


def _assert_owner(session: dict[str, Any], uid: str) -> None:
    if session.get("uid") != uid:
        raise PermissionError("Not allowed to access this session")


def get_recommended_topics(uid: str) -> list[str]:
    profile = _profile_as_dict(uid)
    # Phase 5 (보류): 약점 기반 주제 우선 노출
    # weak_summary = mistake_service.get_weak_area_summary(uid)
    # if weak_summary:
    #     profile = {**profile, "weakAreas": weak_summary}
    # mistake_topics = mistake_service.generate_practice_recommendations(uid, limit=2)
    general_topics = gemini_service.generate_topics(profile)
    # merged: list[str] = []
    # for topic in mistake_topics + general_topics:
    #     if topic not in merged:
    #         merged.append(topic)
    # return merged[:3]
    return general_topics[:3]


def get_recommended_goals(uid: str, topic: str) -> list[str]:
    profile = _profile_as_dict(uid)
    return gemini_service.generate_goals(topic, profile)


def get_session_preview(uid: str, topic: str, goals: list[str]) -> dict[str, str]:
    profile = _profile_as_dict(uid)
    start = gemini_service.generate_session_start(topic, goals, profile)
    ai_role = start["aiRole"]
    suggested_gender = suggest_gender_from_role(ai_role)
    return {
        "topic": topic,
        "aiRole": ai_role,
        "userRole": start["userRole"],
        "location": start["location"],
        "speakerFirst": start["speakerFirst"],
        "sceneNote": start.get("sceneNote", ""),
        "suggestedAiGender": suggested_gender,
        "ttsVoice": pick_voice_for_gender(suggested_gender),
    }


def create_session(
    uid: str, topic: str, goals: list[str], ai_gender: str | None = None
) -> SessionCreateResponse:
    profile = _profile_as_dict(uid)
    start = gemini_service.generate_session_start(topic, goals, profile)

    session_id = uuid.uuid4().hex
    resolved_gender = ai_gender or suggest_gender_from_role(start["aiRole"])
    tts_voice = pick_voice_for_gender(resolved_gender)
    speaker_first = start["speakerFirst"]
    scene_note = start.get("sceneNote", "")

    session_payload = {
        "uid": uid,
        "topic": topic,
        "goals": goals,
        "aiRole": start["aiRole"],
        "userRole": start["userRole"],
        "location": start["location"],
        "aiGender": resolved_gender,
        "ttsVoice": tts_voice,
        "speakerFirst": speaker_first,
        "sceneNote": scene_note,
        "completedGoalIndices": [],
        "status": "active",
        "createdAt": SERVER_TIMESTAMP,
        "updatedAt": SERVER_TIMESTAMP,
    }
    get_firestore().collection(SESSIONS_COLLECTION).document(session_id).set(
        session_payload
    )

    opening_message = None
    opening_raw = start.get("openingMessage")
    if speaker_first == "ai" and opening_raw:
        opening_message = _to_chat_message(opening_raw, is_ai=True)
        _save_message(session_id, opening_message)

    return SessionCreateResponse(
        sessionId=session_id,
        topic=topic,
        goals=goals,
        aiRole=start["aiRole"],
        userRole=start["userRole"],
        location=start["location"],
        ttsVoice=tts_voice,
        speakerFirst=speaker_first,
        sceneNote=scene_note,
        openingMessage=opening_message,
    )


def send_message(
    uid: str,
    session_id: str,
    user_text: str,
    *,
    used_hint: bool = False,
    hint_text: str = "",
    hint_pronunciation: str = "",
    hint_translation: str = "",
) -> SendMessageResponse:
    session = _get_session_doc(session_id)
    _assert_owner(session, uid)

    if session.get("status") != "active":
        raise ValueError("Session is not active")

    goals: list[str] = session.get("goals", [])
    completed_indices: list[int] = list(session.get("completedGoalIndices", []))

    history = _get_history(session_id)
    pending_hint = session.get("pendingHint") or {}
    effective_hint_text = hint_text.strip() or str(pending_hint.get("text", "")).strip()
    matched_hint = bool(
        effective_hint_text
        and (used_hint or texts_match_hint(user_text, effective_hint_text))
    )

    user_payload: dict[str, Any] = {
        "text": user_text,
        "pronunciation": "",
        "translation": "",
    }
    if matched_hint:
        user_payload["usedHint"] = True
        user_payload["hintText"] = effective_hint_text
        user_payload["hintPronunciation"] = hint_pronunciation.strip() or str(
            pending_hint.get("pronunciation", "")
        ).strip()
        user_payload["hintTranslation"] = hint_translation.strip() or str(
            pending_hint.get("translation", "")
        ).strip()

    user_message = _to_chat_message(user_payload, is_ai=False, is_recommended=False)
    _save_message(session_id, user_message)

    reply = gemini_service.generate_reply(
        topic=session.get("topic", ""),
        goals=goals,
        ai_role=session.get("aiRole", ""),
        user_role=session.get("userRole", ""),
        location=session.get("location", ""),
        history=history + [user_message.model_dump(by_alias=True)],
        user_text=user_text,
        completed_goal_indices=completed_indices,
        scene_note=session.get("sceneNote", ""),
    )

    reply = normalize_goal_completion(
        reply,
        goals,
        completed_indices,
    )

    ai_message = _to_chat_message(reply.get("aiMessage", {}), is_ai=True)
    _save_message(session_id, ai_message)

    newly_completed: list[int] = []
    for i in reply.get("newlyCompletedGoalIndices", []):
        try:
            idx = int(i)
            if 0 <= idx < len(goals):
                newly_completed.append(idx)
        except (TypeError, ValueError):
            continue
    updated_completed = sorted(set(completed_indices + newly_completed))
    all_goals_completed = bool(reply.get("allGoalsCompleted")) or (
        len(goals) > 0 and set(updated_completed) == set(range(len(goals)))
    )

    recommended = reply.get("recommendedAnswer")
    recommended_message = None
    if recommended and not all_goals_completed:
        recommended_message = _to_chat_message(
            recommended, is_ai=False, is_recommended=True
        )

    session_update: dict[str, Any] = {
        "completedGoalIndices": updated_completed,
        "updatedAt": SERVER_TIMESTAMP,
    }
    if recommended_message and not all_goals_completed:
        session_update["pendingHint"] = recommended_message.model_dump(by_alias=True)
    else:
        session_update["pendingHint"] = None
    if all_goals_completed:
        session_update["status"] = "ended"
        session_update["endedAt"] = SERVER_TIMESTAMP
        session_update["endReason"] = "goals_completed"

    get_firestore().collection(SESSIONS_COLLECTION).document(session_id).update(
        session_update
    )

    return SendMessageResponse(
        aiMessage=ai_message,
        recommendedAnswer=recommended_message,
        completedGoalIndices=updated_completed,
        allGoalsCompleted=all_goals_completed,
    )


def end_session(uid: str, session_id: str) -> dict[str, str]:
    session = _get_session_doc(session_id)
    _assert_owner(session, uid)

    if session.get("status") != "ended":
        get_firestore().collection(SESSIONS_COLLECTION).document(session_id).update(
            {
                "status": "ended",
                "endedAt": SERVER_TIMESTAMP,
                "updatedAt": SERVER_TIMESTAMP,
            }
        )

    note = feedback_service.create_note_for_session(uid, session_id)
    return {
        "sessionId": session_id,
        "status": "ended",
        "noteId": note["id"],
    }
