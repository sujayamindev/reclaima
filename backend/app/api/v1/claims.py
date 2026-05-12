"""
Claims routes - Generate and manage warranty claim PDFs.
"""

import logging
import uuid
from typing import Optional, List, cast
from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    status,
    Query,
    File,
    UploadFile,
    Form,
)
from sqlalchemy.orm import Session, selectinload
from sqlalchemy import and_
from datetime import datetime, timezone

from app.core.security import get_current_user
from app.services.user_service import user_service
from app.services.pdf_service import get_pdf_service
from app.services.s3_service import get_s3_service
from app.core.config import settings
from app.db.session import get_db
from app.models import ClaimDocument, Receipt, ReceiptLineItem, ClaimDefectImage
from app.schemas import (
    ClaimDocumentResponse,
    ClaimDocumentUpdate,
    ClaimResolutionRequest,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/claims", tags=["Claims"])


def _as_str(value: object) -> str:
    return cast(str, value)


def _as_optional_str(value: object) -> Optional[str]:
    return cast(Optional[str], value)


def _as_optional_datetime(value: object) -> Optional[datetime]:
    return cast(Optional[datetime], value)


def _get_receipt_with_line_items(db: Session, receipt_id: str) -> Optional[Receipt]:
    """Helper to get receipt with line items and images eagerly loaded."""
    return (
        db.query(Receipt)
        .options(selectinload(Receipt.line_items), selectinload(Receipt.images))
        .filter(and_(Receipt.id == receipt_id, Receipt.deleted_at.is_(None)))
        .first()
    )


@router.post(
    "",
    response_model=ClaimDocumentResponse,
    status_code=status.HTTP_201_CREATED,
    response_model_by_alias=True,
)
async def create_claim(
    receipt_id: str = Form(...),
    issue_description: str = Form(...),
    claim_type: str = Form("warranty"),
    line_item_id: Optional[str] = Form(None),
    defect_images: List[UploadFile] = File(default=[]),
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Generate a warranty claim PDF document with optional defect images.

    The PDF includes:
    - Customer information (name, email)
    - Receipt details (store, date, amount, invoice number)
    - Vendor contact information
    - List of purchased items
    - Warranty and return terms
    - Notification status
    - Claim details (issue description, claim type)
    - Defect images (appended as full-page attachments)

    The generated PDF is stored in S3 and a ClaimDocument record is created.

    Args:
        receipt_id: Receipt ID for the claim
        issue_description: Description of the issue/defect
        claim_type: Type of claim ("warranty" or "return")
        line_item_id: Optional specific line item (product) ID
        defect_images: List of defect image files (max 10, 5MB each, JPG/PNG)
        current_user: Current authenticated user
        db: Database session

    Returns:
        ClaimDocumentResponse with claim metadata and defect images

    Raises:
        400: If validation fails (too many images, invalid format, too large)
        404: If receipt or user not found
        403: If user doesn't own the receipt
    """
    # Validate defect images
    if len(defect_images) > 10:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Maximum 10 defect images allowed per claim",
        )

    # Validate each image
    ALLOWED_CONTENT_TYPES = {"image/jpeg", "image/jpg", "image/png"}
    _DEFECT_IMAGE_MAGIC: dict[str, list[bytes]] = {
        "image/jpeg": [b"\xff\xd8\xff"],
        "image/jpg": [b"\xff\xd8\xff"],
        "image/png": [b"\x89PNG\r\n\x1a\n"],
    }

    for idx, img in enumerate(defect_images):
        if img.content_type not in ALLOWED_CONTENT_TYPES:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Image {idx + 1}: Invalid format. Only JPG and PNG allowed.",
            )

        # Read file to check size and signature
        img_content = await img.read()
        if len(img_content) > settings.max_file_size_bytes:
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail=f"Image {idx + 1}: File too large. Maximum {settings.MAX_FILE_SIZE_MB}MB per image.",
            )

        signatures = _DEFECT_IMAGE_MAGIC.get(img.content_type, [])
        if signatures and not any(img_content.startswith(sig) for sig in signatures):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Image {idx + 1}: File content does not match its declared type. The file may be corrupt or mislabelled.",
            )

        # Reset file pointer for later reading
        await img.seek(0)

    # Get internal database user ID
    firebase_uid = current_user.get("uid")
    db_user = user_service.get_user_by_firebase_uid(db, firebase_uid)
    if not db_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )
    db_user_id = _as_str(db_user.id)

    # Get receipt and verify ownership (already loads line items)
    receipt = _get_receipt_with_line_items(db, receipt_id)
    if not receipt:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Receipt not found"
        )

    if _as_str(receipt.user_id) != db_user_id:
        logger.warning(
            f"User {db_user_id} attempted to create claim for receipt "
            f"{_as_str(receipt.id)} owned by {_as_str(receipt.user_id)}"
        )
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have permission to access this receipt",
        )

    try:
        # Initialize S3 service
        s3_service = get_s3_service(
            bucket_name=settings.AWS_S3_BUCKET,
            use_mock=settings.USE_MOCK_AWS,
            region=settings.AWS_REGION,
        )

        # Generate claim ID first (need it for PDF and S3 paths)
        claim_id = str(uuid.uuid4())

        # Upload defect images to S3 and collect their S3 keys
        defect_image_s3_keys = []
        for idx, img in enumerate(defect_images):
            img_content = await img.read()
            # Extract file extension
            file_name = img.filename or "defect.jpg"
            ext = file_name.rsplit(".", 1)[-1] if "." in file_name else "jpg"
            img_uuid = str(uuid.uuid4())
            s3_key = f"users/{db_user_id}/claims/{claim_id}/defects/defect_{idx + 1}_{img_uuid}.{ext}"

            s3_service.upload_file(
                file_content=img_content,
                object_key=s3_key,
                content_type=img.content_type,
            )
            defect_image_s3_keys.append(s3_key)
            logger.info(f"Uploaded defect image {idx + 1} to S3: {s3_key}")
            await img.seek(0)  # Reset for potential reuse

        # Generate PDF with defect images
        pdf_service = get_pdf_service()
        pdf_bytes = pdf_service.generate_claim_pdf(
            receipt=receipt,
            user=db_user,
            issue_description=issue_description,
            claim_type=claim_type,
            s3_service=s3_service,
            claim_id=claim_id,
            line_item_id=line_item_id,
            defect_image_s3_keys=defect_image_s3_keys,
        )
        logger.info(f"Generated claim PDF: {len(pdf_bytes)} bytes")
        s3_object_key = f"users/{db_user_id}/claims/{claim_id}/claim.pdf"

        s3_service.upload_file(
            file_content=pdf_bytes,
            object_key=s3_object_key,
            content_type="application/pdf",
        )
        logger.info(f"Uploaded claim PDF to S3: {s3_object_key}")

        # Create claim document record
        claim_document = ClaimDocument(
            id=claim_id,
            receipt_id=_as_str(receipt.id),
            line_item_id=line_item_id,
            issue_description=issue_description,
            claim_type=claim_type,
            status="DRAFT",
            generated_pdf_s3_key=s3_object_key,
        )
        db.add(claim_document)

        # Create defect image records
        for idx, s3_key in enumerate(defect_image_s3_keys):
            defect_img = ClaimDefectImage(
                id=str(uuid.uuid4()),
                claim_id=claim_id,
                s3_object_key=s3_key,
                display_order=idx,
            )
            db.add(defect_img)

        db.commit()
        db.refresh(claim_document)
        logger.info(
            f"Created claim document record: {claim_id} with {len(defect_image_s3_keys)} defect images"
        )

        # Build response with defect images loaded
        claim_with_images = (
            db.query(ClaimDocument)
            .options(selectinload(ClaimDocument.defect_images))
            .filter(ClaimDocument.id == claim_id)
            .first()
        )

        response = ClaimDocumentResponse.model_validate(claim_with_images)
        return response

    except HTTPException:
        raise
    except Exception as exc:
        logger.error(f"Error creating claim: {exc}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to generate claim PDF",
        )


@router.patch(
    "/{claim_id}", response_model=ClaimDocumentResponse, response_model_by_alias=True
)
async def update_claim(
    claim_id: str,
    claim_update: ClaimDocumentUpdate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Update a claim document's status or notes.
    """
    firebase_uid = current_user.get("uid")
    db_user = user_service.get_user_by_firebase_uid(db, firebase_uid)
    if not db_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )
    db_user_id = _as_str(db_user.id)

    # Get claim
    claim = (
        db.query(ClaimDocument)
        .filter(and_(ClaimDocument.id == claim_id, ClaimDocument.deleted_at.is_(None)))
        .first()
    )

    if not claim:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Claim not found"
        )

    # Verify user owns the associated receipt
    receipt = _get_receipt_with_line_items(db, _as_str(claim.receipt_id))
    if not receipt or _as_str(receipt.user_id) != db_user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have permission to modify this claim",
        )

    # Update fields
    updated = False
    if claim_update.status is not None:
        setattr(claim, "status", claim_update.status.value)
        updated = True
    if claim_update.notes is not None:
        setattr(claim, "notes", claim_update.notes)
        updated = True

    if updated:
        db.commit()
        db.refresh(claim)

    response = ClaimDocumentResponse.model_validate(claim)
    return response


