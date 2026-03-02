import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/receipt_model.dart';
import '../../data/models/receipt_line_item_model.dart';
import '../../providers/receipt_provider.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/product_image_card.dart';

class ReceiptDetailScreen extends ConsumerWidget {
  final String receiptId;

  const ReceiptDetailScreen({super.key, required this.receiptId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptAsync = ref.watch(receiptProvider(receiptId));
    final imageUrlAsync = ref.watch(receiptImageUrlProvider(receiptId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      body: SafeArea(
        child: receiptAsync.when(
          data: (receipt) =>
              _buildScrollBody(context, ref, receipt, imageUrlAsync, isDark),
          loading: () => Column(
            children: [
              _buildTopBar(context, ref, isDark, null),
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ],
          ),
          error: (error, _) => Column(
            children: [
              _buildTopBar(context, ref, isDark, null),
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
                          child: const Icon(
                            Icons.error_outline,
                            size: 32,
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load receipt',
                          style: AppTextStyles.titleLarge.copyWith(
                            color: AppColors.textPrimary(isDark),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$error',
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

  // ── Scrollable body ───────────────────────────────────────────────────────

  Widget _buildScrollBody(
    BuildContext context,
    WidgetRef ref,
    ReceiptModel receipt,
    AsyncValue<String?> imageUrlAsync,
    bool isDark,
  ) {
    const p = AppDimensions.paddingPage;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildTopBar(context, ref, isDark, receipt),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(p, 4, p, 36),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Hero card ────────────────────────────────────────────
              _buildHeroCard(context, ref, receipt, isDark),
              const SizedBox(height: 12),

              // ── Receipt image ─────────────────────────────────────
              if (receipt.s3ObjectKey != null) ...[
                _buildReceiptImageWidget(context, imageUrlAsync, isDark),
                const SizedBox(height: 12),
              ],

              // ── Warranty & Return countdown ───────────────────────
              _buildWarrantyReturnSection(receipt, isDark),
              const SizedBox(height: 12),

              // ── Items Purchased ───────────────────────────────────
              if (receipt.lineItems.isNotEmpty) ...[
                _buildLineItemsSection(isDark, receipt.lineItems),
                const SizedBox(height: 12),
              ],

              // ── Product Information (fallback when no line items) ──
              if (receipt.lineItems.isEmpty &&
                  (receipt.productName != null ||
                      receipt.productCategory != null)) ...[
                _buildSection(
                  isDark,
                  'Product Information',
                  Icons.inventory_2_outlined,
                  [
                    _buildInfoRow(
                        'Product', receipt.productName ?? 'N/A', isDark),
                    _buildInfoRow(
                        'Category', receipt.productCategory ?? 'N/A', isDark),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // ── Product Image (Brave Search) ──────────────────────
              if (receipt.productName != null) ...[
                ProductImageCard(
                  productName: receipt.productName!,
                  imageUrlFuture: Future.value(receipt.productImageUrl),
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
              ],

              // ── Vendor Contact ────────────────────────────────────
              if (_hasVendorContact(receipt)) ...[
                _buildSection(
                  isDark,
                  'Vendor Contact',
                  Icons.store_outlined,
                  [
                    if (receipt.vendorAddress != null)
                      _buildInfoRow('Address', receipt.vendorAddress!, isDark),
                    if (receipt.vendorPhone != null)
                      _buildInfoRow('Phone', receipt.vendorPhone!, isDark),
                    if (receipt.vendorEmail != null)
                      _buildInfoRow('Email', receipt.vendorEmail!, isDark),
                    if (receipt.vendorUrl != null)
                      _buildInfoRow('Website', receipt.vendorUrl!, isDark),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // ── Warranty Terms ────────────────────────────────────
              if (receipt.warrantyNotes != null) ...[
                _buildSection(
                  isDark,
                  'Warranty Terms',
                  Icons.policy_outlined,
                  [
                    Text(
                      receipt.warrantyNotes!,
                      style: AppTextStyles.bodyXSmall.copyWith(
                        color: AppColors.textSecondary(isDark),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // ── Remarks ───────────────────────────────────────────
              if (receipt.remarks != null) ...[
                _buildSection(
                  isDark,
                  'Additional Details',
                  Icons.info_outline,
                  [
                    Text(
                      receipt.remarks!,
                      style: AppTextStyles.bodyXSmall.copyWith(
                        color: AppColors.textSecondary(isDark),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // ── Notes ─────────────────────────────────────────────
              if (receipt.notes != null) ...[
                _buildSection(
                  isDark,
                  'Notes',
                  Icons.notes_outlined,
                  [
                    Text(
                      receipt.notes!,
                      style: AppTextStyles.bodyXSmall.copyWith(
                        color: AppColors.textSecondary(isDark),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // ── Processing Status ─────────────────────────────────
              _buildSection(
                isDark,
                'Processing Status',
                Icons.cloud_done_outlined,
                [
                  _buildInfoRow('OCR Status', receipt.status.name, isDark),
                  _buildInfoRow(
                      'Retry Count', '${receipt.ocrRetryCount}', isDark),
                  if (receipt.lastOcrAttemptAt != null)
                    _buildInfoRow(
                      'Last Attempt',
                      DateFormatter.formatDateTime(receipt.lastOcrAttemptAt!),
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

  // ── Top bar (back + title + actions) ─────────────────────────────────────

  Widget _buildTopBar(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    ReceiptModel? receipt,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, color: AppColors.textPrimary(isDark)),
            padding: const EdgeInsets.all(8),
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
              shape: const CircleBorder(),
            ),
          ),
          Expanded(
            child: Text(
              'Receipt Details',
              textAlign: TextAlign.center,
              style: AppTextStyles.listTitle.copyWith(
                fontSize: 17,
                color: AppColors.textPrimary(isDark),
              ),
            ),
          ),
          // Balance the back button width
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // ── Hero card ─────────────────────────────────────────────────────────────

  Widget _buildHeroCard(
    BuildContext context,
    WidgetRef ref,
    ReceiptModel receipt,
    bool isDark,
  ) {
    final statusColor = _receiptStatusColor(receipt, isDark);

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
          // Store icon + name + amount
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMedium),
                ),
                child: const Icon(
                  Icons.store_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      receipt.storeName ?? 'Unknown Store',
                      style: AppTextStyles.listTitle.copyWith(
                        fontSize: 17,
                        color: AppColors.textPrimary(isDark),
                      ),
                    ),
                    if (receipt.purchaseDate != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        DateFormatter.formatDate(receipt.purchaseDate!),
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary(isDark)),
                      ),
                    ],
                  ],
                ),
              ),
              if (receipt.totalAmount != null) ...[
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(
                        receipt.totalAmount!,
                        currency: receipt.currency ?? 'USD',
                      ),
                      style: AppTextStyles.listTitle.copyWith(
                        fontSize: 16,
                        color: AppColors.textPrimary(isDark),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      receipt.currency ?? 'USD',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary(isDark)),
                    ),
                  ],
                ),
              ],
            ],
          ),

          // Product name + invoice number
          if (receipt.productName != null || receipt.invoiceNumber != null) ...[
            const SizedBox(height: 14),
            Divider(color: AppColors.border(isDark), height: 1),
            const SizedBox(height: 14),
            if (receipt.productName != null)
              Text(
                receipt.productName!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary(isDark),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            if (receipt.invoiceNumber != null) ...[
              const SizedBox(height: 4),
              Text(
                'Invoice # ${receipt.invoiceNumber}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.muted(isDark),
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ],

          // Status + category badges
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _StatusBadge(
                color: statusColor,
                label: _receiptStatusLabel(receipt),
              ),
              if (receipt.productCategory != null)
                _StatusBadge(
                  color: AppColors.textSecondary(isDark),
                  label: receipt.productCategory!,
                  filled: false,
                  isDark: isDark,
                ),
            ],
          ),

          // Action buttons
          const SizedBox(height: 14),
          Divider(color: AppColors.border(isDark), height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _HeroActionButton(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  isDark: isDark,
                  onPressed: () {
                    // TODO: navigate to edit screen
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroActionButton(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  isDark: isDark,
                  color: AppColors.error,
                  onPressed: () async {
                    final confirmed =
                        await _showDeleteConfirmation(context);
                    if (confirmed == true && context.mounted) {
                      final controller =
                          ref.read(receiptControllerProvider.notifier);
                      final success =
                          await controller.deleteReceipt(receipt.id);
                      if (success && context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Warranty & Return countdown tiles ─────────────────────────────────────

  Widget _buildWarrantyReturnSection(ReceiptModel receipt, bool isDark) {
    // Only show tiles for line items that have warranty or return data.
    final trackedItems = receipt.lineItems
        .where(
          (li) => li.warrantyExpiryDate != null || li.returnExpiryDate != null,
        )
        .toList();

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
          if (trackedItems.isEmpty)
            _buildNoWarrantyPlaceholder(isDark)
          else
            ...trackedItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Divider + item name header for multi-item receipts.
                  if (trackedItems.length > 1) ...[
                    if (index > 0) ...[
                      const SizedBox(height: 4),
                      Divider(color: AppColors.border(isDark), height: 20),
                    ],
                    Text(
                      item.displayName,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary(isDark),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: _CountdownTile(
                          label: 'WARRANTY',
                          icon: Icons.shield_outlined,
                          expiryDate: item.warrantyExpiryDate,
                          daysRemaining: item.warrantyDaysRemaining,
                          isExpired: item.isWarrantyExpired,
                          noInfoText: 'Not set',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _CountdownTile(
                          label: 'RETURN',
                          icon: Icons.assignment_return_outlined,
                          expiryDate: item.returnExpiryDate,
                          daysRemaining: item.returnDaysRemaining,
                          isExpired: item.isReturnExpired,
                          noInfoText: 'Not set',
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildNoWarrantyPlaceholder(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Icon(
              Icons.verified_user_outlined,
              size: 36,
              color: AppColors.muted(isDark),
            ),
            const SizedBox(height: 10),
            Text(
              'No warranty information tracked',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.muted(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Receipt image with tap-to-fullscreen ─────────────────────────────────

  Widget _buildReceiptImageWidget(
    BuildContext context,
    AsyncValue<String?> imageUrlAsync,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () => imageUrlAsync.whenData((url) {
        if (url != null) _openFullscreenImage(context, url);
      }),
      child: Container(
        height: 240,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.card(isDark),
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
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
                    size: 36, color: AppColors.muted(isDark)),
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
                      right: 12,
                      bottom: 12,
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
                                color: Colors.white, size: 16),
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

  // ── Generic section card ──────────────────────────────────────────────────

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

  // ── Line items table ──────────────────────────────────────────────────────

  Widget _buildLineItemsSection(
    bool isDark,
    List<ReceiptLineItemModel> items,
  ) {
    final headerStyle = AppTextStyles.tableHeader
        .copyWith(color: AppColors.textSecondary(isDark));
    final cellStyle =
        AppTextStyles.bodyXSmall.copyWith(color: AppColors.textPrimary(isDark));

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
                  title: 'Items Purchased',
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
                  '${items.length} item${items.length == 1 ? '' : 's'}',
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
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
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
                        child:
                            Text(item.itemDescription ?? '—', style: cellStyle),
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
                          style:
                              cellStyle.copyWith(fontWeight: FontWeight.w600),
                          textAlign: TextAlign.right,
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

  Color _receiptStatusColor(ReceiptModel receipt, bool isDark) {
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

  String _receiptStatusLabel(ReceiptModel receipt) {
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

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Receipt'),
        content: const Text('Are you sure you want to delete this receipt?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Private helper widgets ─────────────────────────────────────────────────

/// Circular icon button — mirrors the home screen's _CircleIconButton style.
class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.isDark,
    required this.onPressed,
    this.iconColor,
  });

  final IconData icon;
  final bool isDark;
  final VoidCallback onPressed;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppDimensions.circleButtonSize,
      height: AppDimensions.circleButtonSize,
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border(isDark)),
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Icon(
            icon,
            size: 20,
            color: iconColor ?? AppColors.textSecondary(isDark),
          ),
        ),
      ),
    );
  }
}

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color.withValues(alpha: 0.12) : AppColors.border(isDark),
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (filled) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppTextStyles.badgeText.copyWith(
              color: filled ? color : AppColors.textSecondary(isDark),
            ),
          ),
        ],
      ),
    );
  }
}

/// Outlined action button used inside the hero card.
class _HeroActionButton extends StatelessWidget {
  const _HeroActionButton({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? AppColors.textSecondary(isDark);
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: fg),
      label: Text(label, style: AppTextStyles.badgeText.copyWith(color: fg)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10),
        side: BorderSide(
          color: color != null
              ? color!.withValues(alpha: 0.35)
              : AppColors.border(isDark),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        backgroundColor: color != null
            ? color!.withValues(alpha: 0.07)
            : Colors.transparent,
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
