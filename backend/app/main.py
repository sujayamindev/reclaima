"""
Main FastAPI application entry point.
Smart Receipt & Warranty Manager Backend API.
"""

import logging
import os
import sys
import sentry_sdk
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from sqlalchemy.exc import SQLAlchemyError

from app.core.config import settings
from app.api.v1 import (
    auth,
    receipts,
    warranties,
    health,
    products,
    notifications,
    claims,
)

# Configure logging
logging.basicConfig(
    level=getattr(logging, settings.LOG_LEVEL),
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)],
)

logger = logging.getLogger(__name__)


# Initialize Sentry
if not settings.DEBUG and settings.SENTRY_DSN:
    logger.info("Initializing Sentry SDK")
    sentry_sdk.init(
        dsn=settings.SENTRY_DSN,
        # Set traces_sample_rate to 1.0 to capture 100%
        # of transactions for performance monitoring.
        traces_sample_rate=1.0,
        # Set profiles_sample_rate to 1.0 to profile 100%
        # of sampled transactions.
        profiles_sample_rate=1.0,
        environment=settings.ENVIRONMENT,
    )


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Lifespan context manager for startup and shutdown events.
    """
    # Startup
    logger.info(f"Starting {settings.PROJECT_NAME} v{settings.VERSION}")
    logger.info(f"Debug mode: {settings.DEBUG}")
    logger.info(f"Using mock AWS services: {settings.USE_MOCK_AWS}")
    logger.info(
        f"Database: {settings.DATABASE_URL.split('@')[-1] if '@' in settings.DATABASE_URL else 'configured'}"
    )

    scheduler = None
    if settings.ENABLE_SCHEDULER:
        try:
            from apscheduler.schedulers.background import BackgroundScheduler  # type: ignore[import-untyped]
            from app.services.notification_service import notification_service
            from app.services.deletion_service import run_hard_delete_cleanup

            scheduler = BackgroundScheduler(timezone="UTC")
            # Warranty reminders — daily at 3:00 AM UTC
            scheduler.add_job(
                notification_service.run_warranty_reminders,
                "cron",
                hour=settings.REMINDER_CHECK_HOUR,
                minute=0,
                id="warranty_reminders",
            )
            # Return deadline reminders — daily at 3:05 AM UTC (5 min after warranty job)
            scheduler.add_job(
                notification_service.run_return_reminders,
                "cron",
                hour=settings.REMINDER_CHECK_HOUR,
                minute=5,
                id="return_reminders",
            )
            # Hard-delete cleanup — daily at CLEANUP_HOUR UTC
            scheduler.add_job(
                run_hard_delete_cleanup,
                "cron",
                hour=settings.CLEANUP_HOUR,
                minute=0,
                id="hard_delete_cleanup",
            )
            scheduler.start()
            logger.info(
                f"APScheduler started — reminder jobs at {settings.REMINDER_CHECK_HOUR:02d}:00 UTC (3:00 AM UTC), "
                f"cleanup at {settings.CLEANUP_HOUR:02d}:00 UTC"
            )
        except Exception as exc:
            logger.error(f"Failed to start APScheduler: {exc}", exc_info=True)

    yield

    # Shutdown
    if scheduler and scheduler.running:
        scheduler.shutdown(wait=False)
        logger.info("APScheduler stopped")
    logger.info("Shutting down application")


# Create FastAPI application
app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="Smart Receipt & Warranty Manager - Production-ready API for receipt digitization and warranty tracking",
    docs_url="/docs" if settings.DEBUG else None,
    redoc_url="/redoc" if settings.DEBUG else None,
    openapi_url="/openapi.json" if settings.DEBUG else None,
    lifespan=lifespan,
)


# ============================================
# CORS Middleware
# ============================================
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)


# ============================================
# Global Exception Handlers
# ============================================
@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """Handle request validation errors."""
    logger.warning(f"Validation error on {request.url}: {exc.errors()}")
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "error": "VALIDATION_ERROR",
            "message": "Invalid request data",
            "details": exc.errors(),
        },
    )


@app.exception_handler(SQLAlchemyError)
async def database_exception_handler(request: Request, exc: SQLAlchemyError):
    """Handle database errors."""
    logger.error(f"Database error on {request.url}: {exc}")
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "error": "DATABASE_ERROR",
            "message": "A database error occurred",
            "details": str(exc) if settings.DEBUG else None,
        },
    )


@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    """Handle all other exceptions."""
    logger.error(f"Unhandled exception on {request.url}: {exc}", exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "error": "INTERNAL_ERROR",
            "message": "An internal server error occurred",
            "details": str(exc) if settings.DEBUG else None,
        },
    )


# ============================================
# Request Logging Middleware
# ============================================
@app.middleware("http")
async def log_requests(request: Request, call_next):
    """Log all incoming requests."""
    logger.info(f"{request.method} {request.url.path}")
    response = await call_next(request)
    logger.info(f"{request.method} {request.url.path} - Status: {response.status_code}")
    return response


# ============================================
# API Routes
# ============================================
# Include API v1 routes
app.include_router(health.router, prefix=settings.API_V1_PREFIX)
app.include_router(auth.router, prefix=settings.API_V1_PREFIX)
app.include_router(receipts.router, prefix=settings.API_V1_PREFIX)
app.include_router(warranties.router, prefix=settings.API_V1_PREFIX)
app.include_router(products.router, prefix=settings.API_V1_PREFIX)
app.include_router(notifications.router, prefix=settings.API_V1_PREFIX)
app.include_router(claims.router, prefix=settings.API_V1_PREFIX)


# ============================================
# Root Endpoint
# ============================================
@app.get("/")
async def root():
    """
    Root endpoint - API information.
    """
    return {
        "name": settings.PROJECT_NAME,
        "version": settings.VERSION,
        "status": "running",
        "docs": "/docs",
        "health": f"{settings.API_V1_PREFIX}/health",
        "mock_mode": settings.USE_MOCK_AWS,
    }


# ============================================
# Sentry Debug Endpoint
# ============================================
@app.get("/sentry-debug")
async def trigger_error():
    """
    Deliberately trigger an error to test Sentry integration.
    Only enabled when Sentry is configured.
    """
    if not settings.SENTRY_DSN:
        return {"status": "ignored", "message": "Sentry not configured"}

    # This will raise a ZeroDivisionError
    1 / 0
    return {"status": "failed", "message": "This should never be reached"}


# ============================================
# Development: Auto-reload notice
# ============================================
if settings.DEBUG:
    logger.warning("⚠️  Running in DEBUG mode - Do not use in production!")
    logger.info("📚 API Documentation: http://localhost:8000/docs")
    logger.info(
        f"🏥 Health Check: http://localhost:8000{settings.API_V1_PREFIX}/health"
    )


if __name__ == "__main__":
    import uvicorn

    # Use localhost by default for local runs; deployments can override via env.
    host = os.getenv("UVICORN_HOST", "127.0.0.1")

    uvicorn.run(
        "app.main:app",
        host=host,
        port=8000,
        reload=settings.DEBUG,
        log_level=settings.LOG_LEVEL.lower(),
    )
