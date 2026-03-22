"""
Mock AWS S3 Service for development.
Simulates S3 operations without requiring real AWS credentials.
"""

import logging
import os
import uuid
from typing import Optional
from datetime import datetime, timedelta

logger = logging.getLogger(__name__)


class MockS3Service:
    """Mock S3 service for development without AWS credentials."""
    
    def __init__(self, bucket_name: str):
        """
        Initialize mock S3 service.
        
        Args:
            bucket_name: S3 bucket name (simulated)
        """
        self.bucket_name = bucket_name
        self.storage: dict[str, bytes] = {}  # In-memory storage
        logger.info(f"MockS3Service initialized for bucket: {bucket_name}")
    
    def upload_file(
        self,
        file_content: bytes,
        object_key: str,
        content_type: str = "application/octet-stream"
    ) -> str:
        """
        Mock upload file to S3.
        
        Args:
            file_content: File content as bytes
            object_key: S3 object key (path)
            content_type: MIME type of the file
            
        Returns:
            Object key of uploaded file
        """
        # Store file in memory
        self.storage[object_key] = file_content
        
        logger.info(f"[MOCK] Uploaded file to S3: {object_key} ({len(file_content)} bytes, {content_type})")
        
        return object_key
    
    def generate_presigned_url(
        self,
        object_key: str,
        expiration: int = 86400,  # 1 day (24 hours)
        operation: str = "get_object"
    ) -> str:
        """
        Mock generate pre-signed URL for S3 object.

        Args:
            object_key: S3 object key
            expiration: URL expiration time in seconds (default: 1 day)
            operation: Operation type (get_object, put_object)

        Returns:
            Mock pre-signed URL
        """
        # Generate mock pre-signed URL
        mock_url = f"https://mock-s3.amazonaws.com/{self.bucket_name}/{object_key}?expires={expiration}"
        
        logger.info(f"[MOCK] Generated pre-signed URL for: {object_key} (expires in {expiration}s)")
        
        return mock_url
    
    def get_file(self, object_key: str) -> Optional[bytes]:
        """
        Mock get file from S3.
        
        Args:
            object_key: S3 object key
            
        Returns:
            File content as bytes or None if not found
        """
        file_content = self.storage.get(object_key)
        
        if file_content:
            logger.info(f"[MOCK] Retrieved file from S3: {object_key} ({len(file_content)} bytes)")
        else:
            logger.warning(f"[MOCK] File not found in S3: {object_key}")
        
        return file_content
    
    def delete_file(self, object_key: str) -> bool:
        """
        Mock delete file from S3.
        
        Args:
            object_key: S3 object key
            
        Returns:
            True if deleted, False if not found
        """
        if object_key in self.storage:
            del self.storage[object_key]
            logger.info(f"[MOCK] Deleted file from S3: {object_key}")
            return True
        else:
            logger.warning(f"[MOCK] File not found for deletion: {object_key}")
            return False
    
    def file_exists(self, object_key: str) -> bool:
        """
        Check if file exists in mock S3.
        
        Args:
            object_key: S3 object key
            
        Returns:
            True if file exists, False otherwise
        """
        exists = object_key in self.storage
        logger.debug(f"[MOCK] File exists check: {object_key} = {exists}")
        return exists


class RealS3Service:
    """Real AWS S3 service using boto3."""
    
    def __init__(self, bucket_name: str, region: str = 'us-east-1'):
        """
        Initialize real S3 service with boto3.
        
        Args:
            bucket_name: S3 bucket name
            region: AWS region (default: us-east-1)
        """
        import boto3
        from botocore.exceptions import ClientError
        
        self.bucket_name = bucket_name
        self.s3_client = boto3.client(
            's3',
            region_name=region
        )
        self.ClientError = ClientError
        logger.info(f"RealS3Service initialized for bucket: {bucket_name} in region: {region}")
    
    def upload_file(
        self,
        file_content: bytes,
        object_key: str,
        content_type: str = "application/octet-stream"
    ) -> str:
        """
        Upload file to real S3.
        
        Args:
            file_content: File content as bytes
            object_key: S3 object key (path)
            content_type: MIME type of the file
            
        Returns:
            Object key of uploaded file
        """
        try:
            self.s3_client.put_object(
                Bucket=self.bucket_name,
                Key=object_key,
                Body=file_content,
                ContentType=content_type
            )
            logger.info(f"Uploaded file to S3: {object_key} ({len(file_content)} bytes)")
            return object_key
        except self.ClientError as e:
            logger.error(f"Failed to upload file to S3: {e}")
            raise
    
    def generate_presigned_url(
        self,
        object_key: str,
        expiration: int = 86400,  # 1 day (24 hours)
        operation: str = "get_object"
    ) -> str:
        """
        Generate pre-signed URL for S3 object.
        
        Args:
            object_key: S3 object key
            expiration: URL expiration time in seconds
            operation: Operation type (get_object, put_object)
            
        Returns:
            Pre-signed URL
        """
        try:
            url = self.s3_client.generate_presigned_url(
                operation,
                Params={'Bucket': self.bucket_name, 'Key': object_key},
                ExpiresIn=expiration
            )
            logger.info(f"Generated pre-signed URL for: {object_key}")
            return url
        except self.ClientError as e:
            logger.error(f"Failed to generate pre-signed URL: {e}")
            raise
    
    def get_file(self, object_key: str) -> Optional[bytes]:
        """
        Get file from S3.
        
        Args:
            object_key: S3 object key
            
        Returns:
            File content as bytes or None if not found
        """
        try:
            response = self.s3_client.get_object(Bucket=self.bucket_name, Key=object_key)
            content = response['Body'].read()
            logger.info(f"Retrieved file from S3: {object_key}")
            return content
        except self.ClientError as e:
            if e.response['Error']['Code'] == 'NoSuchKey':
                logger.warning(f"File not found in S3: {object_key}")
                return None
            logger.error(f"Failed to get file from S3: {e}")
            raise
    
    def delete_file(self, object_key: str) -> bool:
        """
        Delete file from S3.
        
        Args:
            object_key: S3 object key
            
        Returns:
            True if deleted
        """
        try:
            self.s3_client.delete_object(Bucket=self.bucket_name, Key=object_key)
            logger.info(f"Deleted file from S3: {object_key}")
            return True
        except self.ClientError as e:
            logger.error(f"Failed to delete file from S3: {e}")
            raise
    
    def file_exists(self, object_key: str) -> bool:
        """
        Check if file exists in S3.
        
        Args:
            object_key: S3 object key
            
        Returns:
            True if file exists
        """
        try:
            self.s3_client.head_object(Bucket=self.bucket_name, Key=object_key)
            return True
        except self.ClientError:
            return False


def get_s3_service(bucket_name: str, use_mock: bool = True, region: str = 'us-east-1'):
    """
    Factory function to get S3 service (mock or real).
    
    Args:
        bucket_name: S3 bucket name
        use_mock: If True, return mock service; if False, return real service
        region: AWS region (default: us-east-1)
        
    Returns:
        S3 service instance (mock or real)
    """
    if use_mock:
        return MockS3Service(bucket_name)
    else:
        return RealS3Service(bucket_name, region)
