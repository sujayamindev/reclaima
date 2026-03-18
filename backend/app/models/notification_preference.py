"""
UserNotificationPreferences model.
Stores per-user push notification settings (one row per user).
"""

from sqlalchemy import Column, String, Boolean, Integer, DateTime, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

from app.db.base import Base


class UserNotificationPreferences(Base):
    """One-to-one notification settings record per user."""

    __tablename__ = "user_notification_preferences"

    # Primary key
    id = Column(String(36), primary_key=True, index=True)

    # One-to-one FK to users
    user_id = Column(
        String(36),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        unique=True,
        index=True,
    )

    # Notification toggles
    warranty_reminders_enabled = Column(Boolean, nullable=False, default=True)
    return_reminders_enabled   = Column(Boolean, nullable=False, default=True)
    ocr_notifications_enabled  = Column(Boolean, nullable=False, default=True)

    # Reminder lead times (how many days before expiry to send the push)
    warranty_lead_days = Column(Integer, nullable=False, default=30)
    return_lead_days   = Column(Integer, nullable=False, default=3)

    # Quiet hours (24-h clock, e.g. start=22, end=8 means 10 PM – 8 AM)
    quiet_hours_start = Column(Integer, nullable=True)  # 0-23
    quiet_hours_end   = Column(Integer, nullable=True)  # 0-23

    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )

    # Relationship
    user = relationship("User", back_populates="notification_preferences")

    def __repr__(self) -> str:
        return f"<UserNotificationPreferences(user_id={self.user_id})>"
