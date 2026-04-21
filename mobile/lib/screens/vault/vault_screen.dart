import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/receipt_line_item_model.dart';
import '../../providers/receipt_provider.dart';
import '../receipt/product_detail_screen.dart';

// ── Filter enum ────────────────────────────────────────────────────────────

enum VaultFilterType {
  all('All Products'),
  active('Active'),
  warrantyExpiring('Warranty Expiring'),
  returnExpiring('Return Expiring'),
  expired('Expired'),
  archived('Archived');

  final String label;
  const VaultFilterType(this.label);
}

// ── Sort enum ─────────────────────────────────────────────────────────────

enum VaultSortType {
  recentlyAdded('Recently Added'),
  warranty('Warranty Expiry'),
  returnDate('Return Expiry'),
  name('Product Name');

  final String label;
  const VaultSortType(this.label);
}

// ── Product item wrapper ──────────────────────────────────────────────────

class _VaultProductItem {
  final String receiptId;
  final ReceiptLineItemModel lineItem;
  final String? storeName;
  final DateTime? purchaseDate;

  const _VaultProductItem({
    required this.receiptId,
    required this.lineItem,
    this.storeName,
    required this.purchaseDate,
  });

  /// Warranty status: null = no warranty, expired = true, active = false
  bool? get hasWarranty => lineItem.warrantyExpiryDate != null;
  bool get isWarrantyExpired => lineItem.isWarrantyExpired;
  bool get isReturnExpired => lineItem.isReturnExpired;
}

// ── Main screen ───────────────────────────────────────────────────────────

class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> {
  late VaultFilterType _selectedFilter = VaultFilterType.active;
  late VaultSortType _selectedSort = VaultSortType.recentlyAdded;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_VaultProductItem> _filterAndSortProducts(
    List<_VaultProductItem> allProducts,
  ) {
    // Apply search
    var searchFiltered = allProducts.where((item) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.trim().toLowerCase();
      final nameMatches = item.lineItem.displayName.toLowerCase().contains(q);
      final storeMatches = item.storeName?.toLowerCase().contains(q) ?? false;
      return nameMatches || storeMatches;
    }).toList();

    // Apply filter
    var filtered = searchFiltered.where((item) {
      switch (_selectedFilter) {
        case VaultFilterType.all:
          return true; // Show all products
        case VaultFilterType.active:
          // Active means at least one of warranty or return is still valid
          final hasActiveWarranty =
              item.hasWarranty == true && !item.isWarrantyExpired;
          final hasActiveReturn =
              item.lineItem.returnExpiryDate != null && !item.isReturnExpired;
          return (hasActiveWarranty || hasActiveReturn) &&
              item.lineItem.status != 'ARCHIVED';
        case VaultFilterType.warrantyExpiring:
          return item.hasWarranty! &&
              !item.isWarrantyExpired &&
              item.lineItem.warrantyDaysRemaining != null &&
              item.lineItem.warrantyDaysRemaining! <= 30 &&
              item.lineItem.status != 'ARCHIVED';
        case VaultFilterType.returnExpiring:
          return item.lineItem.returnExpiryDate != null &&
              !item.isReturnExpired &&
              item.lineItem.returnDaysRemaining != null &&
              item.lineItem.returnDaysRemaining! <= 7 &&
              item.lineItem.status != 'ARCHIVED';
        case VaultFilterType.expired:
          // Expired means BOTH warranty AND return periods are expired (or not set)
          final warrantyExpiredOrNone =
              item.hasWarranty != true || item.isWarrantyExpired;
          final returnExpiredOrNone =
              item.lineItem.returnExpiryDate == null || item.isReturnExpired;
          return warrantyExpiredOrNone &&
              returnExpiredOrNone &&
              item.lineItem.status != 'ARCHIVED';
        case VaultFilterType.archived:
          return item.lineItem.status == 'ARCHIVED';
      }
    }).toList();

    // Apply sort
    filtered.sort((a, b) {
      switch (_selectedSort) {
        case VaultSortType.recentlyAdded:
          return b.lineItem.createdAt.compareTo(a.lineItem.createdAt);
        case VaultSortType.warranty:
          final aDate = a.lineItem.warrantyExpiryDate;
          final bDate = b.lineItem.warrantyExpiryDate;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return aDate.compareTo(bDate);
        case VaultSortType.returnDate:
          final aDate = a.lineItem.returnExpiryDate;
          final bDate = b.lineItem.returnExpiryDate;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return aDate.compareTo(bDate);
        case VaultSortType.name:
          return a.lineItem.displayName.compareTo(b.lineItem.displayName);
      }
    });

