"""
ReceiptLineItem model for database.
Represents a single product / service line on a receipt or invoice.
Supports multi-item receipts and invoices.
"""

from sqlalchemy import (
    Column,
    String,
    DateTime,
    Numeric,
    ForeignKey,
    Integer,
    Boolean,
    Index,
)
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from app.db.base import Base


class ReceiptLineItem(Base):
    """A single line item (product / service) on a receipt.

    Each record represents ONE physical unit. For multi-quantity items
    (e.g., "3× Laptop"), the system creates 3 separate records with the
    same row_index for grouped display.
    """

    __tablename__ = "receipt_line_items"

    # Primary key
    id = Column(String(36), primary_key=True, index=True)

    # Foreign key to parent receipt
    receipt_id = Column(
        String(36),
        ForeignKey("receipts.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    # Row ordering (0-based index from Textract response)
    row_index = Column(Integer, nullable=False, default=0)

    # Product details
    product_code = Column(String(100), nullable=True)  # SKU / barcode
    item_description = Column(String(512), nullable=True)  # Product name / description

    # Pricing (each line item represents 1 physical unit)
    unit_price = Column(Numeric(precision=12, scale=2), nullable=True)  # Price per unit

    # Per-item product details (from OCR or user edit)
    product_name = Column(String(512), nullable=True)  # Product / brand name
    product_category = Column(String(128), nullable=True)  # Category tag
    product_image_url = Column(String(2048), nullable=True)  # Brave Search image URL

    # Per-item warranty & return tracking
    warranty_period_months = Column(Integer, nullable=True)  # Warranty duration
    warranty_expiry_date = Column(DateTime(timezone=True), nullable=True)
    return_period_days = Column(Integer, nullable=True)  # Return window
    return_expiry_date = Column(DateTime(timezone=True), nullable=True)

    # Per-item notification lead time overrides (NULL = use user's global setting)
    warranty_lead_days_override = Column(Integer, nullable=True)
    return_lead_days_override = Column(Integer, nullable=True)

    # Per-item notification toggle (False = don't send notifications for this product)
    warranty_reminder_enabled = Column(Boolean, nullable=False, default=True)
    return_reminder_enabled = Column(Boolean, nullable=False, default=True)

    # Resolution Flow tracking
    status = Column(String(50), nullable=False, default="ACTIVE", index=True)
    replacement_for_id = Column(
        String(36),
        ForeignKey("receipt_line_items.id", ondelete="SET NULL"),
        nullable=True,
    )
    replaced_by_id = Column(String(36), nullable=True)

    # Metadata
    created_at = Column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )
    deleted_at = Column(DateTime(timezone=True), nullable=True)

    # Composite indexes for scheduler queries
    __table_args__ = (
        Index("ix_line_items_warranty_expiry_date", "warranty_expiry_date"),
        Index("ix_line_items_return_expiry_date", "return_expiry_date"),
    )

    # Relationship
    receipt = relationship("Receipt", back_populates="line_items")

    def __repr__(self) -> str:
        return (
            f"<ReceiptLineItem(id={self.id}, receipt={self.receipt_id}, "
            f"idx={self.row_index}, desc={self.item_description!r})>"
        )
