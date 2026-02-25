import 'package:flutter/material.dart';

/// Reusable text styles for the entire app.
///
/// Colors are intentionally NOT baked in — combine with AppColors:
/// ```dart
/// AppTextStyles.displayLarge.copyWith(color: AppColors.textPrimary(isDark))
/// ```
abstract final class AppTextStyles {
  // ── Display / Auth headings ────────────────────────────────────────────────

  /// 36 / bold — auth screen titles (Log In, Sign Up).
  static const TextStyle displayLarge = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  // ── Hero headings ──────────────────────────────────────────────────────────

  /// 32 / bold — home screen hero headline.
  static const TextStyle headingLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.2,
    letterSpacing: -0.5,
  );

  /// 30 / bold — add receipt "Smart Upload" title.
  static const TextStyle headingMedium = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.bold,
    height: 1.25,
  );

  /// 28 / bold — review & confirmation screen titles.
  static const TextStyle headingSmall = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.25,
  );

  // ── App name / brand ───────────────────────────────────────────────────────

  /// 24 / bold — "Recepta." app name in top bar.
  static const TextStyle appName = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  // ── Section / card titles ──────────────────────────────────────────────────

  /// 18 / bold — empty-state "No receipts yet", timed-out banner headings.
  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  /// 15 / bold — card section titles ("Purchase Details", "Store Contact").
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.bold,
  );

  /// 15 / w600 — receipt card store name, ListTile titles.
  static const TextStyle listTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  // ── Body ───────────────────────────────────────────────────────────────────

  /// 16 / normal / height 1.5 — auth screen subtitles, body paragraphs.
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    height: 1.5,
  );

  /// 15 / normal / height 1.6 — add receipt description, OCR body text.
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 15,
    height: 1.6,
  );

  /// 14 / normal — "Don't have an account?", OR divider, small body.
  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
  );

  /// 13 / normal — receipt detail cell text, line item rows.
  static const TextStyle bodyXSmall = TextStyle(
    fontSize: 13,
  );

  // ── Form ───────────────────────────────────────────────────────────────────

  /// 14 / w600 — form field labels.
  static const TextStyle formLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  /// 16 / bold — primary button labels.
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  /// 14 / bold — text button labels (Sign Up, Log In).
  static const TextStyle buttonSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
  );

  // ── Captions / metadata ────────────────────────────────────────────────────

  /// 12 / normal — small metadata, timestamps.
  static const TextStyle caption = TextStyle(
    fontSize: 12,
  );

  /// 12 / bold / letterSpacing 0.7 — "SELECTED FILES" all-caps labels.
  static const TextStyle capsLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.7,
  );

  /// 11 / w700 — status badge text, table column headers.
  static const TextStyle badgeText = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
  );

  /// 11 / w600 — table header labels.
  static const TextStyle tableHeader = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );

  // ── Countdown ─────────────────────────────────────────────────────────────

  /// 56 / bold / height 1.0 — expiry countdown hero number.
  static const TextStyle countdownHero = TextStyle(
    fontSize: 56,
    fontWeight: FontWeight.bold,
    height: 1.0,
  );
}
