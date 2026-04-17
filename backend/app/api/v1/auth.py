"""
Authentication routes - User registration and profile management.
"""

import logging
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status, Body
from sqlalchemy.orm import Session

from app.core.security import get_current_user
from app.db.session import get_db
from app.schemas import UserResponse, UserUpdate
from app.services.user_service import user_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post(
    "/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED
)
async def register_user(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
    full_name: Optional[str] = Body(None, embed=True),
):
    """
    Register or get existing user after Firebase authentication.
    Called by mobile app after successful Firebase login.

    Args:
        current_user: Decoded Firebase JWT token
        db: Database session
        full_name: Full name from signup form (optional)

    Returns:
        User information
    """
    firebase_uid = current_user.get("uid")
    email = current_user.get("email")

    # Use the provided full name if available
    display_name = None
    if full_name:
        display_name = full_name.strip() if full_name.strip() else None

    if not firebase_uid or not email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid Firebase token - missing uid or email",
        )

    user = user_service.create_or_get_user(
        db=db, firebase_uid=firebase_uid, email=email, display_name=display_name
    )

    return user


@router.get("/me", response_model=UserResponse)
async def get_current_user_profile(
    current_user: dict = Depends(get_current_user), db: Session = Depends(get_db)
):
    """
    Get current user's profile.
    """
    firebase_uid = current_user.get("uid")
    user = user_service.get_user_by_firebase_uid(db, firebase_uid)

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )

    return user


@router.patch("/me", response_model=UserResponse)
async def update_current_user_profile(
    user_data: UserUpdate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Update current user's profile.
    """
    firebase_uid = current_user.get("uid")
    db_user = user_service.get_user_by_firebase_uid(db, firebase_uid)

    if not db_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )

    user = user_service.update_user(db, str(db_user.id), user_data)
    return user


@router.delete("/me", status_code=status.HTTP_204_NO_CONTENT)
async def delete_current_user_account(
    current_user: dict = Depends(get_current_user), db: Session = Depends(get_db)
):
    """
    Delete current user's account (GDPR right to be forgotten).
    """
    firebase_uid = current_user.get("uid")
    db_user = user_service.get_user_by_firebase_uid(db, firebase_uid)

    if not db_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )

    success = user_service.delete_user(db, str(db_user.id))

    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )

    logger.info(f"User account deleted (GDPR): {firebase_uid}")
