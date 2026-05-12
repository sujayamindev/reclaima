"""
LLM Service for Smart Receipt & Warranty Manager.

Provides AI-powered cleanup of garbled OCR text extracted from multi-column
receipt layouts.  After the geometric column-reconstruction pass in
TextractService, this service sends partially-cleaned notes/warranty text
through AWS Bedrock (Claude Haiku) to:
  - Remove duplicated words caused by bilingual side-by-side columns
    (e.g. "does does not not cover" → "does not cover")
  - Strip non-English text from bilingual receipts
  - Restore grammatically coherent English sentences
  - Preserve all factual warranty/return policy details

Uses the Boto3 Bedrock Converse API — no new Python packages required since
boto3 is already a project dependency.
"""

import logging
from abc import ABC, abstractmethod

from app.core.prompts import (
    ADDRESS_PROMPT as _ADDRESS_PROMPT,
    CLEANUP_PROMPT as _CLEANUP_PROMPT,
    EMAIL_PROMPT as _EMAIL_PROMPT,
    PHONE_NUMBER_PROMPT as _PHONE_NUMBER_PROMPT,
    PRODUCT_NAME_PROMPT as _PRODUCT_NAME_PROMPT,
    STORE_NAME_PROMPT as _STORE_NAME_PROMPT,
)

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Abstract base
# ---------------------------------------------------------------------------


class BaseLLMService(ABC):
    """Abstract base class for LLM text-cleanup services."""

    @abstractmethod
    def clean_receipt_notes(self, text: str) -> str:
        """
        Clean up garbled OCR warranty/notes text.

        Returns the cleaned text, or the original input if cleaning fails
        (non-critical — OCR result is still usable).
        """

    @abstractmethod
    def extract_product_name(self, text: str) -> str:
        """
        Extract clean product name from OCR text that may contain extra info.

        Args:
            text: Raw OCR text that may include IMEI, warranty info, etc.

        Returns:
            Cleaned product name, or original text if extraction fails.
        """

    @abstractmethod
    def clean_store_name(self, text: str) -> str:
        """
        Clean and format store/vendor name from OCR text.

        Args:
            text: Raw OCR text with potential formatting issues

        Returns:
            Cleaned store name, or original text if cleaning fails.
        """

    @abstractmethod
    def clean_phone_number(self, text: str) -> str:
        """
        Format phone number from OCR text.

        Args:
            text: Raw OCR text with phone number

        Returns:
            Formatted phone number, or original text if cleaning fails.
        """

    @abstractmethod
    def clean_email(self, text: str) -> str:
        """
        Clean email address from OCR text.

        Args:
            text: Raw OCR text with email address

        Returns:
            Cleaned email address, or original text if cleaning fails.
        """

    @abstractmethod
    def clean_address(self, text: str) -> str:
        """
        Format address from OCR text.

        Args:
            text: Raw OCR text with address

        Returns:
            Formatted address, or original text if cleaning fails.
        """


# ---------------------------------------------------------------------------
# Mock implementation (dev / USE_MOCK_AWS=True)
# ---------------------------------------------------------------------------


