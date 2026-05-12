// coverage:ignore-file
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../widgets/app_snackbar.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_constants.dart';
import '../receipt/add_receipt_screen.dart';
import '../receipt/image_crop_rotate_screen.dart';
import '../../providers/receipt_provider.dart';
import '../../services/android_download_manager_service.dart';
import '../../services/claim_service.dart';
import '../../core/utils/logger.dart';
import '../../data/models/receipt_line_item_model.dart';

/// Screen for generating and managing warranty claim PDFs
class ClaimPdfScreen extends ConsumerStatefulWidget {
  final String receiptId;
  final String? lineItemId; // Product/line item ID - optional
  final String receiptStoreName;

  const ClaimPdfScreen({
    super.key,
    required this.receiptId,
    this.lineItemId,
    required this.receiptStoreName,
  });

  @override
  ConsumerState<ClaimPdfScreen> createState() => _ClaimPdfScreenState();
}

class _ClaimPdfScreenState extends ConsumerState<ClaimPdfScreen> {
  late final TextEditingController _issueController = TextEditingController();
  late final TextEditingController _notesController = TextEditingController();
  late final FocusNode _notesFocusNode = FocusNode();
  String _selectedClaimType = 'warranty';
  bool _isClaimTypeExpanded = false;
  bool _isStatusExpanded = false;
  bool _isLoading = false;
  bool _isUpdating = false;
  ClaimDocumentResponse? _generatedClaim;
  String? _error;

  // Defect images
  final List<String> _defectImagePaths = [];

  // PDF cache
  String? _cachedPdfPath;
  bool _isCachingPdf = false;

  final List<String> _statusOptions = [
    'DRAFT',
    'SUBMITTED',
    'IN_PROGRESS',
    'RESOLVED',
    'DENIED',
  ];
  List<String> get _claimTypeOptions =>
      AppConstants.claimTypes.toList(growable: false);

  String _formatClaimTypeText(String type) {
    return type.isNotEmpty
        ? type[0].toUpperCase() + type.substring(1).toLowerCase()
        : type;
  }

