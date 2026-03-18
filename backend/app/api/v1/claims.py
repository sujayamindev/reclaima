"""
Claims routes - Generate and manage warranty claim PDFs.
"""

import logging
import uuid
from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session, selectinload
from sqlalchemy import and_
from datetime import datetime, timezone

from app.core.security import get_current_user
from app.services.user_service import user_service
from app.services.pdf_service import get_pdf_service
from app.services.s3_service import get_s3_service
from app.core.config import settings
from app.db.session import get_db
from app.models import ClaimDocument, Receipt
from app.schemas import (
    ClaimDocumentCreate,
    ClaimDocumentResponse,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/claims", tags=["Claims"])


def _get_receipt_with_line_items(db: Session, receipt_id: str) -> Optional[Receipt]:
    """Helper to get receipt with line items eagerly loaded."""
    return db.query(Receipt).options(
        selectinload(Receipt.line_items)
    ).filter(
        and_(
            Receipt.id == receipt_id,
            Receipt.deleted_at.is_(None)
        )
    ).first()


@router.post(
    "",
    response_model=ClaimDocumentResponse,
    status_code=status.HTTP_201_CREATED,
    response_model_by_alias=True
)
async def create_claim(
    claim_data: ClaimDocumentCreate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Generate a warranty claim PDF document.

    The PDF includes:
    - Customer information (name, email)
    - Receipt details (store, date, amount, invoice number)
    - Vendor contact information
    - List of purchased items
    - Warranty and return terms
    - Notification status
    - Claim details (issue description, claim type)

    The generated PDF is stored in S3 and a ClaimDocument record is created.

    Args:
        claim_data: Claim creation data (receipt_id, issue_description, claim_type)
        current_user: Current authenticated user
        db: Database session

    Returns:
        ClaimDocumentResponse with claim details and pre-signed download URL

    Raises:
        404: If receipt or user not found
        403: If user doesn't own the receipt
    """
    # Get internal database user ID
    firebase_uid = current_user.get("uid")
    db_user = user_service.get_user_by_firebase_uid(db, firebase_uid)
    if not db_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    # Get receipt and verify ownership (already loads line items)
    receipt = _get_receipt_with_line_items(db, claim_data.receipt_id)
    if not receipt:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Receipt not found"
        )

    if receipt.user_id != db_user.id:
        logger.warning(
            f"User {db_user.id} attempted to create claim for receipt "
            f"{receipt.id} owned by {receipt.user_id}"
        )
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have permission to access this receipt"
        )

    try:
        # Generate PDF
        pdf_service = get_pdf_service()
        pdf_bytes = pdf_service.generate_claim_pdf(
            receipt=receipt,
            user=db_user,
            issue_description=claim_data.issue_description,
            claim_type=claim_data.claim_type or "warranty"
        )
        logger.info(f"Generated claim PDF: {len(pdf_bytes)} bytes")

        # Upload PDF to S3
        claim_id = str(uuid.uuid4())
        s3_object_key = f"users/{db_user.id}/claims/{claim_id}.pdf"

        s3_service = get_s3_service(
            bucket_name=settings.AWS_S3_BUCKET,
            use_mock=settings.USE_MOCK_AWS,
            region=settings.AWS_REGION
        )
        s3_service.upload_file(
            file_content=pdf_bytes,
            object_key=s3_object_key,
            content_type="application/pdf"
        )
        logger.info(f"Uploaded claim PDF to S3: {s3_object_key}")

        # Create claim document record
        claim_document = ClaimDocument(
            id=claim_id,
            receipt_id=receipt.id,
            issue_description=claim_data.issue_description,
            claim_type=claim_data.claim_type or "warranty",
            generated_pdf_s3_key=s3_object_key,
        )
        db.add(claim_document)
        db.commit()
        db.refresh(claim_document)
        logger.info(f"Created claim document record: {claim_id}")

        # Generate pre-signed URL
        presigned_url = s3_service.generate_presigned_url(
            s3_object_key,
            expiration=3600,  # 1 hour
            operation="get_object"
        )
        logger.info(f"Generated pre-signed URL for claim {claim_id}")

        # Build response
        response = ClaimDocumentResponse.model_validate(claim_document)
        response.url = presigned_url
        return response

    except Exception as exc:
        logger.error(f"Error creating claim: {exc}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to generate claim PDF"
        )


@router.get(
    "",
    response_model=List[ClaimDocumentResponse],
    response_model_by_alias=True
)
async def list_claims(
    receipt_id: Optional[str] = Query(None, description="Filter by receipt ID"),
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    List warranty claim documents.

    Can optionally filter by receipt_id to get all claims for a specific receipt.

    Args:
        receipt_id: Optional receipt ID to filter by
        current_user: Current authenticated user
        db: Database session

    Returns:
        List of ClaimDocumentResponse objects

    Raises:
        404: If user not found
    """
    # Get internal database user ID
    firebase_uid = current_user.get("uid")
    db_user = user_service.get_user_by_firebase_uid(db, firebase_uid)
    if not db_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    try:
        # Query claims
        query = db.query(ClaimDocument).filter(
            ClaimDocument.deleted_at.is_(None)
        )

        if receipt_id:
            # Verify user owns the receipt
            receipt = _get_receipt_with_line_items(db, receipt_id)
            if not receipt or receipt.user_id != db_user.id:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="You don't have permission to access this receipt"
                )
            query = query.filter(ClaimDocument.receipt_id == receipt_id)
        else:
            # Filter by user's receipts
            user_receipt_ids = db.query(Receipt.id).filter(
                and_(
                    Receipt.user_id == db_user.id,
                    Receipt.deleted_at.is_(None)
                )
            ).all()
            receipt_ids = [r[0] for r in user_receipt_ids]
            query = query.filter(ClaimDocument.receipt_id.in_(receipt_ids))

        claims = query.order_by(ClaimDocument.created_at.desc()).all()

        # Generate pre-signed URLs for all claims
        s3_service = get_s3_service(
            bucket_name=settings.AWS_S3_BUCKET,
            use_mock=settings.USE_MOCK_AWS,
            region=settings.AWS_REGION
        )

        responses = []
        for claim in claims:
            response = ClaimDocumentResponse.model_validate(claim)
            if claim.generated_pdf_s3_key:
                response.url = s3_service.generate_presigned_url(
                    claim.generated_pdf_s3_key,
                    expiration=3600,
                    operation="get_object"
                )
            responses.append(response)

        return responses

    except HTTPException:
        raise
    except Exception as exc:
        logger.error(f"Error listing claims: {exc}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve claims"
        )


@router.get(
    "/{claim_id}",
    response_model=ClaimDocumentResponse,
    response_model_by_alias=True
)
async def get_claim(
    claim_id: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get a specific warranty claim document.

    Returns the claim details and a fresh pre-signed URL for downloading the PDF.

    Args:
        claim_id: Claim ID
        current_user: Current authenticated user
        db: Database session

    Returns:
        ClaimDocumentResponse with claim details and pre-signed download URL

    Raises:
        404: If claim or user not found
        403: If user doesn't own the receipt associated with the claim
    """
    # Get internal database user ID
    firebase_uid = current_user.get("uid")
    db_user = user_service.get_user_by_firebase_uid(db, firebase_uid)
    if not db_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    try:
        # Get claim
        claim = db.query(ClaimDocument).filter(
            and_(
                ClaimDocument.id == claim_id,
                ClaimDocument.deleted_at.is_(None)
            )
        ).first()

        if not claim:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Claim not found"
            )

        # Verify user owns the receipt
        receipt = _get_receipt_with_line_items(db, claim.receipt_id)
        if not receipt or receipt.user_id != db_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have permission to access this claim"
            )

        # Generate pre-signed URL
        s3_service = get_s3_service(
            bucket_name=settings.AWS_S3_BUCKET,
            use_mock=settings.USE_MOCK_AWS,
            region=settings.AWS_REGION
        )

        response = ClaimDocumentResponse.model_validate(claim)
        if claim.generated_pdf_s3_key:
            response.url = s3_service.generate_presigned_url(
                claim.generated_pdf_s3_key,
                expiration=3600,
                operation="get_object"
            )

        return response

    except HTTPException:
        raise
    except Exception as exc:
        logger.error(f"Error retrieving claim: {exc}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve claim"
        )


@router.delete(
    "/{claim_id}",
    status_code=status.HTTP_204_NO_CONTENT
)
async def delete_claim(
    claim_id: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Delete (soft delete) a warranty claim document.

    The claim record is soft-deleted (deleted_at is set) but the PDF remains in S3.

    Args:
        claim_id: Claim ID
        current_user: Current authenticated user
        db: Database session

    Raises:
        404: If claim or user not found
        403: If user doesn't own the receipt associated with the claim
    """
    # Get internal database user ID
    firebase_uid = current_user.get("uid")
    db_user = user_service.get_user_by_firebase_uid(db, firebase_uid)
    if not db_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    try:
        # Get claim
        claim = db.query(ClaimDocument).filter(
            and_(
                ClaimDocument.id == claim_id,
                ClaimDocument.deleted_at.is_(None)
            )
        ).first()

        if not claim:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Claim not found"
            )

        # Verify user owns the receipt
        receipt = _get_receipt_with_line_items(db, claim.receipt_id)
        if not receipt or receipt.user_id != db_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have permission to delete this claim"
            )

        # Soft delete
        claim.deleted_at = datetime.now(timezone.utc)
        db.commit()
        logger.info(f"Soft-deleted claim {claim_id}")

    except HTTPException:
        raise
    except Exception as exc:
        logger.error(f"Error deleting claim: {exc}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to delete claim"
        )