class MockLLMService(BaseLLMService):
    """Mock LLM service — returns text unchanged (passthrough for dev mode)."""

    def __init__(self) -> None:
        logger.info("MockLLMService initialized (passthrough mode)")

    def clean_receipt_notes(self, text: str) -> str:
        logger.debug("[MOCK] LLM cleanup: returning text unchanged")
        return text

    def extract_product_name(self, text: str) -> str:
        """
        Mock implementation using simple regex patterns.
        Attempts to split at common separators or returns first line.
        """
        logger.debug("[MOCK] Product name extraction: using regex fallback")
        import re

        # Common patterns that indicate non-product info starts
        patterns = [
            r"(?i)(IMEI|Serial|S/N|Warranty|Brand\s+new|Refurbished|AppleCare)",
            r"\d{15,}",  # Long numbers (IMEI, etc.)
        ]

        # Try to split at first match
        for pattern in patterns:
            match = re.search(pattern, text)
            if match:
                # Return everything before the match, stripped
                result = text[: match.start()].strip()
                if result:
                    return result

        # Fallback: return first line or first 100 chars
        first_line = text.split("\n")[0].strip()
        if len(first_line) <= 100:
            return first_line

        # Last resort: return original
        return text

    def clean_store_name(self, text: str) -> str:
        """Mock implementation using basic string cleanup."""
        logger.debug("[MOCK] Store name cleanup: using regex")
        import re

        if not text or not text.strip():
            return text

        # Remove common legal suffixes
        result = re.sub(
            r"\s+(Inc\.?|LLC|Ltd\.?|Corp\.?|Co\.?)$", "", text, flags=re.IGNORECASE
        )

        # Remove extra punctuation
        result = re.sub(r"[.]{2,}", ".", result)  # Multiple dots
        result = re.sub(r"\s*[.-]\s*", " ", result)  # Dashes and dots with spaces
        result = re.sub(r"\.+$", "", result)  # Trailing dots

        # Convert to title case
        result = result.strip().title()

        return result if result else text

    def clean_phone_number(self, text: str) -> str:
        """Mock implementation using regex for phone formatting."""
        logger.debug("[MOCK] Phone cleanup: using regex")
        import re

        if not text or not text.strip():
            return text

        # Extract digits only
        digits = re.sub(r"\D", "", text)

        # Check if it looks like a valid phone number (7-15 digits)
        if len(digits) < 7 or len(digits) > 15:
            return text

        # Format US/Canada numbers (10 or 11 digits)
        if len(digits) == 10:
            return f"+1 ({digits[:3]}) {digits[3:6]}-{digits[6:]}"
        elif len(digits) == 11 and digits[0] == "1":
            return f"+1 ({digits[1:4]}) {digits[4:7]}-{digits[7:]}"

        # For other lengths, keep original
        return text

    def clean_email(self, text: str) -> str:
        """Mock implementation using regex for email cleanup."""
        logger.debug("[MOCK] Email cleanup: using regex")
        import re

        if not text or not text.strip():
            return text

        # Remove spaces
        result = text.replace(" ", "")

        # Fix common OCR mistakes
        result = result.replace(",", ".")  # Comma instead of dot
        result = result.replace(";", ".")  # Semicolon instead of dot

        # Remove duplicate dots
        result = re.sub(r"\.{2,}", ".", result)

        # Convert to lowercase
        result = result.lower()

        # Verify it looks like an email (has @ and .)
        if "@" in result and "." in result.split("@")[-1]:
            return result

        return text

    def clean_address(self, text: str) -> str:
        """Mock implementation using basic formatting."""
        logger.debug("[MOCK] Address cleanup: using regex")
        import re

        if not text or not text.strip():
            return text

        # Replace line breaks with spaces
        result = text.replace("\n", " ")

        # Fix common punctuation issues
        result = re.sub(r"\s*\.\s*", " ", result)  # Dots
        result = re.sub(r"\s*-\s*", " ", result)  # Dashes

        # Normalize spacing
        result = re.sub(r"\s+", " ", result)

        # Basic title case (not perfect but better than nothing)
        result = result.strip().title()

        return result if result else text


# ---------------------------------------------------------------------------
# Real implementation — AWS Bedrock (Claude Haiku via Converse API)
# ---------------------------------------------------------------------------