    return filtered;
  }

  Future<void> _refreshProducts() async {
    ref.invalidate(receiptsProvider);
    await ref.read(receiptsProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final receiptsAsync = ref.watch(receiptsProvider);

    final bg = AppColors.background(isDark);
    final textPrimary = AppColors.textPrimary(isDark);
    final textSecondary = AppColors.textSecondary(isDark);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: receiptsAsync.when(
          data: (receipts) {
            // Flatten all receipts into product items
            final allProducts = <_VaultProductItem>[];
            for (final receipt in receipts) {
              for (final item in receipt.lineItems) {
                allProducts.add(
                  _VaultProductItem(
                    receiptId: receipt.id,
                    lineItem: item,
                    storeName: receipt.storeName,
                    purchaseDate: receipt.purchaseDate,
                  ),
                );
              }
            }

            final filteredProducts = _filterAndSortProducts(allProducts);

            return Column(
              children: [
                // ── Header ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.paddingPage,
                    20,
                    AppDimensions.paddingPage,
                    16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Vault',
                            style: AppTextStyles.headingLarge.copyWith(
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Search Bar
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.card(isDark),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) =>
                              setState(() => _searchQuery = val),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search products...',
                            hintStyle: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary(isDark),
                            ),
                            prefixIcon: Icon(
                              Symbols.search_rounded,
                              color: AppColors.textSecondary(isDark),
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Symbols.close_rounded,
                                      color: AppColors.textSecondary(isDark),
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                      FocusScope.of(context).unfocus();
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${filteredProducts.length} product${filteredProducts.length != 1 ? 's' : ''}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Filter & sort bar ─────────────────────────────────
                GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingPage,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: _selectedFilter.label,
                            isDark: isDark,
                            onTap: () => _showFilterMenu(context, isDark),
                            icon: Symbols.tune_rounded,
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: _selectedSort.label,
                            isDark: isDark,
                            onTap: () => _showSortMenu(context, isDark),
                            icon: Symbols.swap_vert_rounded,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Product list ────────────────────────────────
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshProducts,
                    color: AppColors.primary,
                    child: GestureDetector(
                      onTap: () => FocusScope.of(context).unfocus(),
                      behavior: HitTestBehavior.translucent,
                      child: filteredProducts.isEmpty
                          ? _buildEmptyState(isDark, textPrimary, textSecondary)
                          : _buildListView(filteredProducts, isDark),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, st) => Center(
            child: Text(
              'Error loading products',
              style: AppTextStyles.bodyMedium.copyWith(color: textSecondary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color textPrimary, Color textSecondary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Symbols.shopping_bag_rounded,
            size: AppDimensions.iconXXL,
            color: textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No products found',
            style: AppTextStyles.headingSmall.copyWith(color: textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: AppTextStyles.bodySmall.copyWith(color: textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<_VaultProductItem> products, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingPage,
        vertical: 8,
      ),
      itemCount: products.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _ProductListItem(
          item: products[i],
          isDark: isDark,
          onTap: () => _navigateToProduct(products[i]),
        ),
      ),
    );
  }

  void _navigateToProduct(_VaultProductItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          receiptId: item.receiptId,
          lineItemId: item.lineItem.id,
        ),
      ),
    );
  }

  void _showFilterMenu(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background(isDark),
      builder: (context) => _FilterMenu(
        selectedFilter: _selectedFilter,
        onFilterSelected: (filter) {
          setState(() => _selectedFilter = filter);
          Navigator.pop(context);
        },
        isDark: isDark,
      ),
    );
  }

  void _showSortMenu(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background(isDark),
      builder: (context) => _SortMenu(
        selectedSort: _selectedSort,
        onSortSelected: (sort) {
          setState(() => _selectedSort = sort);
          Navigator.pop(context);
        },
        isDark: isDark,
      ),
    );
  }
}

// ── Product list item ──────────────────────────────────────────────────────

class _ProductListItem extends StatelessWidget {
  final _VaultProductItem item;
  final bool isDark;
  final VoidCallback onTap;

  const _ProductListItem({
    required this.item,
    required this.isDark,
    required this.onTap,
  });

  Color _statusColor() {
    // Green if at least one of warranty or return is still active
    final hasActiveWarranty =
        item.hasWarranty == true && !item.isWarrantyExpired;
    final hasActiveReturn =
        item.lineItem.returnExpiryDate != null && !item.isReturnExpired;
    if (hasActiveWarranty || hasActiveReturn) {
      return AppColors.success;
    }
    return AppColors.error;
  }

  String _expiryLabel() {
    final returnDays = item.lineItem.returnDaysRemaining;
    final warrantyDays = item.lineItem.warrantyDaysRemaining;

    // Priority 1: Warranty expired (show this even if return also expired)
    if (item.isWarrantyExpired) return 'Warranty expired';

    // Priority 2: Warranty active but return expired
    if (item.isReturnExpired && !item.isWarrantyExpired)
      return 'Active warranty';

    // Priority 3: Return expires today (urgent)
    if (returnDays != null && returnDays == 0) {
      return 'Return expires today';
    }

    // Priority 4: Return expiring soon (within 7 days)
    if (returnDays != null && returnDays <= 7 && !item.isReturnExpired) {
      return 'Return in $returnDays day${returnDays != 1 ? 's' : ''}';
    }

    // Priority 5: Warranty expires today
    if (warrantyDays != null && warrantyDays == 0) {
      return 'Warranty expires today';
    }

    // Priority 6: Warranty expiring soon (within 30 days)
    if (warrantyDays != null && warrantyDays <= 30 && !item.isWarrantyExpired) {
      return 'Warranty in $warrantyDays day${warrantyDays != 1 ? 's' : ''}';
    }

    // Default: Both active
    return 'Active';
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.textPrimary(isDark);
    final textSecondary = AppColors.textSecondary(isDark);
    final statusColor = _statusColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.card(isDark),
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
          border: Border.all(color: AppColors.border(isDark)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.paddingCardSmall,
                AppDimensions.paddingCardSmall,
                0,
                AppDimensions.paddingCardSmall,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                child: SizedBox(
                  width: 84,
                  height: 84,
                  child: item.lineItem.productImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: item.lineItem.productImageUrl!,
                          fit: BoxFit.contain,
                          errorWidget: (context, imageUrl, error) =>
                              _VaultImagePlaceholder(color: statusColor),
                        )
                      : _VaultImagePlaceholder(color: statusColor),
                ),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingCardSmall),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.lineItem.displayName,
                      style: AppTextStyles.listTitle.copyWith(
                        color: textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (item.storeName != null &&
                            item.storeName!.isNotEmpty) ...[
                          Icon(
                            Symbols.storefront_rounded,
                            size: AppDimensions.iconTiny,
                            color: textSecondary,
                            weight: AppDimensions.iconWeightBold,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              item.storeName!,
                              style: AppTextStyles.caption.copyWith(
                                color: textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (item.purchaseDate != null) ...[
                          Icon(
                            Symbols.calendar_today_rounded,
                            size: AppDimensions.iconTiny,
                            color: textSecondary,
                            weight: AppDimensions.iconWeightBold,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat(
                              'MMM d, yyyy',
                            ).format(item.purchaseDate!),
                            style: AppTextStyles.caption.copyWith(
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Symbols.timer_rounded,
                          size: AppDimensions.iconTiny,
                          color: statusColor,
                          weight: AppDimensions.iconWeightBold,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _expiryLabel(),
                          style: AppTextStyles.bodyXSmall.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VaultImagePlaceholder extends StatelessWidget {
  final Color color;

  const _VaultImagePlaceholder({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withValues(alpha: 0.08),
      child: Center(
        child: Icon(
          Symbols.image_not_supported_rounded,
          size: AppDimensions.iconNormal,
          color: color.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

// ── Filter menu ────────────────────────────────────────────────────────────

class _FilterMenu extends StatelessWidget {
  final VaultFilterType selectedFilter;
  final ValueChanged<VaultFilterType> onFilterSelected;
  final bool isDark;

  const _FilterMenu({
    required this.selectedFilter,
    required this.onFilterSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.textPrimary(isDark);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Filter by Status',
              style: AppTextStyles.headingSmall.copyWith(color: textPrimary),
            ),
          ),
          const SizedBox(height: 12),
          ...VaultFilterType.values.map(
            (filter) => _MenuItem(
              label: filter.label,
              isSelected: filter == selectedFilter,
              isDark: isDark,
              onTap: () => onFilterSelected(filter),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Sort menu ──────────────────────────────────────────────────────────────

class _SortMenu extends StatelessWidget {
  final VaultSortType selectedSort;
  final ValueChanged<VaultSortType> onSortSelected;
  final bool isDark;

  const _SortMenu({
    required this.selectedSort,
    required this.onSortSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.textPrimary(isDark);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Sort by',
              style: AppTextStyles.headingSmall.copyWith(color: textPrimary),
            ),
          ),
          const SizedBox(height: 12),
          ...VaultSortType.values.map(
            (sort) => _MenuItem(
              label: sort.label,
              isSelected: sort == selectedSort,
              isDark: isDark,
              onTap: () => onSortSelected(sort),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Menu item ──────────────────────────────────────────────────────────────

class _MenuItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _MenuItem({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.textPrimary(isDark);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isSelected ? AppColors.primary : textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              if (isSelected)
                Icon(
                  Symbols.check_rounded,
                  color: AppColors.primary,
                  size: AppDimensions.iconMedium,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Filter chip ────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  final IconData icon;

  const _FilterChip({
    required this.label,
    required this.isDark,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final card = AppColors.card(isDark);
    final border = AppColors.border(isDark);
    final textPrimary = AppColors.textPrimary(isDark);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: AppDimensions.iconSmall,
              color: textPrimary,
              weight: AppDimensions.iconWeightBold,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(color: textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
