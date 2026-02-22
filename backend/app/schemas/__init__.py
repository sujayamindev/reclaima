"""
Pydantic schemas for API request/response validation.
"""

from pydantic import BaseModel, Field, EmailStr, ConfigDict
from typing import Optional
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
# Receipt Schemas
# ============================================
class ReceiptBase(BaseModel):
    """Base receipt schema."""
    store_name: Optional[str] = None
    purchase_date: Optional[datetime] = None
    total_amount: Optional[float] = None
    currency: Optional[str] = "USD"
    product_name: Optional[str] = None
    product_category: Optional[str] = None
    warranty_period_months: Optional[int] = None
    return_period_days: Optional[int] = 30
    notes: Optional[str] = None
    
    model_config = ConfigDict(
        populate_by_name=True,
        alias_generator=to_camel
    )


class ReceiptCreate(ReceiptBase):
    """Receipt creation schema."""
    pass


class ReceiptUpdate(BaseModel):
    """Receipt update schema (partial updates)."""
    store_name: Optional[str] = None
    purchase_date: Optional[datetime] = None
    total_amount: Optional[float] = None
    currency: Optional[str] = None
    product_name: Optional[str] = None
    product_category: Optional[str] = None
    warranty_period_months: Optional[int] = None
    return_period_days: Optional[int] = None
    notes: Optional[str] = None
    
    model_config = ConfigDict(
        populate_by_name=True,
        alias_generator=to_camel
    )


class ReceiptResponse(ReceiptBase):
    """Receipt response schema."""
    id: str
    user_id: str
    s3_object_key: Optional[str]
    warranty_expiry_date: Optional[datetime]
    return_expiry_date: Optional[datetime]
    status: ReceiptStatusEnum
    ocr_retry_count: int
    last_ocr_attempt_at: Optional[datetime]
    created_at: datetime
    updated_at: datetime
    synced_at: Optional[datetime]
    
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
    """Warranty information schema."""
    receipt_id: str
    store_name: Optional[str]
    product_name: Optional[str]
    purchase_date: Optional[datetime]
    warranty_expiry_date: Optional[datetime]
    days_remaining: Optional[int]
    is_expired: bool


class ReturnInfo(BaseModel):
    """Return deadline information schema."""
    receipt_id: str
    store_name: Optional[str]
    product_name: Optional[str]
    purchase_date: Optional[datetime]
    return_expiry_date: Optional[datetime]
    days_remaining: Optional[int]
    is_expired: bool


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