@router.post(
    "/{claim_id}/resolve",
    response_model=ClaimDocumentResponse,
    response_model_by_alias=True,
)
async def resolve_claim(
    claim_id: str,
    resolution_data: ClaimResolutionRequest,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Resolve a warranty claim based on outcome (REFUNDED, REPAIRED, REPLACED).
    Handles archiving items, linking new replacement items, or duplicating items.
    """
    firebase_uid = current_user.get("uid")
    db_user = user_service.get_user_by_firebase_uid(db, firebase_uid)
    if not db_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )
    db_user_id = _as_str(db_user.id)

    # Get claim
    claim = (
        db.query(ClaimDocument)
        .filter(and_(ClaimDocument.id == claim_id, ClaimDocument.deleted_at.is_(None)))
        .first()
    )

    if not claim:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Claim not found"
        )

    # Verify user owns the associated receipt
    receipt = _get_receipt_with_line_items(db, _as_str(claim.receipt_id))
    if not receipt or _as_str(receipt.user_id) != db_user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You don't have permission to modify this claim",
        )

    # Mark claim as RESOLVED
    setattr(claim, "status", "RESOLVED")

    # Get the specific line item associated with this claim
    item = (
        db.query(ReceiptLineItem)
        .filter(ReceiptLineItem.id == claim.line_item_id)
        .first()
    )

    if item:
        if resolution_data.outcome == "REFUNDED":
            setattr(item, "status", "ARCHIVED")
        elif resolution_data.outcome == "REPLACED":
            if resolution_data.duplicate_details:
                import uuid

                new_item_id = str(uuid.uuid4())
                new_item = ReceiptLineItem(
                    id=new_item_id,
                    receipt_id=receipt.id,
                    row_index=len(receipt.line_items) if receipt.line_items else 0,
                    item_description=item.item_description,
                    product_name=item.product_name,
                    product_category=item.product_category,
                    product_image_url=item.product_image_url,
                    warranty_period_months=item.warranty_period_months,
                    return_period_days=item.return_period_days,
                    replacement_for_id=item.id,
                    status="ACTIVE",
                )
                setattr(item, "replaced_by_id", new_item_id)
                setattr(item, "status", "ARCHIVED")
                db.add(new_item)
            elif resolution_data.linked_item_id:
                # Ensure the user owns the linked replacement item
                linked_item = (
                    db.query(ReceiptLineItem)
                    .join(Receipt, Receipt.id == ReceiptLineItem.receipt_id)
                    .filter(
                        and_(
                            ReceiptLineItem.id == resolution_data.linked_item_id,
                            Receipt.user_id == db_user_id,
                            Receipt.deleted_at.is_(None),
                        )
                    )
                    .first()
                )
                if linked_item:
                    setattr(linked_item, "replacement_for_id", _as_str(item.id))
                    setattr(item, "replaced_by_id", _as_str(linked_item.id))
                    setattr(item, "status", "ARCHIVED")
                else:
                    raise HTTPException(
                        status_code=status.HTTP_403_FORBIDDEN,
                        detail="Invalid linked replacement item or permission denied",
                    )

    db.commit()
    db.refresh(claim)

    response = ClaimDocumentResponse.model_validate(claim)
    return response


@router.get(
    "", response_model=List[ClaimDocumentResponse], response_model_by_alias=True
)
async def list_claims(
    receipt_id: Optional[str] = Query(None, description="Filter by receipt ID"),
    line_item_id: Optional[str] = Query(
        None, description="Filter by line item ID (product)"
    ),
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    List warranty claim documents.

    Can optionally filter by receipt_id to get all claims for a specific receipt,
    or by line_item_id to get claims for a specific product.

    Args:
        receipt_id: Optional receipt ID to filter by
        line_item_id: Optional line item ID to filter by (takes precedence over receipt_id)
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
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )
    db_user_id = _as_str(db_user.id)

    try:
        # Query claims
        query = db.query(ClaimDocument).filter(ClaimDocument.deleted_at.is_(None))

        if line_item_id:
            # Filter by specific line item (product) and ensure user owns the receipt
            user_receipt_ids = db.query(Receipt.id).filter(
                and_(Receipt.user_id == db_user_id, Receipt.deleted_at.is_(None))
            )
            query = query.filter(
                ClaimDocument.line_item_id == line_item_id,
                ClaimDocument.receipt_id.in_(user_receipt_ids),
            )
        elif receipt_id:
            # Verify user owns the receipt
            receipt = _get_receipt_with_line_items(db, receipt_id)
            if not receipt or _as_str(receipt.user_id) != db_user_id:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="You don't have permission to access this receipt",
                )
            query = query.filter(ClaimDocument.receipt_id == receipt_id)
        else:
            # Filter by user's receipts
            user_receipt_rows = (
                db.query(Receipt.id)
                .filter(
                    and_(Receipt.user_id == db_user_id, Receipt.deleted_at.is_(None))
                )
                .all()
            )
            receipt_ids = [r[0] for r in user_receipt_rows]
            query = query.filter(ClaimDocument.receipt_id.in_(receipt_ids))

        claims = query.order_by(ClaimDocument.created_at.desc()).all()

        responses = []
        for claim in claims:
            response = ClaimDocumentResponse.model_validate(claim)
            responses.append(response)

        return responses

    except HTTPException:
        raise
    except Exception as exc:
        logger.error(f"Error listing claims: {exc}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve claims",
        )


@router.get(
    "/{claim_id}", response_model=ClaimDocumentResponse, response_model_by_alias=True
)
async def get_claim(
    claim_id: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
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
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )
    db_user_id = _as_str(db_user.id)

    try:
        # Get claim
        claim = (
            db.query(ClaimDocument)
            .filter(
                and_(ClaimDocument.id == claim_id, ClaimDocument.deleted_at.is_(None))
            )
            .first()
        )

        if not claim:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Claim not found"
            )

        # Verify user owns the receipt
        receipt = _get_receipt_with_line_items(db, _as_str(claim.receipt_id))
        if not receipt or _as_str(receipt.user_id) != db_user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have permission to access this claim",
            )

        response = ClaimDocumentResponse.model_validate(claim)
        return response

    except HTTPException:
        raise
    except Exception as exc:
        logger.error(f"Error retrieving claim: {exc}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve claim",
        )


@router.post(
    "/{claim_id}/pdf-access",
    response_model=ClaimDocumentResponse,
    response_model_by_alias=True,
)
async def access_claim_pdf(
    claim_id: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Access a claim PDF for user-initiated actions (open/download/share/copy).

    Regenerates the PDF only when the object is missing from storage.
    """
    firebase_uid = current_user.get("uid")
    db_user = user_service.get_user_by_firebase_uid(db, firebase_uid)
    if not db_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )
    db_user_id = _as_str(db_user.id)

    try:
        claim = (
            db.query(ClaimDocument)
            .filter(
                and_(ClaimDocument.id == claim_id, ClaimDocument.deleted_at.is_(None))
            )
            .first()
        )

        if not claim:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Claim not found"
            )

        receipt = _get_receipt_with_line_items(db, _as_str(claim.receipt_id))
        if not receipt or _as_str(receipt.user_id) != db_user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have permission to access this claim",
            )

        generated_pdf_s3_key = _as_optional_str(claim.generated_pdf_s3_key)
        if not generated_pdf_s3_key:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Claim PDF is not available",
            )

        s3_service = get_s3_service(
            bucket_name=settings.AWS_S3_BUCKET,
            use_mock=settings.USE_MOCK_AWS,
            region=settings.AWS_REGION,
        )

        if not s3_service.file_exists(generated_pdf_s3_key):
            logger.info(
                f"Claim PDF missing in storage for claim {_as_str(claim.id)}; regenerating"
            )
            pdf_service = get_pdf_service()
            pdf_bytes = pdf_service.generate_claim_pdf(
                receipt=receipt,
                user=db_user,
                issue_description=_as_str(claim.issue_description),
                claim_type=_as_optional_str(claim.claim_type) or "warranty",
                created_at=_as_optional_datetime(claim.created_at),
                s3_service=s3_service,
                claim_id=_as_str(claim.id),
                line_item_id=_as_optional_str(claim.line_item_id),
            )
            s3_service.upload_file(
                file_content=pdf_bytes,
                object_key=generated_pdf_s3_key,
                content_type="application/pdf",
            )

        response = ClaimDocumentResponse.model_validate(claim)
        response.url = s3_service.generate_presigned_url(
            generated_pdf_s3_key, expiration=3600, operation="get_object"
        )
        return response

    except HTTPException:
        raise
    except Exception as exc:
        logger.error(f"Error accessing claim PDF: {exc}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to access claim PDF",
        )


@router.delete("/{claim_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_claim(
    claim_id: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
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
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )
    db_user_id = _as_str(db_user.id)

    try:
        # Get claim
        claim = (
            db.query(ClaimDocument)
            .filter(
                and_(ClaimDocument.id == claim_id, ClaimDocument.deleted_at.is_(None))
            )
            .first()
        )

        if not claim:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Claim not found"
            )

        # Verify user owns the receipt
        receipt = _get_receipt_with_line_items(db, _as_str(claim.receipt_id))
        if not receipt or _as_str(receipt.user_id) != db_user_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You don't have permission to delete this claim",
            )

        # Soft delete
        setattr(claim, "deleted_at", datetime.now(timezone.utc))
        db.commit()
        logger.info(f"Soft-deleted claim {claim_id}")

    except HTTPException:
        raise
    except Exception as exc:
        logger.error(f"Error deleting claim: {exc}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to delete claim",
        )
