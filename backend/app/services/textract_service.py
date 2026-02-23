"""
AWS Textract Service for Smart Receipt & Warranty Manager.
Real implementation extracts all structured fields from receipts/invoices.
Mock implementation for development without AWS credentials.
"""

import logging
import re
import random
from typing import Dict, Any, Optional, List
from datetime import datetime, timedelta

logger = logging.getLogger(__name__)


class MockTextractService:
    """Mock Textract service for development without AWS credentials."""
    
    def __init__(self):
        """Initialize mock Textract service."""
        logger.info("MockTextractService initialized")
    
    def analyze_document(self, s3_object_key: str) -> Dict[str, Any]:
        """
        Mock analyze document with OCR.
        Returns simulated receipt data.
        
        Args:
            s3_object_key: S3 object key of the document
            
        Returns:
            Mock OCR result dictionary
        """
        logger.info(f"[MOCK] Analyzing document: {s3_object_key}")
        
        # Simulate processing delay
        import time
        time.sleep(0.5)
        
        # Generate mock receipt data
        mock_stores = ["Target", "Walmart", "Best Buy", "Amazon", "Home Depot", "Costco"]
        mock_products = ["Laptop", "Smartphone", "TV", "Headphones", "Camera", "Tablet"]
        
        mock_result = {
            "status": "success",
            "extracted_data": {
                "store_name": random.choice(mock_stores),
                "purchase_date": (datetime.now() - timedelta(days=random.randint(1, 90))).isoformat(),
                "total_amount": round(random.uniform(50.0, 2000.0), 2),
                "currency": "USD",
                "product_name": random.choice(mock_products),
                "warranty_period_months": random.choice([6, 12, 24, 36]),
            },
            "confidence": round(random.uniform(0.85, 0.99), 2),
            "raw_text": f"""
RECEIPT
Store: {random.choice(mock_stores)}
Date: {datetime.now().strftime('%Y-%m-%d')}
Product: {random.choice(mock_products)}
Total: ${round(random.uniform(50.0, 2000.0), 2)}
Warranty: {random.choice([6, 12, 24])} months
            """.strip()
        }
        
        logger.info(f"[MOCK] OCR completed for: {s3_object_key} - Store: {mock_result['extracted_data']['store_name']}")
        
        return mock_result
    
    def analyze_expense(self, s3_object_key: str) -> Dict[str, Any]:
        """
        Mock analyze expense document (alternative Textract API).
        
        Args:
            s3_object_key: S3 object key of the document
            
        Returns:
            Mock expense analysis result
        """
        logger.info(f"[MOCK] Analyzing expense: {s3_object_key}")
        
        # Use same mock data as analyze_document
        return self.analyze_document(s3_object_key)


