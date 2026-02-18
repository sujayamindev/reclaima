"""
User service - Business logic for user operations.
"""

import logging
import uuid
from typing import Optional
from sqlalchemy.orm import Session

from app.models import User
from app.schemas import UserCreate, UserUpdate

logger = logging.getLogger(__name__)


class UserService:
    """Service for user operations."""
    
    def create_or_get_user(
        self,
        db: Session,
        firebase_uid: str,
        email: str,
        display_name: Optional[str] = None
    ) -> User:
        """
        Create user if not exists, or return existing user.
        Called after Firebase authentication.
        
        Args:
            db: Database session
            firebase_uid: Firebase UID from JWT
            email: User email
            display_name: Optional display name
            
        Returns:
            User instance
        """
        # Check if user exists
        user = db.query(User).filter(User.firebase_uid == firebase_uid).first()
        
        if user:
            logger.info(f"Existing user found: {user.id}")
            return user
        
        # Create new user
        user_id = str(uuid.uuid4())
        user = User(
            id=user_id,
            firebase_uid=firebase_uid,
            email=email,
            display_name=display_name
        )
        
        db.add(user)
        db.commit()
        db.refresh(user)
        
        logger.info(f"Created new user: {user_id} ({email})")
        
        return user
    
    def get_user_by_firebase_uid(
        self,
        db: Session,
        firebase_uid: str
    ) -> Optional[User]:
        """
        Get user by Firebase UID.
        
        Args:
            db: Database session
            firebase_uid: Firebase UID
            
        Returns:
            User or None if not found
        """
        return db.query(User).filter(
            User.firebase_uid == firebase_uid
        ).first()
    
    def get_user_by_id(
        self,
        db: Session,
        user_id: str
    ) -> Optional[User]:
        """
        Get user by ID.
        
        Args:
            db: Database session
            user_id: User ID
            
        Returns:
            User or None if not found
        """
        return db.query(User).filter(User.id == user_id).first()
    
    def update_user(
        self,
        db: Session,
        user_id: str,
        user_data: UserUpdate
    ) -> Optional[User]:
        """
        Update user information.
        
        Args:
            db: Database session
            user_id: User ID
            user_data: Update data
            
        Returns:
            Updated user or None if not found
        """
        user = self.get_user_by_id(db, user_id)
        
        if not user:
            return None
        
        update_data = user_data.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(user, field, value)
        
        db.commit()
        db.refresh(user)
        
        logger.info(f"Updated user: {user_id}")
        
        return user
    
    def delete_user(
        self,
        db: Session,
        user_id: str
    ) -> bool:
        """
        Soft delete user and cascade to receipts.
        
        Args:
            db: Database session
            user_id: User ID
            
        Returns:
            True if deleted, False if not found
        """
        from datetime import datetime
        
        user = self.get_user_by_id(db, user_id)
        
        if not user:
            return False
        
        user.deleted_at = datetime.utcnow()
        
        # Soft delete all user's receipts
        from app.models import Receipt
        db.query(Receipt).filter(Receipt.user_id == user_id).update({
            Receipt.deleted_at: datetime.utcnow()
        })
        
        db.commit()
        
        logger.info(f"Soft deleted user and cascaded receipts: {user_id}")
        
        return True


# Global service instance
user_service = UserService()
