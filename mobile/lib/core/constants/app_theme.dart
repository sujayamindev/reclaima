import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_dimensions.dart';
import 'app_text_styles.dart';

/// Central Material theme configuration for the app.
///
/// Both [lightTheme] and [darkTheme] are seeded from [AppColors.primary]
/// (brand emerald green) and override component defaults to match the
/// design system established in [AppColors], [AppTextStyles], and
/// [AppDimensions].
abstract final class AppTheme {
  // ── Light theme ─────────────────────────────────────────────────────────

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          surface: AppColors.background(false),
          onSurface: AppColors.textPrimary(false),
        ),
        scaffoldBackgroundColor: AppColors.background(false),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: AppColors.background(false),
          foregroundColor: AppColors.textPrimary(false),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.card(false),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppDimensions.radiusMedium),
            side: BorderSide(color: AppColors.border(false)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingPage, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusPill),
            ),
            textStyle: AppTextStyles.button,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.card(false),
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(AppDimensions.radiusPill),
            borderSide: BorderSide(color: AppColors.border(false)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(AppDimensions.radiusPill),
            borderSide: BorderSide(color: AppColors.border(false)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(AppDimensions.radiusPill),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 2),
          ),
          hintStyle:
              AppTextStyles.bodyMedium.copyWith(color: AppColors.muted(false)),
        ),
        textTheme: _buildTextTheme(isDark: false),
        dividerColor: AppColors.border(false),
      );

  // ── Dark theme ───────────────────────────────────────────────────────────

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          surface: AppColors.background(true),
          onSurface: AppColors.textPrimary(true),
        ),
        scaffoldBackgroundColor: AppColors.background(true),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: AppColors.background(true),
          foregroundColor: AppColors.textPrimary(true),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.card(true),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppDimensions.radiusMedium),
            side: BorderSide(color: AppColors.border(true)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingPage, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusPill),
            ),
            textStyle: AppTextStyles.button,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.card(true),
          border: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(AppDimensions.radiusPill),
            borderSide: BorderSide(color: AppColors.border(true)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(AppDimensions.radiusPill),
            borderSide: BorderSide(color: AppColors.border(true)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(AppDimensions.radiusPill),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 2),
          ),
          hintStyle:
              AppTextStyles.bodyMedium.copyWith(color: AppColors.muted(true)),
        ),
        textTheme: _buildTextTheme(isDark: true),
        dividerColor: AppColors.border(true),
      );

  // ── TextTheme helper ─────────────────────────────────────────────────────

  static TextTheme _buildTextTheme({required bool isDark}) {
    final primary = AppColors.textPrimary(isDark);
    final secondary = AppColors.textSecondary(isDark);
    return TextTheme(
      displayLarge:
          AppTextStyles.displayLarge.copyWith(color: primary),
      headlineLarge:
          AppTextStyles.headingLarge.copyWith(color: primary),
      headlineMedium:
          AppTextStyles.headingMedium.copyWith(color: primary),
      headlineSmall:
          AppTextStyles.headingSmall.copyWith(color: primary),
      titleLarge: AppTextStyles.appName.copyWith(color: primary),
      titleMedium: AppTextStyles.sectionTitle.copyWith(color: primary),
      titleSmall: AppTextStyles.listTitle.copyWith(color: primary),
      bodyLarge: AppTextStyles.bodyLarge.copyWith(color: primary),
      bodyMedium: AppTextStyles.bodyMedium.copyWith(color: primary),
      bodySmall: AppTextStyles.bodySmall.copyWith(color: secondary),
      labelLarge: AppTextStyles.button.copyWith(color: primary),
      labelMedium: AppTextStyles.formLabel.copyWith(color: secondary),
      labelSmall: AppTextStyles.caption.copyWith(color: secondary),
    );
  }
}
