"""
Pydantic schemas for API request/response validation.
"""

from pydantic import BaseModel, EmailStr, ConfigDict, Field
from typing import Optional, List, Literal
from datetime import datetime
from enum import Enum


def to_camel(string: str) -> str:
    """Convert snake_case to camelCase."""
    components = string.split("_")
    return components[0] + "".join(x.title() for x in components[1:])


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
    contact_number: Optional[str] = None


class UserCreate(UserBase):
    """User creation schema."""

    firebase_uid: str


class UserUpdate(BaseModel):
    """User update schema."""

    display_name: Optional[str] = Field(None, max_length=200)
    contact_number: Optional[str] = Field(None, max_length=30)

    model_config = ConfigDict(populate_by_name=True, alias_generator=to_camel)


class UserResponse(UserBase):
    """User response schema."""

    id: str
    firebase_uid: str
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(
        from_attributes=True, populate_by_name=True, alias_generator=to_camel
    )


# ============================================
# Receipt Line Item Schema
# ============================================
class ReceiptLineItemResponse(BaseModel):
    """Single line item on a receipt.

    Each line item represents exactly 1 physical unit (implicit quantity=1).
    For multi-quantity items, multiple records are created with the same row_index.
    """

    id: str
    receipt_id: str
    row_index: int
    product_code: Optional[str] = None
    item_description: Optional[str] = None
    unit_price: Optional[float] = None
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
    status: str
    replacement_for_id: Optional[str] = None
    replaced_by_id: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(
        from_attributes=True, populate_by_name=True, alias_generator=to_camel
    )


class ReceiptLineItemUpdate(BaseModel):
    """Partial update schema for a single line item."""

    product_code: Optional[str] = Field(None, max_length=100)
    item_description: Optional[str] = Field(None, max_length=500)
    unit_price: Optional[float] = None
    product_name: Optional[str] = Field(None, max_length=300)
    product_category: Optional[str] = Field(None, max_length=100)
    warranty_period_months: Optional[int] = None
    return_period_days: Optional[int] = None
    warranty_lead_days_override: Optional[int] = None
    return_lead_days_override: Optional[int] = None
    warranty_reminder_enabled: Optional[bool] = None
    return_reminder_enabled: Optional[bool] = None

    model_config = ConfigDict(populate_by_name=True, alias_generator=to_camel)


# ============================================
# Receipt Schemas
# ============================================
class ReceiptBase(BaseModel):
    """Base receipt schema. Product/warranty fields now live on line items."""

    store_name: Optional[str] = Field(None, max_length=300)
    purchase_date: Optional[datetime] = None
    total_amount: Optional[float] = None
    currency: Optional[str] = Field("USD", max_length=10)
    notes: Optional[str] = Field(None, max_length=2000)

    # Invoice / receipt identification
    invoice_number: Optional[str] = Field(None, max_length=100)

    # Vendor contact details
    vendor_address: Optional[str] = Field(None, max_length=500)
    vendor_phone: Optional[str] = Field(None, max_length=30)
    vendor_email: Optional[str] = Field(None, max_length=254)
    vendor_url: Optional[str] = Field(None, max_length=2000)

    # Document-level OCR text fields
    remarks: Optional[str] = Field(None, max_length=1000)  # Remarks / serial number
    warranty_notes: Optional[str] = Field(None, max_length=5000)  # Warranty policy text

    model_config = ConfigDict(populate_by_name=True, alias_generator=to_camel)


class ReceiptCreate(ReceiptBase):
    """Receipt creation schema.

    Accepts optional ``s3_object_key`` and ``back_image_s3_key`` pointing to
    image(s) that were already uploaded to S3 via the ``/receipts/ocr-extract``
    endpoint. When at least one image key is provided, the receipt status is
    set to COMPLETED on creation instead of MANUAL_ENTRY.
    """

    s3_object_key: Optional[str] = None
    back_image_s3_key: Optional[str] = None


class ReceiptUpdate(BaseModel):
    """Receipt update schema (partial updates). Warranty fields are now on line items."""

    store_name: Optional[str] = Field(None, max_length=300)
    purchase_date: Optional[datetime] = None
    total_amount: Optional[float] = None
    currency: Optional[str] = Field(None, max_length=10)
    notes: Optional[str] = Field(None, max_length=2000)
    invoice_number: Optional[str] = Field(None, max_length=100)
    vendor_address: Optional[str] = Field(None, max_length=500)
    vendor_phone: Optional[str] = Field(None, max_length=30)
    vendor_email: Optional[str] = Field(None, max_length=254)
    vendor_url: Optional[str] = Field(None, max_length=2000)
    remarks: Optional[str] = Field(None, max_length=1000)
    warranty_notes: Optional[str] = Field(None, max_length=5000)

    model_config = ConfigDict(populate_by_name=True, alias_generator=to_camel)


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
        from_attributes=True, populate_by_name=True, alias_generator=to_camel
    )


class ReceiptListResponse(BaseModel):
    """Paginated receipt list response."""

    receipts: list[ReceiptResponse]
    total: int
    page: int
    page_size: int

    model_config = ConfigDict(populate_by_name=True, alias_generator=to_camel)


# ============================================
# OCR Extract Schemas  (stateless — no DB write)
# ============================================


