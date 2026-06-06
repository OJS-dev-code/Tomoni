import os

os.environ["ALLOW_MOCK_AUTH"] = "true"
os.environ["ENVIRONMENT"] = "test"

from fastapi.testclient import TestClient

from app.dependencies.auth import MOCK_DEV_TOKEN
from app.main import app

client = TestClient(app)
AUTH_HEADERS = {"Authorization": f"Bearer {MOCK_DEV_TOKEN}"}


def test_health_check():
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ok"
    assert body["mock_auth_enabled"] is True


def test_get_profile_returns_defaults():
    response = client.get("/api/v1/users/profile", headers=AUTH_HEADERS)
    assert response.status_code == 200
    body = response.json()
    assert body["uid"] == "mock-dev-user"
    assert body["level"] == "입문"
    assert body["purposes"] == []


def test_update_profile():
    payload = {
        "gender": "여성",
        "birthDate": "2000.1.1",
        "level": "중급",
        "duration": "1년 이상",
        "purposes": ["취업/비즈니스"],
        "hobbies": ["여행"],
        "aiSpeed": "현지인 속도로",
        "showContentFromStart": "예",
        "showKoreanTranslation": "예",
        "showKoreanPronunciation": "아니오",
    }
    response = client.put(
        "/api/v1/users/profile",
        headers=AUTH_HEADERS,
        json=payload,
    )
    assert response.status_code == 200
    body = response.json()
    assert body["gender"] == "여성"
    assert body["level"] == "중급"
    assert body["purposes"] == ["취업/비즈니스"]

    get_response = client.get("/api/v1/users/profile", headers=AUTH_HEADERS)
    assert get_response.status_code == 200
    assert get_response.json()["level"] == "중급"


def test_unauthorized_without_token():
    response = client.get("/api/v1/users/profile")
    assert response.status_code == 401
