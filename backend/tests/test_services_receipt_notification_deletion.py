"""Integration-style service tests for receipt, notification, and deletion flows."""

from __future__ import annotations

import uuid
from datetime import datetime, timezone, timedelta
from decimal import Decimal

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.db.base import Base
from app.models import (
    ClaimDocument,
    Receipt,
    ReceiptLineItem,
    ReceiptStatus,
    User,
)
from app.schemas import ReceiptCreate, ReceiptLineItemUpdate, ReceiptUpdate
from app.services.deletion_service import DeletionService
from app.services.notification_service import NotificationService
from app.services.receipt_service import ReceiptService
from app.services.s3_service import MockS3Service


class _DummyLLM:
    def clean_receipt_notes(self, text: str) -> str:
        return f"clean:{text}"


class _StubTextract:
    def __init__(self, responses_by_token: dict[str, dict] | None = None) -> None:
        self.responses_by_token = responses_by_token or {}

    def analyze_document(self, s3_object_key: str) -> dict:
        for token, result in self.responses_by_token.items():
            if token in s3_object_key:
                return result
        return {"status": "failed", "extracted_data": {}}


class _StubProductImageService:
    def search_product_image_sync(self, query: str):
        return {"imageUrl": f"https://img.local/{query.replace(' ', '-')}"}


@pytest.fixture()
def db_session():
    engine = create_engine("sqlite:///:memory:", connect_args={"check_same_thread": False})
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    Base.metadata.create_all(bind=engine)

    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()
        Base.metadata.drop_all(bind=engine)