class OcrLineItemResult(BaseModel):
    """A single line item extracted by OCR (not persisted to DB).

    Note: quantity field is used during processing to split items,
    but is not persisted to the database.
    """

    row_index: int = 0
    product_code: Optional[str] = None
    item_description: Optional[str] = None
    quantity: Optional[int] = None  # Used to split into multiple records
    unit_price: Optional[float] = None
    product_name: Optional[str] = None
    product_category: Optional[str] = None
    warranty_period_months: Optional[int] = None

    model_config = ConfigDict(populate_by_name=True, alias_generator=to_camel)


class OcrExtractResponse(BaseModel):
    """Response from POST /receipts/ocr-extract.

    Returns the S3 keys of the uploaded image(s) and all OCR-extracted fields.
    Images are stored under ``users/{user_id}/receipts/{session_id}/`` —
    a permanent path so the files are preserved even on OCR failure.
    """

    s3_object_key: str  # Front image or single image S3 key
    back_image_s3_key: Optional[str] = None  # Back image S3 key if provided
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

    model_config = ConfigDict(populate_by_name=True, alias_generator=to_camel)


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

    model_config = ConfigDict(populate_by_name=True, alias_generator=to_camel)


# ============================================
# OCR Schemas
# ============================================
class OCRResult(BaseModel):
    """OCR processing result."""

    status: str  # "success" or "failed"
    extracted_data: dict
    confidence: Optional[float] = None
    error: Optional[str] = None

    model_config = ConfigDict(populate_by_name=True, alias_generator=to_camel)


# ============================================
# Claim Document Schemas
# ============================================
class ClaimStatusEnum(str, Enum):
    """Claim processing status."""

    DRAFT = "DRAFT"
    SUBMITTED = "SUBMITTED"
    IN_PROGRESS = "IN_PROGRESS"
    RESOLVED = "RESOLVED"
    DENIED = "DENIED"


class ClaimDefectImageResponse(BaseModel):
    """Defect image reference in claim response."""

    id: str
    s3_object_key: str
    display_order: int
    created_at: datetime

    model_config = ConfigDict(
        from_attributes=True, populate_by_name=True, alias_generator=to_camel
    )


class ClaimDocumentBase(BaseModel):
    """Base claim document schema."""

    issue_description: str = Field(..., max_length=2000)
    claim_type: Optional[str] = "warranty"

    model_config = ConfigDict(populate_by_name=True, alias_generator=to_camel)


class ClaimDocumentCreate(ClaimDocumentBase):
    """Claim document creation schema."""

    receipt_id: str
    line_item_id: Optional[str] = None
    claim_type: Literal["warranty", "return"] = "warranty"


class ClaimDocumentUpdate(BaseModel):
    """Claim document partial update schema."""

    status: Optional[ClaimStatusEnum] = None
    notes: Optional[str] = None

    model_config = ConfigDict(populate_by_name=True, alias_generator=to_camel)


class ClaimDocumentResponse(ClaimDocumentBase):
    """Claim document response schema."""

    id: str
    receipt_id: str
    line_item_id: Optional[str] = None
    status: ClaimStatusEnum
    notes: Optional[str] = None
    generated_pdf_s3_key: Optional[str]
    url: Optional[str] = None  # Pre-signed S3 URL for downloading the PDF
    defect_images: List[ClaimDefectImageResponse] = []
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(
        from_attributes=True, populate_by_name=True, alias_generator=to_camel
    )


class ClaimResolutionRequest(BaseModel):
    """Claim resolution schema."""

    outcome: str  # "REFUNDED", "REPAIRED", "REPLACED"
    linked_item_id: Optional[str] = None
    duplicate_details: bool = False

    model_config = ConfigDict(populate_by_name=True, alias_generator=to_camel)


# ============================================
# Warranty & Return Schemas
# ============================================
class WarrantyInfo(BaseModel):
    """Warranty information for a single line item."""

    receipt_id: str
    line_item_id: str
    store_name: Optional[str]
    item_description: Optional[str]  # Product or line-item description
    product_name: Optional[str]  # Resolved brand/product name
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
    product_name: Optional[str]  # Resolved brand/product name
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
    warranty_lead_days: int = 30  # days before warranty expiry to send push
    return_lead_days: int = 3  # days before return deadline to send push
    quiet_hours_start: Optional[int] = None  # 0-23
    quiet_hours_end: Optional[int] = None  # 0-23


class UserNotificationPreferencesUpdate(BaseModel):
    """Partial update schema for notification preferences."""

    warranty_reminders_enabled: Optional[bool] = None
    return_reminders_enabled: Optional[bool] = None
    ocr_notifications_enabled: Optional[bool] = None
    warranty_lead_days: Optional[int] = None
    return_lead_days: Optional[int] = None
    quiet_hours_start: Optional[int] = None
    quiet_hours_end: Optional[int] = None

    model_config = ConfigDict(populate_by_name=True, alias_generator=to_camel)


class UserNotificationPreferencesResponse(UserNotificationPreferencesBase):
    """Notification preferences response schema."""

    id: str
    user_id: str
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(
        from_attributes=True, populate_by_name=True, alias_generator=to_camel
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
