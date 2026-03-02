"""
Warranty routes - Track warranty and return deadlines.

Warranty / return tracking has moved to the line-item level so that receipts
with multiple products display one entry per product rather than one per receipt.
"""

import logging
from typing import List
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import and_

from app.core.security import get_current_user_id
from app.db.session import get_db
from app.models import Receipt
from app.models.receipt_line_item import ReceiptLineItem
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
    List active warranties for current user (one entry per line item).
    """
    query = (
        db.query(ReceiptLineItem)
        .join(Receipt, Receipt.id == ReceiptLineItem.receipt_id)
        .filter(
            and_(
                Receipt.user_id == user_id,
                Receipt.deleted_at.is_(None),
                ReceiptLineItem.deleted_at.is_(None),
                ReceiptLineItem.warranty_expiry_date.isnot(None),
            )
        )
        .options(joinedload(ReceiptLineItem.receipt))
    )

    if not include_expired:
        query = query.filter(
            ReceiptLineItem.warranty_expiry_date >= datetime.now(timezone.utc)
        )

    line_items = query.order_by(ReceiptLineItem.warranty_expiry_date.asc()).all()

    warranties = []
    for li in line_items:
        receipt = li.receipt
        delta = None
        days_remaining = None
        is_expired = False

        if li.warranty_expiry_date:
            delta = (li.warranty_expiry_date - datetime.now(timezone.utc)).days
            days_remaining = max(0, delta)
            is_expired = delta < 0

        warranties.append(
            WarrantyInfo(
                receipt_id=receipt.id,
                line_item_id=li.id,
                store_name=receipt.store_name,
                item_description=li.item_description,
                product_name=li.product_name,
                purchase_date=receipt.purchase_date,
                warranty_period_months=li.warranty_period_months,
                warranty_expiry_date=li.warranty_expiry_date,
                days_remaining=days_remaining,
                is_expired=is_expired,
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
    List return deadlines for current user (one entry per line item).
    """
    query = (
        db.query(ReceiptLineItem)
        .join(Receipt, Receipt.id == ReceiptLineItem.receipt_id)
        .filter(
            and_(
                Receipt.user_id == user_id,
                Receipt.deleted_at.is_(None),
                ReceiptLineItem.deleted_at.is_(None),
                ReceiptLineItem.return_expiry_date.isnot(None),
            )
        )
        .options(joinedload(ReceiptLineItem.receipt))
    )

    if not include_expired:
        query = query.filter(
            ReceiptLineItem.return_expiry_date >= datetime.now(timezone.utc)
        )

    line_items = query.order_by(ReceiptLineItem.return_expiry_date.asc()).all()

    returns = []
    for li in line_items:
        receipt = li.receipt
        delta = None
        days_remaining = None
        is_expired = False

        if li.return_expiry_date:
            delta = (li.return_expiry_date - datetime.now(timezone.utc)).days
            days_remaining = max(0, delta)
            is_expired = delta < 0

        returns.append(
            ReturnInfo(
                receipt_id=receipt.id,
                line_item_id=li.id,
                store_name=receipt.store_name,
                item_description=li.item_description,
                product_name=li.product_name,
                purchase_date=receipt.purchase_date,
                return_period_days=li.return_period_days,
                return_expiry_date=li.return_expiry_date,
                days_remaining=days_remaining,
                is_expired=is_expired,
            )
        )

    return returns
