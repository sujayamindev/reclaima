"""
NotificationService — push notification delivery, preference CRUD, and
APScheduler job functions for warranty/return deadline reminders.
"""

import logging
import uuid
from datetime import datetime, timezone, timedelta
from typing import Optional

from sqlalchemy.orm import Session

from app.models.notification_preference import UserNotificationPreferences
from app.models.user import User
from app.models.receipt import Receipt
from app.models.receipt_line_item import ReceiptLineItem

logger = logging.getLogger(__name__)

# Default lead times used when a user has no preferences row.
_DEFAULT_WARRANTY_LEAD = 30
_DEFAULT_RETURN_LEAD = 3
# Window (days) for a single DB query to cover every possible lead-time value.
_MAX_LEAD_DAYS = 90


def _is_quiet_hour(hour: int, start: int, end: int) -> bool:
    """Return True if *hour* (UTC 0-23) falls within the [start, end) window.

    Handles overnight windows (e.g. start=22, end=8).
    """
    if start <= end:
        return start <= hour < end
    # Overnight window — wraps midnight
    return hour >= start or hour < end


class NotificationService:
    # ── Preference CRUD ───────────────────────────────────────────────────────

    def get_or_create_preferences(
        self, db: Session, user_id: str
    ) -> UserNotificationPreferences:
        """Return the preferences row for *user_id*, creating it if absent."""
        prefs = (
            db.query(UserNotificationPreferences)
            .filter(UserNotificationPreferences.user_id == user_id)
            .first()
        )
        if prefs is None:
            prefs = UserNotificationPreferences(id=str(uuid.uuid4()), user_id=user_id)
            db.add(prefs)
            db.commit()
            db.refresh(prefs)
        return prefs

    def update_preferences(
        self, db: Session, user_id: str, update_data: dict
    ) -> UserNotificationPreferences:
        """Upsert notification preferences for *user_id*."""
        prefs = self.get_or_create_preferences(db, user_id)
        for field, value in update_data.items():
            if value is not None and hasattr(prefs, field):
                setattr(prefs, field, value)
        setattr(prefs, "updated_at", datetime.now(timezone.utc))
        db.commit()
        db.refresh(prefs)
        return prefs

    def update_fcm_token(
        self, db: Session, user_id: str, token: Optional[str]
    ) -> None:
        """Store or clear the FCM device push token for *user_id*."""
        db.query(User).filter(User.id == user_id).update(
            {"fcm_token": token, "updated_at": datetime.now(timezone.utc)},
            synchronize_session=False,
        )
        db.commit()
        logger.info(f"FCM token {'registered' if token else 'cleared'} for user {user_id}")

    # ── FCM Push Delivery ─────────────────────────────────────────────────────

    def send_fcm(
        self,
        token: str,
        title: str,
        body: str,
        data: Optional[dict] = None,
    ) -> bool:
        """Send a push notification via Firebase Cloud Messaging.

        Returns True on success, False on any error (logged, not re-raised).
        FCM values in ``data`` must all be strings.
        """
        try:
            import firebase_admin.messaging as msg  # type: ignore[import-untyped]

            message = msg.Message(
                notification=msg.Notification(title=title, body=body),
                token=token,
                data={k: str(v) for k, v in (data or {}).items()},
                android=msg.AndroidConfig(priority="high"),
                apns=msg.APNSConfig(
                    headers={"apns-priority": "10"},
                    payload=msg.APNSPayload(aps=msg.Aps(sound="default")),
                ),
            )
            msg.send(message)
            logger.info(f"FCM sent — title='{title}'")
            return True
        except Exception as exc:
            logger.warning(f"FCM send failed: {exc}")
            return False

    # ── APScheduler Job: OCR notifications ───────────────────────────────────

    def send_ocr_notification(
        self, user_id: str, success: bool, receipt_id: str
    ) -> None:
        """Send an OCR-complete or OCR-failed push to the user (called inline)."""
        from app.db.session import SessionLocal

        db = SessionLocal()
        try:
            user = db.query(User).filter(
                User.id == user_id, User.deleted_at.is_(None)
            ).first()
            if not user or not user.fcm_token:
                return
            prefs = (
                db.query(UserNotificationPreferences)
                .filter(UserNotificationPreferences.user_id == user_id)
                .first()
            )
            if prefs and not prefs.ocr_notifications_enabled:
                return
            title = "Receipt processed" if success else "Receipt processing failed"
            body = (
                "Your receipt has been digitised successfully."
                if success
                else "We could not read your receipt. You can enter the details manually."
            )
            self.send_fcm(
                token=str(user.fcm_token),
                title=title,
                body=body,
                data={"type": "ocr", "receipt_id": receipt_id, "success": str(success)},
            )
        finally:
            db.close()

    # ── APScheduler Job: Warranty reminders ──────────────────────────────────

    def run_warranty_reminders(self) -> None:
        """Daily scheduler job — notify users whose warranty expires on their lead-time day."""
        from app.db.session import SessionLocal

        db = SessionLocal()
        try:
            self._send_expiry_reminders(db, kind="warranty")
        except Exception as exc:
            logger.error(f"Warranty reminder job failed: {exc}", exc_info=True)
        finally:
            db.close()

    # ── APScheduler Job: Return reminders ────────────────────────────────────

    def run_return_reminders(self) -> None:
        """Daily scheduler job — notify users whose return deadline falls on their lead-time day."""
        from app.db.session import SessionLocal

        db = SessionLocal()
        try:
            self._send_expiry_reminders(db, kind="return")
        except Exception as exc:
            logger.error(f"Return reminder job failed: {exc}", exc_info=True)
        finally:
            db.close()

    # ── APScheduler Job: Hard-delete cleanup ─────────────────────────────────

    def run_hard_delete_cleanup(self) -> None:
        """
        Daily scheduler job — permanently delete records soft-deleted 30+ days ago.
        Includes S3 file cleanup for GDPR compliance.
        """
        from app.db.session import SessionLocal
        from app.services.deletion_service import DeletionService
        from app.services.s3_service import get_s3_service
        from app.core.config import settings

        db = SessionLocal()
        try:
            # Get S3 service
            s3_service = get_s3_service(
                bucket_name=settings.AWS_S3_BUCKET,
                use_mock=settings.USE_MOCK_AWS,
                region=settings.AWS_REGION
            )
            
            # Create deletion service and run job
            deletion_service = DeletionService(s3_service)
            results = deletion_service.run_hard_delete_job(db)
            
            logger.info(
                f"Hard-delete cleanup: {results['total']} total records removed "
                f"({results['users']} users, {results['receipts']} receipts, "
                f"{results['line_items']} line items, {results['claims']} claims)"
            )
        except Exception as exc:
            db.rollback()
            logger.error(f"Hard-delete cleanup failed: {exc}", exc_info=True)
        finally:
            db.close()

    # ── Internal helpers ──────────────────────────────────────────────────────

    def _send_expiry_reminders(self, db: Session, kind: str) -> None:
        now = datetime.now(timezone.utc)
        today = now.date()
        current_hour = now.hour

        # Fetch all line items whose expiry falls within the next _MAX_LEAD_DAYS days.
        # Per-user lead-time filtering happens in Python below.
        start_window = now.replace(hour=0, minute=0, second=0, microsecond=0)
        end_window = start_window + timedelta(days=_MAX_LEAD_DAYS + 1)

        expiry_col = (
            ReceiptLineItem.warranty_expiry_date
            if kind == "warranty"
            else ReceiptLineItem.return_expiry_date
        )
        expiry_field = (
            "warranty_expiry_date" if kind == "warranty" else "return_expiry_date"
        )

        rows = (
            db.query(ReceiptLineItem, User, UserNotificationPreferences)
            .join(Receipt, Receipt.id == ReceiptLineItem.receipt_id)
            .join(User, User.id == Receipt.user_id)
            .outerjoin(
                UserNotificationPreferences,
                UserNotificationPreferences.user_id == User.id,
            )
            .filter(
                Receipt.deleted_at.is_(None),
                ReceiptLineItem.deleted_at.is_(None),
                User.deleted_at.is_(None),
                User.fcm_token.isnot(None),
                expiry_col.isnot(None),
                expiry_col >= start_window,
                expiry_col <= end_window,
            )
            .all()
        )

        sent = 0
        for item, user, prefs in rows:
            # ── Check toggle ───────────────────────────────────────────────
            if kind == "warranty":
                if prefs and not prefs.warranty_reminders_enabled:
                    continue
                # Use per-item override if set, otherwise fall back to user's global preference
                lead = (
                    item.warranty_lead_days_override
                    if item.warranty_lead_days_override is not None
                    else (
                        prefs.warranty_lead_days
                        if prefs and prefs.warranty_lead_days
                        else _DEFAULT_WARRANTY_LEAD
                    )
                )
            else:
                if prefs and not prefs.return_reminders_enabled:
                    continue
                # Use per-item override if set, otherwise fall back to user's global preference
                lead = (
                    item.return_lead_days_override
                    if item.return_lead_days_override is not None
                    else (
                        prefs.return_lead_days
                        if prefs and prefs.return_lead_days
                        else _DEFAULT_RETURN_LEAD
                    )
                )

            # ── Check target date ──────────────────────────────────────────
            raw_dt = getattr(item, expiry_field)
            if raw_dt is None:
                continue
            expiry_date = raw_dt.date() if hasattr(raw_dt, "date") else raw_dt
            target_date = today + timedelta(days=lead)
            if expiry_date != target_date:
                continue

            # ── Respect quiet hours (UTC) ──────────────────────────────────
            if (
                prefs
                and prefs.quiet_hours_start is not None
                and prefs.quiet_hours_end is not None
                and _is_quiet_hour(
                    current_hour, prefs.quiet_hours_start, prefs.quiet_hours_end
                )
            ):
                logger.debug(
                    f"Skipping notification for user {user.id} — quiet hours active"
                )
                continue

            # ── Build and send ─────────────────────────────────────────────
            product_label = item.product_name or item.item_description or "Item"
            if kind == "warranty":
                title = "Warranty Expiring Soon"
                body = f'"{product_label}" warranty expires in {lead} day{"s" if lead != 1 else ""}'
            else:
                title = "Return Deadline Approaching"
                body = f'Only {lead} day{"s" if lead != 1 else ""} left to return "{product_label}"'

            self.send_fcm(
                token=str(user.fcm_token),
                title=title,
                body=body,
                data={
                    "type": kind,
                    "receipt_id": str(item.receipt_id),
                    "line_item_id": str(item.id),
                },
            )
            sent += 1

        logger.info(
            f"{kind.capitalize()} reminders sent: {sent} / {len(rows)} candidates"
        )


notification_service = NotificationService()
