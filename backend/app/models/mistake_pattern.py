from pydantic import BaseModel, Field


class MistakePatternResponse(BaseModel):
    id: str
    category: str
    label: str
    description: str = ""
    user_example: str = Field(default="", alias="userExample")
    better_japanese: str = Field(default="", alias="betterJapanese")
    better_pronunciation: str = Field(default="", alias="betterPronunciation")
    better_translation: str = Field(default="", alias="betterTranslation")
    count: int = 1
    last_topic: str = Field(default="", alias="lastTopic")
    updated_at: str = Field(default="", alias="updatedAt")

    model_config = {"populate_by_name": True, "by_alias": True}


class MistakePatternListResponse(BaseModel):
    patterns: list[MistakePatternResponse]