def _create_user(db_session, uid: str = "test-firebase-uid") -> User:
    user = User(
        id=str(uuid.uuid4()),
        firebase_uid=uid,
        email=f"{uid}@example.com",
        display_name="Test User",
        fcm_token="fcm-token-1",
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user


def _make_receipt_service(textract_map: dict[str, dict] | None = None) -> ReceiptService:
    service = ReceiptService.__new__(ReceiptService)
    service.llm_service = _DummyLLM()
    service.s3_service = MockS3Service("unit-test-bucket")
    service.textract_service = _StubTextract(textract_map)
    service.product_image_service = _StubProductImageService()
    return service


def test_receipt_crud_and_list_flow(db_session) -> None:
    user = _create_user(db_session)
    service = _make_receipt_service()

    manual = service.create_receipt(
        db_session,
        str(user.id),
        ReceiptCreate(store_name="Manual Store", total_amount=45.6),
    )
    assert manual.status == ReceiptStatus.MANUAL_ENTRY

    with_images = service.create_receipt(
        db_session,
        str(user.id),
        ReceiptCreate(
            store_name="Image Store",
            s3_object_key="users/u/r/front.jpg",
            back_image_s3_key="users/u/r/back.jpg",
        ),
    )
    assert with_images.status == ReceiptStatus.COMPLETED
    assert len(with_images.images) == 2

    receipts, total = service.list_receipts(db_session, str(user.id), skip=0, limit=50)
    assert total == 2
    assert len(receipts) == 2

    updated = service.update_receipt(
        db_session,
        str(manual.id),
        str(user.id),
        ReceiptUpdate(store_name="Renamed Store"),
    )
    assert updated is not None
    assert updated.store_name == "Renamed Store"

    assert service.get_receipt_image_url(db_session, str(with_images.id), str(user.id))
    assert service.delete_receipt(db_session, str(manual.id), str(user.id))


def test_extract_ocr_from_file_and_multi_file_merge(db_session) -> None:
    user = _create_user(db_session, uid="ocr-user")
    service = _make_receipt_service(
        textract_map={
            "front_": {
                "status": "success",
                "extracted_data": {
                    "store_name": "Front Store",
                    "purchase_date": "2026-01-10",
                    "total_amount": "100.25",
                    "line_items": [{"item_description": "Front Item", "quantity": 1}],
                    "remarks": "front note",
                },
            },
            "back_": {
                "status": "success",
                "extracted_data": {
                    "line_items": [{"item_description": "Back Item", "quantity": 1}],
                    "warranty_notes": "back warranty",
                },
            },
            "single": {
                "status": "success",
                "extracted_data": {
                    "store_name": "Single Store",
                    "purchase_date": "bad-date",
                    "total_amount": "not-number",
                    "line_items": [{"item_description": "Only Item", "quantity": 1}],
                },
            },
        }
    )

    single = service.extract_ocr_from_file(
        user_id=str(user.id),
        file_content=b"front",
        file_name="single.jpg",
        content_type="image/jpeg",
    )
    assert single["ocr_status"] == "success"
    assert single["store_name"] == "Single Store"
    assert single["purchase_date"] is None
    assert single["total_amount"] is None

    merged = service.extract_ocr_from_files(
        user_id=str(user.id),
        front_image_data=(b"f", "scan.jpg", "image/jpeg"),
        back_image_data=(b"b", "scan.jpg", "image/jpeg"),
    )
    assert merged["ocr_status"] == "success"
    assert merged["store_name"] == "Front Store"
    assert merged["s3_object_key"] is not None
    assert merged["back_image_s3_key"] is not None
    assert len(merged["line_items"]) == 2


def test_process_ocr_retry_and_line_item_crud(db_session) -> None:
    user = _create_user(db_session, uid="ocr-process-user")
    service = _make_receipt_service(
        textract_map={
            "success": {
                "status": "success",
                "extracted_data": {
                    "store_name": "OCR Store",
                    "purchase_date": "2026-02-01",
                    "total_amount": "150.00",
                    "currency": "USD",
                    "remarks": "raw remarks",
                    "warranty_notes": "raw warranty",
                    "product_name": "Laptop Pro",
                    "warranty_period_months": 24,
                    "line_items": [
                        {
                            "row_index": 0,
                            "item_description": "Laptop Pro",
                            "quantity": 2,
                            "unit_price": 75.0,
                            "warranty_period_months": 24,
                        }
                    ],
                },
            },
            "failed": {"status": "failed", "extracted_data": {}},
        }
    )

    receipt = Receipt(
        id=str(uuid.uuid4()),
        user_id=str(user.id),
        s3_object_key="users/u/success.jpg",
        status=ReceiptStatus.PROCESSING,
        store_name="Before",
        purchase_date=datetime(2026, 1, 1, tzinfo=timezone.utc),
    )
    db_session.add(receipt)
    db_session.commit()

    processed = service.process_ocr(db_session, str(receipt.id), str(user.id))
    assert processed is not None
    assert processed.status == ReceiptStatus.COMPLETED
    assert processed.store_name == "OCR Store"
    assert len(processed.line_items) == 2
    assert processed.line_items[0].product_image_url.startswith("https://img.local")

    created_item = service.create_line_item(
        db_session,
        str(receipt.id),
        str(user.id),
        ReceiptLineItemUpdate(
            item_description="Mouse",
            product_name="Wireless Mouse",
            warranty_period_months=12,
            return_period_days=14,
            unit_price=Decimal("25.50"),
        ),
    )
    assert created_item is not None
    assert created_item.warranty_expiry_date is not None

    updated_item = service.update_line_item(
        db_session,
        str(receipt.id),
        str(created_item.id),
        str(user.id),
        ReceiptLineItemUpdate(product_name="Wireless Mouse V2", return_period_days=30),
    )
    assert updated_item is not None
    assert updated_item.return_expiry_date is not None

    claim = ClaimDocument(
        id=str(uuid.uuid4()),
        receipt_id=str(receipt.id),
        line_item_id=str(created_item.id),
        issue_description="Broken",
    )
    db_session.add(claim)
    db_session.commit()

    assert service.delete_line_item(db_session, str(receipt.id), str(created_item.id), str(user.id))

    failed_receipt = Receipt(
        id=str(uuid.uuid4()),
        user_id=str(user.id),
        s3_object_key="users/u/failed.jpg",
        status=ReceiptStatus.PROCESSING,
    )
    db_session.add(failed_receipt)
    db_session.commit()

    failed = service.process_ocr(db_session, str(failed_receipt.id), str(user.id))
    assert failed is not None
    assert failed.status == ReceiptStatus.OCR_FAILED

    failed.ocr_retry_count = 999
    db_session.commit()
    same = service.retry_ocr(db_session, str(failed_receipt.id), str(user.id))
    assert same is not None
    assert same.status == ReceiptStatus.OCR_FAILED


def test_notification_service_and_reminder_logic(db_session) -> None:
    user = _create_user(db_session, uid="notify-user")
    service = NotificationService()

    prefs = service.get_or_create_preferences(db_session, str(user.id))
    assert prefs.user_id == str(user.id)

    prefs = service.update_preferences(
        db_session,
        str(user.id),
        {
            "warranty_reminders_enabled": True,
            "return_reminders_enabled": True,
            "warranty_lead_days": 5,
        },
    )
    assert prefs.warranty_lead_days == 5

    service.update_fcm_token(db_session, str(user.id), "new-token")
    db_user = db_session.query(User).filter(User.id == str(user.id)).first()
    assert db_user is not None
    assert db_user.fcm_token == "new-token"

    receipt = Receipt(
        id=str(uuid.uuid4()),
        user_id=str(user.id),
        store_name="Notify Store",
        purchase_date=datetime.now(timezone.utc) - timedelta(days=1),
        status=ReceiptStatus.COMPLETED,
    )
    db_session.add(receipt)
    db_session.flush()

    warranty_target = datetime.now(timezone.utc) + timedelta(days=5)
    return_target = datetime.now(timezone.utc) + timedelta(days=3)

    warranty_item = ReceiptLineItem(
        id=str(uuid.uuid4()),
        receipt_id=str(receipt.id),
        row_index=0,
        item_description="Warranty Product",
        warranty_expiry_date=warranty_target,
        warranty_period_months=12,
    )
    return_item = ReceiptLineItem(
        id=str(uuid.uuid4()),
        receipt_id=str(receipt.id),
        row_index=1,
        item_description="Return Product",
        return_expiry_date=return_target,
        return_period_days=30,
    )
    db_session.add(warranty_item)
    db_session.add(return_item)
    db_session.commit()

    sent_payloads = []

    def _capture_send(**kwargs):
        sent_payloads.append(kwargs)
        return True

    service.send_fcm = _capture_send  # type: ignore[assignment]

    service._send_expiry_reminders(db_session, kind="warranty")
    service._send_expiry_reminders(db_session, kind="return")

    assert len(sent_payloads) >= 2
    assert any(p["data"]["type"] == "warranty" for p in sent_payloads)
    assert any(p["data"]["type"] == "return" for p in sent_payloads)


def test_deletion_service_hard_delete_job(db_session) -> None:
    user = _create_user(db_session, uid="delete-user")
    now = datetime.now(timezone.utc)
    old = now - timedelta(days=40)

    receipt = Receipt(
        id=str(uuid.uuid4()),
        user_id=str(user.id),
        s3_object_key="old-receipt-key",
        store_name="Old Store",
        status=ReceiptStatus.COMPLETED,
        deleted_at=old,
    )
    db_session.add(receipt)
    db_session.flush()

    item = ReceiptLineItem(
        id=str(uuid.uuid4()),
        receipt_id=str(receipt.id),
        row_index=0,
        item_description="Old Item",
        deleted_at=old,
    )
    claim = ClaimDocument(
        id=str(uuid.uuid4()),
        receipt_id=str(receipt.id),
        line_item_id=str(item.id),
        issue_description="Old issue",
        generated_pdf_s3_key="old-claim-pdf",
        deleted_at=old,
    )

    user.deleted_at = old
    db_session.add(item)
    db_session.add(claim)
    db_session.commit()

    s3 = MockS3Service("delete-bucket")
    s3.upload_file(b"r", "old-receipt-key", "image/jpeg")
    s3.upload_file(b"c", "old-claim-pdf", "application/pdf")

    deletion = DeletionService(s3)
    results = deletion.run_hard_delete_job(db_session)

    assert results["claims"] == 1
    assert results["line_items"] == 1
    assert results["receipts"] == 1
    assert results["users"] == 1
    assert results["total"] == 4
