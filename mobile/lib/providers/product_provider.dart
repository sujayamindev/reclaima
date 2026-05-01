// coverage:ignore-file
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/product_view_model.dart';
import 'receipt_provider.dart';

/// Flattens all receipts into a list of [ProductViewModel] entries — one per
/// line item, or one pending entry for receipts with no items yet.
///
/// Sort order:
///   1. Products with active warranties — ascending by expiry (soonest first)
///   2. Products with no warranty / return data — descending by purchase date
///   3. Pending (processing) receipts — descending by createdAt
final productsProvider = FutureProvider<List<ProductViewModel>>((ref) async {
  final receipts = await ref.watch(receiptsProvider.future);

  final products = <ProductViewModel>[];

  for (final receipt in receipts) {
    if (receipt.lineItems.isEmpty) {
      // Pending receipt — no items extracted yet.
      products.add(ProductViewModel(receipt: receipt, lineItem: null));
    } else {
      for (final item in receipt.lineItems) {
        products.add(ProductViewModel(receipt: receipt, lineItem: item));
      }
    }
  }

  // Sort: active warranties (soonest expiry) → no-warranty items (newest) → pending
  products.sort((a, b) {
    if (a.isPending && !b.isPending) return 1;
    if (!a.isPending && b.isPending) return -1;
    if (a.isPending && b.isPending) {
      return (b.receipt.createdAt).compareTo(a.receipt.createdAt);
    }

    final aHasWarranty = a.warrantyExpiryDate != null && !a.isWarrantyExpired;
    final bHasWarranty = b.warrantyExpiryDate != null && !b.isWarrantyExpired;

    if (aHasWarranty && !bHasWarranty) return -1;
    if (!aHasWarranty && bHasWarranty) return 1;

    if (aHasWarranty && bHasWarranty) {
      return a.warrantyExpiryDate!.compareTo(b.warrantyExpiryDate!);
    }

    // Both have no active warranty — sort by purchase date descending
    final aDate = a.receipt.purchaseDate ?? a.receipt.createdAt;
    final bDate = b.receipt.purchaseDate ?? b.receipt.createdAt;
    return bDate.compareTo(aDate);
  });

  return products;
});
