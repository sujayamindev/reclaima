"""Unit tests for OCR, LLM, S3, and product-image service helpers."""

from __future__ import annotations

import io
import json

import httpx

from app.services.llm_service import (
    BedrockLLMService,
    MockLLMService,
    create_llm_service,
)
from app.services.product_image_service import (
    BraveProductImageService,
    MockProductImageService,
    _clean_query,
    _is_blocked,
    _is_trusted,
    create_product_image_service,
)
from app.services.s3_service import MockS3Service, RealS3Service, get_s3_service
from app.services.textract_service import (
    MockTextractService,
    RealTextractService,
    get_textract_service,
)


class _SuccessfulBedrockClient:
    def __init__(self, text: str) -> None:
        self._text = text

    def invoke_model(self, **kwargs):
        payload = {"content": [{"text": self._text}]}
        return {"body": io.BytesIO(json.dumps(payload).encode("utf-8"))}


class _FailingBedrockClient:
    def invoke_model(self, **kwargs):
        raise RuntimeError("bedrock failure")


class _DummyLLM:
    def extract_product_name(self, text: str) -> str:
        return text.replace("IMEI 123", "").strip()

    def clean_store_name(self, text: str) -> str:
        return f"Clean-{text}"

    def clean_phone_number(self, text: str) -> str:
        return f"P:{text}"

    def clean_email(self, text: str) -> str:
        return text.lower()

    def clean_address(self, text: str) -> str:
        return f"A:{text}"


class _DummyHTTPResponse:
    def __init__(self, payload: dict, status_code: int = 200, text: str = "ok") -> None:
        self._payload = payload
        self.status_code = status_code
        self.text = text
        self.request = httpx.Request("GET", "https://unit.test")

    def raise_for_status(self) -> None:
        if self.status_code >= 400:
            raise httpx.HTTPStatusError(
                message="error",
                request=self.request,
                response=httpx.Response(self.status_code, text=self.text),
            )

    def json(self) -> dict:
        return self._payload


class _DummyAsyncClient:
    def __init__(self, response: _DummyHTTPResponse) -> None:
        self._response = response

    async def __aenter__(self):
        return self

    async def __aexit__(self, exc_type, exc, tb):
        return False

    async def get(self, *args, **kwargs):
        return self._response


class _DummySyncClient:
    def __init__(self, response: _DummyHTTPResponse) -> None:
        self._response = response

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        return False

    def get(self, *args, **kwargs):
        return self._response


class _FakeClientError(Exception):
    def __init__(self, code: str, message: str = "err") -> None:
        super().__init__(message)
        self.response = {"Error": {"Code": code, "Message": message}}


class _FakeS3Client:
    def __init__(self) -> None:
        self.files: dict[str, bytes] = {}
        self.deleted_batches: list[list[str]] = []

    def put_object(self, Bucket, Key, Body, ContentType):
        self.files[Key] = Body

    def generate_presigned_url(self, operation, Params, ExpiresIn):
        return f"https://s3.local/{Params['Bucket']}/{Params['Key']}?exp={ExpiresIn}"

    def get_object(self, Bucket, Key):
        if Key not in self.files:
            raise _FakeClientError("NoSuchKey")
        return {"Body": io.BytesIO(self.files[Key])}

    def delete_object(self, Bucket, Key):
        if Key not in self.files:
            raise _FakeClientError("Missing")
        del self.files[Key]

    def delete_objects(self, Bucket, Delete):
        keys = [obj["Key"] for obj in Delete["Objects"]]
        self.deleted_batches.append(keys)
        deleted = []
        errors = []
        for key in keys:
            if key.startswith("bad"):
                errors.append({"Key": key, "Message": "failed"})
            else:
                deleted.append({"Key": key})
                self.files.pop(key, None)
        return {"Deleted": deleted, "Errors": errors}

    def head_object(self, Bucket, Key):
        if Key not in self.files:
            raise _FakeClientError("404")


def _make_bedrock_service(client) -> BedrockLLMService:
    service = BedrockLLMService.__new__(BedrockLLMService)
    service._model_id = "unit-test-model"
    service._client = client
    return service


def _make_real_s3_service(fake_client: _FakeS3Client) -> RealS3Service:
    service = RealS3Service.__new__(RealS3Service)
    service.bucket_name = "bucket"
    service.s3_client = fake_client
    service.ClientError = _FakeClientError
    return service


def test_mock_llm_service_and_factory() -> None:
    service = MockLLMService()

    assert service.clean_receipt_notes("  text  ") == "  text  "
    assert "iPhone" in service.extract_product_name("iPhone 13 IMEI 123")
    assert service.clean_store_name("BEST . BUY . INC") == "Best Buy"
    assert service.clean_phone_number("123.456.7890") == "+1 (123) 456-7890"
    assert service.clean_email("INFO @ SHOP . COM") == "info@shop.com"
    assert "Los Angeles" in service.clean_address("123 main st los angeles ca")

    assert isinstance(create_llm_service(use_mock=True, region="us", model_id="x"), MockLLMService)


