import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/receipt_provider.dart';
import '../../widgets/step_progress_bar.dart';
import 'review_receipt_screen.dart';

class AddReceiptScreen extends ConsumerStatefulWidget {
  const AddReceiptScreen({super.key});

  @override
  ConsumerState<AddReceiptScreen> createState() => _AddReceiptScreenState();
}

class _AddReceiptScreenState extends ConsumerState<AddReceiptScreen> {
  final List<String> _selectedImagePaths = [];
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 0, 0, 0).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt,
                      color: AppColors.primary, size: 20),
                ),
                title: Text('Snap a Photo',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: textPrimary)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 0, 0, 0).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library,
                      color: AppColors.primary, size: 20),
                ),
                title: Text('Choose from Gallery',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: textPrimary)),
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
        setState(() => _selectedImagePaths.add(image.path));
      }
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImagePaths.removeAt(index));
  }

  Future<void> _upload() async {
    if (_selectedImagePaths.isEmpty) return;
    final controller = ref.read(receiptControllerProvider.notifier);
    final receipt = await controller.createReceipt({});
    if (receipt == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create receipt')),
        );
      }
      return;
    }
    final uploaded = await controller.uploadReceipt(
      receipt.id,
      _selectedImagePaths.first,
    );
    if (mounted) {
      if (uploaded == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload failed. Please try again.')),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ReviewReceiptScreen(
              receiptId: receipt.id,
              isManualEntry: false,
            ),
          ),
        );
      }
    }
  }

  void _manualEntry() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ReviewReceiptScreen(
          receiptId: null,
          isManualEntry: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = AppColors.background(isDark);
    final textPrimary = AppColors.textPrimary(isDark);
    final textSecondary = AppColors.textSecondary(isDark);
    final borderColor = AppColors.border(isDark);
    final cardColor = AppColors.card(isDark);
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
                        currentStep: 1,
                        totalSteps: 3,
                      ),
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
                    'Smart Upload',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headingMedium.copyWith(
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Snap a photo or pick from your gallery \n AI does the rest.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // -- Pick image button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXXL),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.onPrimary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_a_photo_outlined,
                          color: AppColors.onPrimary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Snap or Select',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Receipt, warranty card, or invoice',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.onPrimary.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // -- Thumbnail preview
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SELECTED FILES',
                    style: AppTextStyles.capsLabel.copyWith(
                      color: mutedText,
                    ),
                  ),
                  Text(
                    '${_selectedImagePaths.length} '
                    '${_selectedImagePaths.length == 1 ? "item" : "items"}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 138,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _selectedImagePaths.length + 1,
                itemBuilder: (context, index) {
                  if (index == _selectedImagePaths.length) {
                    // Add more card
                    return GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 108,
                        height: 130,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor, width: 1),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: mutedText, size: 28),
                            const SizedBox(height: 6),
                            Text(
                              'Add More',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 108,
                          height: 130,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                            image: DecorationImage(
                              image: FileImage(
                                  File(_selectedImagePaths[index])),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: -5,
                          right: -5,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.onPrimary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: backgroundColor, width: 2),
                              ),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 12),
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
    final footerBorder = AppColors.footerBorder(isDark);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(top: BorderSide(color: footerBorder)),
      ),
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
                    "Can't scan? ",
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
                    Icons.arrow_forward,
                    size: 14,
                    color: AppColors.muted(isDark),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (controllerState.isLoading || _selectedImagePaths.isEmpty)
                  ? null
                  : _upload,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.onPrimary,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppColors.onPrimary.withValues(alpha: 0.35),
                padding: const EdgeInsets.symmetric(vertical: 17),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                ),
                elevation: 0,
              ),
              child: controllerState.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _selectedImagePaths.isEmpty
                          ? 'Select images to continue'
                          : 'Upload ${_selectedImagePaths.length} '
                            '${_selectedImagePaths.length == 1 ? "file" : "files"}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

