"""
Hard Delete Service for GDPR Compliance.

Implements permanent deletion of soft-deleted records after retention period (30 days).
Includes S3 file cleanup to ensure complete data removal.
"""

import logging
from datetime import datetime, timezone, timedelta
from typing import Dict
from sqlalchemy.orm import Session
from sqlalchemy import and_

from app.models.user import User
from app.models.receipt import Receipt
from app.models.receipt_line_item import ReceiptLineItem
from app.models.claim_document import ClaimDocument

logger = logging.getLogger(__name__)


class DeletionService:
    """Service for hard deleting soft-deleted records after retention period."""

    def __init__(self, s3_service):
        """
        Initialize deletion service.

        Args:
            s3_service: S3 service instance for file cleanup
        """
        self.s3_service = s3_service
        self.retention_days = 30

    def get_retention_cutoff(self) -> datetime:
        """
        Get the cutoff datetime for hard deletion.

        Returns:
            Datetime 30 days ago from now
        """
        return datetime.now(timezone.utc) - timedelta(days=self.retention_days)

    def hard_delete_claims(self, db: Session) -> int:
        """
        Hard delete claim documents that were soft-deleted > 30 days ago.
        Also deletes associated PDF files from S3.

        Args:
            db: Database session

        Returns:
            Number of claims permanently deleted
        """
        cutoff = self.get_retention_cutoff()

        # Find claims to delete
        claims_to_delete = (
            db.query(ClaimDocument)
            .filter(
                and_(
                    ClaimDocument.deleted_at.isnot(None),
                    ClaimDocument.deleted_at < cutoff,
                )
            )
            .all()
        )

        if not claims_to_delete:
            logger.info("No claims to hard delete")
            return 0

        deleted_count = 0
        s3_keys_to_delete = []

        for claim in claims_to_delete:
            # Collect S3 keys for PDF files
            if claim.generated_pdf_s3_key:
                s3_keys_to_delete.append(claim.generated_pdf_s3_key)

        try:
            # Delete S3 files first
            if s3_keys_to_delete:
                s3_results = self.s3_service.delete_files_bulk(s3_keys_to_delete)
                successful_s3_deletes = sum(1 for v in s3_results.values() if v)
                logger.info(
                    f"Deleted {successful_s3_deletes}/{len(s3_keys_to_delete)} claim PDF files from S3"
                )

            # Delete from database
            for claim in claims_to_delete:
                db.delete(claim)
                deleted_count += 1

            db.commit()
            logger.info(f"Hard deleted {deleted_count} claim documents")

        except Exception as e:
            db.rollback()
            logger.error(f"Failed to hard delete claims: {e}")
            raise

        return deleted_count

    def hard_delete_line_items(self, db: Session) -> int:
        """
        Hard delete line items that were soft-deleted > 30 days ago.

        Args:
            db: Database session

        Returns:
            Number of line items permanently deleted
        """
        cutoff = self.get_retention_cutoff()

        # Find line items to delete
        items_to_delete = (
            db.query(ReceiptLineItem)
            .filter(
                and_(
                    ReceiptLineItem.deleted_at.isnot(None),
                    ReceiptLineItem.deleted_at < cutoff,
                )
            )
            .all()
        )

        if not items_to_delete:
            logger.info("No line items to hard delete")
            return 0

        deleted_count = 0

        try:
            for item in items_to_delete:
                db.delete(item)
                deleted_count += 1

            db.commit()
            logger.info(f"Hard deleted {deleted_count} line items")

        except Exception as e:
            db.rollback()
            logger.error(f"Failed to hard delete line items: {e}")
            raise

        return deleted_count

    def hard_delete_receipts(self, db: Session) -> int:
        """
        Hard delete receipts that were soft-deleted > 30 days ago.
        Also deletes associated image files from S3.

        Args:
            db: Database session

        Returns:
            Number of receipts permanently deleted
        """
        cutoff = self.get_retention_cutoff()

        # Find receipts to delete
        receipts_to_delete = (
            db.query(Receipt)
            .filter(and_(Receipt.deleted_at.isnot(None), Receipt.deleted_at < cutoff))
            .all()
        )

        if not receipts_to_delete:
            logger.info("No receipts to hard delete")
            return 0

        deleted_count = 0
        s3_keys_to_delete = []

        for receipt in receipts_to_delete:
            # Collect S3 keys for receipt images
            if receipt.s3_object_key:
                s3_keys_to_delete.append(receipt.s3_object_key)

        try:
            # Delete S3 files first
            if s3_keys_to_delete:
                s3_results = self.s3_service.delete_files_bulk(s3_keys_to_delete)
                successful_s3_deletes = sum(1 for v in s3_results.values() if v)
                logger.info(
                    f"Deleted {successful_s3_deletes}/{len(s3_keys_to_delete)} receipt images from S3"
                )

            # Delete from database
            for receipt in receipts_to_delete:
                db.delete(receipt)
                deleted_count += 1

            db.commit()
            logger.info(f"Hard deleted {deleted_count} receipts")

        except Exception as e:
            db.rollback()
            logger.error(f"Failed to hard delete receipts: {e}")
            raise

        return deleted_count

    def hard_delete_users(self, db: Session) -> int:
        """
        Hard delete users that were soft-deleted > 30 days ago.
        Note: User's receipts, line items, and claims should already be deleted by cascade.

        Args:
            db: Database session

        Returns:
            Number of users permanently deleted
        """
        cutoff = self.get_retention_cutoff()

        # Find users to delete
        users_to_delete = (
            db.query(User)
            .filter(and_(User.deleted_at.isnot(None), User.deleted_at < cutoff))
            .all()
        )

        if not users_to_delete:
            logger.info("No users to hard delete")
            return 0

        deleted_count = 0

        try:
            for user in users_to_delete:
                db.delete(user)
                deleted_count += 1

            db.commit()
            logger.info(f"Hard deleted {deleted_count} users")

        except Exception as e:
            db.rollback()
            logger.error(f"Failed to hard delete users: {e}")
            raise

        return deleted_count

    def run_hard_delete_job(self, db: Session) -> Dict[str, int]:
        """
        Run complete hard delete job for all entity types.
        Deletes in order: claims → line_items → receipts → users (children first).

        Args:
            db: Database session

        Returns:
            Dictionary with counts of deleted records per entity type
        """
        logger.info("Starting hard delete job")
        start_time = datetime.now(timezone.utc)

        results = {"claims": 0, "line_items": 0, "receipts": 0, "users": 0, "total": 0}

        try:
            # Delete in order: children first to avoid FK constraints
            results["claims"] = self.hard_delete_claims(db)
            results["line_items"] = self.hard_delete_line_items(db)
            results["receipts"] = self.hard_delete_receipts(db)
            results["users"] = self.hard_delete_users(db)

            results["total"] = sum(
                [
                    results["claims"],
                    results["line_items"],
                    results["receipts"],
                    results["users"],
                ]
            )

            duration = (datetime.now(timezone.utc) - start_time).total_seconds()

            logger.info(
                f"Hard delete job completed in {duration:.2f}s. "
                f"Deleted: {results['total']} records "
                f"({results['users']} users, {results['receipts']} receipts, "
                f"{results['line_items']} line items, {results['claims']} claims)"
            )

        except Exception as e:
            logger.error(f"Hard delete job failed: {e}")
            raise

        return results
