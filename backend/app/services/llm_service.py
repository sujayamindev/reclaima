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
# Prompt template
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
        import boto3

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
