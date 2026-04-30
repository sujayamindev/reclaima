import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.db.base import Base
from app.models.user import User  # noqa: F401
from app.models.receipt import Receipt  # noqa: F401
from app.models.receipt_line_item import ReceiptLineItem  # noqa: F401
from app.models.receipt_image import ReceiptImage  # noqa: F401
from app.models.claim_document import ClaimDocument  # noqa: F401
from app.models.claim_defect_image import ClaimDefectImage  # noqa: F401
from app.models.notification_preference import UserNotificationPreferences  # noqa: F401
from app.main import app
from app.db.session import get_db


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
