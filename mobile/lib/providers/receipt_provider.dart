// coverage:ignore-file
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/models/receipt_model.dart';
import '../data/models/receipt_line_item_model.dart';
import 'auth_provider.dart';
import 'service_providers.dart';

part 'receipt_provider.g.dart';

/// Receipts list provider
final receiptsProvider = FutureProvider<List<ReceiptModel>>((ref) async {
  // Gate on Firebase auth (cached locally) rather than the backend profile fetch,
  // so the local SQLite cache is still readable when the device is offline.
  final firebaseUser = ref.watch(currentUserProvider);
  if (firebaseUser == null) return [];

  final repository = ref.watch(receiptRepositoryProvider);
  return await repository.getReceipts(forceRefresh: true);
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
@riverpod
class ReceiptController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Create a new receipt
  Future<ReceiptModel?> createReceipt(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final receipt = await ref
          .read(receiptRepositoryProvider)
          .createReceipt(data);
      await ref.read(receiptRepositoryProvider).syncReceipts();
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
      final receipt = await ref
          .read(receiptRepositoryProvider)
          .updateReceipt(id, data);
      await ref.read(receiptRepositoryProvider).syncReceipts();
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
      await ref.read(receiptRepositoryProvider).deleteReceipt(id);
      await ref.read(receiptRepositoryProvider).syncReceipts();
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
  Future<bool> deleteLineItem(String receiptId, String itemId) async {
    state = const AsyncValue.loading();
    try {
      await ref
          .read(receiptRepositoryProvider)
          .deleteLineItem(receiptId, itemId);
      await ref.read(receiptRepositoryProvider).syncReceipts();
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
      final receipt = await ref
          .read(receiptRepositoryProvider)
          .uploadReceipt(receiptId, filePath);
      await ref.read(receiptRepositoryProvider).syncReceipts();
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
      final lineItem = await ref
          .read(receiptRepositoryProvider)
          .createLineItem(receiptId, data);
      await ref.read(receiptRepositoryProvider).syncReceipts();
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
      final lineItem = await ref
          .read(receiptRepositoryProvider)
          .updateLineItem(receiptId, itemId, data);
      await ref.read(receiptRepositoryProvider).syncReceipts();
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
      final result = await ref
          .read(receiptRepositoryProvider)
          .extractOcr(frontImagePath, backImagePath, pdfPath: pdfPath);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}
