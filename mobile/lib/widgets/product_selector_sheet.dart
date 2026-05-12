import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../core/constants/app_constants.dart';
import '../data/models/receipt_model.dart';
import '../screens/receipt/claims_list_screen.dart';

class ProductSelectorSheet extends StatefulWidget {
  final List<ReceiptModel> receipts;

  const ProductSelectorSheet({super.key, required this.receipts});

  @override
  State<ProductSelectorSheet> createState() => _ProductSelectorSheetState();
}

class _ProductSelectorSheetState extends State<ProductSelectorSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = AppColors.background(isDark);
    final textPrimary = AppColors.textPrimary(isDark);
    final textSecondary = AppColors.textSecondary(isDark);

    // Extract flatten products
    final products = <Map<String, dynamic>>[];
    for (final receipt in widget.receipts) {
      for (final item in receipt.lineItems) {
        if (item.status == 'ARCHIVED') continue;

        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          if (!item.displayName.toLowerCase().contains(query) &&
              !(receipt.storeName?.toLowerCase().contains(query) ?? false)) {
            continue;
          }
        }
        products.add({
          'receiptId': receipt.id,
          'receiptStoreName': receipt.storeName ?? 'Unknown Store',
          'lineItemId': item.id,
          'displayName': item.displayName,
          'productImageUrl': item.productImageUrl,
          'hasActiveWarranty':
              item.warrantyExpiryDate != null && !item.isWarrantyExpired,
          'hasActiveReturn':
              item.returnExpiryDate != null && !item.isReturnExpired,
          'purchaseDate': receipt.purchaseDate,
        });
      }
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border(isDark),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.paddingPage,
              0,
              AppDimensions.paddingPage,
              16,
            ),
            child: Row(
              children: [
                Text(
                  'Select Product to Claim',
                  style: AppTextStyles.headingLarge.copyWith(
                    color: textPrimary,
                    fontSize: 20,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Symbols.close_rounded, color: textSecondary),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.card(isDark),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingPage,
            ),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: AppTextStyles.bodyMedium.copyWith(color: textPrimary),
              decoration: InputDecoration(
                hintText: 'Search products...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: textSecondary,
                ),
                prefixIcon: Icon(Symbols.search_rounded, color: textSecondary),
                filled: true,
                fillColor: AppColors.card(isDark),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(100),
                  borderSide: BorderSide(color: AppColors.border(isDark)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(100),
                  borderSide: BorderSide(color: AppColors.border(isDark)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(100),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: products.isEmpty
                ? Center(
                    child: Text(
                      'No products found',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: textSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingPage,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final p = products[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context); // Close sheet
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ClaimsListScreen(
                                  receiptId: p['receiptId'],
                                  lineItemId: p['lineItemId'],
                                  receiptStoreName: p['receiptStoreName'],
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.card(isDark),
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusLarge,
                              ),
                              border: Border.all(
                                color: AppColors.border(isDark),
                              ),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    color: isDark
                                        ? const Color(0xFF2C2C2E)
                                        : const Color(0xFFF2F2F7),
                                    child: p['productImageUrl'] != null
                                        ? CachedNetworkImage(
                                            imageUrl: p['productImageUrl'],
                                            fit: BoxFit.cover,
                                            errorWidget:
                                                (context, url, error) =>
                                                    _buildPlaceholder(),
                                          )
                                        : _buildPlaceholder(),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p['displayName'],
                                        style: AppTextStyles.bodyLarge.copyWith(
                                          color: textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        p['receiptStoreName'] ?? 'No Date',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: textSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  Symbols.chevron_right_rounded,
                                  color: textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        Symbols.image_not_supported_rounded,
        color: Colors.grey.withValues(alpha: 0.5),
        size: 24,
      ),
    );
  }
}
