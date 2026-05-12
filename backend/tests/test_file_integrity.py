"""Tests for file integrity validation: magic bytes and size limits.

Covers all three upload endpoints:
  - POST /receipts/{id}/upload
  - POST /receipts/ocr-extract
  - POST /claims (defect_images)
"""

from __future__ import annotations

import io
import uuid
from datetime import datetime, timedelta, timezone

import pytest
from fastapi import HTTPException, UploadFile
from starlette.datastructures import Headers

from app.api.v1 import claims as claims_api
from app.api.v1 import receipts as receipts_api
from app.models import Receipt, ReceiptLineItem, ReceiptStatus, User


# ── Magic byte constants ──────────────────────────────────────────────────────

JPEG_MAGIC = b"\xff\xd8\xff"
PNG_MAGIC = b"\x89PNG\r\n\x1a\n"
PDF_MAGIC = b"%PDF"
FAKE_CONTENT = b"this is not a real image"


# ── Helpers ───────────────────────────────────────────────────────────────────


def _upload_file(name: str, content_type: str, content: bytes) -> UploadFile:
    return UploadFile(
        file=io.BytesIO(content),
        filename=name,
        headers=Headers({"content-type": content_type}),
    )


def _make_user(db_session, uid: str = "integrity-user") -> User:
    user = User(
        id=str(uuid.uuid4()),
        firebase_uid=uid,
        email=f"{uid}@example.com",
        display_name="Integrity User",
        fcm_token="fcm-token",
    )
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user


def _make_receipt(db_session, user_id: str) -> Receipt:
    receipt = Receipt(
        id=str(uuid.uuid4()),
        user_id=user_id,
        store_name="Test Store",
        purchase_date=datetime.now(timezone.utc) - timedelta(days=1),
        status=ReceiptStatus.COMPLETED,
        s3_object_key="users/x/receipt/front.jpg",
    )
    db_session.add(receipt)
    line_item = ReceiptLineItem(
        id=str(uuid.uuid4()),
        receipt_id=str(receipt.id),
        row_index=0,
        item_description="Camera",
        product_name="Camera",
        warranty_period_months=12,
        warranty_expiry_date=datetime.now(timezone.utc) + timedelta(days=365),
    )
    db_session.add(line_item)
    db_session.commit()
    db_session.refresh(receipt)
    return receipt


# ── POST /receipts/{id}/upload ────────────────────────────────────────────────


class TestReceiptUploadMagicBytes:
    @pytest.mark.asyncio
    async def test_jpeg_with_wrong_magic_bytes_rejected(self, db_session):
        user = _make_user(db_session, uid="upload-bad-jpeg")
        receipt = _make_receipt(db_session, str(user.id))
        current_user = {"uid": user.firebase_uid}
        # Claims to be JPEG but has no JPEG magic bytes
        file = _upload_file("evil.jpg", "image/jpeg", FAKE_CONTENT)
        with pytest.raises(HTTPException) as exc:
            await receipts_api.upload_receipt_file(
                str(receipt.id), file=file, current_user=current_user, db=db_session
            )
        assert exc.value.status_code == 400
        assert "does not match" in exc.value.detail

    @pytest.mark.asyncio
    async def test_png_with_wrong_magic_bytes_rejected(self, db_session):
        user = _make_user(db_session, uid="upload-bad-png")
        receipt = _make_receipt(db_session, str(user.id))
        current_user = {"uid": user.firebase_uid}
        file = _upload_file("evil.png", "image/png", FAKE_CONTENT)
        with pytest.raises(HTTPException) as exc:
            await receipts_api.upload_receipt_file(
                str(receipt.id), file=file, current_user=current_user, db=db_session
            )
        assert exc.value.status_code == 400
        assert "does not match" in exc.value.detail

    @pytest.mark.asyncio
    async def test_oversized_file_rejected(self, db_session):
        user = _make_user(db_session, uid="upload-huge")
        receipt = _make_receipt(db_session, str(user.id))
        current_user = {"uid": user.firebase_uid}
        oversized = _upload_file(
            "big.jpg",
            "image/jpeg",
            JPEG_MAGIC + b"x" * receipts_api.settings.max_file_size_bytes,
        )
        with pytest.raises(HTTPException) as exc:
            await receipts_api.upload_receipt_file(
                str(receipt.id),
                file=oversized,
                current_user=current_user,
                db=db_session,
            )
        assert exc.value.status_code == 413

    @pytest.mark.asyncio
    async def test_disallowed_content_type_rejected(self, db_session):
        user = _make_user(db_session, uid="upload-txt")
        receipt = _make_receipt(db_session, str(user.id))
        current_user = {"uid": user.firebase_uid}
        file = _upload_file("file.txt", "text/plain", b"hello")
        with pytest.raises(HTTPException) as exc:
            await receipts_api.upload_receipt_file(
                str(receipt.id), file=file, current_user=current_user, db=db_session
            )
        assert exc.value.status_code == 400


