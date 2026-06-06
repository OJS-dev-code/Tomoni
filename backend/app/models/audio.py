from pydantic import BaseModel, Field


class TtsRequest(BaseModel):
    text: str = Field(..., min_length=1, max_length=500)
    speed: float = Field(default=1.0, ge=0.5, le=2.0)
    voice: str | None = Field(default=None, max_length=20)


class TtsResponse(BaseModel):
    audio_url: str
    cached: bool


class SttResponse(BaseModel):
    text: str