class BedrockLLMService(BaseLLMService):
    """
    AWS Bedrock LLM service using Claude Haiku for OCR text cleanup.

    Uses the Bedrock InvokeModel API (compatible with boto3 >= 1.28).
    Approximate cost: ~$0.00025 per receipt (Claude 3 Haiku pricing).
    """

    def __init__(self, region: str, model_id: str) -> None:
        import boto3  # type: ignore[import-not-found,import-untyped]

        self._client = boto3.client("bedrock-runtime", region_name=region)
        self._model_id = model_id
        # Log the boto3 client's resolved region and endpoint for diagnostics.
        client_region = getattr(self._client.meta, "region_name", None)
        endpoint = None
        try:
            endpoint = getattr(self._client._endpoint, "host", None)
        except Exception:
            endpoint = None

        logger.info(
            f"BedrockLLMService initialized — model: {model_id}, region_setting: {region}, "
            f"client_region: {client_region}, endpoint: {endpoint}"
        )

    def clean_receipt_notes(self, text: str) -> str:
        """
        Send garbled OCR text to Claude via Bedrock Converse API and return
        the cleaned text.  Falls back to the original text on any error so
        that OCR processing is never blocked by an LLM failure.
        """
        if not text or not text.strip():
            return text

        prompt = _CLEANUP_PROMPT.format(text=text.strip())
        logger.info(
            f"Bedrock LLM cleanup starting — model={self._model_id}, "
            f"input_chars={len(text)}"
        )

        try:
            import json

            body = json.dumps(
                {
                    "anthropic_version": "bedrock-2023-05-31",
                    "max_tokens": 512,
                    "temperature": 0.1,  # low temp → deterministic cleanup
                    "messages": [
                        {
                            "role": "user",
                            "content": [{"type": "text", "text": prompt}],
                        }
                    ],
                }
            )

            raw = self._client.invoke_model(
                modelId=self._model_id,
                body=body,
                contentType="application/json",
                accept="application/json",
            )

            result = json.loads(raw["body"].read())
            cleaned = result["content"][0]["text"].strip()
            logger.info(
                f"Bedrock LLM cleanup: {len(text)} chars → {len(cleaned)} chars"
            )
            return cleaned

        except Exception as exc:
            # Non-critical: log the full error so we can diagnose IAM /
            # model-access issues, then fall back to the original text.
            logger.error(
                f"Bedrock LLM cleanup failed (model={self._model_id}): "
                f"{type(exc).__name__}: {exc}",
                exc_info=True,
            )
            return text

    def extract_product_name(self, text: str) -> str:
        """
        Extract clean product name from OCR text using Claude via Bedrock.
        Falls back to original text on any error.
        """
        if not text or not text.strip():
            return text

        prompt = _PRODUCT_NAME_PROMPT.format(text=text.strip())
        logger.info(
            f"Bedrock product name extraction starting — model={self._model_id}, "
            f"input_chars={len(text)}"
        )

        try:
            import json

            body = json.dumps(
                {
                    "anthropic_version": "bedrock-2023-05-31",
                    "max_tokens": 100,  # Product names are short
                    "temperature": 0.1,  # Deterministic extraction
                    "messages": [
                        {
                            "role": "user",
                            "content": [{"type": "text", "text": prompt}],
                        }
                    ],
                }
            )

            raw = self._client.invoke_model(
                modelId=self._model_id,
                body=body,
                contentType="application/json",
                accept="application/json",
            )

            result = json.loads(raw["body"].read())
            product_name = result["content"][0]["text"].strip()
            logger.info(
                f"Bedrock product name extraction: '{text[:50]}...' → '{product_name}'"
            )
            return product_name

        except Exception as exc:
            logger.error(
                f"Bedrock product name extraction failed (model={self._model_id}): "
                f"{type(exc).__name__}: {exc}",
                exc_info=True,
            )
            return text

    def clean_store_name(self, text: str) -> str:
        """Clean store name using Claude via Bedrock."""
        if not text or not text.strip():
            return text

        prompt = _STORE_NAME_PROMPT.format(text=text.strip())
        logger.info(f"Bedrock store name cleanup starting — input_chars={len(text)}")

        try:
            import json

            body = json.dumps(
                {
                    "anthropic_version": "bedrock-2023-05-31",
                    "max_tokens": 50,
                    "temperature": 0.1,
                    "messages": [
                        {
                            "role": "user",
                            "content": [{"type": "text", "text": prompt}],
                        }
                    ],
                }
            )

            raw = self._client.invoke_model(
                modelId=self._model_id,
                body=body,
                contentType="application/json",
                accept="application/json",
            )

            result = json.loads(raw["body"].read())
            cleaned = result["content"][0]["text"].strip()
            logger.info(f"Bedrock store name: '{text}' → '{cleaned}'")
            return cleaned

        except Exception as exc:
            logger.error(
                f"Bedrock store name cleanup failed: {type(exc).__name__}: {exc}",
                exc_info=True,
            )
            return text

    def clean_phone_number(self, text: str) -> str:
        """Format phone number using Claude via Bedrock."""
        if not text or not text.strip():
            return text

        prompt = _PHONE_NUMBER_PROMPT.format(text=text.strip())
        logger.info(f"Bedrock phone cleanup starting — input_chars={len(text)}")

        try:
            import json

            body = json.dumps(
                {
                    "anthropic_version": "bedrock-2023-05-31",
                    "max_tokens": 50,
                    "temperature": 0.1,
                    "messages": [
                        {
                            "role": "user",
                            "content": [{"type": "text", "text": prompt}],
                        }
                    ],
                }
            )

            raw = self._client.invoke_model(
                modelId=self._model_id,
                body=body,
                contentType="application/json",
                accept="application/json",
            )

            result = json.loads(raw["body"].read())
            cleaned = result["content"][0]["text"].strip()
            logger.info(f"Bedrock phone: '{text}' → '{cleaned}'")
            return cleaned

        except Exception as exc:
            logger.error(
                f"Bedrock phone cleanup failed: {type(exc).__name__}: {exc}",
                exc_info=True,
            )
            return text

    def clean_email(self, text: str) -> str:
        """Clean email address using Claude via Bedrock."""
        if not text or not text.strip():
            return text

        prompt = _EMAIL_PROMPT.format(text=text.strip())
        logger.info(f"Bedrock email cleanup starting — input_chars={len(text)}")

        try:
            import json

            body = json.dumps(
                {
                    "anthropic_version": "bedrock-2023-05-31",
                    "max_tokens": 50,
                    "temperature": 0.1,
                    "messages": [
                        {
                            "role": "user",
                            "content": [{"type": "text", "text": prompt}],
                        }
                    ],
                }
            )

            raw = self._client.invoke_model(
                modelId=self._model_id,
                body=body,
                contentType="application/json",
                accept="application/json",
            )

            result = json.loads(raw["body"].read())
            cleaned = result["content"][0]["text"].strip()
            logger.info(f"Bedrock email: '{text}' → '{cleaned}'")
            return cleaned

        except Exception as exc:
            logger.error(
                f"Bedrock email cleanup failed: {type(exc).__name__}: {exc}",
                exc_info=True,
            )
            return text

    def clean_address(self, text: str) -> str:
        """Format address using Claude via Bedrock."""
        if not text or not text.strip():
            return text

        prompt = _ADDRESS_PROMPT.format(text=text.strip())
        logger.info(f"Bedrock address cleanup starting — input_chars={len(text)}")

        try:
            import json

            body = json.dumps(
                {
                    "anthropic_version": "bedrock-2023-05-31",
                    "max_tokens": 150,  # Addresses can be longer
                    "temperature": 0.1,
                    "messages": [
                        {
                            "role": "user",
                            "content": [{"type": "text", "text": prompt}],
                        }
                    ],
                }
            )

            raw = self._client.invoke_model(
                modelId=self._model_id,
                body=body,
                contentType="application/json",
                accept="application/json",
            )

            result = json.loads(raw["body"].read())
            cleaned = result["content"][0]["text"].strip()
            logger.info(f"Bedrock address: '{text[:50]}...' → '{cleaned[:50]}...'")
            return cleaned

        except Exception as exc:
            logger.error(
                f"Bedrock address cleanup failed: {type(exc).__name__}: {exc}",
                exc_info=True,
            )
            return text


# ---------------------------------------------------------------------------
# Factory
# ---------------------------------------------------------------------------


def create_llm_service(
    use_mock: bool,
    region: str,
    model_id: str,
) -> BaseLLMService:
    """
    Return a MockLLMService when use_mock=True (USE_MOCK_AWS env var),
    or a BedrockLLMService pointing at the configured Claude Haiku model.
    """
    if use_mock:
        return MockLLMService()
    return BedrockLLMService(region=region, model_id=model_id)
