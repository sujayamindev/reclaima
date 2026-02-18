"""
Authentication routes - User registration and profile management.
"""

import logging
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.security import get_current_user, get_current_user_id
from app.db.session import get_db
from app.schemas import UserResponse, UserCreate, UserUpdate
from app.services.user_service import user_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register_user(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Register or get existing user after Firebase authentication.
    Called by mobile app after successful Firebase login.
    
    Args:
        current_user: Decoded Firebase JWT token
        db: Database session
        
    Returns:
        User information
    """
    firebase_uid = current_user.get("uid")
    email = current_user.get("email")
    display_name = current_user.get("name")
    
    if not firebase_uid or not email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid Firebase token - missing uid or email"
        )
    
    user = user_service.create_or_get_user(
        db=db,
        firebase_uid=firebase_uid,
        email=email,
        display_name=display_name
    )
    
    return user


@router.get("/me", response_model=UserResponse)
async def get_current_user_profile(
    user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    """
    Get current user's profile.
    
    Args:
        user_id: Current user ID from JWT
        db: Database session
        
    Returns:
        User profile information
    """
    user = user_service.get_user_by_id(db, user_id)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    return user


@router.patch("/me", response_model=UserResponse)
async def update_current_user_profile(
    user_data: UserUpdate,
    user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    """
    Update current user's profile.
    
    Args:
        user_data: User update data
        user_id: Current user ID from JWT
        db: Database session
        
    Returns:
        Updated user profile
    """
    user = user_service.update_user(db, user_id, user_data)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    return user


@router.delete("/me", status_code=status.HTTP_204_NO_CONTENT)
async def delete_current_user_account(
    user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    """
    Delete current user's account (GDPR right to be forgotten).
    Soft deletes user and cascades to all receipts.
    
    Args:
        user_id: Current user ID from JWT
        db: Database session
    """
    success = user_service.delete_user(db, user_id)
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    logger.info(f"User account deleted (GDPR): {user_id}")
