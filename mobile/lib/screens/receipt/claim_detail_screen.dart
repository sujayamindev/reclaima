import 'dart:io';
import '../../core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/receipt_model.dart';
import '../../providers/receipt_provider.dart';
import '../../services/android_download_manager_service.dart';
import '../../services/claim_service.dart';
import '../../core/utils/logger.dart';

/// Screen for viewing and managing an existing warranty claim
class ClaimDetailScreen extends ConsumerStatefulWidget {
  final String claimId;
  final String receiptStoreName;

  const ClaimDetailScreen({
    super.key,
    required this.claimId,
    required this.receiptStoreName,
  });

  @override
  ConsumerState<ClaimDetailScreen> createState() => _ClaimDetailScreenState();
}

class _ClaimDetailScreenState extends ConsumerState<ClaimDetailScreen> {
  late final TextEditingController _notesController = TextEditingController();
  bool _isLoading = true;
  bool _isUpdating = false;
  ClaimDocumentResponse? _claim;
  String? _pendingStatus;
  String? _error;

  bool _isStatusExpanded = false;

  final List<String> _statusOptions = [
    'DRAFT',
    'SUBMITTED',
    'IN_PROGRESS',
    'RESOLVED',
    'DENIED',
  ];

  @override
  void initState() {
    super.initState();
    _loadClaim();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadClaim() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      logger.i('Loading claim ${widget.claimId}');
      final claimService = ref.read(claimServiceProvider);
      final claim = await claimService.getClaim(widget.claimId);

      if (!mounted) return;
      setState(() {
        _claim = claim;
        _pendingStatus = claim.status;
        _notesController.text = claim.notes ?? '';
        _isLoading = false;
      });
      logger.i('Claim loaded successfully');
    } catch (e) {
      logger.e('Error loading claim: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveChangesAndClose() async {
    if (_claim == null || _isUpdating) return;

    final pendingStatus = _pendingStatus ?? _claim!.status;
    final notesText = _notesController.text.trim();
    final statusChanged = pendingStatus != _claim!.status;
    final notesChanged = notesText != (_claim!.notes ?? '');

    if (!statusChanged && !notesChanged) {
      if (mounted) Navigator.pop(context, true);
      return;
    }

    if (pendingStatus == 'RESOLVED' && _claim!.status != 'RESOLVED') {
      await _showResolutionOutcomeDialog(closeOnSuccess: true);
      return;
    }

    setState(() => _isUpdating = true);
    try {
      final claimService = ref.read(claimServiceProvider);
      final updated = await claimService.updateClaim(
        _claim!.id,
        status: statusChanged ? pendingStatus : null,
        notes: notesChanged ? notesText : null,
      );

      if (!mounted) return;
      setState(() {
        _claim = updated;
        _pendingStatus = updated.status;
      });
      Navigator.pop(context, true);
    } catch (e) {
      logger.e('Error saving claim changes: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _showResolutionOutcomeDialog({
    bool closeOnSuccess = false,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = AppColors.card(isDark);
    final textColor = AppColors.textPrimary(isDark);

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Claim Resolved',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'What was the outcome of this claim?',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary(isDark),
                  ),
                ),
                const SizedBox(height: 24),

                // Refunded
                _buildOutcomeOption(
                  icon: Symbols.payments_rounded,
                  title: 'Refunded / Returned',
                  subtitle: 'Item will be archived and stop tracking warranty.',
                  onTap: () {
                    Navigator.pop(ctx);
                    _resolveClaimOutcome(
                      'REFUNDED',
                      closeOnSuccess: closeOnSuccess,
                    );
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 12),

                // Repaired
                _buildOutcomeOption(
                  icon: Symbols.build_rounded,
                  title: 'Repaired',
                  subtitle:
                      'Item stays active. You can update its details if needed.',
                  onTap: () {
                    Navigator.pop(ctx);
                    _resolveClaimOutcome(
                      'REPAIRED',
                      closeOnSuccess: closeOnSuccess,
                    );
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 12),

                // Replaced
                _buildOutcomeOption(
                  icon: Symbols.autorenew_rounded,
                  title: 'Replaced with New Item',
                  subtitle:
                      'Archive old item and prepare a new digital record.',
                  onTap: () {
                    Navigator.pop(ctx);
                    _showReplacementStrategyDialog(
                      closeOnSuccess: closeOnSuccess,
                    );
                  },
                  isDark: isDark,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOutcomeOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border(isDark)),
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                weight: AppDimensions.iconWeightBold,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textPrimary(isDark),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary(isDark),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReplacementStrategyDialog({
    bool closeOnSuccess = false,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.card(isDark),
          title: Text(
            'Add Replacement',
            style: AppTextStyles.titleLarge.copyWith(
              color: AppColors.textPrimary(isDark),
            ),
          ),
          content: Text(
            'How would you like to add the new replacement item to your inventory?',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary(isDark),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                // Implementation for Phase 4 linking will go here shortly.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Upload a new receipt to link it (Coming soon)',
                    ),
                  ),
                );
              },
              child: Text(
                'Scan New Receipt',
                style: AppTextStyles.buttonSmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _resolveClaimOutcome(
                  'REPLACED',
                  duplicateDetails: true,
                  closeOnSuccess: closeOnSuccess,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
              child: Text('Duplicate Old Details', style: AppTextStyles.button),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showStatusInfoDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card(isDark),
        title: Text(
          'Claim Status Guide',
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textPrimary(isDark),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusInfoItem(
              'DRAFT',
              'Claim document is created but not submitted yet.',
              isDark,
            ),
            const SizedBox(height: 16),
            _buildStatusInfoItem(
              'SUBMITTED',
              'Claim is sent and awaiting processing.',
              isDark,
            ),
            const SizedBox(height: 16),
            _buildStatusInfoItem(
              'IN_PROGRESS',
              'Claim is currently being worked on.',
              isDark,
            ),
            const SizedBox(height: 16),
            _buildStatusInfoItem(
              'RESOLVED',
              'Claim has been completed successfully.',
              isDark,
            ),
            const SizedBox(height: 16),
            _buildStatusInfoItem(
              'DENIED',
              'Claim was reviewed and rejected.',
              isDark,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: AppTextStyles.buttonSmall.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusInfoItem(String status, String description, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          _getStatusIcon(status),
          size: 18,
          color: AppColors.textSecondary(isDark),
          weight: 700.0,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$status: ',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary(isDark),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary(isDark),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _resolveClaimOutcome(
    String outcome, {
    bool duplicateDetails = false,
    bool closeOnSuccess = false,
  }) async {
    if (_claim == null) return;
    setState(() => _isUpdating = true);
    try {
      final claimService = ref.read(claimServiceProvider);
      final updated = await claimService.resolveClaim(
        _claim!.id,
        outcome,
        duplicateDetails: duplicateDetails ? true : null,
      );
      setState(() {
        _claim = updated;
        _pendingStatus = updated.status;
      });

      if (!mounted) return;
      if (outcome == 'REFUNDED') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item successfully archived.')),
        );
      } else if (outcome == 'REPAIRED') {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.card(
              Theme.of(context).brightness == Brightness.dark,
            ),
            title: Text(
              'Claim Resolved',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.textPrimary(
                  Theme.of(context).brightness == Brightness.dark,
                ),
              ),
            ),
            content: Text(
              'Please check your warranty and return coverages and update them if they got extended.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary(
                  Theme.of(context).brightness == Brightness.dark,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'OK',
                  style: AppTextStyles.buttonSmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      } else if (outcome == 'REPLACED') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Replacement item created successfully.'),
          ),
        );
      }

      if (closeOnSuccess && mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      logger.e('Error resolving claim: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to resolve claim: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _downloadPdf() async {
    await _downloadPdfToPublicDownloads();
  }

  Future<void> _openPdf() async {
    final filePath = await _downloadPdfFile(showSuccessMessage: false);
    if (filePath == null) return;

    try {
      final openResult = await OpenFilex.open(
        filePath,
        type: 'application/pdf',
      );
      if (openResult.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              openResult.message.isNotEmpty
                  ? openResult.message
                  : 'No PDF app found on this device.',
            ),
          ),
        );
      }
    } catch (e) {
      logger.e('Error opening PDF: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open PDF. Please try Download instead.'),
        ),
      );
    }
  }

