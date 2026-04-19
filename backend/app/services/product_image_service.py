"""
Product Image Service for Smart Receipt & Warranty Manager.

Searches for product images using the Brave Search Image API,
with a mock fallback for development mode.

Brave Search API free tier: 2,000 queries/month.
Docs: https://api.search.brave.com/app#/documentation/image-search
"""

import logging
from abc import ABC, abstractmethod
from typing import Optional, Dict

import re

import httpx

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Brave Search constants
# ---------------------------------------------------------------------------
_BRAVE_IMAGE_ENDPOINT = "https://api.search.brave.com/res/v1/images/search"

# Domains that typically serve low-quality, watermarked, or cluttered images.
_BLOCKED_DOMAINS = {
    "ebay.com",
    "ebay.co.uk",
    "ebay.de",
    "ebay.fr",
    "aliexpress.com",
    "alibaba.com",
    "wish.com",
    "temu.com",
    "dhgate.com",
    "facebook.com",
    "pinterest.com",
    "instagram.com",
    "reddit.com",
    "twitter.com",
    "x.com",
    "shutterstock.com",
    "gettyimages.com",
    "alamy.com",  # stock-photo paywalls
}

# Domains that provide high quality official product images.
_TRUSTED_DOMAINS = {
    "apple.com",
    "samsung.com",
    "sony.com",
    "lg.com",
    "panasonic.com",
    "bose.com",
    "dell.com",
    "hp.com",
    "lenovo.com",
    "asus.com",
    "acer.com",
    "microsoft.com",
    "bestbuy.com",
    "target.com",
    "walmart.com",
    "homedepot.com",
    "lowes.com",
    "ikea.com",
    "canadiantire.ca",
    "costco.com",
    "costco.ca",
    "bjs.com",
    "samsclub.com",
    "bhphotovideo.com",
    "adorama.com",
    "officedepot.com",
    "staples.com",
    "amazon.com",
}


def _clean_query(raw: str) -> str:
    """
    Normalise a product name into a better image-search query.

    Steps:
      1. Strip content inside brackets/parens  (e.g. "[2024 model]")
      2. Remove long serial/model suffixes      (e.g. "MK2J3LL/A")
      3. Collapse whitespace
      4. Append bias phrase for cleaner results
    """
    # Temporarily disabled
    return raw.strip()

    q = raw.strip()

    # Remove bracketed noise  e.g.  "(256GB, Space Gray)"
    q = re.sub(r"[\[\(].*?[\]\)]", "", q)

    # Remove tokens that look like serial/model codes (≥4 chars mixing letters+digits+slashes)
    q = re.sub(r"\b[A-Z0-9]{2,}[/-][A-Z0-9]+\b", "", q, flags=re.IGNORECASE)

    # Collapse whitespace
    q = " ".join(q.split())

    # Append a bias phrase for clean product imagery
    if q:
        q += " product official image"

    return q


def _is_blocked(url: str) -> bool:
    """Return True if the image URL is hosted on a blocked domain."""
    from urllib.parse import urlparse

    host = urlparse(url).hostname or ""
    # Match "ebay.com" and "i.ebay.com", etc.
    for blocked in _BLOCKED_DOMAINS:
        if host == blocked or host.endswith("." + blocked):
            return True
    return False


def _is_trusted(url: str) -> bool:
    """Return True if the image URL is hosted on a trusted domain."""
    from urllib.parse import urlparse

    host = urlparse(url).hostname or ""
    for trusted in _TRUSTED_DOMAINS:
        if host == trusted or host.endswith("." + trusted):
            return True
    return False


# ---------------------------------------------------------------------------
# Abstract base
# ---------------------------------------------------------------------------


class BaseProductImageService(ABC):
    """Abstract base class for product image search services."""

    @abstractmethod
    async def search_product_image(self, query: str) -> Optional[Dict[str, str]]:
        """
        Search for a product image by name.

        Returns a dict with keys: imageUrl, title, source — or None.
        """

    def search_product_image_sync(self, query: str) -> Optional[Dict[str, str]]:
        """Synchronous wrapper for use in non-async contexts (e.g. receipt_service)."""
        return None


# ---------------------------------------------------------------------------
# Mock implementation (dev / USE_MOCK_AWS=True)
# ---------------------------------------------------------------------------


class MockProductImageService(BaseProductImageService):
    """Mock service — returns a placeholder image URL for development."""

    def __init__(self) -> None:
        logger.info("MockProductImageService initialized (placeholder mode)")

    async def search_product_image(self, query: str) -> Optional[Dict[str, str]]:
        logger.debug(f"[MOCK] Product image search for: {query}")
        return {
            "imageUrl": "https://via.placeholder.com/300x300.png?text=Product",
            "title": query,
            "source": "placeholder",
        }

    def search_product_image_sync(self, query: str) -> Optional[Dict[str, str]]:
        logger.debug(f"[MOCK] Sync product image search for: {query}")
        return {
            "imageUrl": "https://via.placeholder.com/300x300.png?text=Product",
            "title": query,
            "source": "placeholder",
        }