# ── POST /receipts/ocr-extract ────────────────────────────────────────────────


class TestOcrExtractMagicBytes:
    @pytest.mark.asyncio
    async def test_jpeg_with_wrong_magic_bytes_rejected(self, db_session):
        user = _make_user(db_session, uid="ocr-bad-jpeg")
        current_user = {"uid": user.firebase_uid}
        file = _upload_file("evil.jpg", "image/jpeg", FAKE_CONTENT)
        with pytest.raises(HTTPException) as exc:
            await receipts_api.ocr_extract(
                front_image=file,
                back_image=None,
                current_user=current_user,
                db=db_session,
            )
        assert exc.value.status_code == 400
        assert "does not match" in exc.value.detail

    @pytest.mark.asyncio
    async def test_png_with_wrong_magic_bytes_rejected(self, db_session):
        user = _make_user(db_session, uid="ocr-bad-png")
        current_user = {"uid": user.firebase_uid}
        file = _upload_file("evil.png", "image/png", FAKE_CONTENT)
        with pytest.raises(HTTPException) as exc:
            await receipts_api.ocr_extract(
                front_image=file,
                back_image=None,
                current_user=current_user,
                db=db_session,
            )
        assert exc.value.status_code == 400
        assert "does not match" in exc.value.detail

    @pytest.mark.asyncio
    async def test_pdf_with_wrong_magic_bytes_rejected(self, db_session):
        user = _make_user(db_session, uid="ocr-bad-pdf")
        current_user = {"uid": user.firebase_uid}
        file = _upload_file("evil.pdf", "application/pdf", FAKE_CONTENT)
        with pytest.raises(HTTPException) as exc:
            await receipts_api.ocr_extract(
                front_image=file,
                back_image=None,
                current_user=current_user,
                db=db_session,
            )
        assert exc.value.status_code == 400
        assert "does not match" in exc.value.detail

    @pytest.mark.asyncio
    async def test_oversized_front_image_rejected(self, db_session):
        user = _make_user(db_session, uid="ocr-huge")
        current_user = {"uid": user.firebase_uid}
        oversized = _upload_file(
            "big.jpg",
            "image/jpeg",
            JPEG_MAGIC + b"x" * receipts_api.settings.max_file_size_bytes,
        )
        with pytest.raises(HTTPException) as exc:
            await receipts_api.ocr_extract(
                front_image=oversized,
                back_image=None,
                current_user=current_user,
                db=db_session,
            )
        assert exc.value.status_code == 413

    @pytest.mark.asyncio
    async def test_back_image_with_wrong_magic_bytes_rejected(self, db_session):
        user = _make_user(db_session, uid="ocr-bad-back")
        current_user = {"uid": user.firebase_uid}
        # Front image is valid; back image is corrupt
        valid_front = _upload_file("front.jpg", "image/jpeg", JPEG_MAGIC + b"data")
        bad_back = _upload_file("back.png", "image/png", FAKE_CONTENT)
        with pytest.raises(HTTPException) as exc:
            await receipts_api.ocr_extract(
                front_image=valid_front,
                back_image=bad_back,
                current_user=current_user,
                db=db_session,
            )
        assert exc.value.status_code == 400
        assert "does not match" in exc.value.detail



# ── POST /claims (defect_images) ──────────────────────────────────────────────


