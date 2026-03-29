"""
Import all models here for easy access.
"""

from app.models.user import User
from app.models.receipt import Receipt, ReceiptStatus
from app.models.receipt_line_item import ReceiptLineItem
from app.models.receipt_image import ReceiptImage
from app.models.claim_document import ClaimDocument
from app.models.claim_defect_image import ClaimDefectImage
from app.models.notification_preference import UserNotificationPreferences

__all__ = [
    "User",
    "Receipt",
    "ReceiptStatus",
    "ReceiptLineItem",
    "ReceiptImage",
    "ClaimDocument",
    "ClaimDefectImage",
    "UserNotificationPreferences",
]
