import 'receipt_model.dart';
import 'receipt_line_item_model.dart';

/// A product-centric view model that pairs a [ReceiptModel] with one of its
/// [ReceiptLineItemModel] line items (or null for pending/processing receipts
/// that have no line items yet).
///
/// [ProductViewModel] is the primary entity shown on the home screen and in
/// [ProductDetailScreen]. The receipt is secondary context (store, date, image).
class ProductViewModel {
  final ReceiptModel receipt;

  /// Null when the receipt is still PROCESSING / UPLOADED and has no line items.
  final ReceiptLineItemModel? lineItem;

  const ProductViewModel({
    required this.receipt,
    this.lineItem,
  });

  // ── Identity ────────────────────────────────────────────────────────────

  String get receiptId => receipt.id;
  String? get lineItemId => lineItem?.id;

  // ── Display ─────────────────────────────────────────────────────────────

  /// Human-readable product name.
  /// Priority: lineItem.productName → lineItem.itemDescription → storeName
  String get displayName =>
      lineItem?.productName ??
      lineItem?.itemDescription ??
      receipt.storeName ??
      'Unknown Product';

  String? get productCategory => lineItem?.productCategory;
  String? get productImageUrl => lineItem?.productImageUrl;

  /// True when the receipt has no line items yet (still processing).
  bool get isPending => lineItem == null;

  /// The amount to show on the card.
  /// Uses the line item's own amount when available, otherwise the receipt total.
  double? get itemAmount => lineItem?.amount ?? receipt.totalAmount;

  String? get currency => receipt.currency;

  // ── Warranty & Return ───────────────────────────────────────────────────

  DateTime? get warrantyExpiryDate => lineItem?.warrantyExpiryDate;
  DateTime? get returnExpiryDate => lineItem?.returnExpiryDate;
  int? get warrantyPeriodMonths => lineItem?.warrantyPeriodMonths;
  int? get returnPeriodDays => lineItem?.returnPeriodDays;

  bool get isWarrantyExpired => lineItem?.isWarrantyExpired ?? false;
  bool get isReturnExpired => lineItem?.isReturnExpired ?? false;

  int? get warrantyDaysRemaining => lineItem?.warrantyDaysRemaining;
  int? get returnDaysRemaining => lineItem?.returnDaysRemaining;

  bool get hasWarranty => warrantyExpiryDate != null;
  bool get hasReturn => returnExpiryDate != null;

  /// True if the warranty is active and expires within 30 days.
  bool get warrantyExpiresSoon =>
      !isWarrantyExpired &&
      warrantyDaysRemaining != null &&
      warrantyDaysRemaining! <= 30;
}
