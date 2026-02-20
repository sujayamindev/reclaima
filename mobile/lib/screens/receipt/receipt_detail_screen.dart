import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/receipt_provider.dart';
import '../../core/utils/formatters.dart';

class ReceiptDetailScreen extends ConsumerWidget {
  final String receiptId;

  const ReceiptDetailScreen({super.key, required this.receiptId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptAsync = ref.watch(receiptProvider(receiptId));

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
              // Receipt image placeholder
              if (receipt.s3ObjectKey != null)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(Icons.image, size: 48),
                  ),
                ),
              const SizedBox(height: 24),

              // Store info
              _buildSection(
                context,
                'Store Information',
                [
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
              const SizedBox(height: 24),

              // Product info
              _buildSection(
                context,
                'Product Information',
                [
                  _buildInfoRow('Product', receipt.productName ?? 'N/A'),
                  _buildInfoRow('Category', receipt.productCategory ?? 'N/A'),
                ],
              ),
              const SizedBox(height: 24),

              // Warranty info
              _buildSection(
                context,
                'Warranty & Return',
                [
                  if (receipt.warrantyExpiryDate != null) ...[
                    _buildInfoRow(
                      'Warranty Expires',
                      DateFormatter.formatDate(receipt.warrantyExpiryDate!),
                      valueColor: receipt.isWarrantyExpired
                          ? Colors.red
                          : Colors.green,
                    ),
                    _buildInfoRow(
                      'Days Remaining',
                      '${receipt.warrantyDaysRemaining} days',
                      valueColor: receipt.isWarrantyExpired
                          ? Colors.red
                          : Colors.green,
                    ),
                  ] else
                    _buildInfoRow('Warranty', 'No warranty information'),
                  const Divider(),
                  if (receipt.returnExpiryDate != null) ...[
                    _buildInfoRow(
                      'Return Window Expires',
                      DateFormatter.formatDate(receipt.returnExpiryDate!),
                      valueColor: receipt.isReturnExpired
                          ? Colors.red
                          : Colors.green,
                    ),
                    _buildInfoRow(
                      'Days Remaining',
                      '${receipt.returnDaysRemaining} days',
                      valueColor: receipt.isReturnExpired
                          ? Colors.red
                          : Colors.green,
                    ),
                  ] else
                    _buildInfoRow('Return Window', 'No return information'),
                ],
              ),
              const SizedBox(height: 24),

              // Notes
              if (receipt.notes != null) ...[
                _buildSection(
                  context,
                  'Notes',
                  [
                    Text(receipt.notes!),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Status
              _buildSection(
                context,
                'Status',
                [
                  _buildInfoRow('OCR Status', receipt.status.toString()),
                  _buildInfoRow('Retry Count', '${receipt.ocrRetryCount}'),
                  if (receipt.lastOcrAttemptAt != null)
                    _buildInfoRow(
                      'Last OCR Attempt',
                      DateFormatter.formatDateTime(receipt.lastOcrAttemptAt!),
                    ),
                ],
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading receipt: $error'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
              ),
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
        content: const Text('Are you sure you want to delete this receipt?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
