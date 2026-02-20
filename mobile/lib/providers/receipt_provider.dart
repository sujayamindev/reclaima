import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/receipt_model.dart';
import '../services/receipt_service.dart';
import 'service_providers.dart';

/// Receipts list provider
final receiptsProvider = FutureProvider<List<ReceiptModel>>((ref) async {
  final receiptService = ref.watch(receiptServiceProvider);
  return await receiptService.getReceipts();
});

/// Single receipt provider
final receiptProvider = FutureProvider.family<ReceiptModel, String>((ref, id) async {
  final receiptService = ref.watch(receiptServiceProvider);
  return await receiptService.getReceipt(id);
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
}

/// Receipt controller provider
final receiptControllerProvider =
    StateNotifierProvider<ReceiptController, AsyncValue<void>>((ref) {
  final receiptService = ref.watch(receiptServiceProvider);
  return ReceiptController(receiptService);
});
