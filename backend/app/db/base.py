"""
SQLAlchemy declarative base and common database utilities.
"""

from sqlalchemy.ext.declarative import declarative_base

# Create Base class for all models
Base = declarative_base()

# Import all models here for Alembic to detect them
# This ensures migrations can find all models
def import_models():
    """Import all models to ensure they're registered with Base."""
    from app.models import user, receipt  # noqa: F401
