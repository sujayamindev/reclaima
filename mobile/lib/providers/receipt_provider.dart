import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/receipt_model.dart';
import '../data/models/receipt_line_item_model.dart';
import '../services/receipt_service.dart';
import 'auth_provider.dart';
import 'service_providers.dart';

/// Receipts list provider
///
/// Waits for [userProfileProvider] to resolve first so that the backend user
/// record is guaranteed to exist before we query /receipts. This prevents a
/// 500 race-condition where the HomeScreen loads and hits GET /receipts before
/// POST /auth/register has finished creating the user row.
final receiptsProvider = FutureProvider<List<ReceiptModel>>((ref) async {
  // Block until the user profile is confirmed (or confirmed absent).
  // userProfileProvider already handles auto-registration internally.
  await ref.watch(userProfileProvider.future);

  final receiptService = ref.watch(receiptServiceProvider);
  return await receiptService.getReceipts();
});

/// Single receipt provider
final receiptProvider = FutureProvider.family<ReceiptModel, String>((ref, id) async {
  final receiptService = ref.watch(receiptServiceProvider);
  return await receiptService.getReceipt(id);
});

/// Pre-signed S3 URL provider for the receipt image.
/// Returns null if the receipt has no uploaded image.
final receiptImageUrlProvider = FutureProvider.family<String?, String>((ref, receiptId) async {
  final receiptService = ref.watch(receiptServiceProvider);
  return await receiptService.getReceiptImageUrl(receiptId);
});

/// Receipt Controller
class ReceiptController extends StateNotifier<AsyncValue<void>> {
  final ReceiptService _receiptService;
  
  ReceiptController(this._receiptService) : super(const AsyncValue.data(null));
  
  /// Create a new receipt
  Future<ReceiptModel?> createReceipt(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    
    try {
      final receipt = await _receiptService.createReceipt(data);
      state = const AsyncValue.data(null);
      return receipt;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
  
  /// Update receipt
  Future<ReceiptModel?> updateReceipt(
    String id,
    Map<String, dynamic> data,
  ) async {
    state = const AsyncValue.loading();
    
    try {
      final receipt = await _receiptService.updateReceipt(id, data);
      state = const AsyncValue.data(null);
      return receipt;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
  
  /// Delete receipt
  Future<bool> deleteReceipt(String id) async {
    state = const AsyncValue.loading();
    
    try {
      await _receiptService.deleteReceipt(id);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
  
  /// Upload receipt file
  Future<ReceiptModel?> uploadReceipt(
    String receiptId,
    String filePath,
  ) async {
    state = const AsyncValue.loading();
    
    try {
      final receipt = await _receiptService.uploadReceipt(
        receiptId,
        filePath,
      );
      state = const AsyncValue.data(null);
      return receipt;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
  
  /// Retry OCR processing
  Future<ReceiptModel?> retryOcr(String receiptId) async {
    state = const AsyncValue.loading();
    
    try {
      final receipt = await _receiptService.retryOcr(receiptId);
      state = const AsyncValue.data(null);
      return receipt;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Create a new line item on a receipt (for manual-entry receipts).
  Future<ReceiptLineItemModel?> createLineItem(
    String receiptId,
    Map<String, dynamic> data,
  ) async {
    state = const AsyncValue.loading();

    try {
      final lineItem =
          await _receiptService.createLineItem(receiptId, data);
      state = const AsyncValue.data(null);
      return lineItem;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Update a single line item's product / warranty fields.
  Future<ReceiptLineItemModel?> updateLineItem(
    String receiptId,
    String itemId,
    Map<String, dynamic> data,
  ) async {
    state = const AsyncValue.loading();

    try {
      final lineItem =
          await _receiptService.updateLineItem(receiptId, itemId, data);
      state = const AsyncValue.data(null);
      return lineItem;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Upload image to S3 and run OCR without creating a receipt record.
  ///
  /// Returns the OCR-extracted data map (camelCase keys) including
  /// [s3ObjectKey] on success, or null on error.
  Future<Map<String, dynamic>?> extractOcr(String filePath) async {
    state = const AsyncValue.loading();

    try {
      final result = await _receiptService.extractOcr(filePath);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

/// Receipt controller provider
final receiptControllerProvider =
    StateNotifierProvider<ReceiptController, AsyncValue<void>>((ref) {
  final receiptService = ref.watch(receiptServiceProvider);
  return ReceiptController(receiptService);
});
