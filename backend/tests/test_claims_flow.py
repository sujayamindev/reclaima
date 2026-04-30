import pytest
import uuid
from fastapi.testclient import TestClient

from app.main import app
from app.core.security import get_current_user, get_current_user_id
from app.models import ClaimDocument, ReceiptLineItem
from tests.test_helpers import _create_user, _make_receipt

client = TestClient(app, raise_server_exceptions=False)


@pytest.fixture()
def user_a(db_session):
    return _create_user(db_session, uid="claims-user-a")


@pytest.fixture()
def user_b(db_session):
    return _create_user(db_session, uid="claims-user-b")


def mock_auth(user_uuid: str, firebase_uid: str):
    app.dependency_overrides[get_current_user] = lambda: {
        "uid": firebase_uid,
        "email": "test@test.com",
    }
    app.dependency_overrides[get_current_user_id] = lambda: user_uuid


def cleanup_auth():
    app.dependency_overrides.pop(get_current_user, None)
    app.dependency_overrides.pop(get_current_user_id, None)


# ============================================
# Resolution Tests
# ============================================


def test_resolve_claim_refunded(db_session, user_a):
    mock_auth(str(user_a.id), user_a.firebase_uid)
    receipt = _make_receipt(db_session, str(user_a.id), with_line_item=True)
    item = (
        db_session.query(ReceiptLineItem)
        .filter(ReceiptLineItem.receipt_id == str(receipt.id))
        .first()
    )

    claim = ClaimDocument(
        id=str(uuid.uuid4()),
        receipt_id=str(receipt.id),
        line_item_id=str(item.id),
        issue_description="Broken",
        status="PENDING",
    )
    db_session.add(claim)
    db_session.commit()

    payload = {"outcome": "REFUNDED"}
    resp = client.post(f"/api/v1/claims/{claim.id}/resolve", json=payload)
    assert resp.status_code == 200
    assert resp.json()["status"] == "RESOLVED"

    db_session.refresh(item)
    assert item.status == "ARCHIVED"
    cleanup_auth()


def test_resolve_claim_replaced_duplicate(db_session, user_a):
    mock_auth(str(user_a.id), user_a.firebase_uid)
    receipt = _make_receipt(db_session, str(user_a.id), with_line_item=True)
    item = (
        db_session.query(ReceiptLineItem)
        .filter(ReceiptLineItem.receipt_id == str(receipt.id))
        .first()
    )

    claim = ClaimDocument(
        id=str(uuid.uuid4()),
        receipt_id=str(receipt.id),
        line_item_id=str(item.id),
        issue_description="Broken",
        status="PENDING",
    )
    db_session.add(claim)
    db_session.commit()

    payload = {"outcome": "REPLACED", "duplicate_details": True}
    resp = client.post(f"/api/v1/claims/{claim.id}/resolve", json=payload)
    assert resp.status_code == 200

    db_session.refresh(item)
    assert item.status == "ARCHIVED"
    assert item.replaced_by_id is not None

    new_item = (
        db_session.query(ReceiptLineItem)
        .filter(ReceiptLineItem.id == item.replaced_by_id)
        .first()
    )
    assert new_item is not None
    assert new_item.status == "ACTIVE"
    assert new_item.replacement_for_id == str(item.id)
    cleanup_auth()


def test_resolve_claim_replaced_linked_item(db_session, user_a):
    mock_auth(str(user_a.id), user_a.firebase_uid)
    receipt1 = _make_receipt(db_session, str(user_a.id), with_line_item=True)
    item1 = (
        db_session.query(ReceiptLineItem)
        .filter(ReceiptLineItem.receipt_id == str(receipt1.id))
        .first()
    )

    receipt2 = _make_receipt(db_session, str(user_a.id), with_line_item=True)
    item2 = (
        db_session.query(ReceiptLineItem)
        .filter(ReceiptLineItem.receipt_id == str(receipt2.id))
        .first()
    )

    claim = ClaimDocument(
        id=str(uuid.uuid4()),
        receipt_id=str(receipt1.id),
        line_item_id=str(item1.id),
        issue_description="Broken",
        status="PENDING",
    )
    db_session.add(claim)
    db_session.commit()

    payload = {"outcome": "REPLACED", "linked_item_id": str(item2.id)}
    resp = client.post(f"/api/v1/claims/{claim.id}/resolve", json=payload)
    assert resp.status_code == 200

    db_session.refresh(item1)
    db_session.refresh(item2)
    assert item1.status == "ARCHIVED"
    assert item1.replaced_by_id == str(item2.id)
    assert item2.replacement_for_id == str(item1.id)
    cleanup_auth()


def test_resolve_claim_replaced_linked_item_forbidden(db_session, user_a, user_b):
    """Test T-18 ownership check: User A tries to link a replacement item owned by User B."""
    mock_auth(str(user_a.id), user_a.firebase_uid)
    receipt_a = _make_receipt(db_session, str(user_a.id), with_line_item=True)
    item_a = (
        db_session.query(ReceiptLineItem)
        .filter(ReceiptLineItem.receipt_id == str(receipt_a.id))
        .first()
    )

    receipt_b = _make_receipt(db_session, str(user_b.id), with_line_item=True)
    item_b = (
        db_session.query(ReceiptLineItem)
        .filter(ReceiptLineItem.receipt_id == str(receipt_b.id))
        .first()
    )

    claim = ClaimDocument(
        id=str(uuid.uuid4()),
        receipt_id=str(receipt_a.id),
        line_item_id=str(item_a.id),
        issue_description="Broken",
        status="PENDING",
    )
    db_session.add(claim)
    db_session.commit()

    payload = {"outcome": "REPLACED", "linked_item_id": str(item_b.id)}
    resp = client.post(f"/api/v1/claims/{claim.id}/resolve", json=payload)
    assert resp.status_code == 403
    cleanup_auth()
