"""
Background Scheduler for periodic tasks.

Runs scheduled jobs like hard deletion of soft-deleted records.
"""

import logging
from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.cron import CronTrigger

from app.db.session import SessionLocal
from app.services.deletion_service import DeletionService
from app.core.config import settings

logger = logging.getLogger(__name__)

# Global scheduler instance
scheduler = None


def run_hard_delete_job():
    """
    Job function to run hard delete of soft-deleted records.
    Runs daily at 2 AM UTC.
    """
    logger.info("Running scheduled hard delete job")

    db = SessionLocal()
    try:
        # Get S3 service
        from app.services.s3_service import get_s3_service

        s3_service = get_s3_service(
            bucket_name=settings.AWS_S3_BUCKET_NAME,
            use_mock=settings.USE_MOCK_S3,
            region=settings.AWS_REGION,
        )

        # Create deletion service and run job
        deletion_service = DeletionService(s3_service)
        results = deletion_service.run_hard_delete_job(db)

        logger.info(f"Hard delete job completed: {results}")

    except Exception as e:
        logger.error(f"Hard delete job failed: {e}", exc_info=True)
    finally:
        db.close()


def start_scheduler():
    """Start the background scheduler and register jobs."""
    global scheduler

    if scheduler is not None:
        logger.warning("Scheduler already started")
        return

    scheduler = BackgroundScheduler(timezone="UTC")

    # Schedule hard delete job to run daily at 2 AM UTC
    scheduler.add_job(
        run_hard_delete_job,
        trigger=CronTrigger(hour=2, minute=0, timezone="UTC"),
        id="hard_delete_job",
        name="Hard delete soft-deleted records",
        replace_existing=True,
        misfire_grace_time=3600,  # Allow 1 hour grace if server was down
    )

    scheduler.start()
    logger.info(
        "Background scheduler started - hard delete job scheduled for 2 AM UTC daily"
    )


def stop_scheduler():
    """Stop the background scheduler gracefully."""
    global scheduler

    if scheduler is not None:
        scheduler.shutdown(wait=True)
        scheduler = None
        logger.info("Background scheduler stopped")


def get_scheduler_status():
    """
    Get current scheduler status and next run time.

    Returns:
        Dictionary with scheduler status
    """
    if scheduler is None:
        return {"running": False, "jobs": []}

    jobs = []
    for job in scheduler.get_jobs():
        jobs.append(
            {
                "id": job.id,
                "name": job.name,
                "next_run_time": (
                    job.next_run_time.isoformat() if job.next_run_time else None
                ),
            }
        )

    return {"running": scheduler.running, "jobs": jobs}
