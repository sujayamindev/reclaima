import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import '../../data/models/product_view_model.dart';
import '../../data/models/receipt_model.dart';
import '../../data/models/receipt_line_item_model.dart';
import '../../providers/receipt_provider.dart';
import '../../core/utils/formatters.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'claim_pdf_screen.dart';
import 'claims_list_screen.dart';

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
          loading: () => CustomScrollView(
            slivers: [
              _buildStickyAppBar(context, ref, null, isDark),
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ],
          ),
          error: (err, _) => CustomScrollView(
            slivers: [
              _buildStickyAppBar(context, ref, null, isDark),
              SliverFillRemaining(
                hasScrollBody: false,
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
                          child: const Icon(
                            Symbols.error_rounded,
                            size: 32,
                            color: AppColors.error,
                            weight: 800.0,
                          ),
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
        _buildStickyAppBar(context, ref, product, isDark),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(p, 4, p, 36),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Hero card ───────────────────────────────────────
              _buildHeroCard(product, isDark),
              const SizedBox(height: 12),
              
              // ── Link Banners (Replacements) ──────────────────────
              _buildLinkBanners(context, ref, product, isDark),

              // ── Warranty & Return countdown ──────────────────────
              _buildWarrantySection(context, product, isDark),
              const SizedBox(height: 12),

              // ── Per-product Notification Settings ─────────────────
              _NotificationSettings(
                isDark: isDark,
                hasWarranty: product.hasWarranty,
                hasReturn: product.hasReturn,
                receiptId: receiptId,
                lineItemId: lineItemId ?? '',
                ref: ref,
                currentWarrantyLeadOverride:
                    product.lineItem?.warrantyLeadDaysOverride,
                currentReturnLeadOverride:
                    product.lineItem?.returnLeadDaysOverride,
                currentWarrantyReminderEnabled:
                    product.lineItem?.warrantyReminderEnabled,
                currentReturnReminderEnabled:
                    product.lineItem?.returnReminderEnabled,
              ),
              const SizedBox(height: 12),

              // ── Purchase Details ─────────────────────────────────
              _buildPurchaseDetails(
                  context, product.receipt, imageUrlAsync, isDark),
              const SizedBox(height: 12),

              // ── Product Info (single-item only) ──────────────────
              if (product.lineItem != null &&
                  product.receipt.lineItems.length <= 1 &&
                  _hasProductInfo(product.lineItem!)) ...[
                _buildSection(
                  isDark,
                  'Product Info',
                  Symbols.info_rounded,
                  [
                    if (product.lineItem!.quantity != null)
                      _buildInfoRow(
                          'Quantity', product.lineItem!.quantity!, isDark),
                    if (product.lineItem!.unitPrice != null)
                      _buildInfoRow(
                        'Unit Price',
                        CurrencyFormatter.format(
                          product.lineItem!.unitPrice!,
                          currency: product.currency ?? 'USD',
                        ),
                        isDark,
                      ),
                    if (product.lineItem!.amount != null)
                      _buildInfoRow(
                        'Amount',
                        CurrencyFormatter.format(
                          product.lineItem!.amount!,
                          currency: product.currency ?? 'USD',
                        ),
                        isDark,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // ── All line items table (multi-product context) ──────
              if (product.receipt.lineItems.length > 1) ...[
                _buildLineItemsSection(isDark, product.receipt.lineItems,
                    highlightId: lineItemId),
                const SizedBox(height: 12),
              ],

              // ── Vendor Contact ───────────────────────────────────
              if (_hasVendorContact(product.receipt)) ...[
                _buildSection(
                  isDark,
                  'Vendor Contact',
                  Symbols.contact_support_rounded,
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

              // ── Warranty Terms ───────────────────────────────────
              if (product.receipt.warrantyNotes != null) ...[
                _buildSection(
                  isDark,
                  'Warranty Terms',
                  Symbols.policy_rounded,
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

              // ── Additional Details ───────────────────────────────
              if (product.receipt.remarks != null) ...[
                _buildSection(
                  isDark,
                  'Additional Details',
                  Symbols.info_rounded,
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

              // ── Notes ────────────────────────────────────────────
              if (product.receipt.notes != null) ...[
                _buildSection(
                  isDark,
                  'Notes',
                  Symbols.notes_rounded,
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

              // ── Processing Status ────────────────────────────────
              _buildSection(
                isDark,
                'Processing Status',
                Symbols.cloud_done_rounded,
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
                  _buildInfoRow(
                    'Added',
                    DateFormatter.formatDateTime(product.receipt.createdAt),
                    isDark,
                  ),
                  if (product.receipt.syncedAt != null)
                    _buildInfoRow(
                      'Last Synced',
                      DateFormatter.formatDateTime(
                          product.receipt.syncedAt!),
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

  /// Sticky app bar that stays pinned at the top while scrolling
  Widget _buildStickyAppBar(
    BuildContext context,
    WidgetRef ref,
    ProductViewModel? product,
    bool isDark,
  ) {
    return SliverAppBar(
      backgroundColor: AppColors.background(isDark),
      surfaceTintColor: Colors.transparent,
      pinned: true,
      toolbarHeight: 64,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Symbols.arrow_back_rounded, color: AppColors.textPrimary(isDark), weight: 600.0,),
        padding: const EdgeInsets.all(8),
        style: IconButton.styleFrom(
          backgroundColor: Colors.transparent,
          shape: const CircleBorder(),
        ),
      ),
      title: Text(
        'Product Details',
        style: AppTextStyles.listTitle.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary(isDark),
        ),
      ),
      centerTitle: true,
      actions: [
        if (product != null)
          PopupMenuButton<String>(
            icon: Icon(Symbols.more_horiz_rounded,
              color: AppColors.textPrimary(isDark), size: 22, weight: 600.0, grade: 200.0),
            padding: EdgeInsets.zero,
            position: PopupMenuPosition.under,
            offset: const Offset(0, 8),
            menuPadding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 124, maxWidth: 124),
            color: AppColors.card(isDark),
            elevation: 4,
            shadowColor: Colors.black.withValues(alpha: 0.12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
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
            itemBuilder: (_) => [_buildActionsMenuEntry(context, isDark)],
          )
        else
          const SizedBox(width: 48),
      ],
    );
  }

  PopupMenuEntry<String> _buildActionsMenuEntry(
    BuildContext context,
    bool isDark,
  ) {
    return PopupMenuItem<String>(
      value: '_noop',
      height: 52,
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: 124,
        height: 52,
        child: Row(
          children: [
            Expanded(
              child: Center(
                child: InkWell(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusPill),
                  onTap: () => Navigator.of(context).pop('edit'),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      Symbols.edit_rounded,
                      size: 20,
                      color: AppColors.primary,
                      weight: 800.0,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 20,
              child: VerticalDivider(
                width: 1,
                thickness: 1,
                color: AppColors.border(isDark),
              ),
            ),
            Expanded(
              child: Center(
                child: InkWell(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusPill),
                  onTap: () => Navigator.of(context).pop('delete'),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      Symbols.delete_rounded,
                      size: 20,
                      color: AppColors.error,
                      weight: 800.0
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
      child: Stack(
        children: [
          Column(
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

              // ── Product name ───────────────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: product.displayName,
                          style: AppTextStyles.listTitle.copyWith(
                            fontSize: 16,
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
                  if (product.lineItem?.productCode != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      product.lineItem!.productCode!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.muted(isDark),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                  if (product.receipt.storeName != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Symbols.storefront_rounded,
                          size: 14, color: AppColors.muted(isDark), weight: 800.0),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            product.receipt.storeName!,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.muted(isDark),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Link Banners (Replacements) ──────────────────────────────────────────

  Widget _buildLinkBanners(BuildContext context, WidgetRef ref, ProductViewModel product, bool isDark) {
    if (product.lineItem == null) return const SizedBox.shrink();
    
    final replacedById = product.lineItem!.replacedById;
    final replacementForId = product.lineItem!.replacementForId;
    
    if (replacedById == null && replacementForId == null) return const SizedBox.shrink();
    
    final allReceiptsVal = ref.read(receiptsProvider);
    if (allReceiptsVal.valueOrNull == null) return const SizedBox.shrink();
    
    final allReceipts = allReceiptsVal.value!;
    
    Widget buildBanner({required String id, required String label, required IconData icon, required Color color}) {
      // Find the receipt that has this line item
      ReceiptModel? targetReceipt;
      for (final r in allReceipts) {
        if (r.lineItems.any((item) => item.id == id)) {
          targetReceipt = r;
          break;
        }
      }
      
      if (targetReceipt == null) return const SizedBox.shrink();
      
      return InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(receiptId: targetReceipt!.id, lineItemId: id)));
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textPrimary(isDark), fontWeight: FontWeight.w600),
                ),
              ),
              Icon(Symbols.chevron_right_rounded, color: color, size: 20, weight: 800.0),
            ],
          ),
        ),
      );
    }
    
    return Column(
      children: [
        if (replacedById != null) buildBanner(id: replacedById, label: 'View Replacement Item', icon: Symbols.autorenew_rounded, color: AppColors.primary),
        if (replacementForId != null) buildBanner(id: replacementForId, label: 'View Original Replaced Item', icon: Symbols.history_rounded, color: AppColors.info),
      ],
    );
  }

  // ── Warranty & Return section ─────────────────────────────────────────────

  Widget _buildWarrantySection(BuildContext context, ProductViewModel product, bool isDark) {
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
            icon: Symbols.verified_rounded,
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
                    icon: Symbols.shield_rounded,
                    expiryDate: product.warrantyExpiryDate,
                    daysRemaining: product.warrantyDaysRemaining,
                    totalDays: product.warrantyPeriodMonths != null
                        ? product.warrantyPeriodMonths! * 30
                        : null,
                    isExpired: product.isWarrantyExpired,
                    noInfoText: 'Not set',
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CountdownTile(
                    label: 'RETURN',
                    icon: Symbols.assignment_return_rounded,
                    expiryDate: product.returnExpiryDate,
                    daysRemaining: product.returnDaysRemaining,
                    totalDays: product.returnPeriodDays,
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
            const SizedBox(height: 14),
            if (product.warrantyPeriodMonths != null)
              _buildPeriodRow(
                'Warranty period',
                '${product.warrantyPeriodMonths} months',
                isDark,
              ),
            if (product.returnPeriodDays != null)
              _buildPeriodRow(
                'Return window',
                '${product.returnPeriodDays} days',
                isDark,
              ),
          ],
          // ── Warranty Claims Button ────────────────────────────────
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: AppDimensions.buttonHeight,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClaimsListScreen(
                      receiptId: product.receiptId,
                      lineItemId: product.lineItemId,
                      receiptStoreName: product.receipt.storeName ?? 'Store',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                elevation: 0,
                shadowColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                overlayColor: Colors.transparent,
                splashFactory: NoSplash.splashFactory,
                enableFeedback: false,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusXL),
                  side: BorderSide.none,
                ),
                side: BorderSide.none,
              ),
              icon: const Icon(Symbols.description_rounded, size: 20, weight: 800.0),
              label: const Text('Manage Claims'),
            ),
          ),
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
            Icon(Symbols.verified_user_rounded,
              size: 36, color: AppColors.muted(isDark), weight: 800.0),
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

  // ── Details card ─────────────────────────────────────────────────

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
                const Icon(Symbols.storefront_rounded,
                  size: 20, color: AppColors.primary, weight: 800.0),
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
                Icon(Symbols.broken_image_rounded,
                  size: 32, color: AppColors.muted(isDark), weight: 800.0),
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
                        Icon(Symbols.receipt_long_rounded,
                          size: 36, color: AppColors.muted(isDark), weight: 800.0),
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
                        child: Icon(Symbols.broken_image_rounded,
                          size: 36, color: AppColors.muted(isDark), weight: 800.0),
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
                            const Icon(Symbols.fullscreen_rounded,
                              color: Colors.white, size: 15, weight: 800.0),
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
                  icon: const Icon(Symbols.close_rounded, color: Colors.white, size: 24, weight: 800.0),
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
                  icon: Symbols.shopping_cart_rounded,
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

  // ── Period row (label left, value right) ──────────────────────────────────

  Widget _buildPeriodRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyXSmall.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary(isDark),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyXSmall.copyWith(
              color: AppColors.textPrimary(isDark),
            ),
          ),
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

  bool _hasProductInfo(ReceiptLineItemModel item) =>
      item.productCode != null ||
      item.quantity != null ||
      item.unitPrice != null ||
      item.amount != null;

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
        Icon(icon, size: 20, color: AppColors.primary, weight: 800.0),
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



/// Side-by-side countdown tile showing days remaining until expiry
/// with a circular progress ring.
class _CountdownTile extends StatelessWidget {
  const _CountdownTile({
    required this.label,
    required this.icon,
    required this.expiryDate,
    required this.daysRemaining,
    required this.totalDays,
    required this.isExpired,
    required this.noInfoText,
    required this.isDark,
  });

  final String label;
  final IconData icon;
  final DateTime? expiryDate;
  final int? daysRemaining;
  final int? totalDays;
  final bool isExpired;
  final String noInfoText;
  final bool isDark;

  Color get _accent {
    if (expiryDate == null) return AppColors.muted(isDark);
    if (isExpired) return AppColors.error;
    if (daysRemaining != null && daysRemaining! <= 30) return AppColors.warning;
    return AppColors.success;
  }

  double get _progress {
    if (expiryDate == null || totalDays == null || totalDays! <= 0) return 0.0;
    if (isExpired) return 0.0;
    final remaining = (daysRemaining ?? 0).clamp(0, totalDays!);
    return remaining / totalDays!;
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent;
    final progress = _progress;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.border(isDark).withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          // Label row
          Row(
            children: [
              Icon(icon, size: 13, color: accent, weight: 800.0),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTextStyles.capsLabel
                    .copyWith(fontSize: 10, color: accent),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Circular progress ring with centered text
          if (expiryDate == null) ...[
            SizedBox(
              width: 80,
              height: 80,
              child: CustomPaint(
                painter: _CircularCountdownPainter(
                  progress: 0,
                  accentColor: AppColors.muted(isDark),
                  trackColor: AppColors.muted(isDark).withValues(alpha: 0.15),
                  strokeWidth: 6,
                ),
                child: Center(
                  child: Text(
                    noInfoText,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.muted(isDark),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Invisible spacer matching the date text height below
            Text(
              ' ',
              style: AppTextStyles.caption,
            ),
          ]
          else ...[
            SizedBox(
              width: 80,
              height: 80,
              child: CustomPaint(
                painter: _CircularCountdownPainter(
                  progress: progress,
                  accentColor: accent,
                  trackColor: accent.withValues(alpha: 0.15),
                  strokeWidth: 6,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isExpired ? '!' : '${daysRemaining ?? 0}',
                        style: AppTextStyles.headingSmall.copyWith(
                          fontSize: isExpired ? 24 : 22,
                          color: accent,
                          height: 1.0,
                        ),
                      ),
                      if (!isExpired)
                        Text(
                          'days',
                          style: AppTextStyles.caption.copyWith(
                            color: accent,
                            fontSize: 10,
                          ),
                        ),
                      if (isExpired)
                        Text(
                          'Expired',
                          style: AppTextStyles.caption.copyWith(
                            color: accent,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
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

/// Paints a circular progress arc for the countdown tiles.
class _CircularCountdownPainter extends CustomPainter {
  _CircularCountdownPainter({
    required this.progress,
    required this.accentColor,
    required this.trackColor,
    this.strokeWidth = 6,
  });

  final double progress;
  final Color accentColor;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) - strokeWidth) / 2;

    // Track (background circle)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    if (progress > 0) {
      final arcPaint = Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      const startAngle = -pi / 2; // 12 o'clock
      final sweepAngle = 2 * pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_CircularCountdownPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.accentColor != accentColor;
}

/// Per-product notification preferences card.
///
/// Local state only — backend persistence will be added later.
class _NotificationSettings extends StatefulWidget {
  const _NotificationSettings({
    required this.isDark,
    required this.hasWarranty,
    required this.hasReturn,
    required this.receiptId,
    required this.lineItemId,
    required this.ref,
    this.currentWarrantyLeadOverride,
    this.currentReturnLeadOverride,
    this.currentWarrantyReminderEnabled,
    this.currentReturnReminderEnabled,
  });

  final bool isDark;
  final bool hasWarranty;
  final bool hasReturn;
  final String receiptId;
  final String lineItemId;
  final WidgetRef ref;
  final int? currentWarrantyLeadOverride;
  final int? currentReturnLeadOverride;
  final bool? currentWarrantyReminderEnabled;
  final bool? currentReturnReminderEnabled;

  @override
  State<_NotificationSettings> createState() => _NotificationSettingsState();
}

class _NotificationSettingsState extends State<_NotificationSettings> {
  // Global reminder toggles (read-only, from user preferences)
  bool _warrantyReminder = true;
  bool _returnReminder = true;

  // Per-product lead time overrides
  int? _localWarrantyLeadOverride;
  int? _localReturnLeadOverride;

  // Save state
  bool _isSaving = false;

  static const _warrantyOptions = [7, 14, 30, 60, 90];
  static const _returnOptions = [1, 2, 3, 5, 7];

  @override
  void initState() {
    super.initState();
    // Initialize with current override values from the product
    _localWarrantyLeadOverride = widget.currentWarrantyLeadOverride;
    _localReturnLeadOverride = widget.currentReturnLeadOverride;
    // Initialize reminder on/off state from the product (default to true if not set)
    _warrantyReminder = widget.currentWarrantyReminderEnabled ?? true;
    _returnReminder = widget.currentReturnReminderEnabled ?? true;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

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
          // Header
          Row(
            children: [
                Icon(Symbols.notifications_rounded,
                  size: 20, color: AppColors.primary, weight: 800.0),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Notifications',
                  style: AppTextStyles.sectionTitle
                      .copyWith(color: AppColors.textPrimary(isDark)),
                ),
              ),
            ],
          ),

          // Warranty reminder
          if (widget.hasWarranty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _overrideLeadTimeSelector(
                widget.isDark,
                options: _warrantyOptions,
                selected: _localWarrantyLeadOverride,
                onChanged: (v) =>
                    setState(() => _localWarrantyLeadOverride = v),
                reminderEnabled: _warrantyReminder,
                onReminderEnabledChanged: (v) =>
                    setState(() => _warrantyReminder = v),
              ),
            ),
          ],



          // Return reminder
          if (widget.hasReturn) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _overrideLeadTimeSelector(
                widget.isDark,
                options: _returnOptions,
                selected: _localReturnLeadOverride,
                onChanged: (v) =>
                    setState(() => _localReturnLeadOverride = v),
                reminderEnabled: _returnReminder,
                onReminderEnabledChanged: (v) =>
                    setState(() => _returnReminder = v),
              ),
            ),
          ],

          // Save button (if has warranty or return)
          if ((widget.hasWarranty || widget.hasReturn) &&
              (_localWarrantyLeadOverride != widget.currentWarrantyLeadOverride ||
                  _localReturnLeadOverride != widget.currentReturnLeadOverride ||
                  _warrantyReminder != (widget.currentWarrantyReminderEnabled ?? true) ||
                  _returnReminder != (widget.currentReturnReminderEnabled ?? true)))
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveNotificationSettings,
                  icon: _isSaving
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                              AppColors.background(false),
                            ),
                          ),
                        )
                      : const Icon(Symbols.save_rounded, weight: 800.0),
                  label: Text(_isSaving
                      ? 'Saving...'
                      : 'Save Notification Settings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background(false),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusPill),
                    ),
                  ),
                ),
              ),
            ),

          // Fallback when no warranty or return
          if (!widget.hasWarranty && !widget.hasReturn)
            Text(
              'No warranty or return info to set reminders for.',
              style: AppTextStyles.bodyXSmall.copyWith(
                color: AppColors.muted(widget.isDark),
              ),
            ),
        ],
      ),
    );
  }

  // ── Save notification settings ──────────────────────────────────────

  Future<void> _saveNotificationSettings() async {
    setState(() => _isSaving = true);
    try {
      await widget.ref
          .read(receiptControllerProvider.notifier)
          .updateLineItem(
            widget.receiptId,
            widget.lineItemId,
            {
              if (_localWarrantyLeadOverride != null)
                'warrantyLeadDaysOverride': _localWarrantyLeadOverride,
              if (_localReturnLeadOverride != null)
                'returnLeadDaysOverride': _localReturnLeadOverride,
              'warrantyReminderEnabled': _warrantyReminder,
              'returnReminderEnabled': _returnReminder,
            },
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification settings saved'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(milliseconds: 1500),
          ),
        );
      }
    } catch (e, st) {
      logger.e('Failed to save notification settings: $e', stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save notification settings'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Override lead time chip selector ────────────────────────────────

  Widget _overrideLeadTimeSelector(
    bool isDark, {
    required List<int> options,
    required int? selected,
    required ValueChanged<int?> onChanged,
    required bool reminderEnabled,
    required ValueChanged<bool> onReminderEnabledChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            // "Off" option
            GestureDetector(
              onTap: () {
                onReminderEnabledChanged(false);
                onChanged(null);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: !reminderEnabled
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusPill),
                  border: Border.all(
                    color: !reminderEnabled
                        ? AppColors.primary
                        : AppColors.border(isDark),
                  ),
                ),
                child: Text(
                  'Off',
                  style: AppTextStyles.caption.copyWith(
                    color: !reminderEnabled
                        ? AppColors.primary
                        : AppColors.textSecondary(isDark),
                    fontWeight:
                        !reminderEnabled ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
            // "Use Default" option
            GestureDetector(
              onTap: () {
                onReminderEnabledChanged(true);
                onChanged(null);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: reminderEnabled && selected == null
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusPill),
                  border: Border.all(
                    color: reminderEnabled && selected == null
                        ? AppColors.primary
                        : AppColors.border(isDark),
                  ),
                ),
                child: Text(
                  'Use default',
                  style: AppTextStyles.caption.copyWith(
                    color: reminderEnabled && selected == null
                        ? AppColors.primary
                        : AppColors.textSecondary(isDark),
                    fontWeight: reminderEnabled && selected == null
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
            // Custom options
            ...options.map((days) {
              final isSelected = reminderEnabled && days == selected;
              return GestureDetector(
                onTap: () {
                  onReminderEnabledChanged(true);
                  onChanged(days);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusPill),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.border(isDark),
                    ),
                  ),
                  child: Text(
                    '$days days',
                    style: AppTextStyles.caption.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary(isDark),
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ],
    );
  }
}
