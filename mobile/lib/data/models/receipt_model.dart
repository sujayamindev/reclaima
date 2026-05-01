// coverage:ignore-file
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
  final String? remarks; // OCR OTHER/Remarks — serial numbers, etc.
  final String? warrantyNotes; // OCR OTHER/Note — warranty policy text

  // ── Line items (multi-product receipts) ─────────────────────────────────
  // Product images, warranty & return data all live on individual line items.
  final List<ReceiptLineItemModel> lineItems;

  ReceiptModel({
    required this.id,
    required this.userId,
    this.s3ObjectKey,
    this.storeName,
    this.purchaseDate,
    this.totalAmount,
    this.currency,
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

  // ── Convenience delegation getters ──────────────────────────────────────
  // These read from line items so that screens written before the per-item
  // model migration continue to compile without changes.

  /// Product image URL from the first line item that has one.
  String? get productImageUrl {
    for (final li in lineItems) {
      if (li.productImageUrl != null) return li.productImageUrl;
    }
    return null;
  }

  /// Primary product name — first item with a warranty, or first item overall.
  String? get productName {
    if (lineItems.isEmpty) return null;
    for (final li in lineItems) {
      if (li.warrantyPeriodMonths != null) {
        return li.productName ?? li.itemDescription;
      }
    }
    return lineItems.first.productName ?? lineItems.first.itemDescription;
  }

  /// Primary product category from the first line item that has one.
  String? get productCategory {
    for (final li in lineItems) {
      if (li.productCategory != null) return li.productCategory;
    }
    return null;
  }

  /// Primary warranty period (months) from the first line item that has one.
  int? get warrantyPeriodMonths {
    for (final li in lineItems) {
      if (li.warrantyPeriodMonths != null) return li.warrantyPeriodMonths;
    }
    return null;
  }

  /// Primary return period (days) from the first line item that has one.
  int? get returnPeriodDays {
    for (final li in lineItems) {
      if (li.returnPeriodDays != null) return li.returnPeriodDays;
    }
    return null;
  }

  /// Earliest warranty expiry date across all line items.
  DateTime? get warrantyExpiryDate {
    for (final li in lineItems) {
      if (li.warrantyExpiryDate != null) return li.warrantyExpiryDate;
    }
    return null;
  }

  /// Earliest return expiry date across all line items.
  DateTime? get returnExpiryDate {
    for (final li in lineItems) {
      if (li.returnExpiryDate != null) return li.returnExpiryDate;
    }
    return null;
  }

  /// Whether the primary warranty has expired.
  bool get isWarrantyExpired {
    final expiry = warrantyExpiryDate;
    if (expiry == null) return false;
    return DateTime.now().isAfter(expiry);
  }

  /// Whether the primary return window has closed.
  bool get isReturnExpired {
    final expiry = returnExpiryDate;
    if (expiry == null) return false;
    return DateTime.now().isAfter(expiry);
  }

  /// Days remaining on the primary warranty (0 if expired).
  int? get warrantyDaysRemaining {
    final expiry = warrantyExpiryDate;
    if (expiry == null) return null;
    final days = expiry.difference(DateTime.now()).inDays;
    return days < 0 ? 0 : days;
  }

  /// Days remaining on the primary return window (0 if closed).
  int? get returnDaysRemaining {
    final expiry = returnExpiryDate;
    if (expiry == null) return null;
    final days = expiry.difference(DateTime.now()).inDays;
    return days < 0 ? 0 : days;
  }
}
