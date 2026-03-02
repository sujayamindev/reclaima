import 'package:dio/dio.dart';
import '../core/utils/logger.dart';
import '../data/models/receipt_model.dart';
import '../data/models/receipt_line_item_model.dart';
import 'api_service.dart';
import '../core/constants/app_constants.dart';

/// Receipt service
class ReceiptService {
  final ApiService _apiService;
  
  ReceiptService(this._apiService);
  
  /// Get all receipts with optional pagination
  Future<List<ReceiptModel>> getReceipts({
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final response = await _apiService.get(
        ApiConstants.receipts,
        queryParameters: {
          'skip': skip,
          'limit': limit,
        },
      );
      
      // Handle response data - could be List or Map
      final dynamic data = response.data;
      
      if (data is List) {
        return data.map((json) => ReceiptModel.fromJson(json)).toList();
      } else if (data is Map<String, dynamic>) {
        // Handle paginated response - backend returns {receipts: [], total: 0, ...}
        if (data.containsKey('receipts')) {
          final List<dynamic> items = data['receipts'];
          return items.map((json) => ReceiptModel.fromJson(json)).toList();
        } else if (data.containsKey('items')) {
          final List<dynamic> items = data['items'];
          return items.map((json) => ReceiptModel.fromJson(json)).toList();
        } else if (data.containsKey('data')) {
          final List<dynamic> items = data['data'];
          return items.map((json) => ReceiptModel.fromJson(json)).toList();
        }
      }
      
      // If neither format matches, return empty list
      logger.w('Unexpected response format: $data');
      return [];
    } catch (e) {
      logger.e('Error getting receipts: $e');
      rethrow;
    }
  }
  
  /// Get single receipt by ID
  Future<ReceiptModel> getReceipt(String id) async {
    try {
      final response = await _apiService.get('${ApiConstants.receipts}/$id');
      return ReceiptModel.fromJson(response.data);
    } catch (e) {
      logger.e('Error getting receipt $id: $e');
      rethrow;
    }
  }
  
  /// Create a new receipt
  Future<ReceiptModel> createReceipt(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post(
        ApiConstants.receipts,
        data: data,
      );
      return ReceiptModel.fromJson(response.data);
    } catch (e) {
      logger.e('Error creating receipt: $e');
      rethrow;
    }
  }
  
  /// Update receipt
  Future<ReceiptModel> updateReceipt(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiService.patch(
        '${ApiConstants.receipts}/$id',
        data: data,
      );
      return ReceiptModel.fromJson(response.data);
    } catch (e) {
      logger.e('Error updating receipt $id: $e');
      rethrow;
    }
  }
  
  /// Delete receipt
  Future<void> deleteReceipt(String id) async {
    try {
      await _apiService.delete('${ApiConstants.receipts}/$id');
    } catch (e) {
      logger.e('Error deleting receipt $id: $e');
      rethrow;
    }
  }
  
  /// Upload receipt file
  Future<ReceiptModel> uploadReceipt(
    String receiptId,
    String filePath, {
    ProgressCallback? onProgress,
  }) async {
    try {
      logger.i('Uploading receipt file: $filePath');
      
      final response = await _apiService.uploadFile(
        '${ApiConstants.receipts}/$receiptId/upload',
        filePath,
        onSendProgress: onProgress,
      );
      
      return ReceiptModel.fromJson(response.data);
    } catch (e) {
      logger.e('Error uploading receipt: $e');
      rethrow;
    }
  }
  
  /// Retry OCR processing
  Future<ReceiptModel> retryOcr(String receiptId) async {
    try {
      final response = await _apiService.post(
        '${ApiConstants.receipts}/$receiptId/retry-ocr',
      );
      return ReceiptModel.fromJson(response.data);
    } catch (e) {
      logger.e('Error retrying OCR for receipt $receiptId: $e');
      rethrow;
    }
  }

  /// Get pre-signed S3 URL for viewing the receipt image.
  /// Returns null if the receipt has no uploaded image or on any error.
  Future<String?> getReceiptImageUrl(String receiptId) async {
    try {
      final response = await _apiService.get(
        '${ApiConstants.receipts}/$receiptId/image-url',
      );
      return response.data['url'] as String?;
    } catch (e) {
      logger.w('Could not get image URL for receipt $receiptId: $e');
      return null;
    }
  }

  /// Create a new line item on a receipt (used for manual-entry receipts
  /// that have no OCR-generated items yet).
  Future<ReceiptLineItemModel> createLineItem(
    String receiptId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiService.post(
        '${ApiConstants.receipts}/$receiptId/items',
        data: data,
      );
      return ReceiptLineItemModel.fromJson(response.data);
    } catch (e) {
      logger.e('Error creating line item on receipt $receiptId: $e');
      rethrow;
    }
  }

  /// Update a single line item (product name, category, warranty period,
  /// return period). Expiry dates are computed server-side.
  Future<ReceiptLineItemModel> updateLineItem(
    String receiptId,
    String itemId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiService.patch(
        '${ApiConstants.receipts}/$receiptId/items/$itemId',
        data: data,
      );
      return ReceiptLineItemModel.fromJson(response.data);
    } catch (e) {
      logger.e('Error updating line item $itemId on receipt $receiptId: $e');
      rethrow;
    }
  }

  /// Upload a receipt image to S3, run OCR, and return extracted data.
  ///
  /// Does NOT create a receipt record in the database. The [s3ObjectKey]
  /// returned in the map should be passed to [createReceipt] when the user
  /// saves on the confirmation screen.
  Future<Map<String, dynamic>> extractOcr(String filePath) async {
    try {
      logger.i('OCR extract: uploading $filePath');
      final response = await _apiService.uploadFile(
        '${ApiConstants.receipts}/ocr-extract',
        filePath,
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      logger.e('Error during OCR extract: $e');
      rethrow;
    }
  }
}
