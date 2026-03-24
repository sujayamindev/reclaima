"""
User model for database.
Represents users authenticated via Firebase.
"""

from sqlalchemy import Column, String, DateTime
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from app.db.base import Base



class User(Base):
    """User model - stores Firebase authenticated users."""
    
    __tablename__ = "users"
    
    # Primary key - using UUID as string
    id = Column(String(36), primary_key=True, index=True)
    
    # Firebase UID (unique identifier from Firebase Auth)
    firebase_uid = Column(String(128), unique=True, nullable=False, index=True)
    
    # User information
    email = Column(String(255), unique=True, nullable=False, index=True)
    display_name = Column(String(255), nullable=True)
    contact_number = Column(String(50), nullable=True)

    # Push notifications
    fcm_token = Column(String(512), nullable=True)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)
    
    # Soft delete support
    deleted_at = Column(DateTime(timezone=True), nullable=True)
    
    # Relationships
    receipts = relationship("Receipt", back_populates="user", cascade="all, delete-orphan")
    notification_preferences = relationship(
        "UserNotificationPreferences", back_populates="user",
        uselist=False, cascade="all, delete-orphan"
    )
    
    def __repr__(self):
        return f"<User(id={self.id}, email={self.email})>"