  Future<void> _sharePdf() async {
    final filePath = await _downloadPdfFile(showSuccessMessage: false);
    if (filePath == null) return;

    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Warranty claim PDF',
        subject: 'Warranty Claim PDF - ${_claim!.id}',
      );
    } catch (e) {
      logger.e('Error sharing PDF: $e');
    }
  }

  Future<String?> _downloadPdfFile({bool showSuccessMessage = true}) async {
    final url = await _getFreshClaimUrl();
    if (url == null) return null;

    try {
      final documentsDir = await getApplicationDocumentsDirectory();
      final pdfDir = Directory('${documentsDir.path}/claim_pdfs');
      if (!await pdfDir.exists()) {
        await pdfDir.create(recursive: true);
      }

      final filePath =
          '${pdfDir.path}/claim_${_claim!.id}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      await Dio().download(url, filePath);

      if (showSuccessMessage && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF downloaded successfully.')),
        );
      }

      return filePath;
    } catch (e) {
      logger.e('Error downloading PDF file: $e');
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to download PDF. Please try again.'),
        ),
      );
      return null;
    }
  }

  Future<String?> _downloadPdfToPublicDownloads() async {
    final url = await _getFreshClaimUrl();
    if (url == null) return null;

    try {
      if (Platform.isAndroid) {
        final fileName =
            'claim_${_claim!.id}_${DateTime.now().millisecondsSinceEpoch}.pdf';
        await AndroidDownloadManagerService.enqueuePdfDownload(
          url: url,
          fileName: fileName,
          title: 'Claim PDF',
          description:
              'Downloading document. Open notification to view when complete.',
        );

        if (mounted) {
          _showDownloadStartedMessage();
        }

        return fileName;
      } else {
        final documentsDir = await getApplicationDocumentsDirectory();
        final downloadsDir = Directory('${documentsDir.path}/Downloads');
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }

        final filePath =
            '${downloadsDir.path}/claim_${_claim!.id}_${DateTime.now().millisecondsSinceEpoch}.pdf';
        await Dio().download(url, filePath);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF saved to Downloads folder.')),
          );
        }

        return filePath;
      }
    } catch (e) {
      logger.e('Error saving PDF to Downloads: $e');
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to save to Downloads. Please check storage permissions.',
          ),
        ),
      );
      return null;
    }
  }

  void _showDownloadStartedMessage() {
    if (!mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        duration: const Duration(seconds: 6),
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        backgroundColor: AppColors.card(isDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
          side: BorderSide(color: AppColors.border(isDark)),
        ),
        content: Row(
          children: [
            Expanded(
              child: Text(
                'Download started. Open notification to view file.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textPrimary(isDark),
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _getFreshClaimUrl() async {
    if (_claim == null) return null;

    try {
      final claimService = ref.read(claimServiceProvider);
      final refreshedClaim = await claimService.accessClaimPdf(_claim!.id);

      if (!mounted) return refreshedClaim.url;
      setState(() => _claim = refreshedClaim);

      if (refreshedClaim.url == null || refreshedClaim.url!.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Claim PDF is not available yet. Try again shortly.'),
          ),
        );
        return null;
      }

      return refreshedClaim.url;
    } catch (e) {
      logger.e('Error refreshing claim URL: $e');
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not refresh PDF link. Please try again.'),
        ),
      );
      return null;
    }
  }

  PreferredSizeWidget _buildStyledAppBar(bool isDark) {
    return AppBar(
      backgroundColor: AppColors.background(isDark),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 64,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(
          Symbols.arrow_back_rounded,
          color: AppColors.textPrimary(isDark),
          weight: 800.0,
        ),
        padding: const EdgeInsets.all(8),
        style: IconButton.styleFrom(
          backgroundColor: Colors.transparent,
          shape: const CircleBorder(),
        ),
      ),
      title: Text(
        'Claim Details',
        style: AppTextStyles.listTitle.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary(isDark),
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(
            Symbols.delete_rounded,
            color: AppColors.textPrimary(isDark),
            size: 22,
            weight: 800.0,
          ),
          onPressed: () {
            // TODO: Implement delete functionality
          },
          tooltip: 'Delete',
          padding: const EdgeInsets.all(8),
          style: IconButton.styleFrom(
            backgroundColor: Colors.transparent,
            shape: const CircleBorder(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background(isDark),
        appBar: _buildStyledAppBar(isDark),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _claim == null) {
      return Scaffold(
        backgroundColor: AppColors.background(isDark),
        appBar: _buildStyledAppBar(isDark),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Symbols.error_rounded,
                  size: AppDimensions.iconXXL,
                  color: Colors.red.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load claim',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.textPrimary(isDark),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error ?? 'Claim not found',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary(isDark),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                  ),
                  child: Text('Go Back', style: AppTextStyles.button),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _buildDetailScreen(isDark);
  }

  Widget _buildDetailScreen(bool isDark) {
    final cardColor = AppColors.card(isDark);
    final textColor = AppColors.textPrimary(isDark);
    final secondaryColor = AppColors.textSecondary(isDark);
    final receiptAsync = ref.watch(receiptProvider(_claim!.receiptId));
    final receipt = receiptAsync.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );
    final productName = _getProductName(receipt);
    final receiptDate = _getFormattedDate(receipt?.purchaseDate);
    final createdDate = _getFormattedDate(_claim!.createdAt);

    return Scaffold(
      appBar: _buildStyledAppBar(isDark),
      backgroundColor: AppColors.background(isDark),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Claim Summary',
                style: AppTextStyles.formLabel.copyWith(color: secondaryColor),
              ),
              const SizedBox(height: 8),

              // Claim details card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                  border: Border.all(color: AppColors.border(isDark)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStackedDetailItem(
                      icon: Symbols.confirmation_number_rounded,
                      label: 'Claim ID',
                      value: _claim!.id,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 6),
                    _buildStackedDetailItem(
                      icon: Symbols.category_rounded,
                      label: 'Type',
                      value: _claim!.claimType?.toUpperCase() ?? 'UNKNOWN',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 6),
                    _buildStackedDetailItem(
                      icon: Symbols.storefront_rounded,
                      label: 'Store',
                      value: widget.receiptStoreName,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 6),
                    _buildStackedDetailItem(
                      icon: Symbols.shopping_bag_rounded,
                      label: 'Product',
                      value: productName ?? 'Unknown',
                      isDark: isDark,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 6),
                    _buildStackedDetailItem(
                      icon: Symbols.calendar_month_rounded,
                      label: 'Receipt Date',
                      value: receiptDate,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 6),
                    _buildStackedDetailItem(
                      icon: Symbols.event_available_rounded,
                      label: 'Created',
                      value: createdDate,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 6),
                    _buildStackedDetailItem(
                      icon: Symbols.description_rounded,
                      label: 'Issue Description',
                      value: _claim!.issueDescription,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Status section (outside top details card)
              Row(
                children: [
                  Text(
                    'Status',
                    style: AppTextStyles.formLabel.copyWith(
                      color: secondaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  IconButton(
                    onPressed: _showStatusInfoDialog,
                    icon: Icon(
                      Symbols.info_rounded,
                      size: AppDimensions.iconSmall,
                      color: AppColors.textSecondary(isDark),
                      weight: 700.0,
                    ),
                    tooltip: 'Status info',
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: const VisualDensity(
                      horizontal: -2,
                      vertical: -2,
                    ),
                  ),
                ],
              ),

              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                  border: Border.all(color: AppColors.border(isDark)),
                ),
                child: Column(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => setState(
                          () => _isStatusExpanded = !_isStatusExpanded,
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _getStatusIcon(
                                      _pendingStatus ?? _claim!.status,
                                    ),
                                    size: 20,
                                    weight: 600.0,
                                    color: AppColors.textPrimary(isDark),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _formatStatusText(
                                      _pendingStatus ?? _claim!.status,
                                    ),
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textPrimary(isDark),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              AnimatedRotation(
                                turns: _isStatusExpanded ? 0.5 : 0,
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  Symbols.expand_more_rounded,
                                  color: AppColors.textSecondary(isDark),
                                  size: 20,
                                  weight: 800.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      child: _isStatusExpanded
                          ? Column(
                              children: [
                                Divider(
                                  height: 1,
                                  color: AppColors.border(isDark),
                                ),
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _statusOptions.length,
                                  separatorBuilder: (context, index) => Divider(
                                    height: 1,
                                    color: AppColors.border(isDark),
                                  ),
                                  itemBuilder: (context, index) {
                                    final status = _statusOptions[index];
                                    final isSelected =
                                        (_pendingStatus ?? _claim?.status) ==
                                        status;
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isStatusExpanded = false;
                                          _pendingStatus = status;
                                        });
                                      },
                                      child: Container(
                                        color: isSelected
                                            ? AppColors.primary.withValues(
                                                alpha: 0.10,
                                              )
                                            : Colors.transparent,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              _getStatusIcon(status),
                                              size: 20,
                                              weight: 600.0,
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : AppColors.textSecondary(
                                                      isDark,
                                                    ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              _formatStatusText(status),
                                              style: AppTextStyles.bodyMedium
                                                  .copyWith(
                                                    color: isSelected
                                                        ? AppColors.primary
                                                        : AppColors.textSecondary(
                                                            isDark,
                                                          ),
                                                    fontWeight: isSelected
                                                        ? FontWeight.w700
                                                        : FontWeight.w500,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Notes field
              Text(
                'Notes',
                style: AppTextStyles.formLabel.copyWith(
                  color: secondaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 4,
                minLines: 1,
                enabled: !_isUpdating,
                style: AppTextStyles.bodySmall.copyWith(color: textColor),
                decoration: InputDecoration(
                  hintText:
                      'Add tracking numbers, support ticket IDs, or resolution notes...',
                  hintStyle: AppTextStyles.bodySmall.copyWith(
                    color: secondaryColor.withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: cardColor,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                    borderSide: BorderSide(color: AppColors.border(isDark)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                    borderSide: BorderSide(color: AppColors.border(isDark)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // PDF Actions card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border(isDark)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Open button
                    SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _claim != null ? _openPdf : null,
                        icon: const Icon(
                          Symbols.open_in_new_rounded,
                          weight: AppDimensions.iconWeightHeavy,
                        ),
                        label: const Text('Open PDF'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary(isDark),
                          side: BorderSide(color: AppColors.border(isDark)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusXL,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Download button
                    SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _claim != null ? _downloadPdf : null,
                        icon: const Icon(
                          Symbols.file_download_rounded,
                          weight: AppDimensions.iconWeightHeavy,
                        ),
                        label: const Text('Download PDF'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary(isDark),
                          side: BorderSide(color: AppColors.border(isDark)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusXL,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Share button
                    SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _claim != null ? _sharePdf : null,
                        icon: const Icon(
                          Symbols.share_rounded,
                          weight: AppDimensions.iconWeightHeavy,
                        ),
                        label: const Text('Share PDF'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary(isDark),
                          side: BorderSide(color: AppColors.border(isDark)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusXL,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.paddingPage,
            16,
            AppDimensions.paddingPage,
            16,
          ),
          child: SizedBox(
            width: double.infinity,
            height: AppDimensions.buttonHeight,
            child: ElevatedButton.icon(
              onPressed: () async {
                await _saveChangesAndClose();
              },
              icon: const Icon(
                Symbols.done_all_rounded,
                weight: AppDimensions.iconWeightHeavy,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                ),
              ),
              label: Text('Done', style: AppTextStyles.button),
            ),
          ),
        ),
      ),
    );
  }

  String? _getProductName(ReceiptModel? receipt) {
    if (receipt != null && _claim?.lineItemId != null) {
      try {
        final item = receipt.lineItems.firstWhere(
          (i) => i.id == _claim!.lineItemId,
        );
        return item.displayName;
      } catch (_) {}
    }

    if (receipt?.productName != null &&
        receipt!.productName!.trim().isNotEmpty) {
      return receipt.productName!;
    }
    if (receipt != null && receipt.lineItems.isNotEmpty) {
      return receipt.lineItems.first.displayName;
    }
    return null;
  }

  String _getFormattedDate(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown';
    return DateFormatter.formatDate(dateTime.toLocal());
  }

  String _formatStatusText(String status) {
    return status
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'DRAFT':
        return Symbols.adf_scanner_rounded;
      case 'SUBMITTED':
        return Symbols.publish_rounded;
      case 'IN_PROGRESS':
        return Symbols.progress_activity_rounded;
      case 'RESOLVED':
        return Symbols.check_rounded;
      case 'DENIED':
        return Symbols.close_rounded;
      default:
        return Symbols.help_rounded;
    }
  }

  Widget _buildStackedDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: AppDimensions.iconTiny,
              weight: AppDimensions.iconWeightHeavy,
              color: AppColors.textSecondary(isDark),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary(isDark),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textPrimary(isDark),
            height: 1.2,
          ),
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
