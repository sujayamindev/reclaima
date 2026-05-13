from fastapi.testclient import TestClient
from sqlalchemy.exc import SQLAlchemyError
from fastapi import HTTPException

from app.main import app
from app.db.session import get_db
from app.core.config import settings

client = TestClient(app, raise_server_exceptions=False)


def test_readiness_db_failure(monkeypatch):
    class BrokenDB:
        def execute(self, *args, **kwargs):
            raise SQLAlchemyError("Simulated database failure")

    previous = app.dependency_overrides.get(get_db)
    app.dependency_overrides[get_db] = lambda: BrokenDB()
    response = client.get("/api/v1/ready")
    if previous:
        app.dependency_overrides[get_db] = previous
    else:
        app.dependency_overrides.pop(get_db, None)
    assert response.status_code == 503


def test_health_check_db_failure(monkeypatch):
    class BrokenDB:
        def execute(self, *args, **kwargs):
            raise SQLAlchemyError("Simulated database failure")

    previous = app.dependency_overrides.get(get_db)
    app.dependency_overrides[get_db] = lambda: BrokenDB()
    response = client.get("/api/v1/health")
    if previous:
        app.dependency_overrides[get_db] = previous
    else:
        app.dependency_overrides.pop(get_db, None)
    assert response.status_code == 200
    assert response.json()["status"] == "degraded"


def test_global_exception_handlers_hide_details(monkeypatch):
    monkeypatch.setattr(settings, "DEBUG", False)

    @app.get("/_test_db_crash")
    def crash_route():
        raise SQLAlchemyError("Secret DB Connection String Leaked!")

    db_resp = client.get("/_test_db_crash")
    assert db_resp.status_code == 500
    assert db_resp.json()["details"] is None


def test_auth_missing_token():
    response = client.get("/api/v1/auth/me")
    assert response.status_code == 401


def test_auth_invalid_token(monkeypatch):
    from app.core.security import get_current_user

    def mock_get_current_user():
        raise HTTPException(
            status_code=401, detail="Invalid authentication credentials"
        )

    app.dependency_overrides[get_current_user] = mock_get_current_user
    response = client.get(
        "/api/v1/auth/me", headers={"Authorization": "Bearer fake.token.here"}
    )
    app.dependency_overrides.pop(get_current_user, None)
    assert response.status_code == 401


def test_auth_register_new_user(db_session, monkeypatch):
    from app.core.security import get_current_user

    def mock_get_current_user():
        return {
            "uid": "new-test-firebase-uid",
            "email": "new@example.com",
            "name": "New User",
        }

    app.dependency_overrides[get_current_user] = mock_get_current_user

    response = client.post(
        "/api/v1/auth/register", headers={"Authorization": "Bearer valid.token.here"}
    )
    assert response.status_code == 201
    data = response.json()
    assert data["email"] == "new@example.com"

    response2 = client.get(
        "/api/v1/auth/me", headers={"Authorization": "Bearer valid.token.here"}
    )
    app.dependency_overrides.pop(get_current_user, None)
    assert response2.status_code == 200
    assert response2.json()["id"] == data["id"]


def test_auth_register_missing_uid(monkeypatch):
    from app.core.security import get_current_user

    def mock_get_current_user_no_uid():
        return {"email": "no-uid@example.com"}

    app.dependency_overrides[get_current_user] = mock_get_current_user_no_uid
    response = client.post("/api/v1/auth/register")
    app.dependency_overrides.pop(get_current_user, None)
    assert response.status_code == 400


def test_auth_get_me_not_found(monkeypatch):
    from app.core.security import get_current_user

    def mock_get_current_user_not_in_db():
        return {"uid": "non-existent-uid", "email": "not-found@example.com"}

    app.dependency_overrides[get_current_user] = mock_get_current_user_not_in_db
    response = client.get("/api/v1/auth/me")
    app.dependency_overrides.pop(get_current_user, None)
    assert response.status_code == 404


def test_auth_update_me_not_found(monkeypatch):
    from app.core.security import get_current_user

    def mock_get_current_user_not_in_db():
        return {"uid": "non-existent-uid", "email": "not-found@example.com"}

    app.dependency_overrides[get_current_user] = mock_get_current_user_not_in_db
    response = client.patch("/api/v1/auth/me", json={"full_name": "New Name"})
    app.dependency_overrides.pop(get_current_user, None)
    assert response.status_code == 404


def test_auth_delete_me_not_found(monkeypatch):
    from app.core.security import get_current_user

    def mock_get_current_user_not_in_db():
        return {"uid": "non-existent-uid", "email": "not-found@example.com"}

    app.dependency_overrides[get_current_user] = mock_get_current_user_not_in_db
    response = client.delete("/api/v1/auth/me")
    app.dependency_overrides.pop(get_current_user, None)
    assert response.status_code == 404
