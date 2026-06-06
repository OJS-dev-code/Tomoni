from datetime import datetime

from pydantic import BaseModel, Field


class UserProfileUpdate(BaseModel):
    gender: str = ""
    birth_date: str = Field(default="", alias="birthDate")
    level: str = "입문"
    duration: str = ""
    purposes: list[str] = Field(default_factory=list)
    hobbies: list[str] = Field(default_factory=list)
    ai_speed: str = Field(default="현지인 속도로", alias="aiSpeed")
    show_content_from_start: str = Field(default="예", alias="showContentFromStart")
    show_korean_translation: str = Field(default="예", alias="showKoreanTranslation")
    show_korean_pronunciation: str = Field(
        default="아니오", alias="showKoreanPronunciation"
    )

    model_config = {"populate_by_name": True}


class UserProfileResponse(UserProfileUpdate):
    uid: str
    created_at: datetime | None = Field(default=None, alias="createdAt")
    updated_at: datetime | None = Field(default=None, alias="updatedAt")

    model_config = {"populate_by_name": True, "by_alias": True}
