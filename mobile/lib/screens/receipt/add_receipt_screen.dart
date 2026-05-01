// coverage:ignore-file
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/receipt_provider.dart';
import '../../widgets/step_progress_bar.dart';
import '../../widgets/app_primary_button.dart';
import 'image_crop_rotate_screen.dart';
import 'review_receipt_screen.dart';
import 'package:material_symbols_icons/symbols.dart';

class AddReceiptScreen extends ConsumerStatefulWidget {
  const AddReceiptScreen({super.key});

  @override
  ConsumerState<AddReceiptScreen> createState() => _AddReceiptScreenState();
}

class _AddReceiptScreenState extends ConsumerState<AddReceiptScreen> {
  String? _frontImagePath;
  String? _backImagePath;
  final _picker = ImagePicker();

  Future<void> _pickImage() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = AppColors.card(isDark);
    final textPrimary = AppColors.textPrimary(isDark);
    final borderColor = AppColors.border(isDark);

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingCardSmall),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusIconContainer,
                    ),
                  ),
                  child: const Icon(
                    Symbols.camera_alt_rounded,
                    color: AppColors.primary,
                    size: AppDimensions.iconMedium,
                  ),
                ),
                title: Text(
                  'Snap a Photo',
                  style: AppTextStyles.listTitle.copyWith(color: textPrimary),
                ),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingCardSmall),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusIconContainer,
                    ),
                  ),
                  child: const Icon(
                    Symbols.photo_library_rounded,
                    color: AppColors.primary,
                    size: AppDimensions.iconMedium,
                  ),
                ),
                title: Text(
                  'Choose from Gallery',
                  style: AppTextStyles.listTitle.copyWith(color: textPrimary),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );

    if (source != null) {
      final image = await _picker.pickImage(source: source);
      if (image != null) {
        if (!mounted) return;

        // Navigate to crop/rotate screen
        final croppedImagePath = await Navigator.of(context).push<String>(
          MaterialPageRoute(
            builder: (_) => ImageCropRotateScreen(imagePath: image.path),
          ),
        );

        // Add cropped image - first to front, then to back
        if (croppedImagePath != null) {
          setState(() {
            if (_frontImagePath == null) {
              _frontImagePath = croppedImagePath;
            } else if (_backImagePath == null) {
              _backImagePath = croppedImagePath;
            } else {
              // Both filled, replace front
              _frontImagePath = croppedImagePath;
            }
          });
        }
      }
    }
  }

  void _removeImage(String imageType) {
    setState(() {
      if (imageType == 'FRONT') {
        _frontImagePath = null;
      } else {
        _backImagePath = null;
      }
    });
  }

  Future<void> _upload() async {
    if (_frontImagePath == null && _backImagePath == null) return;
    final controller = ref.read(receiptControllerProvider.notifier);

    // Upload images → S3 + run OCR without creating a DB record.
    // On failure the images are still preserved (permanent S3 path).
    final ocrData = await controller.extractOcr(
      _frontImagePath,
      _backImagePath,
    );

    if (!mounted) return;

    if (ocrData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload failed. Please try again.')),
      );
      return;
    }

    final stagingKey = ocrData['s3ObjectKey'] as String?;
    final backKey = ocrData['backImageS3Key'] as String?;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewReceiptScreen(
          isManualEntry: false,
          ocrData: ocrData,
          stagingS3Key: stagingKey,
          backImageS3Key: backKey,
        ),
      ),
    );
  }

  void _manualEntry() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Symbols.warning_rounded, color: AppColors.warning),
            const SizedBox(width: 8),
            Text(
              'Missing Image',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.textPrimary(isDark),
              ),
            ),
          ],
        ),
        content: Text(
          'If you don\'t upload a receipt image, it will not be included in generated Claim Documents, and you cannot attach an image later.\n\nWe highly recommend uploading an image even if you enter details manually.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary(isDark),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Go Back & Upload',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary(isDark),
            ),
            child: const Text('Proceed Manually'),
          ),
        ],
      ),
    );

    if (proceed != true) return;
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ReviewReceiptScreen(isManualEntry: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = AppColors.background(isDark);
    final textPrimary = AppColors.textPrimary(isDark);
    final textSecondary = AppColors.textSecondary(isDark);
    final mutedText = AppColors.muted(isDark);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // -- Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Symbols.arrow_back_rounded, color: textPrimary),
                    padding: const EdgeInsets.all(8),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shape: const CircleBorder(),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: StepProgressBar(currentStep: 1, totalSteps: 3),
                    ),
                  ),
                  // Balance the back button width
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // -- Scrollable body
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // -- Hero section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Add a Receipt',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.headingMedium.copyWith(
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Take a photo or upload from your gallery\nour AI will extract the details for you.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // -- Pick image button (original star design)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                      child: Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 240,
                            height: 240,
                            clipBehavior: Clip.antiAlias,
                            decoration: ShapeDecoration(
                              color: AppColors.primary,
                              shape: const StarBorder(
                                points: 8,
                                innerRadiusRatio: 0.8,
                                pointRounding: 0.5,
                                valleyRounding: 0.5,
                                rotation: 22.5,
                              ),
                              shadows: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.0,
                                  ),
                                  blurRadius: 36,
                                  spreadRadius: 6,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.onPrimary.withValues(
                                      alpha: 0.12,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Symbols.add_a_photo_rounded,
                                    color: AppColors.onPrimary,
                                    size: AppDimensions.iconLarge,
                                    fill: 0,
                                    weight: AppDimensions.iconWeightBold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Snap or Upload',
                                  style: AppTextStyles.button.copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.onPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Upload front, then back',
                                  style: AppTextStyles.caption.copyWith(
                                    fontSize: 12,
                                    color: AppColors.onPrimary.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    if (_frontImagePath != null || _backImagePath != null) ...[
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Text(
                              'SELECTED RECEIPT PREVIEW',
                              style: AppTextStyles.capsLabel.copyWith(
                                color: mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 128,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount:
                              (_frontImagePath != null ? 1 : 0) +
                              (_backImagePath != null ? 1 : 0),
                          itemBuilder: (context, index) {
                            final isFirst = index == 0;
                            final imagePath = isFirst
                                ? _frontImagePath!
                                : _backImagePath!;
                            final label = (isFirst && _frontImagePath != null)
                                ? 'Front'
                                : 'Back';
                            final imageType =
                                (isFirst && _frontImagePath != null)
                                ? 'FRONT'
                                : 'BACK';

                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.file(
                                      File(imagePath),
                                      width: 108,
                                      height: 108,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  // Close button
                                  Positioned(
                                    top: -5,
                                    right: -5,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(imageType),
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.6,
                                          ),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: backgroundColor,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Symbols.close_rounded,
                                          color: Colors.white,
                                          size: AppDimensions.iconTiny,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Front/Back label
                                  Positioned(
                                    bottom: 24,
                                    left: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.6,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          AppDimensions.radiusXL,
                                        ),
                                      ),
                                      child: Text(
                                        label,
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
                    ],
                  ],
                ),
              ),
            ),

            // -- Footer
            _buildFooter(backgroundColor),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(Color backgroundColor) {
    final controllerState = ref.watch(receiptControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Manual entry link
          GestureDetector(
            onTap: controllerState.isLoading ? null : _manualEntry,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Prefer to type? ',
                    style: AppTextStyles.formLabel.copyWith(
                      color: AppColors.muted(isDark),
                    ),
                  ),
                  Text(
                    'Enter manually',
                    style: AppTextStyles.formLabel.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.muted(isDark),
                      decorationColor: AppColors.muted(isDark),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Symbols.arrow_forward_rounded,
                    size: AppDimensions.iconTiny,
                    color: AppColors.muted(isDark),
                  ),
                ],
              ),
            ),
          ),
          AppPrimaryButton.dark(
            onPressed:
                (controllerState.isLoading ||
                    (_frontImagePath == null && _backImagePath == null))
                ? null
                : _upload,
            isLoading: controllerState.isLoading,
            text: (_frontImagePath == null && _backImagePath == null)
                ? 'Add at least one image'
                : 'Upload Receipt',
          ),
        ],
      ),
    );
  }
}
