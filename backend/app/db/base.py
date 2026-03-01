"""
SQLAlchemy declarative base and common database utilities.
"""

from sqlalchemy.ext.declarative import declarative_base

# Create Base class for all models
Base = declarative_base()

# All model registration for Alembic autogenerate is handled in alembic/env.py,
# which explicitly imports every model module before the migration context runs.
