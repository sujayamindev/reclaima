"""
Product routes - Product image search via Google Custom Search.
"""

import logging
from typing import Optional
from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field

from app.core.config import settings
from app.core.security import get_current_user
from app.services.product_image_service import create_product_image_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/products", tags=["Products"])

# Lazily-initialised singleton (created on first request)
_image_service = None


def _get_image_service():
    global _image_service
    if _image_service is None:
        _image_service = create_product_image_service(
            use_mock=settings.USE_MOCK_AWS,
            api_key=getattr(settings, "BRAVE_SEARCH_API_KEY", ""),
        )
    return _image_service


class ImageSearchRequest(BaseModel):
    query: Optional[str] = Field(
        None, max_length=1000, description="Product name to search for"
    )


@router.post("/image-search")
async def search_product_image(
    body: ImageSearchRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Search for a product image by product name.

    Returns the first matching image result with URL, title, and source,
    or {"imageUrl": null} when nothing is found. Always 200 — callers
    should check imageUrl for null rather than handling 404 errors.
    Requires authentication.
    """
    query = body.query
    if not query or not query.strip():
        return {"imageUrl": None}

    logger.info(
        f"Product image search requested by user {current_user.get('uid', '?')}: "
        f"{query!r}"
    )

    # Brave's query length limit is 400 chars; truncate silently if OCR produced more.
    search_query = query[:400]

    service = _get_image_service()
    result = await service.search_product_image(search_query)

    return result if result is not None else {"imageUrl": None}
