"""
Health check and system status routes.
"""

from datetime import datetime, timezone
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text

from app.core.config import settings
from app.db.session import get_db
from app.schemas import HealthCheckResponse
from app.core.security import firebase_auth

router = APIRouter(tags=["Health"])


@router.get("/health", response_model=HealthCheckResponse)
async def health_check(db: Session = Depends(get_db)):
    """
    Health check endpoint for monitoring.

    Returns:
        System health status
    """
    # Check database connection
    db_status = "healthy"
    try:
        db.execute(text("SELECT 1"))
    except Exception:
        db_status = "unhealthy"

    # Check Firebase initialization
    firebase_status = "initialized" if firebase_auth._initialized else "not configured"

    return HealthCheckResponse(
        status="healthy" if db_status == "healthy" else "degraded",
        version=settings.VERSION,
        timestamp=datetime.now(timezone.utc),
        database=db_status,
        firebase=firebase_status,
        aws_mock=settings.USE_MOCK_AWS,
    )


@router.get("/ready")
async def readiness_check(db: Session = Depends(get_db)):
    """
    Readiness check for Kubernetes/container orchestration.

    Returns:
        Simple OK response if service is ready
    """
    try:
        db.execute(text("SELECT 1"))
        return {"status": "ready"}
    except Exception as e:
        return {"status": "not ready", "error": str(e)}
