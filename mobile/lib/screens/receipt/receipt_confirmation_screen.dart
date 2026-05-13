// coverage:ignore-file
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import '../../providers/receipt_provider.dart';
import '../../providers/claim_provider.dart';
import '../../providers/service_providers.dart';
import '../../services/claim_service.dart';
import '../../widgets/step_progress_bar.dart';
import '../../widgets/product_image_card.dart';
import '../../widgets/app_snackbar.dart';
import 'product_detail_screen.dart';
import 'package:material_symbols_icons/symbols.dart';

class ReceiptConfirmationScreen extends ConsumerStatefulWidget {
  final String? receiptId;
  final bool isManualEntry;
  final Map<String, dynamic> formData;
  final DateTime? warrantyExpiryDate;
  final DateTime? returnExpiryDate;
  final List<Map<String, dynamic>> itemsPayload;
  final List<dynamic>? itemForms;

  /// S3 key of the front image pre-uploaded via POST /receipts/ocr-extract.
  /// When set, the receipt is created with this image key already attached
  /// and the status is set to COMPLETED server-side.
  final String? stagingS3Key;

  /// S3 key of the back image pre-uploaded via POST /receipts/ocr-extract.
  final String? backImageS3Key;

  const ReceiptConfirmationScreen({
    super.key,
    required this.receiptId,
    required this.isManualEntry,
    required this.formData,
    this.warrantyExpiryDate,
    this.returnExpiryDate,
    this.itemsPayload = const [],
    this.itemForms,
    this.stagingS3Key,
    this.backImageS3Key,
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
    logger.d('ConfirmationScreen initState: productName=$productName');
    if (productName != null && productName.trim().isNotEmpty) {
      _productImageFuture = ref
          .read(productImageServiceProvider)
          .getProductImageUrl(productName);
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  String _displayDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
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
    const lineItemKeys = {
      'productName',
      'productCategory',
      'warrantyPeriodMonths',
      'returnPeriodDays',
    };
    final recData = Map<String, dynamic>.from(widget.formData)
      ..removeWhere((k, _) => lineItemKeys.contains(k));
    // Remove server-side computed fields from the old schema (backend ignores
    // them now, but guard against a stale call being sent accidentally).
    recData.remove('warrantyExpiryDate');
    recData.remove('returnExpiryDate');
    // Attach pre-uploaded images to the new receipt (OCR path).
    // The backend sets status = COMPLETED when s3ObjectKey is provided.
    if (widget.stagingS3Key != null) {
      recData['s3ObjectKey'] = widget.stagingS3Key;
    }
    if (widget.backImageS3Key != null) {
      recData['backImageS3Key'] = widget.backImageS3Key;
    }
    // ── 2. Create / update the receipt ───────────────────────────────
    final result = widget.receiptId == null
        ? await controller.createReceipt(recData)
        : await controller.updateReceipt(widget.receiptId!, recData);

    if (!mounted) return;

    if (result == null) {
      AppSnackBar.showError(
        context,
        message: 'Failed to save. Please try again.',
      );
      return;
    }

    // ── 3. Save product / warranty data to the line item ────────────────
    final ocrLineItems = result.lineItems;
    int index = 0;

    // Create an explicit list of futures for creating/updating line items
    final futures = <Future>[];
    String? firstProcessedItemId;

    for (final rawItemData in widget.itemsPayload) {
      final liData = Map<String, dynamic>.from(rawItemData)
        ..removeWhere((_, v) => v == null);
      if (liData.isEmpty) {
        index++;
        continue;
      }

      final existingId = liData.remove('_existingId') as String?;
      final itemId =
          existingId ??
          (index < ocrLineItems.length ? ocrLineItems[index].id : null);

      if (itemId == null &&
          firstProcessedItemId == null &&
          result.lineItems.isNotEmpty) {
        firstProcessedItemId = result.lineItems.first.id;
      }

      if (itemId != null) {
        firstProcessedItemId ??= itemId;
        futures.add(controller.updateLineItem(result.id, itemId, liData));
      } else {
        futures.add(controller.createLineItem(result.id, liData));
      }
      index++;
    }

    await Future.wait(futures);

    // ── 4. Handle Pending Replacement Links ─────────────────────────────────
    final pendingClaimId = ref.read(pendingReplacementClaimIdProvider);
    if (pendingClaimId != null) {
      try {
        final claimService = ref.read(claimServiceProvider);
        final newLineItemId = firstProcessedItemId;

        if (newLineItemId != null) {
          await claimService.resolveClaim(
            pendingClaimId,
            'REPLACED',
            linkedItemId: newLineItemId,
          );
          // Clear the pending state
          ref.read(pendingReplacementClaimIdProvider.notifier).state = null;
        }
      } catch (e) {
        // We log but don't block navigation if linking fails
        logger.e('Failed to link replacement claim to new receipt: $e');
      }
    }

    if (!mounted) return;

    ref.invalidate(receiptsProvider);
    ref.invalidate(receiptProvider(result.id));
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(receiptId: result.id),
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
    final purchaseDate = purchaseDateStr != null
        ? DateTime.tryParse(purchaseDateStr)
        : null;
    final totalAmount = widget.formData['totalAmount'] as double?;
    final currency = widget.formData['currency'] as String? ?? 'USD';
    final productName = widget.formData['productName'] as String?;

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
                    icon: Icon(
                      Symbols.arrow_back_rounded,
                      color: textPrimary,
                      weight: AppDimensions.iconWeightBold,
                    ),
                    padding: const EdgeInsets.all(8),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shape: const CircleBorder(),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: StepProgressBar(currentStep: 3, totalSteps: 3),
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
                      icon: Symbols.receipt_long_rounded,
                      children: [
                        _buildDetailRow(isDark, 'Store', storeName),
                        if (invoiceNumber != null)
                          _buildDetailRow(isDark, 'Invoice No.', invoiceNumber),
                        if (purchaseDate != null)
                          _buildDetailRow(
                            isDark,
                            'Purchase Date',
                            _displayDate(purchaseDate),
                          ),
                        if (totalAmount != null)
                          _buildDetailRow(
                            isDark,
                            'Total',
                            '$currency ${totalAmount.toStringAsFixed(2)}',
                          ),
                        _buildDetailRow(
                          isDark,
                          'Tracked Items',
                          '${widget.itemsPayload.length}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (widget.itemForms != null)
                      ...List.generate(widget.itemForms!.length, (index) {
                        final form = widget.itemForms![index];
                        final productName = form.productNameCtrl.text.trim();
                        final displayName = productName.isNotEmpty
                            ? productName
                            : 'Item ${index + 1}';

                        final warrantyMonths = int.tryParse(
                          form.warrantyPeriodCtrl.text,
                        );
                        final returnDays = int.tryParse(
                          form.returnPeriodCtrl.text,
                        );
                        final hasWarranty =
                            form.warrantyExpiryDate != null ||
                            warrantyMonths != null;
                        final hasReturn =
                            form.returnExpiryDate != null || returnDays != null;

                        if (!hasWarranty && !hasReturn) {
                          return const SizedBox.shrink();
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 8,
                                  bottom: 8,
                                ),
                                child: Text(
                                  displayName,
                                  style: AppTextStyles.titleLarge.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              _buildSection(
                                isDark: isDark,
                                textPrimary: textPrimary,
                                title: 'Coverage & Returns',
                                icon: Symbols.shield_rounded,
                                children: [
                                  if (hasWarranty) ...[
                                    Row(
                                      children: [
                                        Text(
                                          'Warranty',
                                          style: AppTextStyles.formLabel
                                              .copyWith(
                                                color: AppColors.textPrimary(
                                                  isDark,
                                                ),
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    if (form.warrantyExpiryDate != null)
                                      _buildExpiryBanner(
                                        isDark: isDark,
                                        textPrimary: textPrimary,
                                        expiryDate: form.warrantyExpiryDate!,
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
                                        isDark,
                                        'No warranty information added.',
                                      ),
                                  ],
                                  if (hasWarranty && hasReturn) ...[
                                    const SizedBox(height: 16),
                                    Divider(color: AppColors.border(isDark)),
                                    const SizedBox(height: 16),
                                  ],
                                  if (hasReturn) ...[
                                    Row(
                                      children: [
                                        Text(
                                          'Return Policy',
                                          style: AppTextStyles.formLabel
                                              .copyWith(
                                                color: AppColors.textPrimary(
                                                  isDark,
                                                ),
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    if (form.returnExpiryDate != null)
                                      _buildExpiryBanner(
                                        isDark: isDark,
                                        textPrimary: textPrimary,
                                        expiryDate: form.returnExpiryDate!,
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
                                        isDark,
                                        'No return policy information added.',
                                      ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        );
                      }),
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
              Icon(
                icon,
                size: AppDimensions.iconMedium,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: AppTextStyles.sectionTitle.copyWith(color: textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
                    fontWeight: isHighlighted
                        ? FontWeight.w700
                        : FontWeight.w500,
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
        Icon(
          Symbols.info_rounded,
          size: AppDimensions.iconSmall,
          color: labelColor,
        ),
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

    // Progress fraction
    final purchaseDateStr = widget.formData['purchaseDate'] as String?;
    final purchaseDate = purchaseDateStr != null
        ? DateTime.tryParse(purchaseDateStr)
        : null;
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
        : (100 - (progressFraction * 100).round()).clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Top row: countdown + status (left) · percentage (right) ──────
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Big number
            Text(
              duration.value,
              style: AppTextStyles.countdownHero.copyWith(color: statusColor),
            ),
            const SizedBox(width: 10),
            // Unit + status chip
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
                  const SizedBox(height: 0),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.35),
                      ),
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
            const Spacer(),
            // Percentage badge on the right
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '$percentLeft% left',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),

        // ── Linear progress bar ───────────────────────────────────────────
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (1.0 - progressFraction).clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: statusColor.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
          ),
        ),

        // ── Meta info ─────────────────────────────────────────────────────
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(
              Symbols.event_rounded,
              size: AppDimensions.iconTiny,
              color: labelColor,
            ),
            const SizedBox(width: 5),
            Text(
              'Expires ${_displayDate(expiryDate)}',
              style: TextStyle(fontSize: 13, color: labelColor),
            ),
            if (periodLabel != null) ...[
              const Spacer(),
              Text(
                periodLabel,
                style: TextStyle(fontSize: 13, color: labelColor),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // ─── Save footer (matches review_receipt_screen style) ─────────────────────

  Widget _buildSaveFooter(bool isDark, AsyncValue<void> controllerState) {
    final backgroundColor = AppColors.background(isDark);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(color: backgroundColor),
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
              : const Icon(
                  Symbols.check_circle_rounded,
                  size: AppDimensions.iconMedium,
                  color: AppColors.onPrimary,
                  weight: AppDimensions.iconWeightBold,
                ),
          label: const Text(
            'Save Receipt',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
