// coverage:ignore-file
import '../../widgets/app_snackbar.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../core/constants/app_constants.dart';

class ImageCropRotateScreen extends StatefulWidget {
  final String imagePath;

  const ImageCropRotateScreen({super.key, required this.imagePath});

  @override
  State<ImageCropRotateScreen> createState() => _ImageCropRotateScreenState();
}

class _ImageCropRotateScreenState extends State<ImageCropRotateScreen> {
  late String _currentImagePath;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _currentImagePath = widget.imagePath;
  }

  Future<void> _cropImage() async {
    setState(() => _isProcessing = true);

    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: _currentImagePath,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Receipt Image',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: 'Crop Receipt Image'),
        ],
      );

      if (croppedFile != null) {
        setState(() => _currentImagePath = croppedFile.path);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, message: 'Crop failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _rotateImage(int degrees) async {
    setState(() => _isProcessing = true);

    try {
      final dir = File(_currentImagePath).parent.path;
      final targetPath =
          '$dir/img_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        _currentImagePath,
        targetPath,
        quality: 100,
        rotate: degrees,
      );

      if (result != null) {
        setState(() => _currentImagePath = result.path);
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, message: 'Rotation failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = AppColors.background(isDark);
    final textPrimary = AppColors.textPrimary(isDark);
    final borderColor = AppColors.border(isDark);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Crop & Rotate',
          style: AppTextStyles.headingLarge.copyWith(
            color: textPrimary,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Symbols.arrow_back_rounded,
            color: textPrimary,
            weight: AppDimensions.iconWeightBold,
          ),
        ),
      ),
      body: _isProcessing
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                // Image Preview
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.file(
                        File(_currentImagePath),
                        key: ValueKey(_currentImagePath),
                        fit: BoxFit.contain,
                        // Decode at display resolution instead of full camera resolution.
                        // Without this, a 12MP camera image takes ~10s to decode.
                        cacheWidth:
                            (MediaQuery.of(context).size.width *
                                    MediaQuery.of(context).devicePixelRatio)
                                .round(),
                        frameBuilder:
                            (context, child, frame, wasSynchronouslyLoaded) {
                              if (wasSynchronouslyLoaded || frame != null) {
                                return AnimatedOpacity(
                                  opacity: 1,
                                  duration: const Duration(milliseconds: 200),
                                  child: child,
                                );
                              }
                              return Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                  strokeWidth: 2,
                                ),
                              );
                            },
                      ),
                    ),
                  ),
                ),

                // Instructions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Crop and rotate your receipt image to ensure quality documents. This helps make your warranty claims more credible.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyXSmall.copyWith(
                      color: AppColors.textSecondary(isDark),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Crop & Rotate Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Crop button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isProcessing ? null : _cropImage,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: borderColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusXL,
                              ),
                            ),
                          ),
                          icon: Icon(
                            Symbols.crop_rounded,
                            color: AppColors.onPrimary,
                            size: AppDimensions.iconMedium,
                            weight: AppDimensions.iconWeightBold,
                          ),
                          label: Text(
                            'Crop Image',
                            style: AppTextStyles.button.copyWith(
                              color: AppColors.onPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Rotation buttons row
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isProcessing
                                  ? null
                                  : () => _rotateImage(-90),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                side: BorderSide(color: borderColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusXL,
                                  ),
                                ),
                              ),
                              icon: Icon(
                                Symbols.rotate_left_rounded,
                                color: AppColors.onPrimary,
                                size: AppDimensions.iconMedium,
                                weight: AppDimensions.iconWeightBold,
                              ),
                              label: Text(
                                'Rotate Left',
                                style: AppTextStyles.button.copyWith(
                                  color: AppColors.onPrimary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isProcessing
                                  ? null
                                  : () => _rotateImage(90),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                side: BorderSide(color: borderColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusXL,
                                  ),
                                ),
                              ),
                              icon: Icon(
                                Symbols.rotate_right_rounded,
                                color: AppColors.onPrimary,
                                size: AppDimensions.iconMedium,
                                weight: AppDimensions.iconWeightBold,
                              ),
                              label: Text(
                                'Rotate Right',
                                style: AppTextStyles.button.copyWith(
                                  color: AppColors.onPrimary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isProcessing
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: borderColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusXL,
                              ),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: AppTextStyles.button.copyWith(
                              color: textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isProcessing
                              ? null
                              : () => Navigator.of(
                                  context,
                                ).pop(_currentImagePath),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusXL,
                              ),
                            ),
                          ),
                          child: Text(
                            'Done',
                            style: AppTextStyles.button.copyWith(
                              color: AppColors.onPrimary,
                              fontSize: AppTextStyles.button.fontSize,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
