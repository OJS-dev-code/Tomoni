from pydantic import BaseModel, Field


class ChatMessage(BaseModel):
    is_ai: bool = Field(alias="isAI")
    text: str
    pronunciation: str = ""
    translation: str = ""
    is_recommended: bool | None = Field(default=None, alias="isRecommended")
    used_hint: bool | None = Field(default=None, alias="usedHint")
    hint_text: str = Field(default="", alias="hintText")
    hint_pronunciation: str = Field(default="", alias="hintPronunciation")
    hint_translation: str = Field(default="", alias="hintTranslation")

    model_config = {"populate_by_name": True, "by_alias": True}


class SessionCreateRequest(BaseModel):
    topic: str
    goals: list[str]
    ai_gender: str | None = Field(default=None, alias="aiGender")

    model_config = {"populate_by_name": True}


class SessionPreviewRequest(BaseModel):
    topic: str
    goals: list[str]


class SessionPreviewResponse(BaseModel):
    topic: str
    ai_role: str = Field(alias="aiRole")
    user_role: str = Field(alias="userRole")
    location: str
    speaker_first: str = Field(alias="speakerFirst")
    scene_note: str = Field(default="", alias="sceneNote")
    suggested_ai_gender: str = Field(default="female", alias="suggestedAiGender")
    tts_voice: str = Field(default="shimmer", alias="ttsVoice")

    model_config = {"populate_by_name": True, "by_alias": True}


class SessionCreateResponse(BaseModel):
    session_id: str = Field(alias="sessionId")
    topic: str
    goals: list[str]
    ai_role: str = Field(alias="aiRole")
    user_role: str = Field(alias="userRole")
    location: str
    tts_voice: str = Field(alias="ttsVoice")
    speaker_first: str = Field(alias="speakerFirst")
    scene_note: str = Field(default="", alias="sceneNote")
    opening_message: ChatMessage | None = Field(default=None, alias="openingMessage")

    model_config = {"populate_by_name": True, "by_alias": True}


class SendMessageRequest(BaseModel):
    text: str
    used_hint: bool = Field(default=False, alias="usedHint")
    hint_text: str = Field(default="", alias="hintText")
    hint_pronunciation: str = Field(default="", alias="hintPronunciation")
    hint_translation: str = Field(default="", alias="hintTranslation")

    model_config = {"populate_by_name": True}


class SendMessageResponse(BaseModel):
    ai_message: ChatMessage = Field(alias="aiMessage")
    recommended_answer: ChatMessage | None = Field(
        default=None, alias="recommendedAnswer"
    )
    completed_goal_indices: list[int] = Field(
        default_factory=list, alias="completedGoalIndices"
    )
    all_goals_completed: bool = Field(default=False, alias="allGoalsCompleted")

    model_config = {"populate_by_name": True, "by_alias": True}


class SessionEndResponse(BaseModel):
    session_id: str = Field(alias="sessionId")
    status: str
    note_id: str | None = Field(default=None, alias="noteId")

    model_config = {"populate_by_name": True, "by_alias": True}
