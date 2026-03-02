import 'package:json_annotation/json_annotation.dart';

part 'receipt_line_item_model.g.dart';

/// A single product / service line item on a receipt or invoice.
///
/// Warranty and return tracking lives here (not on [ReceiptModel]) so that
/// multi-product receipts can track each item's warranty independently.
@JsonSerializable()
class ReceiptLineItemModel {
  final String id;
  final String receiptId;
  final int rowIndex;
  final String? productCode;
  final String? itemDescription;
  final String? quantity;
  final double? unitPrice;
  final double? amount;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ── Per-item product fields ────────────────────────────────────────────
  final String? productName;
  final String? productCategory;
  final String? productImageUrl;

  // ── Per-item warranty & return fields ─────────────────────────────────
  final int? warrantyPeriodMonths;
  final DateTime? warrantyExpiryDate;
  final int? returnPeriodDays;
  final DateTime? returnExpiryDate;

  const ReceiptLineItemModel({
    required this.id,
    required this.receiptId,
    required this.rowIndex,
    this.productCode,
    this.itemDescription,
    this.quantity,
    this.unitPrice,
    this.amount,
    required this.createdAt,
    required this.updatedAt,
    this.productName,
    this.productCategory,
    this.productImageUrl,
    this.warrantyPeriodMonths,
    this.warrantyExpiryDate,
    this.returnPeriodDays,
    this.returnExpiryDate,
  });

  factory ReceiptLineItemModel.fromJson(Map<String, dynamic> json) =>
      _$ReceiptLineItemModelFromJson(json);

  /// Creates a display-only line item from an OCR extract response map.
  ///
  /// Used to populate the read-only items-table in [ReviewReceiptScreen] for
  /// receipts that have not been saved to the database yet. The [id] and
  /// [receiptId] fields are intentionally empty strings.
  factory ReceiptLineItemModel.fromOcrExtract(Map<String, dynamic> json) {
    final now = DateTime.now();
    return ReceiptLineItemModel(
      id: '',
      receiptId: '',
      rowIndex: (json['rowIndex'] as num?)?.toInt() ?? 0,
      productCode: json['productCode'] as String?,
      itemDescription: json['itemDescription'] as String?,
      quantity: json['quantity'] as String?,
      unitPrice: (json['unitPrice'] as num?)?.toDouble(),
      amount: (json['amount'] as num?)?.toDouble(),
      createdAt: now,
      updatedAt: now,
      productName: json['productName'] as String?,
      productCategory: json['productCategory'] as String?,
      warrantyPeriodMonths: (json['warrantyPeriodMonths'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => _$ReceiptLineItemModelToJson(this);

  // ── Computed helpers ───────────────────────────────────────────────────

  /// Human-readable name — productName first, then itemDescription, else 'Item'.
  String get displayName => productName ?? itemDescription ?? 'Item';

  /// Whether this item's warranty has expired.
  bool get isWarrantyExpired {
    if (warrantyExpiryDate == null) return false;
    return DateTime.now().isAfter(warrantyExpiryDate!);
  }

  /// Whether this item's return window has closed.
  bool get isReturnExpired {
    if (returnExpiryDate == null) return false;
    return DateTime.now().isAfter(returnExpiryDate!);
  }

  /// Days remaining until warranty expires (0 if already expired).
  int? get warrantyDaysRemaining {
    if (warrantyExpiryDate == null) return null;
    final days = warrantyExpiryDate!.difference(DateTime.now()).inDays;
    return days < 0 ? 0 : days;
  }

  /// Days remaining until return window closes (0 if already closed).
  int? get returnDaysRemaining {
    if (returnExpiryDate == null) return null;
    final days = returnExpiryDate!.difference(DateTime.now()).inDays;
    return days < 0 ? 0 : days;
  }
}