def test_bedrock_llm_success_paths() -> None:
    service = _make_bedrock_service(_SuccessfulBedrockClient("cleaned"))

    assert service.clean_receipt_notes("dirty") == "cleaned"
    assert service.extract_product_name("raw") == "cleaned"
    assert service.clean_store_name("raw") == "cleaned"
    assert service.clean_phone_number("raw") == "cleaned"
    assert service.clean_email("raw") == "cleaned"
    assert service.clean_address("raw") == "cleaned"


def test_bedrock_llm_failure_falls_back() -> None:
    service = _make_bedrock_service(_FailingBedrockClient())

    assert service.clean_receipt_notes("dirty") == "dirty"
    assert service.extract_product_name("raw") == "raw"
    assert service.clean_store_name("raw") == "raw"
    assert service.clean_phone_number("raw") == "raw"
    assert service.clean_email("raw") == "raw"
    assert service.clean_address("raw") == "raw"


def test_product_image_helpers_and_factory() -> None:
    assert _clean_query("Laptop Pro") == "Laptop Pro"
    assert _is_blocked("https://www.ebay.com/item/1")
    assert _is_trusted("https://www.apple.com/iphone")

    mock = MockProductImageService()
    async_result = __import__("asyncio").run(mock.search_product_image("Camera"))
    sync_result = mock.search_product_image_sync("Camera")
    assert async_result and "imageUrl" in async_result
    assert sync_result and "imageUrl" in sync_result

    assert isinstance(create_product_image_service(use_mock=True), MockProductImageService)
    assert isinstance(
        create_product_image_service(use_mock=False, api_key="token"),
        BraveProductImageService,
    )


def test_brave_product_image_service_async(monkeypatch) -> None:
    payload = {
        "results": [
            {"url": "https://www.random.com/p/1", "properties": {"url": "https://www.random.com/i.jpg"}},
            {"url": "https://www.apple.com/p/2", "properties": {"url": "https://www.apple.com/i.jpg"}},
        ]
    }
    response = _DummyHTTPResponse(payload=payload)
    monkeypatch.setattr(
        "app.services.product_image_service.httpx.AsyncClient",
        lambda timeout: _DummyAsyncClient(response),
    )

    service = BraveProductImageService("token")
    result = __import__("asyncio").run(service.search_product_image("iPhone"))

    assert result is not None
    assert result["imageUrl"].startswith("https://www.apple.com")


def test_brave_product_image_service_sync_error(monkeypatch) -> None:
    response = _DummyHTTPResponse(payload={}, status_code=500, text="boom")
    monkeypatch.setattr(
        "app.services.product_image_service.httpx.Client",
        lambda timeout: _DummySyncClient(response),
    )

    service = BraveProductImageService("token")
    assert service.search_product_image_sync("anything") is None


def test_mock_and_real_s3_service_behaviors() -> None:
    mock = MockS3Service("bucket")
    key = mock.upload_file(b"abc", "k1", "text/plain")
    assert key == "k1"
    assert mock.file_exists("k1")
    assert mock.get_file("k1") == b"abc"
    assert mock.delete_file("k1")
    assert not mock.delete_file("k1")

    bulk = mock.delete_files_bulk(["a", "b"])
    assert bulk == {"a": False, "b": False}

    fake_client = _FakeS3Client()
    fake_client.files["ok1"] = b"x"
    service = _make_real_s3_service(fake_client)

    out_key = service.upload_file(b"pdf", "doc.pdf", "application/pdf")
    assert out_key == "doc.pdf"
    assert service.generate_presigned_url("doc.pdf", expiration=120).startswith("https://s3.local")
    assert service.get_file("doc.pdf") == b"pdf"
    assert service.get_file("missing") is None

    assert service.delete_file("doc.pdf")

    bulk_results = service.delete_files_bulk(["ok1", "bad2"])
    assert bulk_results["ok1"] is True
    assert bulk_results["bad2"] is False

    assert not service.file_exists("does-not-exist")


def test_textract_geometry_helpers() -> None:
    region = {"Left": 0.1, "Top": 0.1, "Width": 0.6, "Height": 0.6}
    bbox_inside = {"Left": 0.2, "Top": 0.2, "Width": 0.2, "Height": 0.2}
    bbox_outside = {"Left": 0.9, "Top": 0.9, "Width": 0.05, "Height": 0.05}

    assert RealTextractService._boxes_overlap(region, bbox_inside)
    assert not RealTextractService._boxes_overlap(region, bbox_outside)

    blocks = [
        {"BlockType": "LINE", "Text": "L1", "Geometry": {"BoundingBox": {"Left": 0.15, "Top": 0.20, "Width": 0.10, "Height": 0.02}}},
        {"BlockType": "LINE", "Text": "L2", "Geometry": {"BoundingBox": {"Left": 0.16, "Top": 0.30, "Width": 0.10, "Height": 0.02}}},
        {"BlockType": "LINE", "Text": "R1", "Geometry": {"BoundingBox": {"Left": 0.55, "Top": 0.20, "Width": 0.10, "Height": 0.02}}},
    ]
    text = RealTextractService._reconstruct_column_text(blocks, region)
    assert "L1" in text and "R1" in text