class RealTextractService:
    """Real AWS Textract service using boto3."""
    
    def __init__(self, s3_bucket: str, region: str = 'us-east-1'):
        """
        Initialize real Textract service.
        
        Args:
            s3_bucket: S3 bucket name for document location
            region: AWS region (default: us-east-1)
        """
        import boto3
        from botocore.exceptions import ClientError
        
        self.s3_bucket = s3_bucket
        self.textract_client = boto3.client(
            'textract',
            region_name=region
        )
        self.ClientError = ClientError
        logger.info(f"RealTextractService initialized for bucket: {s3_bucket} in region: {region}")
    
    def analyze_document(self, s3_object_key: str) -> Dict[str, Any]:
        """
        Analyze document using real AWS Textract.
        
        Args:
            s3_object_key: S3 object key of the document
            
        Returns:
            Textract analysis result
        """
        try:
            logger.info(f"Analyzing document with Textract: {s3_object_key}")
            
            # Call Textract AnalyzeExpense API (best for receipts)
            response = self.textract_client.analyze_expense(
                Document={
                    'S3Object': {
                        'Bucket': self.s3_bucket,
                        'Name': s3_object_key
                    }
                }
            )
            
            # Parse Textract response
            extracted_data = self._parse_textract_response(response)
            
            logger.info(f"Textract analysis completed for: {s3_object_key}")
            
            return {
                "status": "success",
                "extracted_data": extracted_data,
                "raw_response": response
            }
        
        except self.ClientError as e:
            logger.error(f"Textract analysis failed: {e}")
            return {
                "status": "failed",
                "error": str(e),
                "extracted_data": {}
            }
    
    def _parse_textract_response(self, response: Dict[str, Any]) -> Dict[str, Any]:
        """
        Parse Textract AnalyzeExpense response to extract all structured fields.

        Strategy: collect every detection for each field type and keep the one
        with the highest ValueDetection.Confidence, eliminating the first-match
        bug that previously caused low-confidence values to win.

        Extracts:
          - store_name, purchase_date, total_amount, invoice_number
          - vendor_address, vendor_phone, vendor_url, vendor_email
          - remarks (OTHER/Remarks), warranty_notes (OTHER/Note)
          - line_items list with product_code, item_description,
            quantity, unit_price, amount per row
          - warranty_period_months (from line item EXPENSE_ROW text)
        """
        extracted: Dict[str, Any] = {}

        if 'ExpenseDocuments' not in response:
            return extracted

        # ── helper ──────────────────────────────────────────────────────────
        # _best tracks (value, confidence) per logical key; only keep highest.
        _best: Dict[str, tuple] = {}

        def _keep_best(key: str, value: str, confidence: float) -> None:
            """Store value only if it improves on current best confidence."""
            if value and value.strip() and (
                key not in _best or confidence > _best[key][1]
            ):
                _best[key] = (value.strip(), confidence)

        # Currency symbols / codes to strip when parsing amounts
        _AMOUNT_JUNK = re.compile(r'[^\d.]')
        _WARRANTY_PATTERN = re.compile(
            r'(\d+)\s*(year|yr|month|mo)', re.IGNORECASE
        )
        _EMAIL_PATTERN = re.compile(
            r'[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}'
        )

        for doc in response['ExpenseDocuments']:

            # ────────────────────────────────────────────────────────────────
            # 1. Summary Fields
            # ────────────────────────────────────────────────────────────────
            # Collect all VENDOR_NAME candidates for URL cross-check later
            _vendor_name_candidates: List[tuple] = []  # (value, confidence)

            for field in doc.get('SummaryFields', []):
                field_type  = field.get('Type', {}).get('Text', '') or ''
                value_det   = field.get('ValueDetection', {}) or {}
                value       = value_det.get('Text', '') or ''
                confidence  = float(value_det.get('Confidence', 0))
                label_text  = (field.get('LabelDetection', {}) or {}).get('Text', '') or ''

                if field_type == 'VENDOR_NAME':
                    if value and value.strip():
                        _vendor_name_candidates.append((value.strip(), confidence))

                elif field_type == 'INVOICE_RECEIPT_DATE':
                    _keep_best('purchase_date', value, confidence)

                elif field_type == 'TOTAL':
                    _keep_best('total_amount_raw', value, confidence)

                elif field_type == 'INVOICE_RECEIPT_ID':
                    # Prefer the labelled "Invoice No." over a bare number
                    bonus = 5.0 if 'invoice' in label_text.lower() else 0.0
                    _keep_best('invoice_number', value, confidence + bonus)

                elif field_type in ('VENDOR_ADDRESS', 'ADDRESS_BLOCK'):
                    _keep_best('vendor_address', value, confidence)

                elif field_type == 'VENDOR_PHONE':
                    _keep_best('vendor_phone', value, confidence)

                elif field_type == 'VENDOR_URL':
                    _keep_best('vendor_url', value, confidence)

                elif field_type == 'OTHER':
                    label_lower = label_text.lower()
                    if 'remark' in label_lower:
                        _keep_best('remarks', value, confidence)
                    elif 'note' in label_lower:
                        _keep_best('warranty_notes', value, confidence)

            # ── flush best candidates into extracted ────────────────────────
            for key, (val, _conf) in _best.items():
                extracted[key] = val
            _best.clear()

            # ── VENDOR_NAME: prefer URL-corroborated candidate ────────────────
            # Textract sometimes assigns higher confidence to a logo mis-read
            # (e.g. "DOLL" from a stylised "Dell" graphic) over the correct
            # text form ("Dellshop.lk"). Cross-check against VENDOR_URL: any
            # candidate whose text appears in the URL domain wins, regardless
            # of raw confidence.
            if _vendor_name_candidates:
                vendor_url = extracted.get('vendor_url', '')
                url_domain = vendor_url.lower().replace('www.', '') if vendor_url else ''
                url_domain_root = url_domain.split('.')[0] if url_domain else ''

                chosen_name = None
                if url_domain_root:
                    for cand_val, cand_conf in _vendor_name_candidates:
                        if url_domain_root in cand_val.lower():
                            chosen_name = cand_val
                            break

                if chosen_name is None:
                    # No URL match — fall back to highest confidence
                    chosen_name = max(_vendor_name_candidates, key=lambda x: x[1])[0]

                extracted['store_name'] = chosen_name

            # ── parse total_amount from raw string ──────────────────────────
            if 'total_amount_raw' in extracted:
                raw = extracted.pop('total_amount_raw')
                clean = _AMOUNT_JUNK.sub('', raw.replace(',', ''))
                try:
                    extracted['total_amount'] = float(clean)
                except ValueError:
                    logger.warning(f"Could not parse total_amount from: {raw!r}")

            # ────────────────────────────────────────────────────────────────
            # 2. Vendor email — Textract has no VENDOR_EMAIL field type;
            #    the email only appears as a raw LINE block in the response.
            # ────────────────────────────────────────────────────────────────
            best_email_conf = 0.0
            for block in response.get('Blocks', []):
                if block.get('BlockType') != 'LINE':
                    continue
                text = (block.get('Text') or '').strip()
                conf = float(block.get('Confidence', 0))
                if _EMAIL_PATTERN.fullmatch(text) and conf > best_email_conf:
                    extracted['vendor_email'] = text
                    best_email_conf = conf

            # ────────────────────────────────────────────────────────────────
            # 3. Line Items — full multi-item support
            # ────────────────────────────────────────────────────────────────
            line_items: List[Dict[str, Any]] = []
            warranty_from_rows: Optional[int] = None

            for group in doc.get('LineItemGroups', []):
                for row_idx, row in enumerate(group.get('LineItems', [])):
                    item: Dict[str, Any] = {'row_index': row_idx}
                    row_text = ''  # Full row text from EXPENSE_ROW field

                    for lf in row.get('LineItemExpenseFields', []):
                        lf_type  = (lf.get('Type', {}) or {}).get('Text', '') or ''
                        lf_value = (lf.get('ValueDetection', {}) or {}).get('Text', '') or ''

                        if lf_type == 'PRODUCT_CODE':
                            item['product_code'] = lf_value.strip()

                        elif lf_type == 'ITEM':
                            item['item_description'] = lf_value.strip()

                        elif lf_type == 'QUANTITY':
                            item['quantity'] = lf_value.strip()

                        elif lf_type in ('UNIT_PRICE', 'RATE'):
                            clean = _AMOUNT_JUNK.sub('', lf_value.replace(',', ''))
                            try:
                                item['unit_price'] = float(clean)
                            except ValueError:
                                item['unit_price_raw'] = lf_value.strip()

                        elif lf_type in ('PRICE', 'AMOUNT'):
                            clean = _AMOUNT_JUNK.sub('', lf_value.replace(',', ''))
                            try:
                                item['amount'] = float(clean)
                            except ValueError:
                                item['amount_raw'] = lf_value.strip()

                        elif lf_type == 'EXPENSE_ROW':
                            # AWS Textract stores the full row text as a typed
                            # field entry inside LineItemExpenseFields, NOT as
                            # a top-level 'ExpenseRow' key on the row dict.
                            row_text = lf_value

                    # Search the full row text for a warranty period pattern,
                    # e.g. "3YEARS" or "12 months" embedded in EXPENSE_ROW.
                    match = _WARRANTY_PATTERN.search(row_text)
                    if match and warranty_from_rows is None:
                        num  = int(match.group(1))
                        unit = match.group(2).lower()
                        warranty_from_rows = num * 12 if unit.startswith('y') else num

                    # Only append rows that have at least one useful field
                    if any(k in item for k in (
                        'product_code', 'item_description',
                        'quantity', 'unit_price', 'amount'
                    )):
                        line_items.append(item)

            if line_items:
                extracted['line_items'] = line_items
                # If single-item receipt and no product name yet, backfill it
                if len(line_items) == 1 and not extracted.get('product_name'):
                    extracted['product_name'] = line_items[0].get('item_description')

            # Warranty from rows only if not already found in summary fields
            if warranty_from_rows and not extracted.get('warranty_period_months'):
                extracted['warranty_period_months'] = warranty_from_rows

        logger.debug(f"Textract extracted fields: {list(extracted.keys())}")
        return extracted
    
    def analyze_expense(self, s3_object_key: str) -> Dict[str, Any]:
        """
        Analyze expense document using Textract AnalyzeExpense API.
        This is optimized for receipts and invoices.
        
        Args:
            s3_object_key: S3 object key of the document
            
        Returns:
            Textract expense analysis result
        """
        return self.analyze_document(s3_object_key)


def get_textract_service(s3_bucket: str, use_mock: bool = True, region: str = 'us-east-1'):
    """
    Factory function to get Textract service (mock or real).
    
    Args:
        s3_bucket: S3 bucket name
        use_mock: If True, return mock service; if False, return real service
        region: AWS region (default: us-east-1)
        
    Returns:
        Textract service instance (mock or real)
    """
    if use_mock:
        return MockTextractService()
    else:
        return RealTextractService(s3_bucket, region)
