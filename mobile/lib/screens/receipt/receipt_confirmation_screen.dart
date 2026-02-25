import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/receipt_provider.dart';
import '../../widgets/step_progress_bar.dart';
import 'receipt_detail_screen.dart';

class ReceiptConfirmationScreen extends ConsumerStatefulWidget {
  final String? receiptId;
  final bool isManualEntry;
  final Map<String, dynamic> formData;
  final DateTime? warrantyExpiryDate;
  final DateTime? returnExpiryDate;

  const ReceiptConfirmationScreen({
    super.key,
    required this.receiptId,
    required this.isManualEntry,
    required this.formData,
    this.warrantyExpiryDate,
    this.returnExpiryDate,
  });

  @override
  ConsumerState<ReceiptConfirmationScreen> createState() =>
      _ReceiptConfirmationScreenState();
}

class _ReceiptConfirmationScreenState
    extends ConsumerState<ReceiptConfirmationScreen> {
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

  // ─── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final controller = ref.read(receiptControllerProvider.notifier);
    final data = Map<String, dynamic>.from(widget.formData);

    // Always send expiry dates explicitly — null tells the backend to clear them
    data['warrantyExpiryDate'] = widget.warrantyExpiryDate != null
        ? _formatDate(widget.warrantyExpiryDate!)
        : null;
    data['returnExpiryDate'] = widget.returnExpiryDate != null
        ? _formatDate(widget.returnExpiryDate!)
        : null;

    final result = widget.receiptId == null
        ? await controller.createReceipt(data)
        : await controller.updateReceipt(widget.receiptId!, data);

    if (!mounted) return;

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save. Please try again.')),
      );
      return;
    }

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
    final warrantyMonths = widget.formData['warrantyPeriodMonths'] as int?;
    final returnDays = widget.formData['returnPeriodDays'] as int?;

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
                    // Title
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
                        color: textPrimary.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Purchase Summary ─────────────────────────────────────
                    _buildCard(
                      isDark,
                      textPrimary,
                      [
                        Row(
                          children: [
                            const Icon(
                              Icons.receipt_long_outlined,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Purchase Summary',
                              style: AppTextStyles.sectionTitle.copyWith(
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildRow(isDark, 'Store', storeName, textPrimary,
                            valueBold: true),
                        if (invoiceNumber != null) ...[
                          const SizedBox(height: 8),
                          _buildRow(
                              isDark, 'Invoice No.', invoiceNumber, textPrimary),
                        ],
                        if (purchaseDate != null) ...[
                          const SizedBox(height: 8),
                          _buildRow(isDark, 'Purchase Date',
                              _displayDate(purchaseDate), textPrimary),
                        ],
                        if (totalAmount != null) ...[
                          const SizedBox(height: 8),
                          _buildRow(
                            isDark,
                            'Total',
                            '$currency ${totalAmount.toStringAsFixed(2)}',
                            textPrimary,
                            valueBold: true,
                          ),
                        ],
                        if (productName != null) ...[
                          const SizedBox(height: 8),
                          _buildRow(
                              isDark, 'Product', productName, textPrimary),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Warranty Coverage ────────────────────────────────────
                    if (widget.warrantyExpiryDate != null || warrantyMonths != null)
                    _buildCard(
                      isDark,
                      textPrimary,
                      [
                        Row(
                          children: [
                            const Icon(
                              Icons.verified_outlined,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Warranty Coverage',
                              style: AppTextStyles.sectionTitle.copyWith(
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
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
                          _buildNoInfoRow(
                              isDark, textPrimary, 'No warranty information added.'),
                      ],
                    ),
                    if (widget.warrantyExpiryDate != null || warrantyMonths != null)
                    const SizedBox(height: 16),

                    // ── Return Window ────────────────────────────────────────
                    if (widget.returnExpiryDate != null || returnDays != null)
                    _buildCard(
                      isDark,
                      textPrimary,
                      [
                        Row(
                          children: [
                            const Icon(
                              Icons.assignment_return_outlined,
                              size: 20,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Return Window',
                              style: AppTextStyles.sectionTitle.copyWith(
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
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
                              isDark, textPrimary, 'No return policy information added.'),
                      ],
                    ),
                    if (widget.returnExpiryDate != null || returnDays != null)
                    const SizedBox(height: 8),
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

  // ─── Card wrapper ──────────────────────────────────────────────────────────

  Widget _buildCard(bool isDark, Color textPrimary, List<Widget> children) {
    final cardColor = AppColors.card(isDark);
    final borderColor = AppColors.border(isDark);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  // ─── Row helpers ───────────────────────────────────────────────────────────

  Widget _buildRow(
    bool isDark,
    String label,
    String value,
    Color textPrimary, {
    bool valueBold = false,
  }) {
    final labelColor = AppColors.textSecondary(isDark);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: labelColor),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: textPrimary,
              fontWeight: valueBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoInfoRow(bool isDark, Color textPrimary, String message) {
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
                fontStyle: FontStyle.italic),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Big countdown number + status badge
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              isExpired ? '${daysLeft.abs()}' : '$daysLeft',
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
                    isExpired ? 'days ago' : 'days left',
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
    );
  }

  // ─── Save footer ───────────────────────────────────────────────────────────

  Widget _buildSaveFooter(
      bool isDark, AsyncValue<void> controllerState) {
    final backgroundColor = AppColors.background(isDark);
    final footerBorder = AppColors.footerBorder(isDark);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(top: BorderSide(color: footerBorder)),
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
              color: AppColors.onPrimary,
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
