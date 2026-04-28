"""
Receipt Image model for database.
Represents individual images (front/back) uploaded for a receipt.
"""

from sqlalchemy import Column, String, DateTime, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from app.db.base import Base


class ReceiptImage(Base):
    """Receipt Image model - stores front/back images for receipts."""

    __tablename__ = "receipt_images"

    # Primary key
    id = Column(String(36), primary_key=True, index=True)

    # Foreign key to receipt
    receipt_id = Column(
        String(36),
        ForeignKey("receipts.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    # S3 object key for the image
    s3_object_key = Column(String(512), nullable=False)

    # Image type: 'FRONT' or 'BACK'
    image_type = Column(String(10), nullable=False, index=True)

    # Timestamps
    created_at = Column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    # Soft delete support
    deleted_at = Column(DateTime(timezone=True), nullable=True)

    # Relationships
    receipt = relationship("Receipt", back_populates="images")

    def __repr__(self):
        return f"<ReceiptImage(id={self.id}, receipt_id={self.receipt_id}, type={self.image_type})>"
