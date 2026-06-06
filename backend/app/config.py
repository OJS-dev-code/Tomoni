from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

BACKEND_ROOT = Path(__file__).resolve().parent.parent


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=BACKEND_ROOT / ".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    environment: str = "development"
    port: int = 8000
    allow_mock_auth: bool = False

    firebase_project_id: str = ""
    firebase_service_account_json: str = ""
    firebase_credentials_path: str = ""

    gemini_api_key: str = ""
    gemini_model: str = "gemini-2.0-flash"

    # 대화 엔진: openai (권장, 자연스러움) | gemini
    dialogue_provider: str = "openai"
    openai_chat_model: str = "gpt-4o-mini"

    openai_api_key: str = ""
    openai_whisper_model: str = "whisper-1"
    openai_tts_model: str = "tts-1"
    openai_tts_voice: str = "nova"

    firebase_storage_bucket: str = ""

    @property
    def gemini_enabled(self) -> bool:
        return bool(self.gemini_api_key)

    @property
    def openai_enabled(self) -> bool:
        return bool(self.openai_api_key)

    @property
    def is_development(self) -> bool:
        return self.environment == "development"

    @property
    def resolved_credentials_path(self) -> str:
        if not self.firebase_credentials_path:
            return ""
        path = Path(self.firebase_credentials_path)
        if not path.is_absolute():
            path = BACKEND_ROOT / path
        return str(path)


@lru_cache
def get_settings() -> Settings:
    return Settings()
