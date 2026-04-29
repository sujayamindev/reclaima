"""
Basic tests for the API endpoints.
Run with: pytest
"""

from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.main import app
from app.db.base import Base
from app.db.session import get_db

# Test database URL (use in-memory SQLite for tests)
SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def override_get_db():
    """Override database dependency for tests."""
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db

client = TestClient(app)


def setup_module(module):
    """Create test database tables."""
    Base.metadata.create_all(bind=engine)


def teardown_module(module):
    """Drop test database tables."""
    Base.metadata.drop_all(bind=engine)


# ============================================
# Health Check Tests
# ============================================
def test_health_check():
    """Test health check endpoint."""
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    data = response.json()
    assert "status" in data
    assert "version" in data


def test_readiness_check():
    """Test readiness check endpoint."""
    response = client.get("/api/v1/ready")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ready"


# ============================================
# Root Endpoint Test
# ============================================
def test_root_endpoint():
    """Test root endpoint."""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert "name" in data
    assert "version" in data
    assert "status" in data


# ============================================
# Receipt Tests (Basic - without auth)
# ============================================
def test_list_receipts_without_auth():
    """Test listing receipts without authentication."""
    response = client.get("/api/v1/receipts")
    # Should return 403 (Forbidden) or 401 (Unauthorized) without auth
    assert response.status_code in [401, 403]


# ============================================
# API Documentation Tests
# ============================================
def test_openapi_schema():
    """Test OpenAPI schema is hidden by default in production."""
    response = client.get("/openapi.json")
    assert response.status_code == 404


def test_docs_endpoint():
    """Test Swagger UI is hidden by default in production."""
    response = client.get("/docs")
    assert response.status_code == 404


# ============================================
# Add more tests here:
# - Test with mocked Firebase authentication
# - Test CRUD operations on receipts
# - Test OCR processing workflow
# - Test warranty calculations
# ============================================