def test_textract_parse_response_extracts_fields_and_line_items() -> None:
    service = RealTextractService.__new__(RealTextractService)
    service.llm_service = _DummyLLM()

    note_bbox = {"Left": 0.1, "Top": 0.4, "Width": 0.7, "Height": 0.2}
    response = {
        "ExpenseDocuments": [
            {
                "SummaryFields": [
                    {"Type": {"Text": "VENDOR_NAME"}, "ValueDetection": {"Text": "DOLL", "Confidence": 90}},
                    {"Type": {"Text": "VENDOR_NAME"}, "ValueDetection": {"Text": "Dellshop.lk", "Confidence": 80}},
                    {"Type": {"Text": "VENDOR_URL"}, "ValueDetection": {"Text": "https://dellshop.lk", "Confidence": 95}},
                    {"Type": {"Text": "INVOICE_RECEIPT_DATE"}, "ValueDetection": {"Text": "2026-04-01", "Confidence": 95}},
                    {"Type": {"Text": "TOTAL"}, "ValueDetection": {"Text": "$123.45", "Confidence": 99}},
                    {
                        "Type": {"Text": "INVOICE_RECEIPT_ID"},
                        "LabelDetection": {"Text": "Invoice No"},
                        "ValueDetection": {"Text": "INV-001", "Confidence": 90},
                    },
                    {"Type": {"Text": "VENDOR_ADDRESS"}, "ValueDetection": {"Text": "123 MAIN ST", "Confidence": 90}},
                    {"Type": {"Text": "VENDOR_PHONE"}, "ValueDetection": {"Text": "123.456.7890", "Confidence": 90}},
                    {
                        "Type": {"Text": "OTHER"},
                        "LabelDetection": {"Text": "Note"},
                        "ValueDetection": {
                            "Text": "Warranty warranty terms terms",
                            "Confidence": 90,
                            "Geometry": {"BoundingBox": note_bbox},
                        },
                    },
                    {
                        "Type": {"Text": "OTHER"},
                        "LabelDetection": {"Text": "Remarks"},
                        "ValueDetection": {"Text": "Serial 123", "Confidence": 88},
                    },
                ],
                "Blocks": [
                    {"BlockType": "LINE", "Text": "left column text", "Confidence": 99, "Geometry": {"BoundingBox": {"Left": 0.11, "Top": 0.41, "Width": 0.20, "Height": 0.02}}},
                    {"BlockType": "LINE", "Text": "right column text", "Confidence": 99, "Geometry": {"BoundingBox": {"Left": 0.50, "Top": 0.41, "Width": 0.20, "Height": 0.02}}},
                    {"BlockType": "LINE", "Text": "support@shop.com", "Confidence": 99, "Geometry": {"BoundingBox": {"Left": 0.10, "Top": 0.20, "Width": 0.20, "Height": 0.02}}},
                ],
                "LineItemGroups": [
                    {
                        "LineItems": [
                            {
                                "LineItemExpenseFields": [
                                    {"Type": {"Text": "PRODUCT_CODE"}, "ValueDetection": {"Text": "SKU1"}},
                                    {"Type": {"Text": "ITEM"}, "ValueDetection": {"Text": "Laptop IMEI 123"}},
                                    {"Type": {"Text": "QUANTITY"}, "ValueDetection": {"Text": "3"}},
                                    {"Type": {"Text": "PRICE"}, "ValueDetection": {"Text": "300.00"}},
                                    {"Type": {"Text": "EXPENSE_ROW"}, "ValueDetection": {"Text": "Warranty 2 years"}},
                                ]
                            }
                        ]
                    }
                ],
            }
        ]
    }

    extracted = service._parse_textract_response(response)

    assert extracted["store_name"] == "Clean-Dellshop.lk"
    assert extracted["invoice_number"] == "INV-001"
    assert extracted["total_amount"] == 123.45
    assert extracted["vendor_email"] == "support@shop.com"
    assert extracted["vendor_phone"].startswith("P:")
    assert extracted["vendor_address"].startswith("A:")
    assert extracted["line_items"][0]["quantity"] == 3
    assert extracted["line_items"][0]["item_description"] == "Laptop"
    assert extracted["warranty_period_months"] == 24


def test_textract_analyze_document_failure_and_factories() -> None:
    class _FailingTextractClient:
        def analyze_expense(self, *args, **kwargs):
            raise _FakeClientError("AccessDenied", "denied")

    service = RealTextractService.__new__(RealTextractService)
    service.s3_bucket = "bucket"
    service.llm_service = None
    service.textract_client = _FailingTextractClient()
    service.ClientError = _FakeClientError

    result = service.analyze_document("doc.pdf")
    assert result["status"] == "failed"

    mock = MockTextractService().analyze_document("doc.pdf")
    assert mock["status"] == "success"

    assert isinstance(get_textract_service("bucket", use_mock=True), MockTextractService)
    assert isinstance(get_s3_service("bucket", use_mock=True), MockS3Service)
