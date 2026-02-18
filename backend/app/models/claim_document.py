"""
Claim Document model for database.
Represents warranty claim documents generated for users.
"""

from sqlalchemy import Column, String, DateTime, ForeignKey, Text
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from app.db.base import Base


class ClaimDocument(Base):
    """Claim Document model - stores generated warranty claim PDFs."""
    
    __tablename__ = "claim_documents"
    
    # Primary key
    id = Column(String(36), primary_key=True, index=True)
    
    # Foreign key to receipt
    receipt_id = Column(String(36), ForeignKey("receipts.id", ondelete="CASCADE"), nullable=False, index=True)
    
    # Claim information
    issue_description = Column(Text, nullable=False)
    claim_type = Column(String(64), nullable=True)  # e.g., "warranty", "return", "repair"
    
    # Generated PDF reference
    generated_pdf_s3_key = Column(String(512), nullable=True)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False, index=True)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    
    # Soft delete support
    deleted_at = Column(DateTime(timezone=True), nullable=True)
    
    # Relationships
    receipt = relationship("Receipt", back_populates="claim_documents")
    
    def __repr__(self):
        return f"<ClaimDocument(id={self.id}, receipt_id={self.receipt_id})>"
