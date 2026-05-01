// coverage:ignore-file
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

class AppPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double width;
  final double height;
  final Color backgroundColor;
  final Color foregroundColor;
  final BorderSide? side;
  final Widget? icon;

  const AppPrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width = double.infinity,
    this.height = AppDimensions.buttonHeight,
    this.backgroundColor = AppColors.primary,
    this.foregroundColor = AppColors.onPrimary,
    this.side,
    this.icon,
  });

  factory AppPrimaryButton.dark({
    Key? key,
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    double width = double.infinity,
    double height = AppDimensions.buttonHeight,
    BorderSide? side,
    Widget? icon,
  }) {
    return AppPrimaryButton(
      key: key,
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      width: width,
      height: height,
      backgroundColor: AppColors.onPrimary,
      foregroundColor: Colors
          .white, // In dark button, we use white text on the navy background
      side: side,
      icon: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: backgroundColor.withValues(alpha: 0.5),
          disabledForegroundColor: foregroundColor.withValues(alpha: 0.5),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
            side: side ?? BorderSide.none,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[icon!, const SizedBox(width: 8)],
                  Text(
                    text,
                    style: AppTextStyles.button.copyWith(
                      color: foregroundColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
