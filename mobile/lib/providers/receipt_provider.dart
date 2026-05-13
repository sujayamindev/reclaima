// coverage:ignore-file
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/receipt_model.dart';
import '../data/models/receipt_line_item_model.dart';
import '../data/repositories/receipt_repository.dart';
import 'auth_provider.dart';
import 'service_providers.dart';

/// Receipts list provider
final receiptsProvider = FutureProvider<List<ReceiptModel>>((ref) async {
  // Gate on Firebase auth (cached locally) rather than the backend profile fetch,
  // so the local SQLite cache is still readable when the device is offline.
  final firebaseUser = ref.watch(currentUserProvider);
  if (firebaseUser == null) return [];

  final repository = ref.watch(receiptRepositoryProvider);
  return await repository.getReceipts();
});

/// Single receipt provider
final receiptProvider = FutureProvider.family<ReceiptModel, String>((
  ref,
  id,
) async {
  final receiptService = ref.watch(receiptServiceProvider);
  return await receiptService.getReceipt(id);
});

/// Pre-signed S3 URL provider
final receiptImageUrlProvider = FutureProvider.family<String?, String>((
  ref,
  receiptId,
) async {
  final receiptService = ref.watch(receiptServiceProvider);
  return await receiptService.getReceiptImageUrl(receiptId);
});

/// Receipt Controller
class ReceiptController extends StateNotifier<AsyncValue<void>> {
  final ReceiptRepository _repository;

  ReceiptController(this._repository) : super(const AsyncValue.data(null));

  /// Create a new receipt
  Future<ReceiptModel?> createReceipt(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final receipt = await _repository.createReceipt(data);
      await _repository.syncReceipts();
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
      final receipt = await _repository.updateReceipt(id, data);
      await _repository.syncReceipts();
      state = const AsyncValue.data(null);
      return receipt;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Delete receipt
  Future<bool> deleteReceipt(String id, WidgetRef ref) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteReceipt(id);
      await _repository.syncReceipts();
      ref.invalidate(receiptsProvider);
      ref.invalidate(receiptProvider(id));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Delete a single line item
  Future<bool> deleteLineItem(
    String receiptId,
    String itemId,
    WidgetRef ref,
  ) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteLineItem(receiptId, itemId);
      await _repository.syncReceipts();
      ref.invalidate(receiptsProvider);
      ref.invalidate(receiptProvider(receiptId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Upload receipt file
  Future<ReceiptModel?> uploadReceipt(String receiptId, String filePath) async {
    state = const AsyncValue.loading();
    try {
      final receipt = await _repository.uploadReceipt(receiptId, filePath);
      await _repository.syncReceipts();
      state = const AsyncValue.data(null);
      return receipt;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Create a new line item
  Future<ReceiptLineItemModel?> createLineItem(
    String receiptId,
    Map<String, dynamic> data,
  ) async {
    state = const AsyncValue.loading();
    try {
      final lineItem = await _repository.createLineItem(receiptId, data);
      await _repository.syncReceipts();
      state = const AsyncValue.data(null);
      return lineItem;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Update a single line item
  Future<ReceiptLineItemModel?> updateLineItem(
    String receiptId,
    String itemId,
    Map<String, dynamic> data,
  ) async {
    state = const AsyncValue.loading();
    try {
      final lineItem = await _repository.updateLineItem(
        receiptId,
        itemId,
        data,
      );
      await _repository.syncReceipts();
      state = const AsyncValue.data(null);
      return lineItem;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Extract OCR
  Future<Map<String, dynamic>?> extractOcr(
    String? frontImagePath,
    String? backImagePath, {
    String? pdfPath,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.extractOcr(
        frontImagePath,
        backImagePath,
        pdfPath: pdfPath,
      );
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
      final repository = ref.watch(receiptRepositoryProvider);
      return ReceiptController(repository);
    });
