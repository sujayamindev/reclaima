"""
Receipt routes - Upload, manage, and process receipts.
"""

import logging
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Query
from sqlalchemy.orm import Session

from app.core.security import get_current_user
from app.services.user_service import user_service
from app.core.config import settings
from app.db.session import get_db
from app.schemas import (
    ReceiptResponse,
    ReceiptCreate,
    ReceiptUpdate,
    ReceiptListResponse,
    ReceiptStatusEnum,
    ReceiptImageUrlResponse,
    ReceiptLineItemResponse,
    ReceiptLineItemUpdate,
    OcrExtractResponse,
)
from app.services.receipt_service import receipt_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/receipts", tags=["Receipts"])


@router.post("", response_model=ReceiptResponse, status_code=status.HTTP_201_CREATED, response_model_by_alias=True)
async def create_receipt(
    receipt_data: ReceiptCreate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Create a new receipt record.
    
    Args:
        receipt_data: Receipt creation data
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        Created receipt
    """
    # Get internal database user ID
    firebase_uid = current_user.get("uid")
    db_user = user_service.get_user_by_firebase_uid(db, firebase_uid)
    if not db_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    receipt = receipt_service.create_receipt(db, db_user.id, receipt_data)
    return receipt


@router.post(
    "/ocr-extract",
    response_model=OcrExtractResponse,
    status_code=status.HTTP_200_OK,
    response_model_by_alias=True,
)
async def ocr_extract(
    front_image: Optional[UploadFile] = File(None),
    back_image: Optional[UploadFile] = File(None),
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Upload receipt image(s) to S3, run OCR, and return extracted data.
    
    Accepts optional front and back images for double-sided receipts.
    Both images are uploaded to S3 and processed. OCR data from both images
    is merged, with preference given to front image data.

    **Does NOT create a receipt record in the database.**
    The image(s) are stored at ``users/{user_id}/receipts/{session_id}/`` — a
    permanent path so the files survive even if OCR fails (needed for later
    claim-PDF generation and manual review).

    The ``s3ObjectKey`` and ``backImageS3Key`` in the response must be passed to
    ``POST /receipts`` when the user saves the receipt on the confirmation screen.
    """
    firebase_uid = current_user.get("uid")
    db_user = user_service.get_user_by_firebase_uid(db, firebase_uid)
    if not db_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )

    # Validate at least one image is provided
    if not front_image and not back_image:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="At least one image (front or back) must be provided",
        )

    # Helper to validate and read image
    async def validate_and_read_image(file: Optional[UploadFile]) -> Optional[tuple[bytes, str, str]]:
        if not file:
            return None
            
        if file.content_type not in settings.allowed_file_types_list:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=(
                    f"Invalid file type. Allowed: "
                    f"{', '.join(settings.allowed_file_types_list)}"
                ),
            )
        
        content = await file.read()
        
        if len(content) > settings.max_file_size_bytes:
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail=f"File too large. Maximum: {settings.MAX_FILE_SIZE_MB}MB",
            )
        
        return content, file.filename or "receipt", file.content_type or "image/jpeg"

    # Validate and read images
    front_data = await validate_and_read_image(front_image)
    back_data = await validate_and_read_image(back_image)

    # Extract OCR from both images
    result = receipt_service.extract_ocr_from_files(
        user_id=db_user.id,
        front_image_data=front_data,
        back_image_data=back_data,
    )
    return result


@router.get("", response_model=ReceiptListResponse, response_model_by_alias=True)
async def list_receipts(
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(20, ge=1, le=100, description="Items per page"),
    status_filter: Optional[ReceiptStatusEnum] = Query(None, alias="status", description="Filter by status"),
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    List receipts for current user with pagination.

    Args:
        page: Page number (1-indexed)
        page_size: Number of items per page
        status_filter: Optional status filter
        current_user: Current authenticated user
        db: Database session

    Returns:
        Paginated list of receipts
    """
    # Get internal database user ID
    firebase_uid = current_user.get("uid")
    db_user = user_service.get_user_by_firebase_uid(db, firebase_uid)
    if not db_user:
        # New user whose backend registration hasn't completed yet — return
        # an empty list rather than crashing. The mobile app will register the
        # user via POST /auth/register and then retry.
        return {
            "receipts": [],
            "total": 0,
            "page": page,
            "page_size": page_size,
        }

    skip = (page - 1) * page_size
    receipts, total = receipt_service.list_receipts(
        db=db,
        user_id=db_user.id,
        skip=skip,
        limit=page_size,
        status=status_filter,
    )

    return {
        "receipts": receipts,
        "total": total,
        "page": page,
        "page_size": page_size,
    }


@router.get("/{receipt_id}", response_model=ReceiptResponse, response_model_by_alias=True)
async def get_receipt(
    receipt_id: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get receipt by ID.
    
    Args:
        receipt_id: Receipt ID
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        Receipt details
    """
    # Get internal database user ID
    firebase_uid = current_user.get("uid")
    db_user = user_service.get_user_by_firebase_uid(db, firebase_uid)
    if not db_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    receipt = receipt_service.get_receipt(db, receipt_id, db_user.id)
    
    if not receipt:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Receipt not found"
        )
    
    return receipt


