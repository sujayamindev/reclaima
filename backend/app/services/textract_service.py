"""
Mock AWS Textract Service for development.
Simulates OCR operations without requiring real AWS credentials.
"""

import logging
import random
from typing import Dict, Any, Optional
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
        Parse Textract response to extract structured receipt data.
        
        Args:
            response: Raw Textract API response
            
        Returns:
            Structured receipt data
        """
        extracted = {}
        
        # Parse expense documents (receipts)
        if 'ExpenseDocuments' in response:
            for doc in response['ExpenseDocuments']:
                # Extract summary fields
                if 'SummaryFields' in doc:
                    for field in doc['SummaryFields']:
                        field_type = field.get('Type', {}).get('Text', '')
                        field_value = field.get('ValueDetection', {}).get('Text', '')
                        
                        # Map Textract fields to our schema
                        if 'VENDOR_NAME' in field_type:
                            extracted['store_name'] = field_value
                        elif 'INVOICE_RECEIPT_DATE' in field_type:
                            extracted['purchase_date'] = field_value
                        elif 'TOTAL' in field_type:
                            try:
                                extracted['total_amount'] = float(field_value.replace('$', '').replace(',', ''))
                            except ValueError:
                                pass
        
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
