import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/product_view_model.dart';
import '../../data/models/receipt_model.dart';
import '../../data/models/receipt_line_item_model.dart';
import '../../providers/receipt_provider.dart';
import '../../core/utils/formatters.dart';

/// Full-screen product detail view.
///
/// The product ([ProductViewModel]) is resolved here from the receipt +
/// optional line item rather than passed as a constructor argument so that
/// this screen re-renders when the provider data updates (e.g. after edit).
class ProductDetailScreen extends ConsumerWidget {
  final String receiptId;

  /// The id of the specific [ReceiptLineItemModel] to display.
  /// Null means the receipt is still pending (no line items yet).
  final String? lineItemId;

  const ProductDetailScreen({
    super.key,
    required this.receiptId,
    this.lineItemId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptAsync = ref.watch(receiptProvider(receiptId));
    final imageUrlAsync = ref.watch(receiptImageUrlProvider(receiptId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      body: SafeArea(
        child: receiptAsync.when(
          data: (receipt) {
            // Resolve the specific line item (null for pending receipts).
            ReceiptLineItemModel? item;
            if (lineItemId != null) {
              try {
                item = receipt.lineItems
                    .firstWhere((li) => li.id == lineItemId);
              } catch (_) {
                item = null;
              }
            }
            // Fall back to the first available line item when no specific ID
            // was provided (e.g. navigating from the confirmation screen after
            // save, or arriving via a notification deep link).
            item ??= receipt.lineItems.isNotEmpty ? receipt.lineItems.first : null;
            final product =
                ProductViewModel(receipt: receipt, lineItem: item);
            return _buildBody(context, ref, product, imageUrlAsync, isDark);
          },
          loading: () => Column(
            children: [
              _buildTopBar(context, ref, null, isDark),
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ],
          ),
          error: (err, _) => Column(
            children: [
              _buildTopBar(context, ref, null, isDark),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.paddingPage),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.error_outline,
                              size: 32, color: AppColors.error),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load product',
                          style: AppTextStyles.titleLarge
                              .copyWith(color: AppColors.textPrimary(isDark)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$err',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyXSmall.copyWith(
                            color: AppColors.textSecondary(isDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Scroll body ──────────────────────────────────────────────────────────

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    ProductViewModel product,
    AsyncValue<String?> imageUrlAsync,
    bool isDark,
  ) {
    const p = AppDimensions.paddingPage;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildTopBar(context, ref, product, isDark)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(p, 4, p, 36),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Hero card ───────────────────────────────────────────
              _buildHeroCard(product, isDark),
              const SizedBox(height: 12),

              // ── Warranty & Return countdown ──────────────────────────
              _buildWarrantySection(product, isDark),
              const SizedBox(height: 12),

              // ── Purchase Details ─────────────────────────────────────
              _buildPurchaseDetails(
                  context, product.receipt, imageUrlAsync, isDark),
              const SizedBox(height: 12),

              // ── All line items table (multi-product context) ──────────
              if (product.receipt.lineItems.length > 1) ...[
                _buildLineItemsSection(isDark, product.receipt.lineItems,
                    highlightId: lineItemId),
                const SizedBox(height: 12),
              ],

              // ── Vendor Contact ───────────────────────────────────────
              if (_hasVendorContact(product.receipt)) ...[
                _buildSection(
                  isDark,
                  'Vendor Contact',
                  Icons.store_outlined,
                  [
                    if (product.receipt.vendorAddress != null)
                      _buildInfoRow(
                          'Address', product.receipt.vendorAddress!, isDark),
                    if (product.receipt.vendorPhone != null)
                      _buildInfoRow(
                          'Phone', product.receipt.vendorPhone!, isDark),
                    if (product.receipt.vendorEmail != null)
                      _buildInfoRow(
                          'Email', product.receipt.vendorEmail!, isDark),
                    if (product.receipt.vendorUrl != null)
                      _buildInfoRow(
                          'Website', product.receipt.vendorUrl!, isDark),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // ── Warranty Terms ───────────────────────────────────────
              if (product.receipt.warrantyNotes != null) ...[
                _buildSection(
                  isDark,
                  'Warranty Terms',
                  Icons.policy_outlined,
                  [
                    Text(
                      product.receipt.warrantyNotes!,
                      style: AppTextStyles.bodyXSmall.copyWith(
                        color: AppColors.textSecondary(isDark),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // ── Additional Details ───────────────────────────────────
              if (product.receipt.remarks != null) ...[
                _buildSection(
                  isDark,
                  'Additional Details',
                  Icons.info_outline,
                  [
                    Text(
                      product.receipt.remarks!,
                      style: AppTextStyles.bodyXSmall.copyWith(
                        color: AppColors.textSecondary(isDark),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // ── Notes ────────────────────────────────────────────────
              if (product.receipt.notes != null) ...[
                _buildSection(
                  isDark,
                  'Notes',
                  Icons.notes_outlined,
                  [
                    Text(
                      product.receipt.notes!,
                      style: AppTextStyles.bodyXSmall.copyWith(
                        color: AppColors.textSecondary(isDark),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // ── Processing Status ────────────────────────────────────
              _buildSection(
                isDark,
                'Processing Status',
                Icons.cloud_done_outlined,
                [
                  _buildInfoRow(
                      'OCR Status', product.receipt.status.name, isDark),
                  _buildInfoRow(
                      'Retry Count', '${product.receipt.ocrRetryCount}',
                      isDark),
                  if (product.receipt.lastOcrAttemptAt != null)
                    _buildInfoRow(
                      'Last Attempt',
                      DateFormatter.formatDateTime(
                          product.receipt.lastOcrAttemptAt!),
                      isDark,
                    ),
                ],
              ),
            ]),
          ),
        ),
      ],
    );
  }

  // ── Top bar ──────────────────────────────────────────────────────────────

  Widget _buildTopBar(
    BuildContext context,
    WidgetRef ref,
    ProductViewModel? product,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back,
                color: AppColors.textPrimary(isDark)),
            padding: const EdgeInsets.all(8),
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              shape: const CircleBorder(),
            ),
          ),
          Expanded(
            child: Text(
              'Product Details',
              textAlign: TextAlign.center,
              style: AppTextStyles.listTitle.copyWith(
                fontSize: 17,
                color: AppColors.textPrimary(isDark),
              ),
            ),
          ),
          if (product != null)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert,
                  color: AppColors.textPrimary(isDark), size: 22),
              padding: EdgeInsets.zero,
              color: AppColors.card(isDark),
              elevation: 4,
              shadowColor: Colors.black.withValues(alpha: 0.12),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusLarge),
                side: BorderSide(color: AppColors.border(isDark)),
              ),
              onSelected: (value) async {
                if (value == 'edit') {
                  // TODO: navigate to edit screen
                } else if (value == 'delete') {
                  final confirmed = await _showDeleteDialog(context);
                  if (confirmed == true && context.mounted) {
                    final ok = await ref
                        .read(receiptControllerProvider.notifier)
                        .deleteReceipt(product.receiptId);
                    if (ok && context.mounted) Navigator.pop(context);
                  }
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'edit',
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 30,
                        height: 30,
                        child: const Icon(Icons.edit_outlined,
                            size: 15, color: AppColors.primary),
                      ),
                      const SizedBox(width: 6),
                      Text('Edit',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textPrimary(isDark),
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 30,
                        height: 30,
                        child: const Icon(Icons.delete_outline,
                            size: 15, color: AppColors.error),
                      ),
                      const SizedBox(width: 6),
                      Text('Delete',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  // ── Hero card ────────────────────────────────────────────────────────────

  Widget _buildHeroCard(
    ProductViewModel product,
    bool isDark,
  ) {
    final statusColor = _statusColor(product.receipt, isDark);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingCard),
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(color: AppColors.border(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Product image (top) ─────────────────────────────────────
          if (product.productImageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              child: CachedNetworkImage(
                imageUrl: product.productImageUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.contain,
                placeholder: (_, __) => Container(
                  height: 200,
                  color: AppColors.primary.withValues(alpha: 0.06),
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: AppColors.primary),
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Product name + amount ───────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: product.displayName,
                      style: AppTextStyles.listTitle.copyWith(
                        fontSize: 18,
                        color: AppColors.textPrimary(isDark),
                        height: 1.3,
                      ),
                    ),
                    // Only show badge for non-completed / notable states
                    if (product.receipt.status != ReceiptStatus.completed)
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: product.isPending
                              ? const _StatusBadge(
                                  color: AppColors.warning,
                                  label: 'Processing',
                                )
                              : _StatusBadge(
                                  color: statusColor,
                                  label: _statusLabel(product.receipt),
                                ),
                        ),
                      ),
                  ],
                ),
              ),
              if (product.productCategory != null) ...[
                const SizedBox(height: 4),
                Text(
                  product.productCategory!,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary(isDark),
                  ),
                ),
              ],
            ],
          ),


        ],
      ),
    );
  }

  // ── Warranty & Return section ─────────────────────────────────────────────

  Widget _buildWarrantySection(ProductViewModel product, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingCard),
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(color: AppColors.border(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Warranty & Return',
            icon: Icons.verified_outlined,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          if (product.isPending)
            _buildPendingWarrantyPlaceholder(isDark)
          else if (!product.hasWarranty && !product.hasReturn)
            _buildNoWarrantyPlaceholder(isDark)
          else
            Row(
              children: [
                Expanded(
                  child: _CountdownTile(
                    label: 'WARRANTY',
                    icon: Icons.shield_outlined,
                    expiryDate: product.warrantyExpiryDate,
                    daysRemaining: product.warrantyDaysRemaining,
                    isExpired: product.isWarrantyExpired,
                    noInfoText: 'Not set',
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CountdownTile(
                    label: 'RETURN',
                    icon: Icons.assignment_return_outlined,
                    expiryDate: product.returnExpiryDate,
                    daysRemaining: product.returnDaysRemaining,
                    isExpired: product.isReturnExpired,
                    noInfoText: 'Not set',
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          // Period details if set
          if (!product.isPending &&
              (product.warrantyPeriodMonths != null ||
                  product.returnPeriodDays != null)) ...[
            const SizedBox(height: 12),
            Divider(color: AppColors.border(isDark), height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                if (product.warrantyPeriodMonths != null)
                  Expanded(
                    child: _buildInfoRow(
                      'Warranty period',
                      '${product.warrantyPeriodMonths} months',
                      isDark,
                    ),
                  ),
                if (product.returnPeriodDays != null)
                  Expanded(
                    child: _buildInfoRow(
                      'Return window',
                      '${product.returnPeriodDays} days',
                      isDark,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPendingWarrantyPlaceholder(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.warning.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Processing receipt…',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.muted(isDark)),
            ),
            const SizedBox(height: 4),
            Text(
              'Warranty details will appear once OCR is complete.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.muted(isDark),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoWarrantyPlaceholder(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Icon(Icons.verified_user_outlined,
                size: 36, color: AppColors.muted(isDark)),
            const SizedBox(height: 10),
            Text(
              'No warranty information tracked',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.muted(isDark)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Purchase Details card ─────────────────────────────────────────────────

  Widget _buildPurchaseDetails(
    BuildContext context,
    ReceiptModel receipt,
    AsyncValue<String?> imageUrlAsync,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingCard),
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(color: AppColors.border(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: icon + "Purchase Details"
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusIconContainer),
                ),
                child: const Icon(Icons.store_outlined,
                    size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Text(
                'Purchase Details',
                style: AppTextStyles.sectionTitle
                    .copyWith(color: AppColors.textPrimary(isDark)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Store name + date
          _buildInfoRow(
            'Store',
            receipt.storeName ?? 'Unknown Store',
            isDark,
          ),
          if (receipt.purchaseDate != null)
            _buildInfoRow(
              'Purchase Date',
              DateFormatter.formatDate(receipt.purchaseDate!),
              isDark,
            ),
          if (receipt.totalAmount != null)
            _buildInfoRow(
              'Total',
              CurrencyFormatter.format(
                receipt.totalAmount!,
                currency: receipt.currency ?? 'USD',
              ),
              isDark,
            ),
          if (receipt.invoiceNumber != null)
            _buildInfoRow('Invoice #', receipt.invoiceNumber!, isDark),

          // Receipt image thumbnail
          if (receipt.s3ObjectKey != null) ...[
            const SizedBox(height: 14),
            Divider(color: AppColors.border(isDark), height: 1),
            const SizedBox(height: 14),
            _buildReceiptThumbnail(context, imageUrlAsync, isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildReceiptThumbnail(
    BuildContext context,
    AsyncValue<String?> imageUrlAsync,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () => imageUrlAsync.whenData(
        (url) {
          if (url != null) _openFullscreenImage(context, url);
        },
      ),
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.card(isDark),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          border: Border.all(color: AppColors.border(isDark)),
        ),
        clipBehavior: Clip.antiAlias,
        child: imageUrlAsync.when(
          loading: () => const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: AppColors.primary),
            ),
          ),
          error: (_, __) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image_outlined,
                    size: 32, color: AppColors.muted(isDark)),
                const SizedBox(height: 8),
                Text('Image unavailable',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.muted(isDark))),
              ],
            ),
          ),
          data: (url) => url == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 36, color: AppColors.muted(isDark)),
                      const SizedBox(height: 8),
                      Text('Receipt image',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.muted(isDark))),
                    ],
                  ),
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: AppColors.primary),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Center(
                        child: Icon(Icons.broken_image_outlined,
                            size: 36, color: AppColors.muted(isDark)),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusPill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.fullscreen,
                                color: Colors.white, size: 15),
                            const SizedBox(width: 4),
                            Text(
                              'View',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _openFullscreenImage(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 5.0,
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 24),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Line items table (multi-product receipts) ────────────────────────────

  Widget _buildLineItemsSection(
    bool isDark,
    List<ReceiptLineItemModel> items, {
    String? highlightId,
  }) {
    final headerStyle = AppTextStyles.tableHeader
        .copyWith(color: AppColors.textSecondary(isDark));
    final cellStyle = AppTextStyles.bodyXSmall
        .copyWith(color: AppColors.textPrimary(isDark));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingCard),
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(color: AppColors.border(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _SectionHeader(
                  title: 'Items on This Receipt',
                  icon: Icons.shopping_cart_outlined,
                  isDark: isDark,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusPill),
                ),
                child: Text(
                  '${items.length} items',
                  style: AppTextStyles.badgeText
                      .copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                    flex: 3, child: Text('Description', style: headerStyle)),
                SizedBox(
                    width: 48,
                    child: Text('Qty',
                        style: headerStyle, textAlign: TextAlign.center)),
                SizedBox(
                    width: 64,
                    child: Text('Unit',
                        style: headerStyle, textAlign: TextAlign.right)),
                SizedBox(
                    width: 72,
                    child: Text('Amount',
                        style: headerStyle, textAlign: TextAlign.right)),
              ],
            ),
          ),
          Divider(color: AppColors.border(isDark), height: 8),
          ...items.map(
            (item) => Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding: item.id == highlightId
                  ? const EdgeInsets.symmetric(vertical: 4, horizontal: 6)
                  : EdgeInsets.zero,
              decoration: item.id == highlightId
                  ? BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.07),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSmall),
                    )
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.productCode != null)
                      Text(
                        item.productCode!,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.muted(isDark),
                          fontFamily: 'monospace',
                        ),
                      ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(item.itemDescription ?? '—',
                              style: cellStyle),
                        ),
                        SizedBox(
                          width: 48,
                          child: Text(item.quantity ?? '—',
                              style: cellStyle, textAlign: TextAlign.center),
                        ),
                        SizedBox(
                          width: 64,
                          child: Text(
                            item.unitPrice != null
                                ? item.unitPrice!.toStringAsFixed(2)
                                : '—',
                            style: cellStyle,
                            textAlign: TextAlign.right,
                          ),
                        ),
                        SizedBox(
                          width: 72,
                          child: Text(
                            item.amount != null
                                ? item.amount!.toStringAsFixed(2)
                                : '—',
                            style: cellStyle
                                .copyWith(fontWeight: FontWeight.w600),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared card builder ───────────────────────────────────────────────────

  Widget _buildSection(
    bool isDark,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingCard),
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(color: AppColors.border(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: title, icon: icon, isDark: isDark),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  // ── Info row ──────────────────────────────────────────────────────────────

  Widget _buildInfoRow(String label, String value, bool isDark,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: AppTextStyles.bodyXSmall.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary(isDark),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyXSmall.copyWith(
                color: valueColor ?? AppColors.textPrimary(isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Utilities ─────────────────────────────────────────────────────────────

  bool _hasVendorContact(ReceiptModel receipt) =>
      receipt.vendorAddress != null ||
      receipt.vendorPhone != null ||
      receipt.vendorEmail != null ||
      receipt.vendorUrl != null;

  Color _statusColor(ReceiptModel receipt, bool isDark) {
    switch (receipt.status) {
      case ReceiptStatus.completed:
        return AppColors.primary;
      case ReceiptStatus.processing:
        return AppColors.warning;
      case ReceiptStatus.ocrFailed:
        return AppColors.error;
      case ReceiptStatus.uploaded:
        return AppColors.info;
      case ReceiptStatus.localOnly:
      case ReceiptStatus.manualEntry:
        return AppColors.muted(isDark);
    }
  }

  String _statusLabel(ReceiptModel receipt) {
    switch (receipt.status) {
      case ReceiptStatus.completed:
        return 'Completed';
      case ReceiptStatus.processing:
        return 'Processing';
      case ReceiptStatus.ocrFailed:
        return 'OCR Failed';
      case ReceiptStatus.uploaded:
        return 'Uploaded';
      case ReceiptStatus.localOnly:
        return 'Local Only';
      case ReceiptStatus.manualEntry:
        return 'Manual Entry';
    }
  }

  Future<bool?> _showDeleteDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text(
          'This will delete the receipt and all its items. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Private helper widgets ────────────────────────────────────────────────

/// Colored icon container + title — used at the top of every card section.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.isDark,
  });

  final String title;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius:
                BorderRadius.circular(AppDimensions.radiusIconContainer),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: AppTextStyles.sectionTitle
              .copyWith(color: AppColors.textPrimary(isDark)),
        ),
      ],
    );
  }
}

/// Colored pill badge for status and category labels.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.color,
    required this.label,
    this.filled = true,
    this.isDark = false,
  });

  final Color color;
  final String label;
  final bool filled;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        border: Border.all(
          color: filled ? color.withValues(alpha: 0.45) : color,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (filled) ...[
            Container(
              width: 6,
              height: 6,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppTextStyles.badgeText.copyWith(
              color: filled ? color : color,
            ),
          ),
        ],
      ),
    );
  }
}



/// Side-by-side countdown tile showing days remaining until expiry.
class _CountdownTile extends StatelessWidget {
  const _CountdownTile({
    required this.label,
    required this.icon,
    required this.expiryDate,
    required this.daysRemaining,
    required this.isExpired,
    required this.noInfoText,
    required this.isDark,
  });

  final String label;
  final IconData icon;
  final DateTime? expiryDate;
  final int? daysRemaining;
  final bool isExpired;
  final String noInfoText;
  final bool isDark;

  Color get _accent {
    if (expiryDate == null) return AppColors.muted(isDark);
    if (isExpired) return AppColors.error;
    if (daysRemaining != null && daysRemaining! <= 30) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: accent),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTextStyles.capsLabel
                    .copyWith(fontSize: 10, color: accent),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (expiryDate == null)
            Text(
              noInfoText,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.muted(isDark), height: 1.4),
            )
          else ...[
            Text(
              isExpired ? 'Expired' : '${daysRemaining ?? 0}',
              style: AppTextStyles.headingSmall.copyWith(
                fontSize: 28,
                color: accent,
                height: 1.0,
              ),
            ),
            if (!isExpired)
              Text(
                'days left',
                style: AppTextStyles.caption.copyWith(color: accent),
              ),
            const SizedBox(height: 6),
            Text(
              DateFormatter.formatDate(expiryDate!),
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary(isDark)),
            ),
          ],
        ],
      ),
    );
  }
}
