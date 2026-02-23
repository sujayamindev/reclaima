import 'package:json_annotation/json_annotation.dart';
import 'receipt_line_item_model.dart';

part 'receipt_model.g.dart';

enum ReceiptStatus {
  @JsonValue('LOCAL_ONLY')
  localOnly,
  @JsonValue('UPLOADED')
  uploaded,
  @JsonValue('PROCESSING')
  processing,
  @JsonValue('COMPLETED')
  completed,
  @JsonValue('OCR_FAILED')
  ocrFailed,
  @JsonValue('MANUAL_ENTRY')
  manualEntry,
}

@JsonSerializable()
class ReceiptModel {
  final String id;
  final String userId;
  final String? s3ObjectKey;
  final String? storeName;
  final DateTime? purchaseDate;
  final double? totalAmount;
  final String? currency;
  final String? productName;
  final String? productCategory;
  final int? warrantyPeriodMonths;
  final DateTime? warrantyExpiryDate;
  final int? returnPeriodDays;
  final DateTime? returnExpiryDate;
  final ReceiptStatus status;
  final int ocrRetryCount;
  final DateTime? lastOcrAttemptAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? syncedAt;

  // ── Extended OCR fields ──────────────────────────────────────────────────
  final String? invoiceNumber;
  final String? vendorAddress;
  final String? vendorPhone;
  final String? vendorEmail;
  final String? vendorUrl;
  final String? remarks;        // OCR OTHER/Remarks — serial numbers, etc.
  final String? warrantyNotes;  // OCR OTHER/Note — warranty policy text

  // ── Line items (multi-product receipts) ─────────────────────────────────
  final List<ReceiptLineItemModel> lineItems;

  ReceiptModel({
    required this.id,
    required this.userId,
    this.s3ObjectKey,
    this.storeName,
    this.purchaseDate,
    this.totalAmount,
    this.currency,
    this.productName,
    this.productCategory,
    this.warrantyPeriodMonths,
    this.warrantyExpiryDate,
    this.returnPeriodDays,
    this.returnExpiryDate,
    required this.status,
    required this.ocrRetryCount,
    this.lastOcrAttemptAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.syncedAt,
    this.invoiceNumber,
    this.vendorAddress,
    this.vendorPhone,
    this.vendorEmail,
    this.vendorUrl,
    this.remarks,
    this.warrantyNotes,
    this.lineItems = const [],
  });
  
  factory ReceiptModel.fromJson(Map<String, dynamic> json) =>
      _$ReceiptModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$ReceiptModelToJson(this);
  
  /// Check if warranty is expired
  bool get isWarrantyExpired {
    if (warrantyExpiryDate == null) return false;
    return DateTime.now().isAfter(warrantyExpiryDate!);
  }
  
  /// Check if return window is expired
  bool get isReturnExpired {
    if (returnExpiryDate == null) return false;
    return DateTime.now().isAfter(returnExpiryDate!);
  }
  
  /// Days remaining until warranty expires
  int? get warrantyDaysRemaining {
    if (warrantyExpiryDate == null) return null;
    final days = warrantyExpiryDate!.difference(DateTime.now()).inDays;
    return days < 0 ? 0 : days;
  }
  
  /// Days remaining until return window expires
  int? get returnDaysRemaining {
    if (returnExpiryDate == null) return null;
    final days = returnExpiryDate!.difference(DateTime.now()).inDays;
    return days < 0 ? 0 : days;
  }
}
