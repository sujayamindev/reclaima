import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/receipt_model.dart';
import '../../data/models/receipt_line_item_model.dart';
import '../../providers/receipt_provider.dart';
import '../../core/utils/formatters.dart';

class ReceiptDetailScreen extends ConsumerWidget {
  final String receiptId;

  const ReceiptDetailScreen({super.key, required this.receiptId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptAsync = ref.watch(receiptProvider(receiptId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Navigate to edit screen
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirmed = await _showDeleteConfirmation(context);
              if (confirmed == true && context.mounted) {
                final controller = ref.read(receiptControllerProvider.notifier);
                final success = await controller.deleteReceipt(receiptId);
                if (success && context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
          ),
        ],
      ),
      body: receiptAsync.when(
        data: (receipt) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Receipt image placeholder ──────────────────────────────
              if (receipt.s3ObjectKey != null)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.border(isDark),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  ),
                  child: const Center(
                    child: Icon(Icons.image, size: 48),
                  ),
                ),
              const SizedBox(height: 24),

              // ── Invoice / Receipt Details ──────────────────────────────
              _buildSection(
                context,
                isDark,
                'Receipt Details',
                Icons.receipt_long_outlined,
                [
                  if (receipt.invoiceNumber != null)
                    _buildInfoRow('Invoice No.', receipt.invoiceNumber!),
                  _buildInfoRow('Store', receipt.storeName ?? 'N/A'),
                  _buildInfoRow(
                    'Purchase Date',
                    receipt.purchaseDate != null
                        ? DateFormatter.formatDate(receipt.purchaseDate!)
                        : 'N/A',
                  ),
                  _buildInfoRow(
                    'Total Amount',
                    receipt.totalAmount != null
                        ? CurrencyFormatter.format(
                            receipt.totalAmount!,
                            currency: receipt.currency ?? 'USD',
                          )
                        : 'N/A',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Vendor / Store Contact ─────────────────────────────────
              if (_hasVendorContact(receipt))
                _buildSection(
                  context,
                  isDark,
                  'Vendor Contact',
                  Icons.store_outlined,
                  [
                    if (receipt.vendorAddress != null)
                      _buildInfoRow('Address', receipt.vendorAddress!),
                    if (receipt.vendorPhone != null)
                      _buildInfoRow('Phone', receipt.vendorPhone!),
                    if (receipt.vendorEmail != null)
                      _buildInfoRow('Email', receipt.vendorEmail!),
                    if (receipt.vendorUrl != null)
                      _buildInfoRow('Website', receipt.vendorUrl!),
                  ],
                ),
              if (_hasVendorContact(receipt)) const SizedBox(height: 16),

              // ── Items Purchased ────────────────────────────────────────
              if (receipt.lineItems.isNotEmpty)
                _buildLineItemsSection(context, isDark, receipt.lineItems),
              if (receipt.lineItems.isNotEmpty) const SizedBox(height: 16),

              // ── Product Information (fallback when no line items) ──────
              if (receipt.lineItems.isEmpty &&
                  (receipt.productName != null ||
                      receipt.productCategory != null))
                _buildSection(
                  context,
                  isDark,
                  'Product Information',
                  Icons.inventory_2_outlined,
                  [
                    _buildInfoRow('Product', receipt.productName ?? 'N/A'),
                    _buildInfoRow(
                        'Category', receipt.productCategory ?? 'N/A'),
                  ],
                ),
              if (receipt.lineItems.isEmpty &&
                  (receipt.productName != null ||
                      receipt.productCategory != null))
                const SizedBox(height: 16),

              // ── Warranty & Return ──────────────────────────────────────
              _buildSection(
                context,
                isDark,
                'Warranty & Return',
                Icons.verified_outlined,
                [
                  if (receipt.warrantyExpiryDate != null) ...[
                    _buildInfoRow(
                      'Warranty Expires',
                      DateFormatter.formatDate(receipt.warrantyExpiryDate!),
                      valueColor: receipt.isWarrantyExpired
                          ? AppColors.error
                          : AppColors.success,
                    ),
                    _buildInfoRow(
                      'Days Remaining',
                      '${receipt.warrantyDaysRemaining} days',
                      valueColor: receipt.isWarrantyExpired
                          ? AppColors.error
                          : AppColors.success,
                    ),
                  ] else
                    _buildInfoRow('Warranty', 'No warranty information'),
                  const Divider(height: 24),
                  if (receipt.returnExpiryDate != null) ...[
                    _buildInfoRow(
                      'Return Expires',
                      DateFormatter.formatDate(receipt.returnExpiryDate!),
                      valueColor: receipt.isReturnExpired
                          ? AppColors.error
                          : AppColors.success,
                    ),
                    _buildInfoRow(
                      'Days Remaining',
                      '${receipt.returnDaysRemaining} days',
                      valueColor: receipt.isReturnExpired
                          ? AppColors.error
                          : AppColors.success,
                    ),
                  ] else
                    _buildInfoRow('Return Window', 'No return information'),
                ],
              ),
              const SizedBox(height: 16),

              // ── Warranty Terms (OCR-extracted policy text) ─────────────
              if (receipt.warrantyNotes != null)
                _buildSection(
                  context,
                  isDark,
                  'Warranty Terms',
                  Icons.policy_outlined,
                  [Text(receipt.warrantyNotes!, style: const TextStyle(fontSize: 13, height: 1.5))],
                ),
              if (receipt.warrantyNotes != null) const SizedBox(height: 16),

              // ── Remarks / Additional Details ───────────────────────────
              if (receipt.remarks != null)
                _buildSection(
                  context,
                  isDark,
                  'Additional Details',
                  Icons.info_outline,
                  [Text(receipt.remarks!)],
                ),
              if (receipt.remarks != null) const SizedBox(height: 16),

              // ── User Notes ─────────────────────────────────────────────
              if (receipt.notes != null)
                _buildSection(
                  context,
                  isDark,
                  'Notes',
                  Icons.notes_outlined,
                  [Text(receipt.notes!)],
                ),
              if (receipt.notes != null) const SizedBox(height: 16),

              // ── Processing Status ──────────────────────────────────────
              _buildSection(
                context,
                isDark,
                'Status',
                Icons.cloud_done_outlined,
                [
                  _buildInfoRow('OCR Status', receipt.status.name),
                  _buildInfoRow('Retry Count', '${receipt.ocrRetryCount}'),
                  if (receipt.lastOcrAttemptAt != null)
                    _buildInfoRow(
                      'Last Attempt',
                      DateFormatter.formatDateTime(receipt.lastOcrAttemptAt!),
                    ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Error loading receipt: $error'),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool _hasVendorContact(ReceiptModel receipt) =>
      receipt.vendorAddress != null ||
      receipt.vendorPhone != null ||
      receipt.vendorEmail != null ||
      receipt.vendorUrl != null;

  Widget _buildSection(
    BuildContext context,
    bool isDark,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: AppColors.border(isDark),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.sectionTitle.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  /// Renders the multi-item line items table.
  Widget _buildLineItemsSection(
    BuildContext context,
    bool isDark,
    List<ReceiptLineItemModel> items,
  ) {
    final headerStyle = AppTextStyles.tableHeader.copyWith(
      color: AppColors.textSecondary(isDark),
    );
    final cellStyle = AppTextStyles.bodyXSmall;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: AppColors.border(isDark),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shopping_cart_outlined,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Items Purchased',
                style: AppTextStyles.sectionTitle.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(isDark),
                ),
              ),
              const Spacer(),
              Text(
                '${items.length} item${items.length == 1 ? '' : 's'}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.muted(isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Header row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('Description', style: headerStyle)),
                SizedBox(width: 48, child: Text('Qty', style: headerStyle, textAlign: TextAlign.center)),
                SizedBox(width: 64, child: Text('Unit', style: headerStyle, textAlign: TextAlign.right)),
                SizedBox(width: 72, child: Text('Amount', style: headerStyle, textAlign: TextAlign.right)),
              ],
            ),
          ),
          const Divider(height: 8),
          // Item rows
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product code (if present)
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
                      child: Text(
                        item.itemDescription ?? '—',
                        style: cellStyle,
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: Text(
                        item.quantity ?? '—',
                        style: cellStyle,
                        textAlign: TextAlign.center,
                      ),
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
                        style: cellStyle.copyWith(fontWeight: FontWeight.w600),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
    bool isDark = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
              style: AppTextStyles.bodyXSmall.copyWith(color: valueColor),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Receipt'),
        content:
            const Text('Are you sure you want to delete this receipt?'),
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

