"""
Pydantic schemas for API request/response validation.
"""

from pydantic import BaseModel, Field, EmailStr, ConfigDict
from typing import Optional, List
from datetime import datetime
from enum import Enum


def to_camel(string: str) -> str:
    """Convert snake_case to camelCase."""
    components = string.split('_')
    return components[0] + ''.join(x.title() for x in components[1:])


# ============================================
# Receipt Status Enum
# ============================================
class ReceiptStatusEnum(str, Enum):
    """Receipt processing status."""
    LOCAL_ONLY = "LOCAL_ONLY"
    UPLOADED = "UPLOADED"
    PROCESSING = "PROCESSING"
    COMPLETED = "COMPLETED"
    OCR_FAILED = "OCR_FAILED"
    MANUAL_ENTRY = "MANUAL_ENTRY"


# ============================================
# User Schemas
# ============================================
class UserBase(BaseModel):
    """Base user schema."""
    email: EmailStr
    display_name: Optional[str] = None


class UserCreate(UserBase):
    """User creation schema."""
    firebase_uid: str


class UserUpdate(BaseModel):
    """User update schema."""
    display_name: Optional[str] = None


class UserResponse(UserBase):
    """User response schema."""
    id: str
    firebase_uid: str
    created_at: datetime
    updated_at: datetime
    
    model_config = ConfigDict(
        from_attributes=True,
        populate_by_name=True,
        alias_generator=to_camel
    )


# ============================================
# Receipt Line Item Schema
# ============================================
class ReceiptLineItemResponse(BaseModel):
    """Single line item on a receipt."""
    id: str
    receipt_id: str
    row_index: int
    product_code: Optional[str] = None
    item_description: Optional[str] = None
    quantity: Optional[str] = None
    unit_price: Optional[float] = None
    amount: Optional[float] = None
    # Per-item product & warranty fields
    product_name: Optional[str] = None
    product_category: Optional[str] = None
    product_image_url: Optional[str] = None
    warranty_period_months: Optional[int] = None
    warranty_expiry_date: Optional[datetime] = None
    return_period_days: Optional[int] = None
    return_expiry_date: Optional[datetime] = None
    # Per-item notification lead time overrides
    warranty_lead_days_override: Optional[int] = None
    return_lead_days_override: Optional[int] = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(
        from_attributes=True,
        populate_by_name=True,
        alias_generator=to_camel
    )


class ReceiptLineItemUpdate(BaseModel):
    """Partial update schema for a single line item."""
    item_description: Optional[str] = None
    product_name: Optional[str] = None
    product_category: Optional[str] = None
    warranty_period_months: Optional[int] = None
    return_period_days: Optional[int] = None
    warranty_lead_days_override: Optional[int] = None
    return_lead_days_override: Optional[int] = None
    warranty_reminder_enabled: Optional[bool] = None
    return_reminder_enabled: Optional[bool] = None

    model_config = ConfigDict(
        populate_by_name=True,
        alias_generator=to_camel
    )


# ============================================
# Receipt Schemas
# ============================================
class ReceiptBase(BaseModel):
    """Base receipt schema. Product/warranty fields now live on line items."""
    store_name: Optional[str] = None
    purchase_date: Optional[datetime] = None
    total_amount: Optional[float] = None
    currency: Optional[str] = "USD"
    notes: Optional[str] = None

    # Invoice / receipt identification
    invoice_number: Optional[str] = None

    # Vendor contact details
    vendor_address: Optional[str] = None
    vendor_phone: Optional[str] = None
    vendor_email: Optional[str] = None
    vendor_url: Optional[str] = None

    # Document-level OCR text fields
    remarks: Optional[str] = None        # Remarks / serial number
    warranty_notes: Optional[str] = None  # Warranty policy text

    model_config = ConfigDict(
        populate_by_name=True,
        alias_generator=to_camel
    )