class TestClaimDefectImagesMagicBytes:
    @pytest.mark.asyncio
    async def test_jpeg_with_wrong_magic_bytes_rejected(self, db_session):
        user = _make_user(db_session, uid="claim-bad-jpeg")
        receipt = _make_receipt(db_session, str(user.id))
        current_user = {"uid": user.firebase_uid}
        line_item = (
            db_session.query(ReceiptLineItem)
            .filter(ReceiptLineItem.receipt_id == str(receipt.id))
            .first()
        )
        file = _upload_file("evil.jpg", "image/jpeg", FAKE_CONTENT)
        with pytest.raises(HTTPException) as exc:
            await claims_api.create_claim(
                receipt_id=str(receipt.id),
                issue_description="Screen cracked",
                claim_type="warranty",
                line_item_id=str(line_item.id),
                defect_images=[file],
                current_user=current_user,
                db=db_session,
            )
        assert exc.value.status_code == 400
        assert "does not match" in exc.value.detail

    @pytest.mark.asyncio
    async def test_png_with_wrong_magic_bytes_rejected(self, db_session):
        user = _make_user(db_session, uid="claim-bad-png")
        receipt = _make_receipt(db_session, str(user.id))
        current_user = {"uid": user.firebase_uid}
        line_item = (
            db_session.query(ReceiptLineItem)
            .filter(ReceiptLineItem.receipt_id == str(receipt.id))
            .first()
        )
        file = _upload_file("evil.png", "image/png", FAKE_CONTENT)
        with pytest.raises(HTTPException) as exc:
            await claims_api.create_claim(
                receipt_id=str(receipt.id),
                issue_description="Screen cracked",
                claim_type="warranty",
                line_item_id=str(line_item.id),
                defect_images=[file],
                current_user=current_user,
                db=db_session,
            )
        assert exc.value.status_code == 400
        assert "does not match" in exc.value.detail

    @pytest.mark.asyncio
    async def test_oversized_defect_image_rejected(self, db_session):
        user = _make_user(db_session, uid="claim-huge")
        receipt = _make_receipt(db_session, str(user.id))
        current_user = {"uid": user.firebase_uid}
        line_item = (
            db_session.query(ReceiptLineItem)
            .filter(ReceiptLineItem.receipt_id == str(receipt.id))
            .first()
        )
        oversized = _upload_file(
            "big.jpg",
            "image/jpeg",
            JPEG_MAGIC + b"x" * claims_api.settings.max_file_size_bytes,
        )
        with pytest.raises(HTTPException) as exc:
            await claims_api.create_claim(
                receipt_id=str(receipt.id),
                issue_description="Screen cracked",
                claim_type="warranty",
                line_item_id=str(line_item.id),
                defect_images=[oversized],
                current_user=current_user,
                db=db_session,
            )
        assert exc.value.status_code == 413

    @pytest.mark.asyncio
    async def test_second_image_with_wrong_magic_bytes_rejected(self, db_session):
        user = _make_user(db_session, uid="claim-bad-second")
        receipt = _make_receipt(db_session, str(user.id))
        current_user = {"uid": user.firebase_uid}
        line_item = (
            db_session.query(ReceiptLineItem)
            .filter(ReceiptLineItem.receipt_id == str(receipt.id))
            .first()
        )
        valid = _upload_file("ok.jpg", "image/jpeg", JPEG_MAGIC + b"data")
        corrupt = _upload_file("bad.jpg", "image/jpeg", FAKE_CONTENT)
        with pytest.raises(HTTPException) as exc:
            await claims_api.create_claim(
                receipt_id=str(receipt.id),
                issue_description="Defect",
                claim_type="warranty",
                line_item_id=str(line_item.id),
                defect_images=[valid, corrupt],
                current_user=current_user,
                db=db_session,
            )
        assert exc.value.status_code == 400
        assert "does not match" in exc.value.detail

    @pytest.mark.asyncio
    async def test_disallowed_content_type_rejected(self, db_session):
        user = _make_user(db_session, uid="claim-txt")
        receipt = _make_receipt(db_session, str(user.id))
        current_user = {"uid": user.firebase_uid}
        line_item = (
            db_session.query(ReceiptLineItem)
            .filter(ReceiptLineItem.receipt_id == str(receipt.id))
            .first()
        )
        file = _upload_file("file.txt", "text/plain", b"hello")
        with pytest.raises(HTTPException) as exc:
            await claims_api.create_claim(
                receipt_id=str(receipt.id),
                issue_description="Defect",
                claim_type="warranty",
                line_item_id=str(line_item.id),
                defect_images=[file],
                current_user=current_user,
                db=db_session,
            )
        assert exc.value.status_code == 400


# ── Unit tests for _assert_magic_bytes directly ───────────────────────────────


class TestAssertMagicBytesUnit:
    def test_jpeg_valid(self):
        receipts_api._assert_magic_bytes(JPEG_MAGIC + b"rest", "image/jpeg")

    def test_jpeg_invalid(self):
        with pytest.raises(HTTPException) as exc:
            receipts_api._assert_magic_bytes(FAKE_CONTENT, "image/jpeg")
        assert exc.value.status_code == 400

    def test_png_valid(self):
        receipts_api._assert_magic_bytes(PNG_MAGIC + b"rest", "image/png")

    def test_png_invalid(self):
        with pytest.raises(HTTPException) as exc:
            receipts_api._assert_magic_bytes(FAKE_CONTENT, "image/png")
        assert exc.value.status_code == 400

    def test_pdf_valid(self):
        receipts_api._assert_magic_bytes(PDF_MAGIC + b"-1.4", "application/pdf")

    def test_pdf_invalid(self):
        with pytest.raises(HTTPException) as exc:
            receipts_api._assert_magic_bytes(FAKE_CONTENT, "application/pdf")
        assert exc.value.status_code == 400

    def test_unknown_content_type_passes(self):
        # Unknown types have no signatures — validation is skipped
        receipts_api._assert_magic_bytes(FAKE_CONTENT, "application/octet-stream")

    def test_empty_file_jpeg_rejected(self):
        with pytest.raises(HTTPException) as exc:
            receipts_api._assert_magic_bytes(b"", "image/jpeg")
        assert exc.value.status_code == 400

    def test_jpeg_alias_image_jpg(self):
        receipts_api._assert_magic_bytes(JPEG_MAGIC + b"rest", "image/jpg")

    def test_wrong_magic_for_type_error_message(self):
        with pytest.raises(HTTPException) as exc:
            receipts_api._assert_magic_bytes(PNG_MAGIC + b"rest", "image/jpeg")
        assert "does not match" in exc.value.detail


