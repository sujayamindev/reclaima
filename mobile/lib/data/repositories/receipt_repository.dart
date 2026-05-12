// coverage:ignore-file
import 'package:drift/drift.dart';
import '../../services/receipt_service.dart';
import '../database/app_database.dart';
import '../models/receipt_model.dart';
import '../models/receipt_line_item_model.dart';

/// Repository that coordinates between local database and remote API
class ReceiptRepository {
  final ReceiptService _remoteService;
  final AppDatabase _localDb;

  ReceiptRepository(this._remoteService, this._localDb);

  /// Get receipts - Offline First
  Future<List<ReceiptModel>> getReceipts({bool forceRefresh = false}) async {
    final localReceipts = await _localDb.getAllReceipts();
    final models = localReceipts.map((r) => _mapToModel(r)).toList();

    if (models.isEmpty || forceRefresh) {
      return await syncReceipts();
    }

    _syncInBackground();
    return models;
  }

  /// Sync all receipts from remote to local
  Future<List<ReceiptModel>> syncReceipts() async {
    final remoteReceipts = await _remoteService.getReceipts();
    await _saveToLocal(remoteReceipts);
    return remoteReceipts;
  }

  Future<void> _syncInBackground() async {
    try {
      await syncReceipts();
    } catch (_) {}
  }

  Future<void> _saveToLocal(List<ReceiptModel> remoteReceipts) async {
    await _localDb.transaction(() async {
      for (final r in remoteReceipts) {
        await _localDb.upsertReceipt(_mapToCompanion(r));
      }
    });
  }

  // Wrapper methods for remote service to centralize API calls
  Future<ReceiptModel> createReceipt(Map<String, dynamic> data) =>
      _remoteService.createReceipt(data);
  Future<ReceiptModel> updateReceipt(String id, Map<String, dynamic> data) =>
      _remoteService.updateReceipt(id, data);
  Future<void> deleteReceipt(String id) => _remoteService.deleteReceipt(id);
  Future<void> deleteLineItem(String receiptId, String itemId) =>
      _remoteService.deleteLineItem(receiptId, itemId);
  Future<ReceiptModel> uploadReceipt(String receiptId, String filePath) =>
      _remoteService.uploadReceipt(receiptId, filePath);
  Future<ReceiptLineItemModel> createLineItem(
    String receiptId,
    Map<String, dynamic> data,
  ) => _remoteService.createLineItem(receiptId, data);
  Future<ReceiptLineItemModel> updateLineItem(
    String receiptId,
    String itemId,
    Map<String, dynamic> data,
  ) => _remoteService.updateLineItem(receiptId, itemId, data);
  Future<Map<String, dynamic>> extractOcr(
    String? front,
    String? back, {
    String? pdfPath,
  }) => _remoteService.extractOcr(front, back, pdfPath: pdfPath);

  ReceiptModel _mapToModel(Receipt r) {
    return ReceiptModel(
      id: r.id,
      userId: r.userId,
      storeName: r.storeName,
      purchaseDate: r.purchaseDate,
      totalAmount: r.totalAmount,
      currency: r.currency,
      status: _parseStatus(r.status),
      ocrRetryCount: r.ocrRetryCount,
      lastOcrAttemptAt: r.lastOcrAttemptAt,
      notes: r.notes,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
      syncedAt: r.syncedAt,
      invoiceNumber: r.invoiceNumber,
      vendorAddress: r.vendorAddress,
      vendorPhone: r.vendorPhone,
      vendorEmail: r.vendorEmail,
      vendorUrl: r.vendorUrl,
      remarks: r.remarks,
      warrantyNotes: r.warrantyNotes,
      lineItems: [],
    );
  }

  ReceiptsCompanion _mapToCompanion(ReceiptModel m) {
    return ReceiptsCompanion(
      id: Value(m.id),
      userId: Value(m.userId),
      storeName: Value(m.storeName),
      purchaseDate: Value(m.purchaseDate),
      totalAmount: Value(m.totalAmount),
      currency: Value(m.currency),
      status: Value(m.status.toString().split('.').last.toUpperCase()),
      ocrRetryCount: Value(m.ocrRetryCount),
      lastOcrAttemptAt: Value(m.lastOcrAttemptAt),
      notes: Value(m.notes),
      createdAt: Value(m.createdAt),
      updatedAt: Value(m.updatedAt),
      syncedAt: Value(m.syncedAt ?? DateTime.now()),
      invoiceNumber: Value(m.invoiceNumber),
      vendorAddress: Value(m.vendorAddress),
      vendorPhone: Value(m.vendorPhone),
      vendorEmail: Value(m.vendorEmail),
      vendorUrl: Value(m.vendorUrl),
      remarks: Value(m.remarks),
      warrantyNotes: Value(m.warrantyNotes),
    );
  }

  ReceiptStatus _parseStatus(String status) {
    final s = status.toUpperCase();
    if (s == 'COMPLETED') return ReceiptStatus.completed;
    if (s == 'PROCESSING') return ReceiptStatus.processing;
    if (s == 'OCR_FAILED') return ReceiptStatus.ocrFailed;
    if (s == 'UPLOADED') return ReceiptStatus.uploaded;
    if (s == 'MANUAL_ENTRY') return ReceiptStatus.manualEntry;
    return ReceiptStatus.localOnly;
  }
}
