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

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Prompt templates
# ---------------------------------------------------------------------------

_CLEANUP_PROMPT = """\
You are a text-repair specialist. The text below was extracted via OCR from a \
printed receipt warranty card that had TWO side-by-side columns. The OCR read \
line-by-line across both columns, so words from the left and right columns are \
interleaved. This produces two specific symptoms you must fix:

SYMPTOM 1 — Word duplication: the same English word appears twice (or with a \
non-English twin) in a row, e.g.:
  "Warranty Warranty does does not not cover cover for for physical damages"
must become:
  "Warranty does not cover for physical damages"

SYMPTOM 2 — Orphan fragments: very short lines containing a single word or \
punctuation ("the", "per", "as", "above", "only", "cover") that are left-over \
column remnants. These must be absorbed into the correct neighbouring sentence \
or dropped if they add no meaning.

Additional rules:
- Keep ONLY clearly readable English text.
- Discard any non-English (Tamil, Sinhala, etc.) words silently.
- Preserve ALL factual warranty details exactly: time periods, day counts, \
  coverage conditions, exclusions, product types, claim procedures.
- Output well-formed English sentences/paragraphs — no bullet symbols unless \
  already present in the original.
- Return ONLY the cleaned text. No explanation, no preamble, no commentary.

Garbled OCR text to repair:
{text}"""

_PRODUCT_NAME_PROMPT = """\
You are a product name extractor. Extract ONLY the main product name from the \
OCR text below. The text may contain extra information like:
- IMEI or serial numbers (e.g., "IMEI: 359433181931874")
- Product condition (e.g., "Brand new", "Refurbished")
- Warranty information (e.g., "1 Year Apple Care Warranty")
- Technical specs that are not part of the brand/model name
- Color or storage variants (include these ONLY if part of the model name)

Rules:
- Extract ONLY the brand and model name
- Include color/storage if it's part of the model identifier (e.g., "iPhone 13 256GB blue" is correct)
- Remove IMEI, serial numbers, warranty text, condition descriptions
- Keep the output concise (typically 2-8 words)
- Return ONLY the product name. No explanation, no extra text.

Examples:
Input: "iPhone 13 256GB blueIMEI : 359433181931874Brand new1 Year Apple Care Warranty"
Output: iPhone 13 256GB blue

Input: "Samsung Galaxy S21 5G\nIMEI: 123456789\nUnlocked\n2 Year Warranty"
Output: Samsung Galaxy S21 5G

Input: "MacBook Pro 16-inch M2 Pro Space Gray AppleCare+ Coverage"
Output: MacBook Pro 16-inch M2 Pro Space Gray

OCR text to process:
{text}"""

_STORE_NAME_PROMPT = """\
You are a store name cleaner. Clean the store/vendor name from OCR text that may \
contain extra information or formatting issues.

Common OCR issues:
- Extra dots, dashes, or spaces: "Best . Buy .", "Apple - Store"
- Concatenated text: "BestBuyElectronics", "AppleStoreOnline"
- Case issues: "BEST BUY", "best buy", "BeSt BuY"
- Legal suffixes mixed in: "Best Buy Inc.", "Apple Store LLC"

Rules:
- Return the clean, properly capitalized store name
- Remove legal suffixes (Inc, LLC, Ltd, Corp, Co) unless they're part of the brand
- Fix spacing and remove extra punctuation
- Use proper Title Case for most stores (exceptions: brand-specific like "eBay", "iPhone")
- Keep brand-specific capitalization if recognizable (e.g., "McDonald's", "7-Eleven")
- Remove extra context like "Online Store", "Official Website"
- Output should be 1-5 words typically
- Return ONLY the cleaned name. No explanation.

Examples:
Input: "BEST . BUY . INC"
Output: Best Buy

Input: "Apple-Store-Online"
Output: Apple Store

Input: "mcdonalds restaurant"
Output: McDonald's

Input: "7 eleven store"
Output: 7-Eleven

OCR text to process:
{text}"""

_PHONE_NUMBER_PROMPT = """\
You are a phone number formatter. Clean and format phone numbers from OCR text.

Common OCR issues:
- Wrong punctuation: "123.456.7890", "123 456 7890"
- Mixed formats: "(123) 456-7890", "123-456-7890"
- Extra characters: "+1 (123). 456. 7890"
- Spaces in wrong places: "1 2 3 4 5 6 7 8 9 0"

Rules:
- Return phone number in format: "+[country code] ([area]) [prefix]-[line]"
- For US numbers: "+1 (123) 456-7890"
- For international: keep country code, use consistent formatting
- Remove all extra dots, spaces, parentheses except standard format
- If no country code detected, assume +1 (US)
- Return ONLY the formatted phone number. No explanation.
- If input doesn't look like a valid phone number, return original text

Examples:
Input: "123.456.7890"
Output: +1 (123) 456-7890

Input: "(123) 456-7890"
Output: +1 (123) 456-7890

Input: "1 2 3 4 5 6 7 8 9 0"
Output: +1 (123) 456-7890

Input: "+94 77 123 4567"
Output: +94 (77) 123-4567

OCR text to process:
{text}"""

