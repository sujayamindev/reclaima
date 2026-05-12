"""Route and scheduler coverage tests for backend CI quality gates."""

from __future__ import annotations

import io
import uuid
from datetime import datetime, timezone, timedelta

import pytest
from fastapi import HTTPException, UploadFile
from starlette.datastructures import Headers

from app.api.v1 import auth as auth_api
from app.api.v1 import claims as claims_api
from app.api.v1 import notifications as notifications_api
from app.api.v1 import products as products_api
from app.api.v1 import receipts as receipts_api
from app.api.v1 import warranties as warranties_api
from app.models import ClaimDocument, Receipt, ReceiptLineItem, ReceiptStatus, User
from app.schemas import (
    ClaimDocumentUpdate,
    ClaimResolutionRequest,
    ReceiptCreate,
    ReceiptLineItemUpdate,
    ReceiptUpdate,
    UserFcmTokenUpdate,
    UserUpdate,
    UserNotificationPreferencesUpdate,
)
from app.services.user_service import UserService


def _make_user(db_session, uid: str = "route-user") -> User:
    user = User(
        id=str(uuid.uuid4()),
        firebase_uid=uid,
        email=f"{uid}@example.com",
        display_name="Route User",
        fcm_token="fcm-token",
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user


def _make_receipt(db_session, user_id: str, with_line_item: bool = True) -> Receipt:
    receipt = Receipt(
        id=str(uuid.uuid4()),
        user_id=user_id,
        store_name="Route Store",
        purchase_date=datetime.now(timezone.utc) - timedelta(days=1),
        status=ReceiptStatus.COMPLETED,
        s3_object_key="users/x/receipt/front.jpg",
    )
    db_session.add(receipt)
    db_session.flush()
    if with_line_item:
        line_item = ReceiptLineItem(
            id=str(uuid.uuid4()),
            receipt_id=str(receipt.id),
            row_index=0,
            item_description="Laptop",
            product_name="Laptop",
            warranty_period_months=12,
            warranty_expiry_date=datetime.now(timezone.utc) + timedelta(days=30),
            return_period_days=14,
            return_expiry_date=datetime.now(timezone.utc) + timedelta(days=7),
        )
        db_session.add(line_item)
    db_session.commit()
    db_session.refresh(receipt)
    return receipt


def _upload_file(name: str, content_type: str, content: bytes) -> UploadFile:
    return UploadFile(
        file=io.BytesIO(content),
        filename=name,
        headers=Headers({"content-type": content_type}),
    )


@pytest.mark.asyncio
async def test_auth_routes_and_user_service_flow(db_session) -> None:
    service = UserService()

    created = service.create_or_get_user(
        db_session,
        firebase_uid="uid-auth-1",
        email="auth@example.com",
        display_name="Auth User",
    )
    assert created.email == "auth@example.com"

    existing = service.create_or_get_user(
        db_session,
        firebase_uid="uid-auth-1-updated",
        email="auth@example.com",
        display_name="Auth User Updated",
    )
    assert existing.firebase_uid == "uid-auth-1-updated"

    assert (
        service.get_user_by_firebase_uid(db_session, "uid-auth-1-updated") is not None
    )
    assert service.get_user_by_id(db_session, str(existing.id)) is not None

    updated = service.update_user(
        db_session, str(existing.id), UserUpdate(display_name="Updated")
    )
    assert updated is not None
    assert updated.display_name == "Updated"

    bad_token = {"uid": "x"}
    with pytest.raises(HTTPException) as exc:
        await auth_api.register_user(
            current_user=bad_token, db=db_session, full_name=None
        )
    assert exc.value.status_code == 400

    token = {"uid": "uid-auth-1-updated", "email": "auth@example.com"}
    profile = await auth_api.get_current_user_profile(current_user=token, db=db_session)
    assert profile.id == str(existing.id)

    updated_profile = await auth_api.update_current_user_profile(
        user_data=UserUpdate(contact_number="+1 555 0000"),
        current_user=token,
        db=db_session,
    )
    assert updated_profile.contact_number == "+1 555 0000"

    await auth_api.delete_current_user_account(current_user=token, db=db_session)
    deleted_user = service.get_user_by_id(db_session, str(existing.id))
    assert deleted_user is not None
    assert deleted_user.deleted_at is not None


@pytest.mark.asyncio
async def test_warranty_and_return_routes(db_session) -> None:
    user = _make_user(db_session, uid="warranty-user")
    receipt = _make_receipt(db_session, str(user.id), with_line_item=True)

    expired_item = ReceiptLineItem(
        id=str(uuid.uuid4()),
        receipt_id=str(receipt.id),
        row_index=1,
        item_description="Old Monitor",
        warranty_expiry_date=datetime.now(timezone.utc) - timedelta(days=3),
        return_expiry_date=datetime.now(timezone.utc) - timedelta(days=1),
        warranty_period_months=6,
        return_period_days=10,
    )
    db_session.add(expired_item)
    db_session.commit()

    active_warranties = await warranties_api.list_active_warranties(
        include_expired=False,
        user_id=str(user.id),
        db=db_session,
    )
    assert len(active_warranties) == 1

    all_warranties = await warranties_api.list_active_warranties(
        include_expired=True,
        user_id=str(user.id),
        db=db_session,
    )
    assert len(all_warranties) == 2

    active_returns = await warranties_api.list_return_deadlines(
        include_expired=False,
        user_id=str(user.id),
        db=db_session,
    )
    assert len(active_returns) == 1

    all_returns = await warranties_api.list_return_deadlines(
        include_expired=True,
        user_id=str(user.id),
        db=db_session,
    )
    assert len(all_returns) == 2


@pytest.mark.asyncio
async def test_notification_and_products_routes(db_session, monkeypatch) -> None:
    user = _make_user(db_session, uid="notify-route-user")
    current_user = {"uid": user.firebase_uid}

    prefs = await notifications_api.get_notification_preferences(
        current_user=current_user,
        db=db_session,
    )
    assert prefs.user_id == str(user.id)

    saved = await notifications_api.save_notification_preferences(
        prefs_update=UserNotificationPreferencesUpdate(warranty_lead_days=9),
        current_user=current_user,
        db=db_session,
    )
    assert saved.warranty_lead_days == 9

    await notifications_api.update_fcm_token(
        body=UserFcmTokenUpdate(token="fresh-token"),
        current_user=current_user,
        db=db_session,
    )

    class _ImageService:
        async def search_product_image(self, query: str):
            return {"imageUrl": "https://img/1.jpg", "title": query, "source": "test"}

    monkeypatch.setattr(products_api, "_get_image_service", lambda: _ImageService())
    found = await products_api.search_product_image(
        query="Laptop", current_user=current_user
    )
    assert found["imageUrl"].endswith("1.jpg")

    class _NoImageService:
        async def search_product_image(self, query: str):
            return None

    monkeypatch.setattr(products_api, "_get_image_service", lambda: _NoImageService())
    with pytest.raises(HTTPException) as exc:
        await products_api.search_product_image(
            query="Unknown", current_user=current_user
        )
    assert exc.value.status_code == 404


@pytest.mark.asyncio
async def test_receipt_routes_branches(db_session, monkeypatch) -> None:
    user = _make_user(db_session, uid="receipt-route-user")
    current_user = {"uid": user.firebase_uid}
    receipt = _make_receipt(db_session, str(user.id), with_line_item=True)

    monkeypatch.setattr(
        receipts_api.receipt_service,
        "create_receipt",
        lambda db, uid, payload: receipt,
    )
    created = await receipts_api.create_receipt(
        receipt_data=ReceiptCreate(store_name="X"),
        current_user=current_user,
        db=db_session,
    )
    assert created.id == receipt.id

    monkeypatch.setattr(
        receipts_api.receipt_service,
        "list_receipts",
        lambda db, user_id, skip, limit, status: ([receipt], 1),
    )
    listed = await receipts_api.list_receipts(
        page=1,
        page_size=10,
        status_filter=None,
        current_user=current_user,
        db=db_session,
    )
    assert listed["total"] == 1

    monkeypatch.setattr(
        receipts_api.receipt_service, "get_receipt", lambda db, rid, uid: None
    )
    with pytest.raises(HTTPException) as exc:
        await receipts_api.get_receipt(
            str(receipt.id), current_user=current_user, db=db_session
        )
    assert exc.value.status_code == 404

    monkeypatch.setattr(
        receipts_api.receipt_service,
        "update_receipt",
        lambda db, rid, uid, payload: None,
    )
    with pytest.raises(HTTPException) as exc:
        await receipts_api.update_receipt(
            str(receipt.id),
            receipt_data=ReceiptUpdate(store_name="Y"),
            current_user=current_user,
            db=db_session,
        )
    assert exc.value.status_code == 404

    monkeypatch.setattr(
        receipts_api.receipt_service, "delete_receipt", lambda db, rid, uid: False
    )
    with pytest.raises(HTTPException) as exc:
        await receipts_api.delete_receipt(
            str(receipt.id), current_user=current_user, db=db_session
        )
    assert exc.value.status_code == 404

    bad_type = _upload_file("file.txt", "text/plain", b"abc")
    with pytest.raises(HTTPException) as exc:
        await receipts_api.upload_receipt_file(
            str(receipt.id),
            file=bad_type,
            current_user=current_user,
            db=db_session,
        )
    assert exc.value.status_code == 400

    huge = _upload_file(
        "file.jpg",
        "image/jpeg",
        b"a" * (receipts_api.settings.max_file_size_bytes + 1),
    )
    with pytest.raises(HTTPException) as exc:
        await receipts_api.upload_receipt_file(
            str(receipt.id),
            file=huge,
            current_user=current_user,
            db=db_session,
        )
    assert exc.value.status_code == 413

    with pytest.raises(HTTPException) as exc:
        await receipts_api.ocr_extract(
            front_image=None,
            back_image=None,
            current_user=current_user,
            db=db_session,
        )
    assert exc.value.status_code == 400

    bad_front = _upload_file("file.txt", "text/plain", b"abc")
    with pytest.raises(HTTPException) as exc:
        await receipts_api.ocr_extract(
            front_image=bad_front,
            back_image=None,
            current_user=current_user,
            db=db_session,
        )
    assert exc.value.status_code == 400

    monkeypatch.setattr(
        receipts_api.receipt_service, "create_line_item", lambda *args, **kwargs: None
    )
    with pytest.raises(HTTPException) as exc:
        await receipts_api.create_line_item(
            str(receipt.id),
            item_data=ReceiptLineItemUpdate(item_description="Mouse"),
            current_user=current_user,
            db=db_session,
        )
    assert exc.value.status_code == 404

    monkeypatch.setattr(
        receipts_api.receipt_service, "update_line_item", lambda *args, **kwargs: None
    )
    with pytest.raises(HTTPException) as exc:
        await receipts_api.update_line_item(
            str(receipt.id),
            "missing-item",
            item_data=ReceiptLineItemUpdate(item_description="Mouse"),
            current_user=current_user,
            db=db_session,
        )
    assert exc.value.status_code == 404

    monkeypatch.setattr(
        receipts_api.receipt_service, "delete_line_item", lambda *args, **kwargs: False
    )
    with pytest.raises(HTTPException) as exc:
        await receipts_api.delete_line_item(
            str(receipt.id),
            "missing-item",
            current_user=current_user,
            db=db_session,
        )
    assert exc.value.status_code == 404


@pytest.mark.asyncio
async def test_claim_routes_success_and_errors(db_session, monkeypatch) -> None:
    user = _make_user(db_session, uid="claim-route-user")
    current_user = {"uid": user.firebase_uid}
    receipt = _make_receipt(db_session, str(user.id), with_line_item=True)
    line_item = (
        db_session.query(ReceiptLineItem)
        .filter(ReceiptLineItem.receipt_id == str(receipt.id))
        .first()
    )
    assert line_item is not None

    too_many = [_upload_file(f"{i}.jpg", "image/jpeg", b"img") for i in range(11)]
    with pytest.raises(HTTPException) as exc:
        await claims_api.create_claim(
            receipt_id=str(receipt.id),
            issue_description="Issue",
            claim_type="warranty",
            line_item_id=str(line_item.id),
            defect_images=too_many,
            current_user=current_user,
            db=db_session,
        )
    assert exc.value.status_code == 400

    class _DummyS3:
        def __init__(self) -> None:
            self.files: dict[str, bytes] = {}

        def upload_file(self, file_content, object_key, content_type):
            self.files[object_key] = file_content
            return object_key

        def file_exists(self, object_key):
            return object_key in self.files

        def generate_presigned_url(
            self, object_key, expiration=3600, operation="get_object"
        ):
            return f"https://signed/{object_key}"

    class _DummyPDF:
        def generate_claim_pdf(self, **kwargs):
            return b"%PDF-test"

    dummy_s3 = _DummyS3()
    monkeypatch.setattr(claims_api, "get_s3_service", lambda **kwargs: dummy_s3)
    monkeypatch.setattr(claims_api, "get_pdf_service", lambda: _DummyPDF())

    one_image = [_upload_file("defect.jpg", "image/jpeg", b"\xff\xd8\xff" + b"image-data")]
    created = await claims_api.create_claim(
        receipt_id=str(receipt.id),
        issue_description="Battery failure",
        claim_type="warranty",
        line_item_id=str(line_item.id),
        defect_images=one_image,
        current_user=current_user,
        db=db_session,
    )
    assert created.receipt_id == str(receipt.id)
    claim_id = created.id

    updated = await claims_api.update_claim(
        claim_id,
        claim_update=ClaimDocumentUpdate(notes="updated note"),
        current_user=current_user,
        db=db_session,
    )
    assert updated.notes == "updated note"

    resolved = await claims_api.resolve_claim(
        claim_id,
        resolution_data=ClaimResolutionRequest(outcome="REFUNDED"),
        current_user=current_user,
        db=db_session,
    )
    assert resolved.status.value == "RESOLVED"

    listed = await claims_api.list_claims(
        receipt_id=str(receipt.id),
        line_item_id=None,
        current_user=current_user,
        db=db_session,
    )
    assert len(listed) >= 1

    fetched = await claims_api.get_claim(
        claim_id, current_user=current_user, db=db_session
    )
    assert fetched.id == claim_id

    # Force regeneration path for PDF access.
    claim_row = (
        db_session.query(ClaimDocument).filter(ClaimDocument.id == claim_id).first()
    )
    assert claim_row is not None
    claim_row.generated_pdf_s3_key = "missing.pdf"
    db_session.commit()

    accessed = await claims_api.access_claim_pdf(
        claim_id, current_user=current_user, db=db_session
    )
    assert accessed.url is not None

    await claims_api.delete_claim(claim_id, current_user=current_user, db=db_session)
    deleted = (
        db_session.query(ClaimDocument).filter(ClaimDocument.id == claim_id).first()
    )
    assert deleted is not None
    assert deleted.deleted_at is not None


@pytest.mark.asyncio
async def test_claim_routes_cross_user_access(db_session, monkeypatch) -> None:
    # 1. Setup: Create User A and User B
    user_a = _make_user(db_session, uid="user-a-uid")
    user_b = _make_user(db_session, uid="user-b-uid")

    user_a_context = {"uid": user_a.firebase_uid}
    user_b_context = {"uid": user_b.firebase_uid}

    # 2. Seed Data: Create a receipt and line item for User A
    receipt_a = _make_receipt(db_session, str(user_a.id), with_line_item=True)
    line_item_a = (
        db_session.query(ReceiptLineItem)
        .filter(ReceiptLineItem.receipt_id == str(receipt_a.id))
        .first()
    )
    assert line_item_a is not None

    # Mock S3 and PDF to allow Claim creation
    class _DummyS3:
        def __init__(self) -> None:
            self.files: dict[str, bytes] = {}

        def upload_file(self, file_content, object_key, content_type):
            self.files[object_key] = file_content
            return object_key

        def file_exists(self, object_key):
            return object_key in self.files

        def generate_presigned_url(
            self, object_key, expiration=3600, operation="get_object"
        ):
            return f"https://signed/{object_key}"

    class _DummyPDF:
        def generate_claim_pdf(self, **kwargs):
            return b"%PDF-test"

    monkeypatch.setattr(claims_api, "get_s3_service", lambda **kwargs: _DummyS3())
    monkeypatch.setattr(claims_api, "get_pdf_service", lambda: _DummyPDF())

    # Create Claim for User A
    claim_a = await claims_api.create_claim(
        receipt_id=str(receipt_a.id),
        issue_description="Broken screen",
        claim_type="warranty",
        line_item_id=str(line_item_a.id),
        defect_images=[],
        current_user=user_a_context,
        db=db_session,
    )
    claim_id_a = claim_a.id

    # 3. Attack Simulation: User B tries to access User A's data

    # A. User B tries to list claims filtering by User A's receipt
    with pytest.raises(HTTPException) as exc:
        await claims_api.list_claims(
            receipt_id=str(receipt_a.id),
            line_item_id=None,
            current_user=user_b_context,
            db=db_session,
        )
    assert exc.value.status_code == 403

    # B. User B tries to list claims filtering by User A's line item (T-06 fix test)
    # The query filters out the results, so it should return an empty list rather than 403
    listed_by_line_item = await claims_api.list_claims(
        receipt_id=None,
        line_item_id=str(line_item_a.id),
        current_user=user_b_context,
        db=db_session,
    )
    assert len(listed_by_line_item) == 0

    # C. User B tries to get User A's specific claim
    with pytest.raises(HTTPException) as exc:
        await claims_api.get_claim(
            claim_id_a,
            current_user=user_b_context,
            db=db_session,
        )
    assert exc.value.status_code == 403

    # D. User B tries to update User A's claim
    with pytest.raises(HTTPException) as exc:
        await claims_api.update_claim(
            claim_id_a,
            claim_update=ClaimDocumentUpdate(notes="hacked"),
            current_user=user_b_context,
            db=db_session,
        )
    assert exc.value.status_code == 403

    # E. User B tries to resolve User A's claim
    with pytest.raises(HTTPException) as exc:
        await claims_api.resolve_claim(
            claim_id_a,
            resolution_data=ClaimResolutionRequest(outcome="REFUNDED"),
            current_user=user_b_context,
            db=db_session,
        )
    assert exc.value.status_code == 403

    # F. User B tries to access User A's claim PDF
    with pytest.raises(HTTPException) as exc:
        await claims_api.access_claim_pdf(
            claim_id_a,
            current_user=user_b_context,
            db=db_session,
        )
    assert exc.value.status_code == 403

    # G. User B tries to delete User A's claim
    with pytest.raises(HTTPException) as exc:
        await claims_api.delete_claim(
            claim_id_a,
            current_user=user_b_context,
            db=db_session,
        )
    assert exc.value.status_code == 403


def test_run_hard_delete_cleanup(monkeypatch) -> None:
    from app.services import deletion_service
    from app.db import session as db_session_module
    from app.services import s3_service

    class _DummyS3:
        pass

    class _DummyDeletionService:
        def __init__(self, s3):
            self.s3 = s3

        def run_hard_delete_job(self, db):
            return {"total": 1, "users": 0, "receipts": 0, "line_items": 0, "claims": 1}

    class _DummyDB:
        def close(self):
            pass

        def rollback(self):
            pass

    monkeypatch.setattr(db_session_module, "SessionLocal", lambda: _DummyDB())
    monkeypatch.setattr(s3_service, "get_s3_service", lambda **kwargs: _DummyS3())
    monkeypatch.setattr(deletion_service, "DeletionService", _DummyDeletionService)

    # Execute the cleanup wrapper
    deletion_service.run_hard_delete_cleanup()
