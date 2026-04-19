"""
Receipt service - Business logic for receipt operations.
Handles CRUD operations, file upload, OCR processing, and warranty calculations.
"""

import logging
import json
import uuid
from typing import Optional, List, cast
from datetime import datetime, timezone, timedelta
from dateutil import parser as dateutil_parser  # type: ignore[import-untyped]
from dateutil.relativedelta import relativedelta  # type: ignore[import-untyped]
from sqlalchemy.orm import Session, selectinload
from sqlalchemy import and_

from app.models import Receipt, ReceiptStatus, ReceiptImage
from app.models.receipt_line_item import ReceiptLineItem
from app.models.claim_document import ClaimDocument
from app.schemas import ReceiptCreate, ReceiptUpdate, ReceiptLineItemUpdate
from app.services.s3_service import get_s3_service
from app.services.textract_service import get_textract_service
from app.services.llm_service import create_llm_service
from app.core.config import settings

logger = logging.getLogger(__name__)


class ReceiptService:
    """Service for receipt operations."""

    def __init__(self):
        """Initialize receipt service with AWS services."""
        # Initialize LLM service first (needed by textract)
        self.llm_service = create_llm_service(
            use_mock=settings.USE_MOCK_AWS,
            region=settings.AWS_REGION,
            model_id=settings.BEDROCK_MODEL_ID,
        )

        self.s3_service = get_s3_service(
            bucket_name=settings.AWS_S3_BUCKET,
            use_mock=settings.USE_MOCK_AWS,
            region=settings.AWS_REGION,
        )
        self.textract_service = get_textract_service(
            s3_bucket=settings.AWS_S3_BUCKET,
            use_mock=settings.USE_MOCK_AWS,
            region=settings.AWS_REGION,
            llm_service=self.llm_service,  # Pass LLM service for product name extraction
        )

        from app.services.product_image_service import create_product_image_service

        self.product_image_service = create_product_image_service(
            use_mock=settings.USE_MOCK_AWS,
            api_key=settings.BRAVE_SEARCH_API_KEY,
        )

    def create_receipt(
        self, db: Session, user_id: str, receipt_data: ReceiptCreate
    ) -> Receipt:
        """
        Create a new receipt record.

        Args:
            db: Database session
            user_id: Owner user ID
            receipt_data: Receipt creation data

        Returns:
            Created receipt
        """
        receipt_id = str(uuid.uuid4())

        # Use provided s3_object_key if the image was pre-uploaded via
        # /ocr-extract.  Status is COMPLETED (OCR already done) when an image
        # key is present, otherwise MANUAL_ENTRY for purely text-based entries.
        s3_key = getattr(receipt_data, "s3_object_key", None)
        back_s3_key = getattr(receipt_data, "back_image_s3_key", None)
        initial_status = (
            ReceiptStatus.COMPLETED
            if (s3_key or back_s3_key)
            else ReceiptStatus.MANUAL_ENTRY
        )

        receipt = Receipt(
            id=receipt_id,
            user_id=user_id,
            s3_object_key=s3_key,
            store_name=receipt_data.store_name,
            purchase_date=receipt_data.purchase_date,
            total_amount=receipt_data.total_amount,
            currency=receipt_data.currency,
            notes=receipt_data.notes,
            invoice_number=getattr(receipt_data, "invoice_number", None),
            vendor_address=getattr(receipt_data, "vendor_address", None),
            vendor_phone=getattr(receipt_data, "vendor_phone", None),
            vendor_email=getattr(receipt_data, "vendor_email", None),
            vendor_url=getattr(receipt_data, "vendor_url", None),
            remarks=getattr(receipt_data, "remarks", None),
            warranty_notes=getattr(receipt_data, "warranty_notes", None),
            status=initial_status,
        )

        db.add(receipt)
        db.flush()  # Flush to get receipt ID for receipt_images

        # Create ReceiptImage records for front and back images
        if s3_key:
            front_image = ReceiptImage(
                id=str(uuid.uuid4()),
                receipt_id=receipt_id,
                s3_object_key=s3_key,
                image_type="FRONT",
            )
            db.add(front_image)

        if back_s3_key:
            back_image = ReceiptImage(
                id=str(uuid.uuid4()),
                receipt_id=receipt_id,
                s3_object_key=back_s3_key,
                image_type="BACK",
            )
            db.add(back_image)

        db.commit()
        db.refresh(receipt)

        logger.info(
            f"Created receipt: {receipt_id} for user: {user_id} (status={initial_status.value}, images={bool(s3_key)}/{bool(back_s3_key)})"
        )

        return receipt

    def get_receipt(
        self, db: Session, receipt_id: str, user_id: str
    ) -> Optional[Receipt]:
        """
        Get receipt by ID (user-scoped), with line items eagerly loaded.
        """
        return (
            db.query(Receipt)
            .options(selectinload(Receipt.line_items))
            .filter(
                and_(
                    Receipt.id == receipt_id,
                    Receipt.user_id == user_id,
                    Receipt.deleted_at.is_(None),
                )
            )
            .first()
        )

    def list_receipts(
        self,
        db: Session,
        user_id: str,
        skip: int = 0,
        limit: int = 100,
        status: Optional[ReceiptStatus] = None,
    ) -> tuple[List[Receipt], int]:
        """
        List receipts for a user with pagination.

        Args:
            db: Database session
            user_id: User ID
            skip: Number of records to skip
            limit: Maximum number of records to return
            status: Optional status filter

        Returns:
            Tuple of (receipts list, total count)
        """
        query = db.query(Receipt).filter(
            and_(Receipt.user_id == user_id, Receipt.deleted_at.is_(None))
        )

        if status:
            query = query.filter(Receipt.status == status)

        total = query.count()
        receipts = (
            query.options(selectinload(Receipt.line_items))
            .order_by(Receipt.created_at.desc())
            .offset(skip)
            .limit(limit)
            .all()
        )

        return receipts, total

    def extract_ocr_from_file(
        self,
        user_id: str,
        file_content: bytes,
        file_name: str,
        content_type: str,
    ) -> dict:
        """
        Upload an image to S3 and run OCR **without** creating a receipt record.

        The image is stored at:
            ``users/{user_id}/receipts/{session_id}/{file_name}``
        which is a permanent path (not ``temp/``), so OCR-failed images are
        preserved for long-term use (claim PDF generation, manual review, etc.).

        Returns a dict matching the ``OcrExtractResponse`` schema (snake_case
        keys — FastAPI alias_generator converts to camelCase on the wire).
        """
        session_id = str(uuid.uuid4())
        s3_object_key = f"users/{user_id}/receipts/{session_id}/{file_name}"

        logger.info(f"OCR extract: uploading to {s3_object_key}")
        self.s3_service.upload_file(file_content, s3_object_key, content_type)

        result: dict = {
            "s3_object_key": s3_object_key,
            "ocr_status": "failed",
            "line_items": [],
        }

        try:
            ocr_raw = self.textract_service.analyze_document(s3_object_key)

            if ocr_raw.get("status") == "success":
                extracted = ocr_raw.get("extracted_data", {})

                # Optional LLM cleanup for long-form text fields
                if settings.LLM_CLEANUP_ENABLED:
                    for _field in ("warranty_notes", "remarks"):
                        if extracted.get(_field):
                            extracted[_field] = self.llm_service.clean_receipt_notes(
                                extracted[_field]
                            )

                # Parse purchase_date to a datetime (or None on failure)
                purchase_date = None
                if extracted.get("purchase_date"):
                    try:
                        purchase_date = dateutil_parser.parse(
                            extracted["purchase_date"], dayfirst=False
                        )
                    except (ValueError, TypeError, OverflowError):
                        logger.warning(
                            f"OCR extract: could not parse purchase_date: "
                            f"{extracted['purchase_date']!r}"
                        )

                total_amount = None
                if extracted.get("total_amount") is not None:
                    try:
                        total_amount = float(extracted["total_amount"])
                    except (TypeError, ValueError):
                        pass

                result.update(
                    {
                        "ocr_status": "success",
                        "store_name": extracted.get("store_name"),
                        "purchase_date": purchase_date,
                        "total_amount": total_amount,
                        "currency": extracted.get("currency"),
                        "invoice_number": extracted.get("invoice_number"),
                        "vendor_address": extracted.get("vendor_address"),
                        "vendor_phone": extracted.get("vendor_phone"),
                        "vendor_email": extracted.get("vendor_email"),
                        "vendor_url": extracted.get("vendor_url"),
                        "remarks": extracted.get("remarks"),
                        "warranty_notes": extracted.get("warranty_notes"),
                        "product_name": extracted.get("product_name"),
                        "warranty_period_months": extracted.get(
                            "warranty_period_months"
                        ),
                        "line_items": extracted.get("line_items", []),
                    }
                )
                logger.info(
                    f"OCR extract succeeded for user {user_id}, "
                    f"s3_key={s3_object_key}"
                )
            else:
                logger.warning(
                    f"OCR extract: Textract returned non-success for "
                    f"s3_key={s3_object_key}"
                )
        except Exception as exc:
            logger.error(
                f"OCR extract error for user {user_id}, "
                f"s3_key={s3_object_key}: {exc}"
            )

        return result

    def extract_ocr_from_files(
        self,
        user_id: str,
        front_image_data: Optional[tuple[bytes, str, str]],
        back_image_data: Optional[tuple[bytes, str, str]],
    ) -> dict:
        """
        Upload front and/or back receipt images to S3, run OCR on both, and merge results.

        Images are stored at:
            ``users/{user_id}/receipts/{session_id}/front_{file_name}``
            ``users/{user_id}/receipts/{session_id}/back_{file_name}``

        OCR is run on both images and results are merged, with preference given to
        front image data for main fields. Line items from both images are combined.

        Args:
            user_id: User ID
            front_image_data: Tuple of (file_content, file_name, content_type) for front image, or None
            back_image_data: Tuple of (file_content, file_name, content_type) for back image, or None

        Returns:
            Dict matching OcrExtractResponse schema with merged OCR data
        """
        session_id = str(uuid.uuid4())

        # Process front image
        front_s3_key = None
        front_ocr_result = None
        if front_image_data:
            file_content, file_name, content_type = front_image_data
            front_s3_key = f"users/{user_id}/receipts/{session_id}/front_{file_name}"

            logger.info(f"OCR extract: uploading front image to {front_s3_key}")
            self.s3_service.upload_file(file_content, front_s3_key, content_type)

            try:
                front_ocr_result = self.textract_service.analyze_document(front_s3_key)
                logger.info(
                    f"OCR extract: front image processed, status={front_ocr_result.get('status')}"
                )
            except Exception as exc:
                logger.error(f"OCR extract error for front image: {exc}")

        # Process back image
        back_s3_key = None
        back_ocr_result = None
        if back_image_data:
            file_content, file_name, content_type = back_image_data
            back_s3_key = f"users/{user_id}/receipts/{session_id}/back_{file_name}"

            logger.info(f"OCR extract: uploading back image to {back_s3_key}")
            self.s3_service.upload_file(file_content, back_s3_key, content_type)

            try:
                back_ocr_result = self.textract_service.analyze_document(back_s3_key)
                logger.info(
                    f"OCR extract: back image processed, status={back_ocr_result.get('status')}"
                )
            except Exception as exc:
                logger.error(f"OCR extract error for back image: {exc}")

        # Merge OCR results (prefer front image data for main fields)
        result: dict = {
            "s3_object_key": front_s3_key or back_s3_key,
            "back_image_s3_key": back_s3_key,
            "ocr_status": "failed",
            "line_items": [],
        }

        # Extract data from front image (primary source)
        front_data = {}
        if front_ocr_result and front_ocr_result.get("status") == "success":
            front_data = front_ocr_result.get("extracted_data", {})
            result["ocr_status"] = "success"

        # Extract data from back image (secondary source)
        back_data = {}
        if back_ocr_result and back_ocr_result.get("status") == "success":
            back_data = back_ocr_result.get("extracted_data", {})
            if result["ocr_status"] != "success":
                result["ocr_status"] = "success"

        # If both failed, return early
        if result["ocr_status"] == "failed":
            logger.warning(
                f"OCR extract: both images failed OCR for session {session_id}"
            )
            return result

        # Merge extracted data (prefer front for main fields, combine line items)
        extracted = front_data.copy()

        # Combine line items from both images
        front_line_items = front_data.get("line_items", [])
        back_line_items = back_data.get("line_items", [])
        combined_line_items = front_line_items + back_line_items
        extracted["line_items"] = combined_line_items

        # Optional LLM cleanup for long-form text fields
        if settings.LLM_CLEANUP_ENABLED:
            for _field in ("warranty_notes", "remarks"):
                if extracted.get(_field):
                    extracted[_field] = self.llm_service.clean_receipt_notes(
                        extracted[_field]
                    )

        # Parse purchase_date to a datetime (or None on failure)
        purchase_date = None
        if extracted.get("purchase_date"):
            try:
                purchase_date = dateutil_parser.parse(
                    extracted["purchase_date"], dayfirst=False
                )
            except (ValueError, TypeError, OverflowError):
                logger.warning(
                    f"OCR extract: could not parse purchase_date: "
                    f"{extracted['purchase_date']!r}"
                )

        total_amount = None
        if extracted.get("total_amount") is not None:
            try:
                total_amount = float(extracted["total_amount"])
            except (TypeError, ValueError):
                pass

        result.update(
            {
                "ocr_status": "success",
                "store_name": extracted.get("store_name"),
                "purchase_date": purchase_date,
                "total_amount": total_amount,
                "currency": extracted.get("currency"),
                "invoice_number": extracted.get("invoice_number"),
                "vendor_address": extracted.get("vendor_address"),
                "vendor_phone": extracted.get("vendor_phone"),
                "vendor_email": extracted.get("vendor_email"),
                "vendor_url": extracted.get("vendor_url"),
                "remarks": extracted.get("remarks"),
                "warranty_notes": extracted.get("warranty_notes"),
                "product_name": extracted.get("product_name"),
                "warranty_period_months": extracted.get("warranty_period_months"),
                "line_items": combined_line_items,
            }
        )

        logger.info(
            f"OCR extract succeeded for user {user_id}, session={session_id}, "
            f"front={front_s3_key}, back={back_s3_key}"
        )

        return result

    def update_receipt(
        self, db: Session, receipt_id: str, user_id: str, receipt_data: ReceiptUpdate
    ) -> Optional[Receipt]:
        """
        Update receipt data.

        Args:
            db: Database session
            receipt_id: Receipt ID
            user_id: User ID for authorization
            receipt_data: Update data

        Returns:
            Updated receipt or None if not found
        """
        receipt = self.get_receipt(db, receipt_id, user_id)

        if not receipt:
            return None

        # Update fields
        update_data = receipt_data.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(receipt, field, value)

        db.commit()
        db.refresh(receipt)

        logger.info(f"Updated receipt: {receipt_id}")

        return receipt

    def delete_receipt(self, db: Session, receipt_id: str, user_id: str) -> bool:
        """
        Soft delete receipt and cascade to line items and claim documents.

        Args:
            db: Database session
            receipt_id: Receipt ID
            user_id: User ID for authorization

        Returns:
            True if deleted, False if not found
        """
        receipt = self.get_receipt(db, receipt_id, user_id)

        if not receipt:
            return False

        now = datetime.now(timezone.utc)

        try:
            # Soft delete receipt
            setattr(receipt, "deleted_at", now)

            # Cascade soft delete to line items
            db.query(ReceiptLineItem).filter(
                ReceiptLineItem.receipt_id == receipt_id,
                ReceiptLineItem.deleted_at.is_(None),
            ).update({ReceiptLineItem.deleted_at: now}, synchronize_session=False)

            # Cascade soft delete to claim documents
            db.query(ClaimDocument).filter(
                ClaimDocument.receipt_id == receipt_id,
                ClaimDocument.deleted_at.is_(None),
            ).update({ClaimDocument.deleted_at: now}, synchronize_session=False)

            db.commit()

            logger.info(f"Soft deleted receipt and cascaded to children: {receipt_id}")

            return True
        except Exception as e:
            db.rollback()
            logger.error(f"Failed to soft delete receipt {receipt_id}: {e}")
            raise

    def get_receipt_image_url(
        self, db: Session, receipt_id: str, user_id: str, expiration: int = 3600
    ) -> Optional[str]:
        """
        Generate a pre-signed S3 URL for viewing the receipt image.

        Args:
            db: Database session
            receipt_id: Receipt ID
            user_id: User ID for authorization
            expiration: URL validity in seconds (default 1 hour)

        Returns:
            Pre-signed URL string, or None if receipt not found / no image uploaded
        """
        receipt = self.get_receipt(db, receipt_id, user_id)
        if not receipt:
            return None
        if not receipt.s3_object_key:
            return None

        url = self.s3_service.generate_presigned_url(
            receipt.s3_object_key, expiration=expiration, operation="get_object"
        )
        logger.info(f"Generated pre-signed image URL for receipt: {receipt_id}")
        return url

    def upload_receipt_file(
        self,
        db: Session,
        receipt_id: str,
        user_id: str,
        file_content: bytes,
        file_name: str,
        content_type: str,
    ) -> Optional[Receipt]:
        """
        Upload receipt file to S3 and trigger OCR.

        Args:
            db: Database session
            receipt_id: Receipt ID
            user_id: User ID
            file_content: File content bytes
            file_name: Original file name
            content_type: MIME type

        Returns:
            Updated receipt or None if not found
        """
        receipt = self.get_receipt(db, receipt_id, user_id)

        if not receipt:
            return None

        # Generate S3 object key
        s3_object_key = f"users/{user_id}/receipts/{receipt_id}/{file_name}"

        # Upload to S3
        self.s3_service.upload_file(
            file_content=file_content,
            object_key=s3_object_key,
            content_type=content_type,
        )

        # Update receipt with S3 key
        setattr(receipt, "s3_object_key", s3_object_key)
        setattr(receipt, "status", ReceiptStatus.PROCESSING)
        db.commit()

        logger.info(f"Uploaded file for receipt: {receipt_id}")

        # Trigger OCR processing and return its result so the caller receives
        # the fully-populated receipt (with line items, warranty notes, etc.)
        # rather than the stale pre-OCR object loaded before processing ran.
        return self.process_ocr(db, receipt_id, user_id)

    def process_ocr(
        self, db: Session, receipt_id: str, user_id: str
    ) -> Optional[Receipt]:
        """
        Process OCR for receipt.

        Args:
            db: Database session
            receipt_id: Receipt ID
            user_id: User ID

        Returns:
            Updated receipt or None if not found
        """
        receipt = self.get_receipt(db, receipt_id, user_id)

        if not receipt or not receipt.s3_object_key:
            return None

        try:
            # Call Textract service
            ocr_result = self.textract_service.analyze_document(receipt.s3_object_key)

            setattr(receipt, "last_ocr_attempt_at", datetime.now(timezone.utc))

            if ocr_result.get("status") == "success":
                # Extract data from OCR result
                extracted = ocr_result.get("extracted_data", {})
                # ── LLM text cleanup for notes and warranty fields ─────────────
                # After the geometric column-reconstruction pass in
                # TextractService, pass partially-cleaned text through
                # Bedrock Claude to fix word duplication from bilingual
                # columns and restore sentence coherence.
                if settings.LLM_CLEANUP_ENABLED:
                    for _notes_field in ("warranty_notes", "remarks"):
                        if extracted.get(_notes_field):
                            extracted[_notes_field] = (
                                self.llm_service.clean_receipt_notes(
                                    extracted[_notes_field]
                                )
                            )
                # ── store name ──────────────────────────────────────────────
                if extracted.get("store_name"):
                    receipt.store_name = extracted["store_name"]

                # ── purchase date — use dateutil to handle multiple formats ─
                # Textract may return "03/05/2023", "03 MAY 2023", ISO 8601…
                if extracted.get("purchase_date"):
                    try:
                        receipt.purchase_date = dateutil_parser.parse(
                            extracted["purchase_date"], dayfirst=False
                        )
                    except (ValueError, TypeError, OverflowError):
                        logger.warning(
                            f"Could not parse purchase_date: {extracted['purchase_date']!r}"
                        )

                # ── total amount ─────────────────────────────────────────────
                if extracted.get("total_amount") is not None:
                    setattr(receipt, "total_amount", float(extracted["total_amount"]))

                if extracted.get("currency"):
                    receipt.currency = extracted["currency"]

                # ── new OCR fields ────────────────────────────────────────────
                if extracted.get("invoice_number"):
                    receipt.invoice_number = extracted["invoice_number"]

                if extracted.get("vendor_address"):
                    receipt.vendor_address = extracted["vendor_address"]

                if extracted.get("vendor_phone"):
                    receipt.vendor_phone = extracted["vendor_phone"]

                if extracted.get("vendor_email"):
                    receipt.vendor_email = extracted["vendor_email"]

                if extracted.get("vendor_url"):
                    receipt.vendor_url = extracted["vendor_url"]

                if extracted.get("remarks"):
                    receipt.remarks = extracted["remarks"]

                if extracted.get("warranty_notes"):
                    receipt.warranty_notes = extracted["warranty_notes"]

                setattr(receipt, "status", ReceiptStatus.COMPLETED)
                setattr(
                    receipt, "ocr_raw_response", json.dumps(ocr_result, default=str)
                )

                # ── line items ────────────────────────────────────────────────
                # Remove any existing line items (e.g. from a previous retry)
                db.query(ReceiptLineItem).filter(
                    ReceiptLineItem.receipt_id == receipt.id
                ).delete(synchronize_session=False)

                ocr_line_items_data = extracted.get("line_items", [])
                created_line_items: List[ReceiptLineItem] = []
                total_item_count = 0

                # Split multi-quantity items into separate records
                for item_data in ocr_line_items_data:
                    qty = item_data.get("quantity", 1)
                    # Default to 1 if quantity is invalid
                    if not isinstance(qty, int) or qty <= 0:
                        qty = 1

                    row_index = item_data.get("row_index", 0)

                    # Create qty separate records, each representing 1 physical unit
                    for _ in range(qty):
                        total_item_count += 1

                        # Enforce 10-item limit per receipt
                        if total_item_count > 10:
                            logger.warning(
                                f"Receipt {receipt.id} exceeds 10-item limit. "
                                f"Truncating at 10 items."
                            )
                            break

                        line_item = ReceiptLineItem(
                            id=str(uuid.uuid4()),
                            receipt_id=receipt.id,
                            row_index=row_index,  # Same row_index for grouped display
                            product_code=item_data.get("product_code"),
                            item_description=item_data.get("item_description"),
                            unit_price=item_data.get("unit_price"),
                            warranty_period_months=item_data.get(
                                "warranty_period_months"
                            ),
                        )
                        db.add(line_item)
                        created_line_items.append(line_item)

                    # Break outer loop if limit reached
                    if total_item_count >= 10:
                        break

                # OCR may emit a receipt-level product_name / warranty hint
                # (e.g. single-product receipts, mock data, legacy format).
                _product_name_hint = extracted.get("product_name")
                _warranty_hint = extracted.get("warranty_period_months")

                if not created_line_items and (_product_name_hint or _warranty_hint):
                    # No line items found — auto-create a synthetic "Primary Item"
                    synthetic = ReceiptLineItem(
                        id=str(uuid.uuid4()),
                        receipt_id=receipt.id,
                        row_index=0,
                        item_description=_product_name_hint,
                        product_name=_product_name_hint,
                        warranty_period_months=_warranty_hint,
                    )
                    db.add(synthetic)
                    created_line_items.append(synthetic)
                elif created_line_items and _warranty_hint:
                    # Assign receipt-level warranty hint to first item if it
                    # doesn't already have its own warranty period.
                    first_li = created_line_items[0]
                    if not first_li.warranty_period_months:
                        first_li.warranty_period_months = _warranty_hint

                # Compute warranty_expiry_date for items that now have a
                # warranty_period_months but no expiry date yet.
                if receipt.purchase_date:
                    for li in created_line_items:
                        if li.warranty_period_months and not li.warranty_expiry_date:
                            li.warranty_expiry_date = (
                                receipt.purchase_date
                                + relativedelta(months=li.warranty_period_months)
                            )

                # ── product image lookup ─────────────────────────────────────
                # Best-effort: fetch from Brave for the first line item that
                # has a product name / description and no image yet.
                # Failure here must never block or fail OCR processing.
                _image_target = next(
                    (
                        li
                        for li in created_line_items
                        if (li.product_name or li.item_description)
                        and not li.product_image_url
                    ),
                    None,
                )
                if _image_target:
                    _query_name = (
                        _image_target.product_name or _image_target.item_description
                    )
                    try:
                        img_result = (
                            self.product_image_service.search_product_image_sync(
                                _query_name
                            )
                        )
                        if img_result:
                            _image_target.product_image_url = img_result.get("imageUrl")
                            logger.info(
                                f"Product image stored for line item {_image_target.id}: "
                                f"{(_image_target.product_image_url or '')[:80]}"
                            )
                    except Exception as img_exc:
                        logger.warning(
                            f"Product image lookup failed for receipt {receipt_id}: {img_exc}"
                        )

                logger.info(f"OCR successful for receipt: {receipt_id}")
            else:
                # OCR failed
                setattr(receipt, "ocr_retry_count", int(receipt.ocr_retry_count) + 1)
                setattr(receipt, "status", ReceiptStatus.OCR_FAILED)
                logger.warning(f"OCR failed for receipt: {receipt_id}")

            db.commit()

            # Re-fetch via get_receipt so the returned object has all scalar
            # columns refreshed AND line_items eagerly loaded via selectinload.
            # A plain db.refresh() after synchronize_session=False delete does
            # NOT repopulate the relationship cache, causing empty lineItems
            # in the upload response.
            return self.get_receipt(db, receipt_id, user_id)

        except Exception as e:
            logger.error(f"OCR processing error for receipt {receipt_id}: {e}")
            setattr(receipt, "ocr_retry_count", int(receipt.ocr_retry_count) + 1)
            setattr(receipt, "status", ReceiptStatus.OCR_FAILED)
            setattr(receipt, "last_ocr_attempt_at", datetime.now(timezone.utc))
            db.commit()
            return receipt

    def retry_ocr(
        self, db: Session, receipt_id: str, user_id: str
    ) -> Optional[Receipt]:
        """
        Retry OCR processing for a failed receipt.

        Args:
            db: Database session
            receipt_id: Receipt ID
            user_id: User ID

        Returns:
            Updated receipt or None
        """
        receipt = self.get_receipt(db, receipt_id, user_id)

        if not receipt:
            return None

        if receipt.ocr_retry_count >= settings.OCR_MAX_RETRIES:
            logger.warning(f"Max OCR retries exceeded for receipt: {receipt_id}")
            return receipt

        setattr(receipt, "status", ReceiptStatus.PROCESSING)
        db.commit()
        return self.process_ocr(db, receipt_id, user_id)

    def create_line_item(
        self,
        db: Session,
        receipt_id: str,
        user_id: str,
        item_data: ReceiptLineItemUpdate,
    ) -> Optional[ReceiptLineItem]:
        """
        Create a new line item on a receipt.

        Used for manual-entry receipts where no OCR line items exist yet.
        Expiry dates are computed from the parent receipt's purchase_date.

        Returns the new ReceiptLineItem, or None if receipt not found.
        """
        receipt = self.get_receipt(db, receipt_id, user_id)
        if not receipt:
            return None

        # Determine next row_index
        existing_count = (
            db.query(ReceiptLineItem)
            .filter(
                ReceiptLineItem.receipt_id == receipt_id,
                ReceiptLineItem.deleted_at.is_(None),
            )
            .count()
        )

        fields = item_data.model_dump(exclude_unset=True)
        warranty_months = fields.get("warranty_period_months")
        return_days = fields.get("return_period_days")

        warranty_expiry = None
        return_expiry = None
        if receipt.purchase_date:
            if warranty_months:
                warranty_expiry = receipt.purchase_date + relativedelta(
                    months=warranty_months
                )
            if return_days:
                return_expiry = receipt.purchase_date + timedelta(days=return_days)

        line_item = ReceiptLineItem(
            id=str(uuid.uuid4()),
            receipt_id=receipt_id,
            row_index=existing_count,
            product_code=fields.get("product_code"),
            item_description=fields.get("item_description"),
            unit_price=fields.get("unit_price"),
            product_name=fields.get("product_name"),
            product_category=fields.get("product_category"),
            warranty_period_months=warranty_months,
            warranty_expiry_date=warranty_expiry,
            return_period_days=return_days,
            return_expiry_date=return_expiry,
            warranty_lead_days_override=fields.get("warranty_lead_days_override"),
            return_lead_days_override=fields.get("return_lead_days_override"),
            warranty_reminder_enabled=fields.get("warranty_reminder_enabled", True),
            return_reminder_enabled=fields.get("return_reminder_enabled", True),
        )
        db.add(line_item)

        # ── Product image lookup ─────────────────────────────────────────
        # Best-effort: fetch a product image from Brave for the new item.
        # Failure must never block the save.
        _query_name = line_item.product_name or line_item.item_description
        if _query_name:
            try:
                img_result = self.product_image_service.search_product_image_sync(
                    _query_name
                )
                if img_result:
                    line_item.product_image_url = img_result.get("imageUrl")
                    logger.info(
                        f"Product image stored for new line item on receipt {receipt_id}: "
                        f"{(line_item.product_image_url or '')[:80]}"
                    )
            except Exception as img_exc:
                logger.warning(
                    f"Product image lookup failed for new line item on receipt "
                    f"{receipt_id}: {img_exc}"
                )

        db.commit()
        db.refresh(line_item)
        logger.info(
            f"Created line item {line_item.id} on receipt {receipt_id} for user {user_id}"
        )
        return line_item

    def update_line_item(
        self,
        db: Session,
        receipt_id: str,
        item_id: str,
        user_id: str,
        item_data: ReceiptLineItemUpdate,
    ) -> Optional[ReceiptLineItem]:
        """
        Partially update a single line item (product name, category, warranty).

        Recalculates warranty_expiry_date / return_expiry_date whenever the
        period fields change, using the parent receipt's purchase_date as anchor.

        Returns updated ReceiptLineItem, or None if not found / unauthorised.
        """
        receipt = self.get_receipt(db, receipt_id, user_id)
        if not receipt:
            return None

        line_item = (
            db.query(ReceiptLineItem)
            .filter(
                ReceiptLineItem.id == item_id,
                ReceiptLineItem.receipt_id == receipt_id,
                ReceiptLineItem.deleted_at.is_(None),
            )
            .first()
        )
        if not line_item:
            return None

        update_fields = item_data.model_dump(exclude_unset=True)
        for field, value in update_fields.items():
            setattr(line_item, field, value)

        # ── Product image lookup ─────────────────────────────────────────
        # Fetch a product image when product_name is being set and the item
        # has no image yet (e.g. first save via the confirmation screen).
        _new_name = update_fields.get("product_name") or line_item.product_name
        if _new_name and not line_item.product_image_url:
            try:
                img_result = self.product_image_service.search_product_image_sync(
                    _new_name
                )
                if img_result:
                    line_item.product_image_url = img_result.get("imageUrl")
                    logger.info(
                        f"Product image stored for line item {item_id}: "
                        f"{(line_item.product_image_url or '')[:80]}"
                    )
            except Exception as img_exc:
                logger.warning(
                    f"Product image lookup failed for line item {item_id}: {img_exc}"
                )

        # Recompute expiry dates using the receipt's purchase_date as anchor
        purchase_date = receipt.purchase_date
        if purchase_date:
            if line_item.warranty_period_months is not None:
                setattr(
                    line_item,
                    "warranty_expiry_date",
                    purchase_date
                    + relativedelta(months=cast(int, line_item.warranty_period_months)),
                )
            else:
                setattr(line_item, "warranty_expiry_date", None)

            if line_item.return_period_days is not None:
                setattr(
                    line_item,
                    "return_expiry_date",
                    purchase_date
                    + timedelta(days=cast(int, line_item.return_period_days)),
                )
            else:
                setattr(line_item, "return_expiry_date", None)

        db.commit()
        db.refresh(line_item)
        logger.info(
            f"Updated line item {item_id} on receipt {receipt_id} for user {user_id}"
        )
        return line_item

    def delete_line_item(
        self,
        db: Session,
        receipt_id: str,
        item_id: str,
        user_id: str,
    ) -> bool:
        """
        Soft delete a single line item.

        Returns:
            True if deleted, False if not found or unauthorized.
        """
        receipt = self.get_receipt(db, receipt_id, user_id)
        if not receipt:
            return False

        line_item = (
            db.query(ReceiptLineItem)
            .filter(
                ReceiptLineItem.id == item_id,
                ReceiptLineItem.receipt_id == receipt_id,
                ReceiptLineItem.deleted_at.is_(None),
            )
            .first()
        )
        if not line_item:
            return False

        now = datetime.now(timezone.utc)
        setattr(line_item, "deleted_at", now)

        # Soft delete claims linked specifically to this line item
        db.query(ClaimDocument).filter(
            ClaimDocument.line_item_id == item_id, ClaimDocument.deleted_at.is_(None)
        ).update({"deleted_at": now})

        db.commit()
        logger.info(
            f"Soft-deleted line item {item_id} on receipt {receipt_id} for user {user_id}"
        )
        return True


# Global service instance
receipt_service = ReceiptService()
