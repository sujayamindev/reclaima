"""
Claim Defect Image model for database.
Represents defect images uploaded by users as evidence for warranty/return claims.
"""

from sqlalchemy import Column, String, DateTime, ForeignKey, Integer
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from app.db.base import Base


class ClaimDefectImage(Base):
    """Claim Defect Image model - stores references to defect images uploaded for claims."""

    __tablename__ = "claim_defect_images"

    # Primary key
    id = Column(String(36), primary_key=True, index=True)

    # Foreign key to claim document
    claim_id = Column(
        String(36),
        ForeignKey("claim_documents.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    # S3 object key for the defect image
    s3_object_key = Column(String(512), nullable=False)

    # Display order for sorting images (0-indexed)
    display_order = Column(Integer, nullable=False, server_default="0", index=True)

    # Timestamps
    created_at = Column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    # Soft delete support
    deleted_at = Column(DateTime(timezone=True), nullable=True)

    # Relationships
    claim = relationship("ClaimDocument", back_populates="defect_images")

    def __repr__(self):
        return f"<ClaimDefectImage(id={self.id}, claim_id={self.claim_id}, order={self.display_order})>"
