import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/receipt_provider.dart';
import '../../providers/service_providers.dart';
import '../../widgets/step_progress_bar.dart';
import '../../widgets/product_image_card.dart';
import 'receipt_detail_screen.dart';

class ReceiptConfirmationScreen extends ConsumerStatefulWidget {
  final String? receiptId;
  final bool isManualEntry;
  final Map<String, dynamic> formData;
  final DateTime? warrantyExpiryDate;
  final DateTime? returnExpiryDate;
  /// ID of the existing primary line item to PATCH with product/warranty data.
  /// Null for new manual-entry receipts (a new line item is created instead).
  final String? primaryLineItemId;
  /// Product / warranty fields destined for the line-item PATCH/POST.
  final Map<String, dynamic> lineItemData;

  const ReceiptConfirmationScreen({
    super.key,
    required this.receiptId,
    required this.isManualEntry,
    required this.formData,
    this.warrantyExpiryDate,
    this.returnExpiryDate,
    this.primaryLineItemId,
    this.lineItemData = const {},
  });

  @override
  ConsumerState<ReceiptConfirmationScreen> createState() =>
      _ReceiptConfirmationScreenState();
}

class _ReceiptConfirmationScreenState
    extends ConsumerState<ReceiptConfirmationScreen> {
  // ─── State ──────────────────────────────────────────────────────────────────

  /// Cached future for the product image URL lookup.
  Future<String?>? _productImageFuture;

  @override
  void initState() {
    super.initState();
    final productName = widget.formData['productName'] as String?;
    if (productName != null && productName.trim().isNotEmpty) {
      _productImageFuture = ref
          .read(productImageServiceProvider)
          .getProductImageUrl(productName);
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}T00:00:00';

  String _displayDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  int _daysUntil(DateTime date) {
    final now = DateTime.now();
    return date.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  /// Converts a raw day count into a human-friendly (value, unit) pair.
  ///
  /// - ≥ 30 days  →  rounded-up months  (e.g. 45 days → "2 months")
  /// - < 30 days  →  days               (e.g. 15 → "15 days")
  ({String value, String unit}) _formatDuration(int totalDays) {
    final absDays = totalDays.abs();

    if (absDays >= 30) {
      final months = (absDays / 30).ceil();
      return (value: '$months', unit: months == 1 ? 'month' : 'months');
    } else {
      return (value: '$absDays', unit: absDays == 1 ? 'day' : 'days');
    }
  }

  // ─── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final controller = ref.read(receiptControllerProvider.notifier);

    // ── 1. Build receipt-level data (strip product/warranty fields) ─────────
    const _lineItemKeys = {
      'productName', 'productCategory',
      'warrantyPeriodMonths', 'returnPeriodDays',
    };
    final recData = Map<String, dynamic>.from(widget.formData)
      ..removeWhere((k, _) => _lineItemKeys.contains(k));
    // Remove server-side computed fields from the old schema (backend ignores
    // them now, but guard against a stale call being sent accidentally).
    recData.remove('warrantyExpiryDate');
    recData.remove('returnExpiryDate');

    // ── 2. Create / update the receipt ───────────────────────────────
    final result = widget.receiptId == null
        ? await controller.createReceipt(recData)
        : await controller.updateReceipt(widget.receiptId!, recData);

    if (!mounted) return;

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save. Please try again.')),
      );
      return;
    }

    // ── 3. Save product / warranty data to the line item ────────────────
    final liData = Map<String, dynamic>.from(widget.lineItemData)
      ..removeWhere((_, v) => v == null);  // drop explicit nulls for create
    if (liData.isNotEmpty) {
      // Prefer the line item ID we already know; fall back to first on result.
      final itemId = widget.primaryLineItemId
          ?? (result.lineItems.isNotEmpty ? result.lineItems.first.id : null);

      if (itemId != null) {
        await controller.updateLineItem(result.id, itemId, liData);
      } else {
        // Manual entry: no OCR line items yet — create a new one.
        await controller.createLineItem(result.id, liData);
      }
    }

    if (!mounted) return;

    ref.invalidate(receiptsProvider);
    ref.invalidate(receiptProvider(result.id));
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptDetailScreen(receiptId: result.id),
      ),
      (route) => route.isFirst,
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = AppColors.background(isDark);
    final textPrimary = AppColors.textPrimary(isDark);
    final textSecondary = AppColors.textSecondary(isDark);
    final controllerState = ref.watch(receiptControllerProvider);

    // Parse display values from formData
    final storeName = widget.formData['storeName'] as String? ?? '—';
    final invoiceNumber = widget.formData['invoiceNumber'] as String?;
    final purchaseDateStr = widget.formData['purchaseDate'] as String?;
    final purchaseDate =
        purchaseDateStr != null ? DateTime.tryParse(purchaseDateStr) : null;
    final totalAmount = widget.formData['totalAmount'] as double?;
    final currency = widget.formData['currency'] as String? ?? 'USD';
    final productName = widget.formData['productName'] as String?;
    final productCategory = widget.formData['productCategory'] as String?;
    final warrantyMonths = widget.formData['warrantyPeriodMonths'] as int?;
    final returnDays = widget.formData['returnPeriodDays'] as int?;
    final remarks = widget.formData['remarks'] as String?;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.arrow_back, color: textPrimary),
                    padding: const EdgeInsets.all(8),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shape: const CircleBorder(),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: StepProgressBar(
                        currentStep: 3,
                        totalSteps: 3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── Hero section ──────────────────────────────────────
                    Text(
                      'Confirm & Save',
                      style: AppTextStyles.headingSmall.copyWith(
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Review your receipt summary before saving',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Product Image ──────────────────────────────────────
                    if (productName != null && _productImageFuture != null) ...[
                      ProductImageCard(
                        productName: productName,
                        imageUrlFuture: _productImageFuture!,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Purchase Summary ───────────────────────────────────
                    _buildSection(
                      isDark: isDark,
                      textPrimary: textPrimary,
                      title: 'Purchase Summary',
                      icon: Icons.receipt_long_outlined,
                      children: [
                        _buildDetailRow(isDark, 'Store', storeName),
                        if (invoiceNumber != null)
                          _buildDetailRow(isDark, 'Invoice No.', invoiceNumber),
                        if (purchaseDate != null)
                          _buildDetailRow(
                              isDark, 'Purchase Date', _displayDate(purchaseDate)),
                        if (totalAmount != null)
                          _buildDetailRow(
                            isDark,
                            'Total',
                            '$currency ${totalAmount.toStringAsFixed(2)}'
                          ),
                        if (productName != null)
                          _buildDetailRow(isDark, 'Product', productName),
                        if (productCategory != null)
                          _buildDetailRow(isDark, 'Category', productCategory),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Warranty Coverage ──────────────────────────────────
                    if (widget.warrantyExpiryDate != null ||
                        warrantyMonths != null) ...[
                      _buildSection(
                        isDark: isDark,
                        textPrimary: textPrimary,
                        title: 'Warranty Coverage',
                        icon: Icons.verified_outlined,
                        children: [
                          if (widget.warrantyExpiryDate != null)
                            _buildExpiryBanner(
                              isDark: isDark,
                              textPrimary: textPrimary,
                              expiryDate: widget.warrantyExpiryDate!,
                              periodLabel: warrantyMonths != null
                                  ? '$warrantyMonths-month warranty'
                                  : null,
                              soonThreshold: 30,
                              soonLabel: 'Expiring Soon',
                              expiredLabel: 'Expired',
                              activeLabel: 'Active',
                              activeColor: AppColors.primary,
                            )
                          else
                            _buildNoInfoRow(isDark, 'No warranty information added.'),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Return Window ──────────────────────────────────────
                    if (widget.returnExpiryDate != null ||
                        returnDays != null) ...[
                      _buildSection(
                        isDark: isDark,
                        textPrimary: textPrimary,
                        title: 'Return Window',
                        icon: Icons.assignment_return_outlined,
                        children: [
                          if (widget.returnExpiryDate != null)
                            _buildExpiryBanner(
                              isDark: isDark,
                              textPrimary: textPrimary,
                              expiryDate: widget.returnExpiryDate!,
                              periodLabel: returnDays != null
                                  ? '$returnDays-day return window'
                                  : null,
                              soonThreshold: 3,
                              soonLabel: 'Closing Soon',
                              expiredLabel: 'Closed',
                              activeLabel: 'Open',
                              activeColor: AppColors.info,
                            )
                          else
                            _buildNoInfoRow(
                                isDark, 'No return policy information added.'),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),

            // ── Footer ────────────────────────────────────────────────────
            _buildSaveFooter(isDark, controllerState),
          ],
        ),
      ),
    );
  }

  // ─── Section card (matches review_receipt_screen pattern) ──────────────────

  Widget _buildSection({
    required bool isDark,
    required Color textPrimary,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final cardColor = AppColors.card(isDark);
    final borderColor = AppColors.border(isDark);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                title,
                style: AppTextStyles.sectionTitle.copyWith(color: textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  // ─── Detail row with divider ───────────────────────────────────────────────

  Widget _buildDetailRow(
    bool isDark,
    String label,
    String value, {
    bool isHighlighted = false,
  }) {
    final labelColor = AppColors.textSecondary(isDark);
    final textPrimary = AppColors.textPrimary(isDark);
    final borderColor = AppColors.border(isDark);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 110,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: labelColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 13,
                    color: isHighlighted ? AppColors.primary : textPrimary,
                    fontWeight:
                        isHighlighted ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: borderColor.withValues(alpha: 0.5)),
      ],
    );
  }

  // ─── No info row ───────────────────────────────────────────────────────────

  Widget _buildNoInfoRow(bool isDark, String message) {
    final labelColor = AppColors.muted(isDark);
    return Row(
      children: [
        Icon(Icons.info_outline, size: 15, color: labelColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: labelColor,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Expiry countdown banner ───────────────────────────────────────────────

  Widget _buildExpiryBanner({
    required bool isDark,
    required Color textPrimary,
    required DateTime expiryDate,
    required String? periodLabel,
    required int soonThreshold,
    required String soonLabel,
    required String expiredLabel,
    required String activeLabel,
    required Color activeColor,
  }) {
    final daysLeft = _daysUntil(expiryDate);
    final isExpired = daysLeft < 0;
    final isSoon = !isExpired && daysLeft <= soonThreshold;

    final Color statusColor;
    final String statusLabel;
    if (isExpired) {
      statusColor = AppColors.error;
      statusLabel = expiredLabel;
    } else if (isSoon) {
      statusColor = AppColors.warning;
      statusLabel = soonLabel;
    } else {
      statusColor = activeColor;
      statusLabel = activeLabel;
    }

    final labelColor = AppColors.label(isDark);

    final duration = _formatDuration(daysLeft);
    final unitSuffix = isExpired ? 'ago' : 'left';
    final unitLabel = duration.unit.isNotEmpty
        ? '${duration.unit} $unitSuffix'
        : unitSuffix;

    // Compute progress ring fraction
    // We need the purchase date to determine total period
    final purchaseDateStr = widget.formData['purchaseDate'] as String?;
    final purchaseDate =
        purchaseDateStr != null ? DateTime.tryParse(purchaseDateStr) : null;

    double progressFraction = 0.0;
    if (purchaseDate != null) {
      final totalDays = expiryDate.difference(purchaseDate).inDays;
      if (totalDays > 0) {
        progressFraction = isExpired
            ? 1.0
            : (1.0 - (daysLeft / totalDays)).clamp(0.0, 1.0);
      }
    }

    final percentLeft = isExpired
        ? 0
        : (progressFraction * 100).round() > 100
            ? 100
            : (100 - (progressFraction * 100).round());

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side — countdown + status + date
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Big countdown number + status badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    duration.value,
                    style: AppTextStyles.countdownHero.copyWith(
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          unitLabel,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: labelColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: statusColor.withValues(alpha: 0.35)),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Expiry date row
              Row(
                children: [
                  Icon(Icons.event_outlined, size: 14, color: labelColor),
                  const SizedBox(width: 5),
                  Text(
                    'Expires ${_displayDate(expiryDate)}',
                    style: TextStyle(fontSize: 13, color: labelColor),
                  ),
                ],
              ),
              if (periodLabel != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: labelColor),
                    const SizedBox(width: 5),
                    Text(
                      periodLabel,
                      style: TextStyle(fontSize: 13, color: labelColor),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // Right side — circular progress ring
        if (purchaseDate != null) ...[
          const SizedBox(width: 16),
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background track
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 6,
                    strokeCap: StrokeCap.round,
                    color: statusColor.withValues(alpha: 0.12),
                  ),
                ),
                // Filled arc
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(
                    value: (1.0 - progressFraction).clamp(0.0, 1.0),
                    strokeWidth: 6,
                    strokeCap: StrokeCap.round,
                    color: statusColor,
                  ),
                ),
                // Percentage text
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$percentLeft%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                    Text(
                      'left',
                      style: TextStyle(
                        fontSize: 10,
                        color: labelColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ─── Save footer (matches review_receipt_screen style) ─────────────────────

  Widget _buildSaveFooter(bool isDark, AsyncValue<void> controllerState) {
    final backgroundColor = AppColors.background(isDark);
    final borderColor = AppColors.border(isDark);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: backgroundColor,
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: controllerState.isLoading ? null : _save,
          icon: controllerState.isLoading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.onPrimary,
                  ),
                )
              : const Icon(Icons.check_circle_outline,
                  size: 20, color: AppColors.onPrimary),
          label: const Text(
            'Save Receipt',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
            padding: const EdgeInsets.symmetric(vertical: 17),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
