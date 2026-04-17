"""
Receipt model for database.
Represents digitized receipts with OCR data and warranty information.
"""

from sqlalchemy import Column, String, DateTime, ForeignKey, Integer, Text, Numeric, Index, Enum as SQLEnum
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
import enum

from app.db.base import Base


class ReceiptStatus(str, enum.Enum):
    """Receipt processing status enum."""
    LOCAL_ONLY = "LOCAL_ONLY"  # Only on mobile device
    UPLOADED = "UPLOADED"  # Uploaded to S3, pending OCR
    PROCESSING = "PROCESSING"  # OCR in progress
    COMPLETED = "COMPLETED"  # OCR successful
    OCR_FAILED = "OCR_FAILED"  # OCR failed (manual entry needed)
    MANUAL_ENTRY = "MANUAL_ENTRY"  # Manually entered data


class Receipt(Base):
    """Receipt model - stores receipt information and OCR results."""
    
    __tablename__ = "receipts"
    
    # Primary key
    id = Column(String(36), primary_key=True, index=True)
    
    # Foreign key to user
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    
    # S3 storage reference
    s3_object_key = Column(String(512), nullable=True)  # Path in S3 bucket
    
    # Receipt information (from OCR or manual entry)
    store_name = Column(String(255), nullable=True)
    purchase_date = Column(DateTime(timezone=True), nullable=True, index=True)
    total_amount = Column(Numeric(precision=12, scale=2), nullable=True)
    currency = Column(String(3), default="USD", nullable=True)  # ISO 4217 currency code

    # Invoice / receipt identification
    invoice_number = Column(String(100), nullable=True)

    # Vendor contact details (OCR-extracted)
    vendor_address = Column(Text, nullable=True)
    vendor_phone   = Column(String(100), nullable=True)
    vendor_email   = Column(String(255), nullable=True)
    vendor_url     = Column(String(255), nullable=True)

    # Additional OCR fields
    remarks        = Column(Text, nullable=True)   # OTHER/Remarks — serial numbers, etc.
    warranty_notes = Column(Text, nullable=True)   # OTHER/Note — warranty policy text
    
    # Processing status
    status = Column(SQLEnum(ReceiptStatus), default=ReceiptStatus.UPLOADED, nullable=False, index=True)
    
    # OCR retry tracking
    ocr_retry_count = Column(Integer, default=0, nullable=False)
    last_ocr_attempt_at = Column(DateTime(timezone=True), nullable=True)
    
    # Raw OCR response (for debugging/reprocessing)
    ocr_raw_response = Column(Text, nullable=True)
    
    # User notes
    notes = Column(Text, nullable=True)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False, index=True)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    synced_at = Column(DateTime(timezone=True), nullable=True)  # Last sync with mobile
    
    # Soft delete support
    deleted_at = Column(DateTime(timezone=True), nullable=True, index=True)
    
    # Relationships
    user = relationship("User", back_populates="receipts")
    claim_documents = relationship("ClaimDocument", back_populates="receipt", cascade="all, delete-orphan")
    line_items = relationship("ReceiptLineItem", back_populates="receipt", cascade="all, delete-orphan", order_by="ReceiptLineItem.row_index")
    images = relationship("ReceiptImage", back_populates="receipt", cascade="all, delete-orphan", order_by="ReceiptImage.image_type")

    # Composite index for pagination queries (user_id + created_at)
    __table_args__ = (
        Index('ix_receipts_user_id_created_at', 'user_id', 'created_at'),
    )

    def __repr__(self):
        return f"<Receipt(id={self.id}, store={self.store_name}, status={self.status})>"