class ReceiptCreate(ReceiptBase):
    """Receipt creation schema.

    Accepts an optional ``s3_object_key`` pointing to an image that was
    already uploaded to S3 via the ``/receipts/ocr-extract`` endpoint.
    When provided the receipt status is set to COMPLETED on creation instead
    of MANUAL_ENTRY.
    """
    s3_object_key: Optional[str] = None


class ReceiptUpdate(BaseModel):
    """Receipt update schema (partial updates). Warranty fields are now on line items."""
    store_name: Optional[str] = None
    purchase_date: Optional[datetime] = None
    total_amount: Optional[float] = None
    currency: Optional[str] = None
    notes: Optional[str] = None
    invoice_number: Optional[str] = None
    vendor_address: Optional[str] = None
    vendor_phone: Optional[str] = None
    vendor_email: Optional[str] = None
    vendor_url: Optional[str] = None
    remarks: Optional[str] = None
    warranty_notes: Optional[str] = None

    model_config = ConfigDict(
        populate_by_name=True,
        alias_generator=to_camel
    )


class ReceiptResponse(ReceiptBase):
    """Receipt response schema. Warranty info is embedded in line_items."""
    id: str
    user_id: str
    s3_object_key: Optional[str]
    status: ReceiptStatusEnum
    ocr_retry_count: int
    last_ocr_attempt_at: Optional[datetime]
    created_at: datetime
    updated_at: datetime
    synced_at: Optional[datetime]
    line_items: List[ReceiptLineItemResponse] = []

    model_config = ConfigDict(
        from_attributes=True,
        populate_by_name=True,
        alias_generator=to_camel
    )


class ReceiptListResponse(BaseModel):
    """Paginated receipt list response."""
    receipts: list[ReceiptResponse]
    total: int
    page: int
    page_size: int
    
    model_config = ConfigDict(
        populate_by_name=True,
        alias_generator=to_camel
    )


# ============================================
# OCR Extract Schemas  (stateless — no DB write)
# ============================================

class OcrLineItemResult(BaseModel):
    """A single line item extracted by OCR (not persisted to DB)."""
    row_index: int = 0
    product_code: Optional[str] = None
    item_description: Optional[str] = None
    quantity: Optional[str] = None
    unit_price: Optional[float] = None
    amount: Optional[float] = None
    product_name: Optional[str] = None
    product_category: Optional[str] = None
    warranty_period_months: Optional[int] = None

    model_config = ConfigDict(
        populate_by_name=True,
        alias_generator=to_camel
    )


class OcrExtractResponse(BaseModel):
    """Response from POST /receipts/ocr-extract.

    Returns the S3 key of the uploaded image and all OCR-extracted fields.
    The image is stored under ``users/{user_id}/receipts/{session_id}/`` —
    a permanent path so the file is preserved even on OCR failure.
    """
    s3_object_key: str
    ocr_status: str  # "success" | "failed"
    # Receipt-level fields
    store_name: Optional[str] = None
    purchase_date: Optional[datetime] = None
    total_amount: Optional[float] = None
    currency: Optional[str] = None
    invoice_number: Optional[str] = None
    vendor_address: Optional[str] = None
    vendor_phone: Optional[str] = None
    vendor_email: Optional[str] = None
    vendor_url: Optional[str] = None
    remarks: Optional[str] = None
    warranty_notes: Optional[str] = None
    # Single-product hints (for receipts with no explicit line items)
    product_name: Optional[str] = None
    warranty_period_months: Optional[int] = None
    # Extracted line items
    line_items: List[OcrLineItemResult] = []

    model_config = ConfigDict(
        populate_by_name=True,
        alias_generator=to_camel
    )


# ============================================
# Receipt Upload Schemas
# ============================================
class ReceiptUploadRequest(BaseModel):
    """Receipt upload initiation request."""
    file_name: str
    content_type: str


class ReceiptUploadResponse(BaseModel):
    """Receipt upload response with pre-signed URL."""
    receipt_id: str
    upload_url: str
    s3_object_key: str
    expires_in: int = 900  # 15 minutes
    
    model_config = ConfigDict(
        populate_by_name=True,
        alias_generator=to_camel
    )


