"""
Warranty routes - Track warranty and return deadlines.

Warranty / return tracking has moved to the line-item level so that receipts
with multiple products display one entry per product rather than one per receipt.
"""

import logging
from typing import List, Optional
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


def _to_optional_str(value: object) -> Optional[str]:
    return value if isinstance(value, str) else None


def _to_optional_int(value: object) -> Optional[int]:
    return value if isinstance(value, int) else None


def _to_optional_datetime(value: object) -> Optional[datetime]:
    return value if isinstance(value, datetime) else None


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
    now = datetime.now(timezone.utc)
    for li in line_items:
        receipt = li.receipt
        warranty_expiry_date = _to_optional_datetime(li.warranty_expiry_date)
        delta = None
        days_remaining = None
        is_expired = False

        if warranty_expiry_date:
            delta = (warranty_expiry_date - now).days
            days_remaining = max(0, delta)
            is_expired = delta < 0

        warranties.append(
            WarrantyInfo(
                receipt_id=str(receipt.id),
                line_item_id=str(li.id),
                store_name=_to_optional_str(receipt.store_name),
                item_description=_to_optional_str(li.item_description),
                product_name=_to_optional_str(li.product_name),
                purchase_date=_to_optional_datetime(receipt.purchase_date),
                warranty_period_months=_to_optional_int(li.warranty_period_months),
                warranty_expiry_date=warranty_expiry_date,
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
    now = datetime.now(timezone.utc)
    for li in line_items:
        receipt = li.receipt
        return_expiry_date = _to_optional_datetime(li.return_expiry_date)
        delta = None
        days_remaining = None
        is_expired = False

        if return_expiry_date:
            delta = (return_expiry_date - now).days
            days_remaining = max(0, delta)
            is_expired = delta < 0

        returns.append(
            ReturnInfo(
                receipt_id=str(receipt.id),
                line_item_id=str(li.id),
                store_name=_to_optional_str(receipt.store_name),
                item_description=_to_optional_str(li.item_description),
                product_name=_to_optional_str(li.product_name),
                purchase_date=_to_optional_datetime(receipt.purchase_date),
                return_period_days=_to_optional_int(li.return_period_days),
                return_expiry_date=return_expiry_date,
                days_remaining=days_remaining,
                is_expired=is_expired,
            )
        )

    return returns
