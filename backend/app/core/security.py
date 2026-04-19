"""
Security utilities for authentication and authorization.
Handles Firebase JWT verification and user authentication.
"""

import logging
from typing import Any, Optional
from fastapi import HTTPException, Security, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
import firebase_admin  # type: ignore[import-untyped]
from firebase_admin import auth, credentials  # type: ignore[import-untyped]
import os

from app.core.config import settings

logger = logging.getLogger(__name__)

# HTTP Bearer token scheme
security = HTTPBearer()


class FirebaseAuthService:
    """Service for Firebase authentication operations."""

    def __init__(self):
        """Initialize Firebase Admin SDK."""
        self._initialized = False
        self._initialize_firebase()

    def _initialize_firebase(self):
        """Initialize Firebase Admin SDK with service account."""
        try:
            # Check if Firebase is already initialized
            if not firebase_admin._apps:
                # Check if service account file exists
                if os.path.exists(settings.FIREBASE_SERVICE_ACCOUNT_PATH):
                    cred = credentials.Certificate(
                        settings.FIREBASE_SERVICE_ACCOUNT_PATH
                    )
                    firebase_admin.initialize_app(cred)
                    logger.info("Firebase Admin SDK initialized successfully")
                    self._initialized = True
                else:
                    logger.warning(
                        f"Firebase service account file not found at {settings.FIREBASE_SERVICE_ACCOUNT_PATH}. "
                        "Firebase authentication will not work. Create a Firebase project and download the service account JSON."
                    )
                    self._initialized = False
            else:
                self._initialized = True
                logger.info("Firebase Admin SDK already initialized")
        except Exception as e:
            logger.error(f"Failed to initialize Firebase Admin SDK: {e}")
            self._initialized = False

    def verify_token(self, token: str) -> dict:
        """
        Verify Firebase JWT token and return decoded token.

        Args:
            token: Firebase JWT token

        Returns:
            Decoded token with user information

        Raises:
            HTTPException: If token is invalid or expired
        """
        if not self._initialized:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Firebase authentication service is not available. Please configure Firebase.",
            )

        try:
            # Verify the token
            decoded_token = auth.verify_id_token(token)
            return decoded_token
        except auth.InvalidIdTokenError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid authentication token",
                headers={"WWW-Authenticate": "Bearer"},
            )
        except auth.ExpiredIdTokenError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Authentication token has expired",
                headers={"WWW-Authenticate": "Bearer"},
            )
        except Exception as e:
            logger.error(f"Token verification failed: {e}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Could not validate credentials",
                headers={"WWW-Authenticate": "Bearer"},
            )


# Global Firebase auth service instance
firebase_auth = FirebaseAuthService()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Security(security),
) -> dict[str, Any]:
    """
    FastAPI dependency to get current authenticated user.

    Args:
        credentials: HTTP Authorization credentials from request header

    Returns:
        Decoded token with user information (firebase_uid, email, etc.)

    Raises:
        HTTPException: If authentication fails
    """
    token = credentials.credentials
    decoded_token = firebase_auth.verify_token(token)
    return decoded_token


async def get_current_user_id(
    current_user: dict[str, Any] = Security(get_current_user),
) -> str:
    """
    FastAPI dependency to get current user's Firebase UID.

    Args:
        current_user: Decoded token from get_current_user dependency

    Returns:
        Firebase UID of the current user
    """
    uid = current_user.get("uid")
    if not isinstance(uid, str) or not uid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication token - missing uid",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return uid


async def get_optional_current_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Security(security),
) -> Optional[dict]:
    """
    FastAPI dependency to optionally get current authenticated user.
    Returns None if no credentials provided.

    Args:
        credentials: HTTP Authorization credentials from request header

    Returns:
        Decoded token with user information or None
    """
    if credentials is None:
        return None

    try:
        token = credentials.credentials
        decoded_token = firebase_auth.verify_token(token)
        return decoded_token
    except HTTPException:
        return None
