import os
import pytest

# Mock environment variables before any app imports
os.environ.setdefault("SECRET_KEY", "test-secret-key-for-local-dev")
os.environ.setdefault("DATABASE_URL", "sqlite:///:memory:")
os.environ.setdefault("AWS_ACCESS_KEY_ID", "mock-key")
os.environ.setdefault("AWS_SECRET_ACCESS_KEY", "mock-secret")
os.environ.setdefault("ENABLE_SCHEDULER", "false")
os.environ.setdefault("USE_MOCK_AWS", "true")

from sqlalchemy import create_engine  # noqa: E402
from sqlalchemy.orm import sessionmaker  # noqa: E402
from sqlalchemy.pool import StaticPool  # noqa: E402

from app.db.base import Base  # noqa: E402
from app.models.user import User  # noqa: F401, E402
from app.models.receipt import Receipt  # noqa: F401, E402
from app.models.receipt_line_item import ReceiptLineItem  # noqa: F401, E402
from app.models.receipt_image import ReceiptImage  # noqa: F401, E402
from app.models.claim_document import ClaimDocument  # noqa: F401, E402
from app.models.claim_defect_image import ClaimDefectImage  # noqa: F401, E402
from app.models.notification_preference import UserNotificationPreferences  # noqa: F401, E402
from app.main import app  # noqa: E402
from app.db.session import get_db  # noqa: E402


@pytest.fixture()
def db_session():
    engine = create_engine(
        "sqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    Base.metadata.create_all(bind=engine)

    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()
        Base.metadata.drop_all(bind=engine)


@pytest.fixture(autouse=True)
def override_get_db(db_session):
    """Automatically override the FastAPI get_db dependency for all tests."""
    app.dependency_overrides[get_db] = lambda: db_session
    yield
    app.dependency_overrides.pop(get_db, None)
