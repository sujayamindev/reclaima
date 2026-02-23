"""
Receipt service - Business logic for receipt operations.
Handles CRUD operations, file upload, OCR processing, and warranty calculations.
"""

import logging
import uuid
from typing import Optional, List
from datetime import datetime, timedelta
from dateutil import parser as dateutil_parser
from sqlalchemy.orm import Session, selectinload
from sqlalchemy import and_

from app.models import Receipt, ReceiptStatus, User
from app.models.receipt_line_item import ReceiptLineItem
from app.schemas import ReceiptCreate, ReceiptUpdate
from app.services.s3_service import get_s3_service
from app.services.textract_service import get_textract_service
from app.core.config import settings

logger = logging.getLogger(__name__)


class ReceiptService:
    """Service for receipt operations."""
    
    def __init__(self):
        """Initialize receipt service with AWS services."""
        self.s3_service = get_s3_service(
            bucket_name=settings.AWS_S3_BUCKET,
            use_mock=settings.USE_MOCK_AWS,
            region=settings.AWS_REGION
        )
        self.textract_service = get_textract_service(
            s3_bucket=settings.AWS_S3_BUCKET,
            use_mock=settings.USE_MOCK_AWS,
            region=settings.AWS_REGION
        )
    
    def create_receipt(
        self,
        db: Session,
        user_id: str,
        receipt_data: ReceiptCreate
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
        
        # Calculate warranty and return expiry dates if purchase date provided
        warranty_expiry = None
        return_expiry = None
        
        if receipt_data.purchase_date:
            if receipt_data.warranty_period_months:
                warranty_expiry = receipt_data.purchase_date + timedelta(
                    days=receipt_data.warranty_period_months * 30
                )
            
            if receipt_data.return_period_days:
                return_expiry = receipt_data.purchase_date + timedelta(
                    days=receipt_data.return_period_days
                )
        
        receipt = Receipt(
            id=receipt_id,
            user_id=user_id,
            store_name=receipt_data.store_name,
            purchase_date=receipt_data.purchase_date,
            total_amount=receipt_data.total_amount,
            currency=receipt_data.currency,
            product_name=receipt_data.product_name,
            product_category=receipt_data.product_category,
            warranty_period_months=receipt_data.warranty_period_months,
            warranty_expiry_date=warranty_expiry,
            # Do NOT default return_period_days here — only set it when the
            # user explicitly provides it or OCR finds a return policy.
            return_period_days=receipt_data.return_period_days,
            return_expiry_date=return_expiry,
            notes=receipt_data.notes,
            status=ReceiptStatus.UPLOADED
        )
        
        db.add(receipt)
        db.commit()
        db.refresh(receipt)
        
        logger.info(f"Created receipt: {receipt_id} for user: {user_id}")
        
        return receipt
    
    def get_receipt(
        self,
        db: Session,
        receipt_id: str,
        user_id: str
    ) -> Optional[Receipt]:
        """
        Get receipt by ID (user-scoped), with line items eagerly loaded.
        """
        return db.query(Receipt).options(
            selectinload(Receipt.line_items)
        ).filter(
            and_(
                Receipt.id == receipt_id,
                Receipt.user_id == user_id,
                Receipt.deleted_at.is_(None)
            )
        ).first()
    
    def list_receipts(
        self,
        db: Session,
        user_id: str,
        skip: int = 0,
        limit: int = 100,
        status: Optional[ReceiptStatus] = None
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
            and_(
                Receipt.user_id == user_id,
                Receipt.deleted_at.is_(None)
            )
        )
        
        if status:
            query = query.filter(Receipt.status == status)
        
        total = query.count()
        receipts = query.options(
            selectinload(Receipt.line_items)
        ).order_by(Receipt.created_at.desc()).offset(skip).limit(limit).all()

        return receipts, total
    
    def update_receipt(
        self,
        db: Session,
        receipt_id: str,
        user_id: str,
        receipt_data: ReceiptUpdate
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
        
        # Recalculate warranty expiry only if not explicitly provided
        if receipt_data.warranty_expiry_date is None and \
                (receipt_data.purchase_date or receipt_data.warranty_period_months):
            if receipt.purchase_date and receipt.warranty_period_months:
                receipt.warranty_expiry_date = receipt.purchase_date + timedelta(
                    days=receipt.warranty_period_months * 30
                )

        # Recalculate return expiry only if not explicitly provided
        if receipt_data.return_expiry_date is None and \
                (receipt_data.purchase_date or receipt_data.return_period_days):
            if receipt.purchase_date and receipt.return_period_days:
                receipt.return_expiry_date = receipt.purchase_date + timedelta(
                    days=receipt.return_period_days
                )
        
        db.commit()
        db.refresh(receipt)
        
        logger.info(f"Updated receipt: {receipt_id}")
        
        return receipt
    
    def delete_receipt(
        self,
        db: Session,
        receipt_id: str,
        user_id: str
    ) -> bool:
        """
        Soft delete receipt.
        
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
        
        receipt.deleted_at = datetime.utcnow()
        db.commit()
        
        logger.info(f"Soft deleted receipt: {receipt_id}")
        
        return True
    
    def upload_receipt_file(
        self,
        db: Session,
        receipt_id: str,
        user_id: str,
        file_content: bytes,
        file_name: str,
        content_type: str
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
            content_type=content_type
        )
        
        # Update receipt with S3 key
        receipt.s3_object_key = s3_object_key
        receipt.status = ReceiptStatus.PROCESSING
        db.commit()
        
        logger.info(f"Uploaded file for receipt: {receipt_id}")

        # Trigger OCR processing and return its result so the caller receives
        # the fully-populated receipt (with line items, warranty notes, etc.)
        # rather than the stale pre-OCR object loaded before processing ran.
        return self.process_ocr(db, receipt_id, user_id)
    
    def process_ocr(
        self,
        db: Session,
        receipt_id: str,
        user_id: str
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
            
            receipt.last_ocr_attempt_at = datetime.utcnow()
            
            if ocr_result.get("status") == "success":
                # Extract data from OCR result
                extracted = ocr_result.get("extracted_data", {})

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
                    receipt.total_amount = float(extracted["total_amount"])

                if extracted.get("currency"):
                    receipt.currency = extracted["currency"]

                if extracted.get("product_name"):
                    receipt.product_name = extracted["product_name"]

                if extracted.get("warranty_period_months"):
                    receipt.warranty_period_months = int(extracted["warranty_period_months"])

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

                # ── calculate warranty / return dates ─────────────────────────
                if receipt.purchase_date:
                    if receipt.warranty_period_months:
                        receipt.warranty_expiry_date = receipt.purchase_date + timedelta(
                            days=receipt.warranty_period_months * 30
                        )

                    # Only calculate return expiry when a return period was
                    # explicitly found (user-provided or OCR-extracted).
                    # Do NOT default to 30 days — that creates false return
                    # deadlines on invoices that have no return policy.
                    if receipt.return_period_days is not None:
                        receipt.return_expiry_date = receipt.purchase_date + timedelta(
                            days=receipt.return_period_days
                        )

                receipt.status = ReceiptStatus.COMPLETED
                receipt.ocr_raw_response = str(ocr_result)

                # ── line items ────────────────────────────────────────────────
                # Remove any existing line items (e.g. from a previous retry)
                db.query(ReceiptLineItem).filter(
                    ReceiptLineItem.receipt_id == receipt.id
                ).delete(synchronize_session=False)

                for item_data in extracted.get("line_items", []):
                    line_item = ReceiptLineItem(
                        id=str(uuid.uuid4()),
                        receipt_id=receipt.id,
                        row_index=item_data.get("row_index", 0),
                        product_code=item_data.get("product_code"),
                        item_description=item_data.get("item_description"),
                        quantity=item_data.get("quantity"),
                        unit_price=item_data.get("unit_price"),
                        amount=item_data.get("amount"),
                    )
                    db.add(line_item)

                logger.info(f"OCR successful for receipt: {receipt_id}")
            else:
                # OCR failed
                receipt.ocr_retry_count += 1
                receipt.status = ReceiptStatus.OCR_FAILED
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
            receipt.ocr_retry_count += 1
            receipt.status = ReceiptStatus.OCR_FAILED
            receipt.last_ocr_attempt_at = datetime.utcnow()
            db.commit()
            return receipt
    
    def retry_ocr(
        self,
        db: Session,
        receipt_id: str,
        user_id: str
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
        
        receipt.status = ReceiptStatus.PROCESSING
        db.commit()
        
        return self.process_ocr(db, receipt_id, user_id)


# Global service instance
receipt_service = ReceiptService()
