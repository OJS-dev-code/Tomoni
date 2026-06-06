import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.routers import audio, health, mistakes, notes, scenarios, users
from app.services.firebase import init_firebase

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(_: FastAPI):
    settings = get_settings()
    try:
        init_firebase()
    except RuntimeError:
        if not settings.allow_mock_auth:
            raise
        logger.warning("Starting without Firebase credentials (mock-auth mode)")
    yield


def create_app() -> FastAPI:
    settings = get_settings()

    app = FastAPI(
        title="Tomoni API",
        description="Backend API for Tomoni — Japanese keigo learning app",
        version="0.2.0",
        lifespan=lifespan,
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=False,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(health.router, prefix="/api/v1")
    app.include_router(users.router, prefix="/api/v1")
    app.include_router(scenarios.router, prefix="/api/v1")
    app.include_router(audio.router, prefix="/api/v1")
    app.include_router(notes.router, prefix="/api/v1")
    app.include_router(mistakes.router, prefix="/api/v1")

    return app


app = create_app()
