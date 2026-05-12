import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../core/constants/app_constants.dart';

class AppSnackBar {
  /// Shows an error snackbar
  static void showError(BuildContext context, {required String message}) {
    _show(context, message, AppColors.error, Symbols.error_rounded);
  }

  /// Shows a success snackbar
  static void showSuccess(BuildContext context, {required String message}) {
    _show(context, message, AppColors.success, Symbols.check_circle_rounded);
  }

  /// Shows an info snackbar
  static void showInfo(BuildContext context, {required String message}) {
    _show(context, message, AppColors.info, Symbols.info_rounded);
  }

  static void _show(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color.fromRGBO(45, 45, 45, 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusNavBar),
          side: BorderSide.none,
        ),
        margin: const EdgeInsets.only(
          bottom: 32,
          left: AppDimensions.paddingPage,
          right: AppDimensions.paddingPage,
        ),
        elevation: 0,
      ),
    );
  }
}