_EMAIL_PROMPT = """\
You are an email address cleaner. Fix email addresses from OCR text.

Common OCR issues:
- Extra spaces: "info @ shop . com"
- Wrong punctuation: "info@shop,com", "info@shop;com"
- Mixed case: "INFO@SHOP.COM", "InFo@ShOp.CoM"
- Extra dots: "info..@shop.com", "info@shop..com"
- Missing @ or dots: "info shop.com", "info@shopcom"

Rules:
- Return email in lowercase
- Fix spacing (no spaces around @)
- Replace wrong punctuation (comma, semicolon) with correct ones
- Remove duplicate dots
- Ensure single @ symbol exists
- Return ONLY the cleaned email. No explanation.
- If input doesn't look like a valid email, return original text

Examples:
Input: "info @ shop . com"
Output: info@shop.com

Input: "INFO@SHOP.COM"
Output: info@shop.com

Input: "sales@store,com"
Output: sales@store.com

Input: "support @ best . buy . com"
Output: support@bestbuy.com

OCR text to process:
{text}"""

_ADDRESS_PROMPT = """\
You are an address formatter. Clean and format addresses from OCR text.

Common OCR issues:
- Wrong punctuation: "123 Main St.Suite 100.City, State.12345"
- Missing commas: "123 Main St Suite 100 City State 12345"
- Line breaks in wrong places: "123 Main\\nSt Suite\\n100"
- Extra dots/dashes: "123. Main. St.", "City - State - 12345"
- Case issues: "123 MAIN STREET", "city, state 12345"

Rules:
- Format as: "[Street], [City], [State] [ZIP]"
- Use proper Title Case for street names and cities
- Use uppercase for state codes (CA, NY, etc.)
- Add proper commas between components
- Remove extra punctuation and normalize spacing
- Keep suite/apartment numbers with street address
- Return ONLY the formatted address. No explanation.

Examples:
Input: "123 Main St.Suite 100.Los Angeles.CA.90001"
Output: 123 Main St Suite 100, Los Angeles, CA 90001

Input: "456 oak street apt 5 new york ny 10001"
Output: 456 Oak Street Apt 5, New York, NY 10001

Input: "789. First. Ave. - San Francisco - CA - 94102"
Output: 789 First Ave, San Francisco, CA 94102

OCR text to process:
{text}"""


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
            r'(?i)(IMEI|Serial|S/N|Warranty|Brand\s+new|Refurbished|AppleCare)',
            r'\d{15,}',  # Long numbers (IMEI, etc.)
        ]
        
        # Try to split at first match
        for pattern in patterns:
            match = re.search(pattern, text)
            if match:
                # Return everything before the match, stripped
                result = text[:match.start()].strip()
                if result:
                    return result
        
        # Fallback: return first line or first 100 chars
        first_line = text.split('\n')[0].strip()
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
        result = re.sub(r'\s+(Inc\.?|LLC|Ltd\.?|Corp\.?|Co\.?)$', '', text, flags=re.IGNORECASE)
        
        # Remove extra punctuation
        result = re.sub(r'[.]{2,}', '.', result)  # Multiple dots
        result = re.sub(r'\s*[.-]\s*', ' ', result)  # Dashes and dots with spaces
        result = re.sub(r'\.+$', '', result)  # Trailing dots
        
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
        digits = re.sub(r'\D', '', text)
        
        # Check if it looks like a valid phone number (7-15 digits)
        if len(digits) < 7 or len(digits) > 15:
            return text
        
        # Format US/Canada numbers (10 or 11 digits)
        if len(digits) == 10:
            return f"+1 ({digits[:3]}) {digits[3:6]}-{digits[6:]}"
        elif len(digits) == 11 and digits[0] == '1':
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
        result = text.replace(' ', '')
        
        # Fix common OCR mistakes
        result = result.replace(',', '.')  # Comma instead of dot
        result = result.replace(';', '.')  # Semicolon instead of dot
        
        # Remove duplicate dots
        result = re.sub(r'\.{2,}', '.', result)
        
        # Convert to lowercase
        result = result.lower()
        
        # Verify it looks like an email (has @ and .)
        if '@' in result and '.' in result.split('@')[-1]:
            return result
        
        return text

    def clean_address(self, text: str) -> str:
        """Mock implementation using basic formatting."""
        logger.debug("[MOCK] Address cleanup: using regex")
        import re
        
        if not text or not text.strip():
            return text
        
        # Replace line breaks with spaces
        result = text.replace('\n', ' ')
        
        # Fix common punctuation issues
        result = re.sub(r'\s*\.\s*', ' ', result)  # Dots
        result = re.sub(r'\s*-\s*', ' ', result)   # Dashes
        
        # Normalize spacing
        result = re.sub(r'\s+', ' ', result)
        
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

            body = json.dumps({
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": 512,
                "temperature": 0.1,  # low temp → deterministic cleanup
                "messages": [
                    {
                        "role": "user",
                        "content": [{"type": "text", "text": prompt}],
                    }
                ],
            })

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

            body = json.dumps({
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": 100,  # Product names are short
                "temperature": 0.1,  # Deterministic extraction
                "messages": [
                    {
                        "role": "user",
                        "content": [{"type": "text", "text": prompt}],
                    }
                ],
            })

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

            body = json.dumps({
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": 50,
                "temperature": 0.1,
                "messages": [
                    {
                        "role": "user",
                        "content": [{"type": "text", "text": prompt}],
                    }
                ],
            })

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

            body = json.dumps({
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": 50,
                "temperature": 0.1,
                "messages": [
                    {
                        "role": "user",
                        "content": [{"type": "text", "text": prompt}],
                    }
                ],
            })

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

            body = json.dumps({
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": 50,
                "temperature": 0.1,
                "messages": [
                    {
                        "role": "user",
                        "content": [{"type": "text", "text": prompt}],
                    }
                ],
            })

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

            body = json.dumps({
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": 150,  # Addresses can be longer
                "temperature": 0.1,
                "messages": [
                    {
                        "role": "user",
                        "content": [{"type": "text", "text": prompt}],
                    }
                ],
            })

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
