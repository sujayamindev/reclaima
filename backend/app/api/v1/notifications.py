"""
Notification routes — user notification preferences and FCM token management.
"""

import logging
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.security import get_current_user
from app.db.session import get_db
from app.schemas import (
    UserNotificationPreferencesResponse,
    UserNotificationPreferencesUpdate,
    UserFcmTokenUpdate,
)
from app.services.notification_service import notification_service
from app.services.user_service import user_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/notifications", tags=["Notifications"])


@router.get(
    "/preferences",
    response_model=UserNotificationPreferencesResponse,
    summary="Get notification preferences",
)
async def get_notification_preferences(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Return the current user's notification preferences.
    A default row is created transparently on first access.
    """
    firebase_uid = current_user.get("uid")
    db_user = user_service.get_user_by_firebase_uid(db, firebase_uid)
    if not db_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )

    return notification_service.get_or_create_preferences(db, str(db_user.id))


@router.patch(
    "/preferences",
    response_model=UserNotificationPreferencesResponse,
    summary="Save notification preferences",
)
async def save_notification_preferences(
    prefs_update: UserNotificationPreferencesUpdate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Upsert (create-or-update) the current user's notification preferences.
    Only the fields included in the request body are changed.
    """
    firebase_uid = current_user.get("uid")
    db_user = user_service.get_user_by_firebase_uid(db, firebase_uid)
    if not db_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )

    update_data = prefs_update.model_dump(exclude_unset=True)
    prefs = notification_service.update_preferences(db, str(db_user.id), update_data)
    logger.info(f"Notification preferences updated for user {db_user.id}")
    return prefs


@router.patch(
    "/fcm-token",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Register or clear FCM push token",
)
async def update_fcm_token(
    body: UserFcmTokenUpdate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Store or clear the FCM device token for push notification delivery.
    Send ``token: null`` to deregister (e.g. on sign-out).
    """
    firebase_uid = current_user.get("uid")
    db_user = user_service.get_user_by_firebase_uid(db, firebase_uid)
    if not db_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )

    notification_service.update_fcm_token(db, str(db_user.id), body.token)