@router.patch("/{receipt_id}", response_model=ReceiptResponse, response_model_by_alias=True)
async def update_receipt(
    receipt_id: str,
    receipt_data: ReceiptUpdate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Update receipt information.
    
    Args:
        receipt_id: Receipt ID
        receipt_data: Update data
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        Updated receipt
    """
    # Get internal database user ID
    firebase_uid = current_user.get("uid")
    db_user = user_service.get_user_by_firebase_uid(db, firebase_uid)
    if not db_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    receipt = receipt_service.update_receipt(db, receipt_id, db_user.id, receipt_data)
    
    if not receipt:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Receipt not found"
        )
    
    return receipt


@router.delete("/{receipt_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_receipt(
    receipt_id: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Delete receipt (soft delete).
    
    Args:
        receipt_id: Receipt ID
        current_user: Current authenticated user
        db: Database session
    """
    # Get internal database user ID
    firebase_uid = current_user.get("uid")
    db_user = user_service.get_user_by_firebase_uid(db, firebase_uid)
    if not db_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    success = receipt_service.delete_receipt(db, receipt_id, db_user.id)
    
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Receipt not found"
        )


@router.post("/{receipt_id}/upload", response_model=ReceiptResponse, response_model_by_alias=True)
async def upload_receipt_file(
    receipt_id: str,
    file: UploadFile = File(...),
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Upload receipt file (image or PDF) and trigger OCR processing.
    
    Args:
        receipt_id: Receipt ID
        file: Uploaded file
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        Updated receipt with processing status
    """
    # Get internal database user ID
    firebase_uid = current_user.get("uid")
    db_user = user_service.get_user_by_firebase_uid(db, firebase_uid)
    if not db_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Validate file type
    if file.content_type not in settings.allowed_file_types_list:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid file type. Allowed types: {', '.join(settings.allowed_file_types_list)}"
        )
    
    # Read file content
    file_content = await file.read()
    
    # Validate file size
    if len(file_content) > settings.max_file_size_bytes:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=f"File too large. Maximum size: {settings.MAX_FILE_SIZE_MB}MB"
        )
    
    # Upload file and process OCR
    receipt = receipt_service.upload_receipt_file(
        db=db,
        receipt_id=receipt_id,
        user_id=db_user.id,
        file_content=file_content,
        file_name=file.filename or "receipt",
        content_type=file.content_type
    )
    
    if not receipt:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Receipt not found"
        )
    
    return receipt


@router.get("/{receipt_id}/image-url", response_model=ReceiptImageUrlResponse, response_model_by_alias=True)
async def get_receipt_image_url(
    receipt_id: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get a pre-signed S3 URL for viewing the receipt image.
    URL is valid for 1 hour.
    """
    firebase_uid = current_user.get("uid")
    db_user = user_service.get_user_by_firebase_uid(db, firebase_uid)
    if not db_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    url = receipt_service.get_receipt_image_url(db, receipt_id, db_user.id)

    if url is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Receipt not found or no image uploaded"
        )

    return {"url": url}


@router.post(
    "/{receipt_id}/items",
    response_model=ReceiptLineItemResponse,
    status_code=status.HTTP_201_CREATED,
    response_model_by_alias=True,
)
async def create_line_item(
    receipt_id: str,
    item_data: ReceiptLineItemUpdate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Create a new line item on a receipt.
    """
    firebase_uid = current_user.get("uid")
    db_user = user_service.get_user_by_firebase_uid(db, firebase_uid)
    if not db_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )
        
    try:
        line_item = receipt_service.create_line_item(
            db, receipt_id, db_user.id, item_data
        )
        if not line_item:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Receipt not found"
            )
        return line_item
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.patch(
    "/{receipt_id}/items/{item_id}",
    response_model=ReceiptLineItemResponse,
    response_model_by_alias=True,
)
async def update_line_item(
    receipt_id: str,
    item_id: str,
    item_data: ReceiptLineItemUpdate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Update an existing line item on a receipt.
    """
    firebase_uid = current_user.get("uid")
    db_user = user_service.get_user_by_firebase_uid(db, firebase_uid)
    if not db_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )
        
    line_item = receipt_service.update_line_item(
        db, receipt_id, item_id, db_user.id, item_data
    )
    if not line_item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Line item not found or you do not have permission to update it."
        )
        
    return line_item


@router.delete("/{receipt_id}/items/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_line_item(
    receipt_id: str,
    item_id: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Soft delete a specific line item.
    """
    firebase_uid = current_user.get("uid")
    db_user = user_service.get_user_by_firebase_uid(db, firebase_uid)
    if not db_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )

    success = receipt_service.delete_line_item(
        db=db,
        receipt_id=receipt_id,
        item_id=item_id,
        user_id=db_user.id,
    )

    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Receipt or line item not found",
        )


@router.post("/{receipt_id}/retry-ocr", response_model=ReceiptResponse, response_model_by_alias=True)
async def retry_ocr_processing(
    receipt_id: str,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Retry OCR processing for a failed receipt.
    
    Args:
        receipt_id: Receipt ID
        current_user: Current authenticated user
        db: Database session
        
    Returns:
        Updated receipt
    """
    # Get internal database user ID
    firebase_uid = current_user.get("uid")
    db_user = user_service.get_user_by_firebase_uid(db, firebase_uid)
    if not db_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    receipt = receipt_service.retry_ocr(db, receipt_id, db_user.id)
    
    if not receipt:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Receipt not found"
        )
    
    return receipt
