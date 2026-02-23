"""
ReceiptLineItem model for database.
Represents a single product / service line on a receipt or invoice.
Supports multi-item receipts and invoices.
"""

from sqlalchemy import Column, String, DateTime, Float, ForeignKey, Integer
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from app.db.base import Base


class ReceiptLineItem(Base):
    """A single line item (product / service) on a receipt."""

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
    product_code    = Column(String(100),  nullable=True)   # SKU / barcode
    item_description = Column(String(512), nullable=True)   # Product name / description

    # Quantity stored as string to preserve "1 PC", "2.5 KG", "each", etc.
    quantity = Column(String(50), nullable=True)

    # Pricing
    unit_price = Column(Float, nullable=True)   # Price per unit
    amount     = Column(Float, nullable=True)   # Row total (quantity × unit_price)

    # Metadata
    created_at = Column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    # Relationship
    receipt = relationship("Receipt", back_populates="line_items")

    def __repr__(self) -> str:
        return (
            f"<ReceiptLineItem(id={self.id}, receipt={self.receipt_id}, "
            f"idx={self.row_index}, desc={self.item_description!r})>"
        )
