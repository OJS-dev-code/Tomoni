from pydantic import BaseModel, Field


class FeedbackItemResponse(BaseModel):
    title: str
    japanese: str
    pronunciation: str = ""
    translation: str = ""
    description: str | None = None


class HintResponseItem(BaseModel):
    user_text: str = Field(alias="userText")
    hint_text: str = Field(alias="hintText")
    hint_pronunciation: str = Field(default="", alias="hintPronunciation")
    hint_translation: str = Field(default="", alias="hintTranslation")

    model_config = {"populate_by_name": True, "by_alias": True}


class FeedbackNoteResponse(BaseModel):
    id: str
    session_id: str = Field(alias="sessionId")
    topic: str
    score: int = Field(ge=1, le=5)
    items: list[FeedbackItemResponse]
    hint_responses: list[HintResponseItem] = Field(
        default_factory=list, alias="hintResponses"
    )
    created_at: str = Field(alias="createdAt")

    model_config = {"populate_by_name": True, "by_alias": True}


class FeedbackNoteListResponse(BaseModel):
    notes: list[FeedbackNoteResponse]