# ---------------------------------------------------------------------------
# Real implementation — Brave Search Image API
# ---------------------------------------------------------------------------


class BraveProductImageService(BaseProductImageService):
    """
    Brave Search Image API service for product image lookup.

    Free tier: 2,000 queries/month. Auth via X-Subscription-Token header.
    """

    def __init__(self, api_key: str) -> None:
        self._api_key = api_key
        logger.info("BraveProductImageService initialized")

    async def search_product_image(self, query: str) -> Optional[Dict[str, str]]:
        if not query or not query.strip():
            return None

        search_query = _clean_query(query)
        if not search_query:
            return None

        logger.info(f"Brave image search: {search_query!r}  (raw: {query!r})")

        try:
            headers = {
                "Accept": "application/json",
                "Accept-Encoding": "gzip",
                "X-Subscription-Token": self._api_key,
            }
            params: dict[str, str | int] = {
                "q": search_query,
                "count": 8,  # fetch extras so we can filter
                "safesearch": "strict",
            }

            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.get(
                    _BRAVE_IMAGE_ENDPOINT,
                    headers=headers,
                    params=params,
                )
                response.raise_for_status()
                data = response.json()

            results = data.get("results", [])
            if not results:
                logger.info(f"No image results for: {search_query!r}")
                return None

            # 1. Prefer images from trusted domains
            for item in results:
                image_url = self._extract_image_url(item)
                if not image_url:
                    continue

                source_url = item.get("url", image_url)
                if _is_trusted(source_url) or _is_trusted(image_url):
                    result = {
                        "imageUrl": image_url,
                        "title": item.get("title", query),
                        "source": item.get("source", ""),
                    }
                    logger.info(
                        f"Brave selected trusted image for {search_query!r}: "
                        f"{result['imageUrl'][:80]}..."
                    )
                    return result

            logger.info(f"No trusted image URL found for: {search_query!r}")
            return None

        except httpx.HTTPStatusError as exc:
            logger.error(
                f"Brave Search HTTP error: {exc.response.status_code} — "
                f"{exc.response.text[:200]}"
            )
            return None
        except Exception as exc:
            logger.error(
                f"Brave Search failed: {type(exc).__name__}: {exc}",
                exc_info=True,
            )
            return None

    def search_product_image_sync(self, query: str) -> Optional[Dict[str, str]]:
        """
        Synchronous version using httpx.Client.
        Called from synchronous service methods (e.g. receipt_service.process_ocr).
        """
        if not query or not query.strip():
            return None

        search_query = _clean_query(query)
        if not search_query:
            return None

        logger.info(f"Brave image search (sync): {search_query!r}")

        try:
            headers = {
                "Accept": "application/json",
                "Accept-Encoding": "gzip",
                "X-Subscription-Token": self._api_key,
            }
            params: dict[str, str | int] = {
                "q": search_query,
                "count": 8,
                "safesearch": "strict",
            }

            with httpx.Client(timeout=10.0) as client:
                response = client.get(
                    _BRAVE_IMAGE_ENDPOINT,
                    headers=headers,
                    params=params,
                )
                response.raise_for_status()
                data = response.json()

            results = data.get("results", [])
            if not results:
                return None

            # 1. Prefer images from trusted domains
            for item in results:
                image_url = self._extract_image_url(item)
                if not image_url:
                    continue
                source_url = item.get("url", image_url)
                if _is_trusted(source_url) or _is_trusted(image_url):
                    return {
                        "imageUrl": image_url,
                        "title": item.get("title", query),
                        "source": item.get("source", ""),
                    }

            return None

        except httpx.HTTPStatusError as exc:
            logger.error(
                f"Brave Search (sync) HTTP error: {exc.response.status_code} — "
                f"{exc.response.text[:200]}"
            )
            return None
        except Exception as exc:
            logger.error(
                f"Brave Search (sync) failed: {type(exc).__name__}: {exc}",
                exc_info=True,
            )
            return None

    @staticmethod
    def _extract_image_url(item: dict) -> str:
        """Pull the best image URL from a Brave result item."""
        properties = item.get("properties", {})
        if properties.get("url"):
            return properties["url"]
        if item.get("thumbnail", {}).get("src"):
            return item["thumbnail"]["src"]
        return ""


# ---------------------------------------------------------------------------
# Factory
# ---------------------------------------------------------------------------


def create_product_image_service(
    use_mock: bool,
    api_key: str = "",
) -> BaseProductImageService:
    """
    Return a MockProductImageService when use_mock=True,
    or a BraveProductImageService when BRAVE_SEARCH_API_KEY is available.
    """
    if use_mock or not api_key:
        if not use_mock:
            logger.warning(
                "BRAVE_SEARCH_API_KEY not set — "
                "falling back to mock product image service"
            )
        return MockProductImageService()
    return BraveProductImageService(api_key=api_key)