  IconData _getClaimTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'warranty':
        return Symbols.verified_user_rounded;
      case 'return':
        return Symbols.undo_rounded;
      case 'repair':
        return Symbols.build_rounded;
      default:
        return Symbols.help_rounded;
    }
  }

  String _shortId(String value, {int take = 64}) {
    if (value.length <= take) return value;
    return '${value.substring(0, take)}...';
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

  @override
  void initState() {
    super.initState();
    _notesFocusNode.addListener(_onNotesFocusChange);
  }

  void _onNotesFocusChange() {
    if (!_notesFocusNode.hasFocus && _generatedClaim != null) {
      _saveNotesIfChanged();
    }
  }

  Future<void> _saveNotesIfChanged() async {
    if (_generatedClaim == null) return;
    final currentNotes = _notesController.text.trim();
    final previousNotes = _generatedClaim!.notes ?? '';

    if (currentNotes == previousNotes) return;

    setState(() => _isUpdating = true);
    try {
      final claimService = ref.read(claimServiceProvider);
      final updated = await claimService.updateClaim(
        _generatedClaim!.id,
        notes: currentNotes,
      );
      setState(() => _generatedClaim = updated);
    } catch (e) {
      logger.e('Error saving notes: $e');
      if (mounted) {
        AppSnackBar.showError(context, message: 'Failed to save notes: $e');
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  void dispose() {
    _issueController.dispose();
    _notesController.dispose();
    _notesFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickDefectImages() async {
    final ImagePicker picker = ImagePicker();

    // Show source selection dialog
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Defect Image',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.textPrimary(isDark),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Icon(
                  Symbols.camera_alt_rounded,
                  color: AppColors.primary,
                  size: AppDimensions.iconMedium,
                  weight: AppDimensions.iconWeightHeavy,
                ),
                title: const Text(
                  'Take Photo',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: Icon(
                  Symbols.photo_library_rounded,
                  color: AppColors.primary,
                  size: AppDimensions.iconMedium,
                  weight: AppDimensions.iconWeightHeavy,
                ),
                title: const Text(
                  'Choose from Gallery',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    try {
      final XFile? image = await picker.pickImage(source: source);
      if (image != null) {
        // Navigate to crop/rotate screen
        if (!mounted) return;
        final result = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (context) => ImageCropRotateScreen(imagePath: image.path),
          ),
        );

        if (result != null) {
          setState(() {
            _defectImagePaths.add(result);
          });
        }
      }
    } catch (e) {
      logger.e('Error picking defect image: $e');
      if (mounted) {
        AppSnackBar.showError(context, message: 'Failed to pick image: $e');
      }
    }
  }

  void _removeDefectImage(int index) {
    setState(() {
      _defectImagePaths.removeAt(index);
    });
  }

  Future<void> _editDefectImage(int index) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ImageCropRotateScreen(imagePath: _defectImagePaths[index]),
      ),
    );

    if (result != null) {
      setState(() {
        _defectImagePaths[index] = result;
      });
    }
  }

  Future<void> _generateClaim() async {
    // Validate input
    final issueDesc = _issueController.text.trim();
    if (issueDesc.isEmpty) {
      AppSnackBar.showError(context, message: 'Please describe the issue');
      return;
    }

    // Validate defect images file sizes
    for (int i = 0; i < _defectImagePaths.length; i++) {
      final file = File(_defectImagePaths[i]);
      final fileSize = await file.length();
      const maxSize = 5 * 1024 * 1024; // 5MB

      if (fileSize > maxSize) {
        if (!mounted) return;
        AppSnackBar.showError(
          context,
          message: 'Image ${i + 1} is too large. Maximum size is 5MB.',
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      logger.i(
        'Generating claim PDF with ${_defectImagePaths.length} defect images...',
      );
      final claimService = ref.read(claimServiceProvider);

      // Convert paths to File objects
      final defectImageFiles = _defectImagePaths
          .map((path) => File(path))
          .toList();

      final claim = await claimService.generateClaimPdf(
        receiptId: widget.receiptId,
        issueDescription: issueDesc,
        claimType: _selectedClaimType,
        lineItemId: widget.lineItemId,
        defectImages: defectImageFiles.isNotEmpty ? defectImageFiles : null,
      );

      logger.i(
        'Claim PDF generated successfully: ${claim.id} with ${claim.defectImages.length} defect images',
      );

      setState(() {
        _generatedClaim = claim;
        _notesController.text = claim.notes ?? '';
      });

      // Start caching PDF in background (don't await)
      _cachePdfInBackground();

      if (!mounted) return;

      // Show success message
      AppSnackBar.showSuccess(
        context,
        message:
            'Claim generated successfully with ${claim.defectImages.length} defect images',
      );
    } catch (e) {
      logger.e('Error generating claim: $e');
      setState(() {
        _error = 'Failed to generate claim';
      });

      if (!mounted) return;

      AppSnackBar.showError(context, message: 'Failed to generate claim');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateClaimStatus(String newStatus) async {
    if (_generatedClaim == null) return;
    setState(() => _isUpdating = true);
    try {
      final claimService = ref.read(claimServiceProvider);
      final updated = await claimService.updateClaim(
        _generatedClaim!.id,
        status: newStatus,
      );
      setState(() => _generatedClaim = updated);
    } catch (e) {
      logger.e('Error updating status: $e');
      if (mounted) {
        AppSnackBar.showError(context, message: 'Failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
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

  Future<void> _showResolutionOutcomeDialog() async {
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
                  style: AppTextStyles.titleLarge.copyWith(color: textColor),
                ),
                const SizedBox(height: 8),
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
                    _resolveClaimOutcome('REFUNDED');
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 12),

                // Repaired
                _buildOutcomeOption(
                  icon: Symbols.build_rounded,
                  title: 'Repaired',
                  subtitle:
                      'Item stays active. You can update its warranty date.',
                  onTap: () {
                    Navigator.pop(ctx);
                    _resolveClaimOutcome('REPAIRED');
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
                    _showReplacementStrategyDialog();
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border(isDark)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary),
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

  Future<void> _showReplacementStrategyDialog() async {
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
            'Scan or upload the receipt for your new replacement item to track its warranty.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary(isDark),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: Text(
                'Cancel',
                style: AppTextStyles.buttonSmall.copyWith(
                  color: AppColors.textSecondary(isDark),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _resolveClaimOutcome('REPLACED');
                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddReceiptScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
              child: Text('Scan New Receipt', style: AppTextStyles.button),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resolveClaimOutcome(
    String outcome, {
    bool duplicateDetails = false,
  }) async {
    if (_generatedClaim == null) return;
    setState(() => _isUpdating = true);
    try {
      final claimService = ref.read(claimServiceProvider);
      final updated = await claimService.resolveClaim(
        _generatedClaim!.id,
        outcome,
        duplicateDetails: duplicateDetails ? true : null,
      );
      setState(() => _generatedClaim = updated);

      if (!mounted) return;
      if (outcome == 'REFUNDED') {
        AppSnackBar.showSuccess(
          context,
          message: 'Item successfully archived.',
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
        AppSnackBar.showSuccess(
          context,
          message: 'Item successfully archived.',
        );
      }
    } catch (e) {
      logger.e('Error resolving claim: $e');
      if (mounted) {
        AppSnackBar.showError(context, message: 'Failed to resolve claim: $e');
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _openPdf() async {
    String? filePath;

    // Check if PDF is already cached
    if (_cachedPdfPath != null && await File(_cachedPdfPath!).exists()) {
      filePath = _cachedPdfPath;
      logger.i('Using cached PDF for opening');
    } else {
      final downloadedPath = await _downloadPdfFile(showSuccessMessage: false);
      if (downloadedPath == null) return;
      filePath = downloadedPath;

      // Cache for future use
      setState(() => _cachedPdfPath = downloadedPath);
    }

    // Ensure filePath is not null before opening
    if (filePath == null) return;

    try {
      final openResult = await OpenFilex.open(
        filePath,
        type: 'application/pdf',
      );
      if (openResult.type != ResultType.done && mounted) {
        AppSnackBar.showInfo(
          context,
          message: openResult.message.isNotEmpty
              ? openResult.message
              : 'No PDF app found on this device.',
        );
      }
    } catch (e) {
      logger.e('Error opening PDF: $e');
      if (!mounted) return;
      AppSnackBar.showError(
        context,
        message: 'Unable to open PDF. Please try Download instead.',
      );
    }
  }

  Future<void> _downloadPdf() async {
    await _downloadPdfToPublicDownloads();
  }

  /// Cache PDF in background after generation
  Future<void> _cachePdfInBackground() async {
    if (_isCachingPdf || _cachedPdfPath != null) return;

    setState(() => _isCachingPdf = true);

    try {
      final filePath = await _downloadPdfFile(showSuccessMessage: false);
      if (filePath != null && mounted) {
        setState(() {
          _cachedPdfPath = filePath;
          _isCachingPdf = false;
        });
        logger.i('PDF cached successfully: $filePath');
      }
    } catch (e) {
      logger.e('Error caching PDF: $e');
      if (mounted) {
        setState(() => _isCachingPdf = false);
      }
    }
  }

  Future<void> _sharePdf() async {
    String? filePath;

    // Check if PDF is already cached
    if (_cachedPdfPath != null) {
      // Verify cached file still exists
      if (await File(_cachedPdfPath!).exists()) {
        filePath = _cachedPdfPath;
        logger.i('Using cached PDF for sharing');
      } else {
        // Cache is stale, clear it
        setState(() => _cachedPdfPath = null);
      }
    }

    // If no cache, show loading and download
    if (filePath == null) {
      // Show loading indicator
      if (mounted) {
        AppSnackBar.showInfo(context, message: 'Preparing PDF for sharing...');
      }

      filePath = await _downloadPdfFile(showSuccessMessage: false);
      if (filePath == null) return;

      // Cache for future use
      setState(() => _cachedPdfPath = filePath);
    }

    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Warranty claim PDF from ${widget.receiptStoreName}',
        subject: 'Warranty Claim PDF',
      );
    } catch (e) {
      logger.e('Error sharing PDF: $e');
      if (!mounted) return;
      AppSnackBar.showError(
        context,
        message: 'Failed to share PDF',
      );
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
          '${pdfDir.path}/claim_${_generatedClaim!.id}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      await Dio().download(url, filePath);

      if (showSuccessMessage && mounted) {
        AppSnackBar.showSuccess(
          context,
          message: 'PDF downloaded successfully.',
        );
      }

      return filePath;
    } catch (e) {
      logger.e('Error downloading PDF file: $e');
      if (!mounted) return null;
      AppSnackBar.showError(
        context,
        message: 'Unable to download PDF. Please try again.',
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
            'claim_${_generatedClaim!.id}_${DateTime.now().millisecondsSinceEpoch}.pdf';
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
            '${downloadsDir.path}/claim_${_generatedClaim!.id}_${DateTime.now().millisecondsSinceEpoch}.pdf';
        await Dio().download(url, filePath);

        if (mounted) {
          AppSnackBar.showSuccess(
            context,
            message: 'PDF saved to Downloads folder.',
          );
        }

        return filePath;
      }
    } catch (e) {
      logger.e('Error saving PDF to Downloads: $e');
      if (!mounted) return null;
      AppSnackBar.showError(
        context,
        message:
            'Unable to save to Downloads. Please check storage permissions.',
      );
      return null;
    }
  }

  void _showDownloadStartedMessage() {
    if (!mounted) return;
    AppSnackBar.showInfo(
      context,
      message: 'Download started. Open notification to view file.',
    );
  }

  Future<String?> _getFreshClaimUrl() async {
    if (_generatedClaim == null) return null;

    try {
      final claimService = ref.read(claimServiceProvider);
      final refreshedClaim = await claimService.accessClaimPdf(
        _generatedClaim!.id,
      );

      if (!mounted) return refreshedClaim.url;
      setState(() => _generatedClaim = refreshedClaim);

      if (refreshedClaim.url == null || refreshedClaim.url!.trim().isEmpty) {
        AppSnackBar.showInfo(
          context,
          message: 'Claim PDF is not available yet. Try again shortly.',
        );
        return null;
      }

      return refreshedClaim.url;
    } catch (e) {
      logger.e('Error refreshing claim PDF URL: $e');
      if (!mounted) return null;
      AppSnackBar.showError(
        context,
        message: 'Could not fetch PDF link. Please try again.',
      );
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_generatedClaim != null) {
      return _buildSuccessScreen(isDark);
    }

    return _buildFormScreen(isDark);
  }

  Widget _buildFormScreen(bool isDark) {
    final cardColor = AppColors.card(isDark);
    final textColor = AppColors.textPrimary(isDark);
    final secondaryColor = AppColors.textSecondary(isDark);
    final dateFormat = DateFormat('MMM dd, yyyy');
    final receiptAsync = ref.watch(receiptProvider(widget.receiptId));

    final productName = receiptAsync.maybeWhen(
      data: (receipt) {
        if (receipt.productName != null &&
            receipt.productName!.trim().isNotEmpty) {
          return receipt.productName!;
        }
        if (receipt.lineItems.isNotEmpty) {
          return receipt.lineItems.first.displayName;
        }
        return 'Unknown Product';
      },
      orElse: () => 'Unknown Product',
    );

    final receiptDate = receiptAsync.maybeWhen(
      data: (receipt) => receipt.purchaseDate != null
          ? dateFormat.format(receipt.purchaseDate!.toLocal())
          : 'Not available',
      orElse: () => 'Not available',
    );

    final warrantyExpiryDate = receiptAsync.maybeWhen(
      data: (receipt) {
        ReceiptLineItemModel? lineItem;
        if (widget.lineItemId != null) {
          for (var item in receipt.lineItems) {
            if (item.id == widget.lineItemId) {
              lineItem = item;
              break;
            }
          }
        }
        lineItem ??= receipt.lineItems.isNotEmpty
            ? receipt.lineItems.first
            : null;

        if (lineItem != null && lineItem.warrantyExpiryDate != null) {
          return dateFormat.format(lineItem.warrantyExpiryDate!.toLocal());
        }
        return 'Not available';
      },
      orElse: () => 'Not available',
    );

    final returnExpiryDate = receiptAsync.maybeWhen(
      data: (receipt) {
        ReceiptLineItemModel? lineItem;
        if (widget.lineItemId != null) {
          for (var item in receipt.lineItems) {
            if (item.id == widget.lineItemId) {
              lineItem = item;
              break;
            }
          }
        }
        lineItem ??= receipt.lineItems.isNotEmpty
            ? receipt.lineItems.first
            : null;

        if (lineItem != null && lineItem.returnExpiryDate != null) {
          return dateFormat.format(lineItem.returnExpiryDate!.toLocal());
        }
        return 'Not available';
      },
      orElse: () => 'Not available',
    );

    return Scaffold(
      appBar: _buildStyledAppBar('New Claim', isDark),
      backgroundColor: AppColors.background(isDark),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingPage),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Header Card
              Text(
                'Claim Information',
                style: AppTextStyles.formLabel.copyWith(color: secondaryColor),
              ),
              const SizedBox(height: 8),
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
                      icon: Symbols.storefront_rounded,
                      label: 'Store',
                      value: widget.receiptStoreName,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 6),
                    _buildStackedDetailItem(
                      icon: Symbols.shopping_bag_rounded,
                      label: 'Product',
                      value: productName,
                      isDark: isDark,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 6),
                    _buildStackedDetailItem(
                      icon: Symbols.calendar_today_rounded,
                      label: 'Purchase Date',
                      value: receiptDate,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 6),
                    _buildStackedDetailItem(
                      icon: Symbols.verified_user_rounded,
                      label: 'Warranty Expires',
                      value: warrantyExpiryDate,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 6),
                    _buildStackedDetailItem(
                      icon: Symbols.undo_rounded,
                      label: 'Return Expires',
                      value: returnExpiryDate,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Issue Description
              Text(
                'Issue Description',
                style: AppTextStyles.formLabel.copyWith(
                  color: secondaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _issueController,
                enabled: !_isLoading,
                maxLines: 8,
                minLines: 6,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText:
                      'E.g., Screen has dead pixels, battery not holding charge, damage on arrival',
                  hintStyle: AppTextStyles.bodySmall.copyWith(
                    color: secondaryColor.withValues(alpha: 0.5),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusLarge,
                    ),
                    borderSide: BorderSide(color: AppColors.border(isDark)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusLarge,
                    ),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusLarge,
                    ),
                    borderSide: BorderSide(color: AppColors.border(isDark)),
                  ),
                  filled: true,
                  fillColor: cardColor,
                  contentPadding: const EdgeInsets.all(12),
                ),
                style: AppTextStyles.bodySmall.copyWith(color: textColor),
              ),
              const SizedBox(height: 24),

              // Claim Type
              Text(
                'Claim Type',
                style: AppTextStyles.formLabel.copyWith(
                  color: secondaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
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
                        onTap: _isLoading
                            ? null
                            : () => setState(
                                () => _isClaimTypeExpanded =
                                    !_isClaimTypeExpanded,
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
                                    _getClaimTypeIcon(_selectedClaimType),
                                    size: 20,
                                    weight: 600.0,
                                    color: AppColors.textPrimary(isDark),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _formatClaimTypeText(_selectedClaimType),
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textPrimary(isDark),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              AnimatedRotation(
                                turns: _isClaimTypeExpanded ? 0.5 : 0,
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
                      child: _isClaimTypeExpanded
                          ? Column(
                              children: [
                                Divider(
                                  height: 1,
                                  color: AppColors.border(isDark),
                                ),
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _claimTypeOptions.length,
                                  separatorBuilder: (context, index) => Divider(
                                    height: 1,
                                    color: AppColors.border(isDark),
                                  ),
                                  itemBuilder: (context, index) {
                                    final type = _claimTypeOptions[index];
                                    final isSelected =
                                        _selectedClaimType == type;
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isClaimTypeExpanded = false;
                                          _selectedClaimType = type;
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
                                              _getClaimTypeIcon(type),
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
                                              _formatClaimTypeText(type),
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
              const SizedBox(height: 24),

              // Defect Images Section
              Text(
                'Defect Images (Optional)',
                style: AppTextStyles.formLabel.copyWith(
                  color: secondaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Add photos showing the defect or issue (max 10)',
                style: AppTextStyles.caption.copyWith(
                  color: secondaryColor.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 12),

              if (_defectImagePaths.isNotEmpty)
                Container(
                  height: 100,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _defectImagePaths.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 100,
                        child: Stack(
                          children: [
                            GestureDetector(
                              onTap: () => _editDefectImage(index),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusMedium,
                                ),
                                child: Image.file(
                                  File(_defectImagePaths[index]),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeDefectImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Symbols.close_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 4,
                              left: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: AppTextStyles.caption.copyWith(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              if (_defectImagePaths.length < 10)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _pickDefectImages,
                    icon: Icon(
                      Symbols.add_a_photo_rounded,
                      size: AppDimensions.iconMedium,
                      color: AppColors.primary,
                      weight: AppDimensions.iconWeightHeavy,
                    ),
                    label: Text(
                      _defectImagePaths.isEmpty
                          ? 'Add Defect Images'
                          : 'Add More',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primary, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusLarge,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),

              if (_defectImagePaths.length >= 10)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusLarge,
                    ),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Symbols.info_rounded,
                        size: 16,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Maximum of 10 defect images reached',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 28),

              // Error Message
              if (_error != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusLarge,
                    ),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Symbols.error_rounded,
                        color: AppColors.error,
                        size: AppDimensions.iconMedium,
                        weight: AppDimensions.iconWeightHeavy,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: AppTextStyles.bodyXSmall.copyWith(
                            color: AppColors.error,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
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
              onPressed: _isLoading ? null : _generateClaim,
              icon: _isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    )
                  : const Icon(
                      Symbols.file_download_rounded,
                      weight: AppDimensions.iconWeightHeavy,
                    ),
              label: Text(
                _isLoading ? 'Generating PDF...' : 'Generate Claim PDF',
                style: AppTextStyles.button,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessScreen(bool isDark) {
    final cardColor = AppColors.card(isDark);
    final textColor = AppColors.textPrimary(isDark);
    final secondaryColor = AppColors.textSecondary(isDark);
    final dateFormat = DateFormat('MMM dd, yyyy • HH:mm');
    final receiptAsync = ref.watch(receiptProvider(widget.receiptId));
    final productName = receiptAsync.maybeWhen(
      data: (receipt) {
        if (receipt.productName != null &&
            receipt.productName!.trim().isNotEmpty) {
          return receipt.productName!;
        }
        if (receipt.lineItems.isNotEmpty) {
          return receipt.lineItems.first.displayName;
        }
        return 'Unknown Product';
      },
      orElse: () => 'Unknown Product',
    );

    return Scaffold(
      appBar: _buildStyledAppBar('Claim Created', isDark),
      backgroundColor: AppColors.background(isDark),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingPage),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Success State
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Symbols.check_circle_rounded,
                      color: AppColors.primary,
                      size: AppDimensions.iconXL,
                      weight: AppDimensions.iconWeightHeavy,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'Claim PDF Ready',
                  style: AppTextStyles.headingSmall.copyWith(color: textColor),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Your claim document has been generated successfully',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: secondaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),

              // Claim Details Card
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
                      value: _shortId(_generatedClaim!.id),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 6),
                    _buildStackedDetailItem(
                      icon: Symbols.shopping_bag_rounded,
                      label: 'Product',
                      value: productName,
                      isDark: isDark,
                      maxLines: 2,
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
                      icon: Symbols.event_available_rounded,
                      label: 'Created',
                      value: dateFormat.format(
                        _generatedClaim!.createdAt.toLocal(),
                      ),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Actions Section
              Text(
                'Actions',
                style: AppTextStyles.formLabel.copyWith(color: secondaryColor),
              ),
              const SizedBox(height: 8),

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
                    // Download button (primary)
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _generatedClaim != null
                            ? _downloadPdf
                            : null,
                        icon: const Icon(
                          Symbols.file_download_rounded,
                          weight: AppDimensions.iconWeightHeavy,
                        ),
                        label: const Text('Download PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusXL,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Open button
                    SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _generatedClaim != null ? _openPdf : null,
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

                    // Share button
                    SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _generatedClaim != null ? _sharePdf : null,
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
              const SizedBox(height: 12),

              // Status Section
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
              const SizedBox(height: 0),
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
                        onTap: _isUpdating
                            ? null
                            : () => setState(
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
                                    _getStatusIcon(_generatedClaim!.status),
                                    size: 20,
                                    weight: 600.0,
                                    color: AppColors.textPrimary(isDark),
                                  ),
                                  const SizedBox(width: 12),
                                  _isUpdating
                                      ? SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          _formatStatusText(
                                            _generatedClaim!.status,
                                          ),
                                          style: AppTextStyles.bodyMedium
                                              .copyWith(
                                                color: AppColors.textPrimary(
                                                  isDark,
                                                ),
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                ],
                              ),
                              if (!_isUpdating)
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
                                        _generatedClaim!.status == status;
                                    return GestureDetector(
                                      onTap: () {
                                        setState(
                                          () => _isStatusExpanded = false,
                                        );
                                        if (status == 'RESOLVED') {
                                          _showResolutionOutcomeDialog();
                                        } else {
                                          _updateClaimStatus(status);
                                        }
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
              const SizedBox(height: 24),

              // Issue Description
              Text(
                'Issue Description',
                style: AppTextStyles.formLabel.copyWith(color: secondaryColor),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                  border: Border.all(color: AppColors.border(isDark)),
                ),
                child: Text(
                  _generatedClaim!.issueDescription,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: textColor,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Notes Section
              Text(
                'Notes',
                style: AppTextStyles.formLabel.copyWith(color: secondaryColor),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                focusNode: _notesFocusNode,
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
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildStyledAppBar(String title, bool isDark) {
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
        title,
        style: AppTextStyles.listTitle.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary(isDark),
        ),
      ),
      centerTitle: true,
    );
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
