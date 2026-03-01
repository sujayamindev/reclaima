"""
Product routes - Product image search via Google Custom Search.
"""

import logging
from fastapi import APIRouter, Depends, HTTPException, Query, status

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


@router.get("/image-search")
async def search_product_image(
    query: str = Query(
        ...,
        min_length=1,
        max_length=200,
        description="Product name to search for",
    ),
    current_user: dict = Depends(get_current_user),
):
    """
    Search for a product image by product name.

    Returns the first matching image result with URL, title, and source.
    Requires authentication.
    """
    logger.info(
        f"Product image search requested by user {current_user.get('uid', '?')}: "
        f"{query!r}"
    )

    service = _get_image_service()
    result = await service.search_product_image(query)

    if result is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No product image found for the given query.",
        )

    return result
