"""
Main FastAPI application entry point.
Smart Receipt & Warranty Manager Backend API.
"""

import logging
import sys
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from sqlalchemy.exc import SQLAlchemyError

from app.core.config import settings
from app.api.v1 import auth, receipts, warranties, health, products, notifications

# Configure logging
logging.basicConfig(
    level=getattr(logging, settings.LOG_LEVEL),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout)
    ]
)

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Lifespan context manager for startup and shutdown events.
    """
    # Startup
    logger.info(f"Starting {settings.PROJECT_NAME} v{settings.VERSION}")
    logger.info(f"Debug mode: {settings.DEBUG}")
    logger.info(f"Using mock AWS services: {settings.USE_MOCK_AWS}")
    logger.info(f"Database: {settings.DATABASE_URL.split('@')[-1] if '@' in settings.DATABASE_URL else 'configured'}")

    scheduler = None
    if settings.ENABLE_SCHEDULER:
        try:
            from apscheduler.schedulers.background import BackgroundScheduler
            from app.services.notification_service import notification_service

            scheduler = BackgroundScheduler(timezone="UTC")
            # Warranty reminders — daily at REMINDER_CHECK_HOUR UTC
            # TODO: Change minute back to 0 after testing. Currently set to 30 for IST+5:30 testing at 8 AM (2:30 AM UTC)
            scheduler.add_job(
                notification_service.run_warranty_reminders,
                "cron",
                hour=settings.REMINDER_CHECK_HOUR,
                minute=30,
                id="warranty_reminders",
            )
            # Return deadline reminders — daily, 5 min after warranty job
            scheduler.add_job(
                notification_service.run_return_reminders,
                "cron",
                hour=settings.REMINDER_CHECK_HOUR,
                minute=35,
                id="return_reminders",
            )
            # Hard-delete cleanup — daily at CLEANUP_HOUR UTC
            scheduler.add_job(
                notification_service.run_hard_delete_cleanup,
                "cron",
                hour=settings.CLEANUP_HOUR,
                minute=0,
                id="hard_delete_cleanup",
            )
            scheduler.start()
            logger.info(
                f"APScheduler started — reminder jobs at {settings.REMINDER_CHECK_HOUR:02d}:30 UTC (08:00 IST for testing), "
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
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
    lifespan=lifespan
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
    expose_headers=["*"]
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
            "details": exc.errors()
        }
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
            "details": str(exc) if settings.DEBUG else None
        }
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
            "details": str(exc) if settings.DEBUG else None
        }
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
        "mock_mode": settings.USE_MOCK_AWS
    }


# ============================================
# Development: Auto-reload notice
# ============================================
if settings.DEBUG:
    logger.warning("⚠️  Running in DEBUG mode - Do not use in production!")
    logger.info(f"📚 API Documentation: http://localhost:8000/docs")
    logger.info(f"🏥 Health Check: http://localhost:8000{settings.API_V1_PREFIX}/health")


if __name__ == "__main__":
    import uvicorn
    
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.DEBUG,
        log_level=settings.LOG_LEVEL.lower()
    )