# ============================================
# OCR Schemas
# ============================================
class OCRResult(BaseModel):
    """OCR processing result."""
    status: str  # "success" or "failed"
    extracted_data: dict
    confidence: Optional[float] = None
    error: Optional[str] = None
    
    model_config = ConfigDict(
        populate_by_name=True,
        alias_generator=to_camel
    )


# ============================================
# Claim Document Schemas
# ============================================
class ClaimDocumentBase(BaseModel):
    """Base claim document schema."""
    issue_description: str
    claim_type: Optional[str] = "warranty"


class ClaimDocumentCreate(ClaimDocumentBase):
    """Claim document creation schema."""
    receipt_id: str


class ClaimDocumentResponse(ClaimDocumentBase):
    """Claim document response schema."""
    id: str
    receipt_id: str
    generated_pdf_s3_key: Optional[str]
    url: Optional[str] = None  # Pre-signed S3 URL for downloading the PDF
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(
        from_attributes=True,
        populate_by_name=True,
        alias_generator=to_camel
    )


# ============================================
# Warranty & Return Schemas
# ============================================
class WarrantyInfo(BaseModel):
    """Warranty information for a single line item."""
    receipt_id: str
    line_item_id: str
    store_name: Optional[str]
    item_description: Optional[str]  # Product or line-item description
    product_name: Optional[str]      # Resolved brand/product name
    purchase_date: Optional[datetime]
    warranty_period_months: Optional[int]
    warranty_expiry_date: Optional[datetime]
    days_remaining: Optional[int]
    is_expired: bool


class ReturnInfo(BaseModel):
    """Return deadline information for a single line item."""
    receipt_id: str
    line_item_id: str
    store_name: Optional[str]
    item_description: Optional[str]  # Product or line-item description
    product_name: Optional[str]      # Resolved brand/product name
    purchase_date: Optional[datetime]
    return_period_days: Optional[int]
    return_expiry_date: Optional[datetime]
    days_remaining: Optional[int]
    is_expired: bool


# ============================================
# Notification Preference Schemas
# ============================================
class UserNotificationPreferencesBase(BaseModel):
    """Base notification preferences schema."""
    warranty_reminders_enabled: bool = True
    return_reminders_enabled: bool = True
    ocr_notifications_enabled: bool = True
    warranty_lead_days: int = 30    # days before warranty expiry to send push
    return_lead_days: int = 3       # days before return deadline to send push
    quiet_hours_start: Optional[int] = None  # 0-23
    quiet_hours_end: Optional[int] = None    # 0-23


class UserNotificationPreferencesUpdate(BaseModel):
    """Partial update schema for notification preferences."""
    warranty_reminders_enabled: Optional[bool] = None
    return_reminders_enabled: Optional[bool] = None
    ocr_notifications_enabled: Optional[bool] = None
    warranty_lead_days: Optional[int] = None
    return_lead_days: Optional[int] = None
    quiet_hours_start: Optional[int] = None
    quiet_hours_end: Optional[int] = None

    model_config = ConfigDict(
        populate_by_name=True,
        alias_generator=to_camel
    )


class UserNotificationPreferencesResponse(UserNotificationPreferencesBase):
    """Notification preferences response schema."""
    id: str
    user_id: str
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(
        from_attributes=True,
        populate_by_name=True,
        alias_generator=to_camel
    )


class UserFcmTokenUpdate(BaseModel):
    """Request body for registering/clearing an FCM device token."""
    token: Optional[str] = None


# ============================================
# Receipt Image URL Schema
# ============================================
class ReceiptImageUrlResponse(BaseModel):
    """Response containing a pre-signed S3 URL for the receipt image."""
    url: str

    model_config = ConfigDict(populate_by_name=True, alias_generator=to_camel)


# ============================================
# Health Check Schema
# ============================================
class HealthCheckResponse(BaseModel):
    """Health check response."""
    status: str
    version: str
    timestamp: datetime
    database: str
    firebase: str
    aws_mock: bool
