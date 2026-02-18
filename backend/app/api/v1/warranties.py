"""
Warranty routes - Track warranty and return deadlines.
"""

import logging
from typing import List
from datetime import datetime
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import and_

from app.core.security import get_current_user_id
from app.db.session import get_db
from app.models import Receipt
from app.schemas import WarrantyInfo, ReturnInfo

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/warranties", tags=["Warranties"])


@router.get("", response_model=List[WarrantyInfo])
async def list_active_warranties(
    include_expired: bool = Query(False, description="Include expired warranties"),
    user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    """
    List active warranties for current user.
    
    Args:
        include_expired: Whether to include expired warranties
        user_id: Current user ID
        db: Database session
        
    Returns:
        List of warranty information
    """
    query = db.query(Receipt).filter(
        and_(
            Receipt.user_id == user_id,
            Receipt.deleted_at.is_(None),
            Receipt.warranty_expiry_date.isnot(None)
        )
    )
    
    if not include_expired:
        query = query.filter(Receipt.warranty_expiry_date >= datetime.utcnow())
    
    receipts = query.order_by(Receipt.warranty_expiry_date.asc()).all()
    
    warranties = []
    for receipt in receipts:
        days_remaining = None
        is_expired = False
        
        if receipt.warranty_expiry_date:
            delta = (receipt.warranty_expiry_date - datetime.utcnow()).days
            days_remaining = max(0, delta)
            is_expired = delta < 0
        
        warranties.append(
            WarrantyInfo(
                receipt_id=receipt.id,
                store_name=receipt.store_name,
                product_name=receipt.product_name,
                purchase_date=receipt.purchase_date,
                warranty_expiry_date=receipt.warranty_expiry_date,
                days_remaining=days_remaining,
                is_expired=is_expired
            )
        )
    
    return warranties


@router.get("/returns", response_model=List[ReturnInfo])
async def list_return_deadlines(
    include_expired: bool = Query(False, description="Include expired return windows"),
    user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db)
):
    """
    List return deadlines for current user.
    
    Args:
        include_expired: Whether to include expired return windows
        user_id: Current user ID
        db: Database session
        
    Returns:
        List of return deadline information
    """
    query = db.query(Receipt).filter(
        and_(
            Receipt.user_id == user_id,
            Receipt.deleted_at.is_(None),
            Receipt.return_expiry_date.isnot(None)
        )
    )
    
    if not include_expired:
        query = query.filter(Receipt.return_expiry_date >= datetime.utcnow())
    
    receipts = query.order_by(Receipt.return_expiry_date.asc()).all()
    
    returns = []
    for receipt in receipts:
        days_remaining = None
        is_expired = False
        
        if receipt.return_expiry_date:
            delta = (receipt.return_expiry_date - datetime.utcnow()).days
            days_remaining = max(0, delta)
            is_expired = delta < 0
        
        returns.append(
            ReturnInfo(
                receipt_id=receipt.id,
                store_name=receipt.store_name,
                product_name=receipt.product_name,
                purchase_date=receipt.purchase_date,
                return_expiry_date=receipt.return_expiry_date,
                days_remaining=days_remaining,
                is_expired=is_expired
            )
        )
    
    return returns
