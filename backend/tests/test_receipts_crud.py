import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.core.security import get_current_user_id, get_current_user
from tests.test_helpers import _create_user, _make_receipt

client = TestClient(app, raise_server_exceptions=False)


@pytest.fixture()
def user_a(db_session):
    return _create_user(db_session, uid="crud-user-a")


@pytest.fixture()
def user_b(db_session):
    return _create_user(db_session, uid="crud-user-b")


def mock_auth(user_uuid: str, firebase_uid: str):
    app.dependency_overrides[get_current_user_id] = lambda: user_uuid
    app.dependency_overrides[get_current_user] = lambda: {
        "uid": firebase_uid,
        "email": "test@test.com",
    }


def cleanup_auth():
    app.dependency_overrides.pop(get_current_user_id, None)
    app.dependency_overrides.pop(get_current_user, None)


# ============================================
# CRUD Tests
# ============================================


def test_create_and_fetch_receipt(db_session, user_a):
    mock_auth(str(user_a.id), user_a.firebase_uid)

    # Create Receipt
    payload = {
        "store_name": "Test Store A",
        "purchase_date": "2026-05-01T12:00:00Z",
        "total_amount": 100.50,
        "currency": "USD",
        "receipt_url": "https://test.local/receipt.jpg",
        "warranty_notes": "1 year warranty",
    }

    resp = client.post("/api/v1/receipts", json=payload)
    assert resp.status_code == 201
    data = resp.json()
    receipt_id = data["id"]
    assert data["storeName"] == "Test Store A"

    # Fetch Receipt
    fetch_resp = client.get(f"/api/v1/receipts/{receipt_id}")
    assert fetch_resp.status_code == 200
    assert fetch_resp.json()["id"] == receipt_id

    cleanup_auth()


def test_update_receipt(db_session, user_a):
    mock_auth(str(user_a.id), user_a.firebase_uid)
    receipt = _make_receipt(db_session, str(user_a.id))

    payload = {"store_name": "Updated Store Name"}

    resp = client.patch(f"/api/v1/receipts/{receipt.id}", json=payload)
    assert resp.status_code == 200
    assert resp.json()["storeName"] == "Updated Store Name"
    cleanup_auth()


def test_delete_receipt(db_session, user_a):
    mock_auth(str(user_a.id), user_a.firebase_uid)
    receipt = _make_receipt(db_session, str(user_a.id))

    resp = client.delete(f"/api/v1/receipts/{receipt.id}")
    assert resp.status_code == 204

    fetch_resp = client.get(f"/api/v1/receipts/{receipt.id}")
    assert fetch_resp.status_code == 404
    cleanup_auth()


def test_list_receipts_pagination(db_session, user_a):
    mock_auth(str(user_a.id), user_a.firebase_uid)

    # Create 5 receipts
    for _ in range(5):
        _make_receipt(db_session, str(user_a.id))

    # Test Pagination
    resp = client.get("/api/v1/receipts?page=1&page_size=2")
    assert resp.status_code == 200
    data = resp.json()
    assert len(data["receipts"]) == 2
    assert data["total"] >= 5
    assert data["page"] == 1
    assert data["pageSize"] == 2
    cleanup_auth()


# ============================================
# Tenant Isolation (Security) Tests
# ============================================


def test_cross_tenant_read_access_denied(db_session, user_a, user_b):
    receipt_a = _make_receipt(db_session, str(user_a.id))

    mock_auth(str(user_b.id), user_b.firebase_uid)

    # Attempt to read User A's receipt
    resp = client.get(f"/api/v1/receipts/{receipt_a.id}")
    assert resp.status_code == 404
    cleanup_auth()


def test_cross_tenant_update_access_denied(db_session, user_a, user_b):
    receipt_a = _make_receipt(db_session, str(user_a.id))

    mock_auth(str(user_b.id), user_b.firebase_uid)
    payload = {"store_name": "Hacked"}
    resp = client.patch(f"/api/v1/receipts/{receipt_a.id}", json=payload)
    assert resp.status_code == 404
    cleanup_auth()


def test_cross_tenant_delete_access_denied(db_session, user_a, user_b):
    receipt_a = _make_receipt(db_session, str(user_a.id))

    mock_auth(str(user_b.id), user_b.firebase_uid)
    resp = client.delete(f"/api/v1/receipts/{receipt_a.id}")
    assert resp.status_code == 404
    cleanup_auth()
