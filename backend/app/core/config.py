"""
Core configuration module for Smart Receipt & Warranty Manager backend.
Loads environment variables and provides application settings.
"""

from functools import lru_cache
from typing import List
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""
    
    # Application
    PROJECT_NAME: str = "Smart Receipt & Warranty Manager"
    VERSION: str = "0.1.0"
    API_V1_PREFIX: str = "/api/v1"
    DEBUG: bool = True
    
    # Security
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # CORS
    ALLOWED_ORIGINS: str = "http://localhost:8000"
    
    @property
    def allowed_origins_list(self) -> List[str]:
        """Parse comma-separated origins into list."""
        return [origin.strip() for origin in self.ALLOWED_ORIGINS.split(",")]
    
    # Database
    DATABASE_URL: str
    
    # Firebase
    FIREBASE_SERVICE_ACCOUNT_PATH: str = "./firebase-service-account.json"
    
    # AWS Configuration
    AWS_ACCESS_KEY_ID: str
    AWS_SECRET_ACCESS_KEY: str
    AWS_REGION: str = "us-east-1"
    AWS_S3_BUCKET: str = "smart-receipt-storage"
    USE_MOCK_AWS: bool = False
    
    # File Upload
    MAX_FILE_SIZE_MB: int = 5
    ALLOWED_FILE_TYPES: str = "image/jpeg,image/png,application/pdf"
    
    @property
    def allowed_file_types_list(self) -> List[str]:
        """Parse comma-separated file types into list."""
        return [ft.strip() for ft in self.ALLOWED_FILE_TYPES.split(",")]
    
    @property
    def max_file_size_bytes(self) -> int:
        """Convert MB to bytes."""
        return self.MAX_FILE_SIZE_MB * 1024 * 1024
    
    # Rate Limiting
    RATE_LIMIT_AUTH: str = "5/minute"
    RATE_LIMIT_UPLOAD: str = "10/hour"
    RATE_LIMIT_API: str = "100/minute"
    
    # OCR Settings
    OCR_MAX_RETRIES: int = 3
    OCR_RETRY_DELAY_SECONDS: int = 5

    # LLM / AWS Bedrock — AI text cleanup for garbled multi-column OCR notes
    BEDROCK_MODEL_ID: str = "us.anthropic.claude-haiku-4-5-20251001-v1:0"
    LLM_CLEANUP_ENABLED: bool = True

    # Brave Search API — product image lookup
    BRAVE_SEARCH_API_KEY: str = ""

    # Scheduler
    ENABLE_SCHEDULER: bool = True
    REMINDER_CHECK_HOUR: int = 9
    CLEANUP_HOUR: int = 2
    
    # Reminders
    WARRANTY_REMINDER_DAYS: int = 30
    RETURN_REMINDER_DAYS: int = 3
    
    # Logging
    LOG_LEVEL: str = "INFO"
    
    model_config = SettingsConfigDict(
        env_file=".env",
        case_sensitive=True,
        extra="ignore"
    )


@lru_cache()
def get_settings() -> Settings:
    """
    Get cached settings instance.
    Using lru_cache ensures we only create one instance.
    """
    return Settings()


# Global settings instance
settings = get_settings()
