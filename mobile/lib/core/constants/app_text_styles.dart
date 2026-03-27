import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reusable text styles for the app — combining Space Grotesk and Inter.
///
/// Colors are intentionally NOT baked in — combine with AppColors:
/// ```dart
/// AppTextStyles.displayLarge.copyWith(color: AppColors.textPrimary(isDark))
/// ```
abstract final class AppTextStyles {
  // ── Display / Auth headings ────────────────────────────────────────────────

  /// 36 / bold — auth screen titles (Log In, Sign Up).
  static TextStyle get displayLarge => GoogleFonts.spaceGrotesk(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      );

  // ── Hero headings ──────────────────────────────────────────────────────────

  /// 32 / bold — home screen hero headline.
  static TextStyle get headingLarge => GoogleFonts.spaceGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        height: 1.2,
        letterSpacing: -0.5,
      );

  /// 30 / bold — add receipt "Smart Upload" title.
  static TextStyle get headingMedium => GoogleFonts.spaceGrotesk(
        fontSize: 30,
        fontWeight: FontWeight.bold,
        height: 1.25,
      );

  /// 28 / bold — review & confirmation screen titles.
  static TextStyle get headingSmall => GoogleFonts.spaceGrotesk(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        height: 1.25,
      );

  // ── App name / brand ───────────────────────────────────────────────────────

  /// 24 / bold — "Recepta." app name in top bar.
  static TextStyle get appName => GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      );

  // ── Section / card titles ──────────────────────────────────────────────────

  /// 18 / bold — empty-state "No receipts yet", timed-out banner headings.
  static TextStyle get titleLarge => GoogleFonts.spaceGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      );

  /// 15 / bold — card section titles ("Purchase Details", "Store Contact").
  static TextStyle get sectionTitle => GoogleFonts.spaceGrotesk(
        fontSize: 15,
        fontWeight: FontWeight.bold,
      );

  /// 15 / w600 — receipt card store name, ListTile titles.
  static TextStyle get listTitle => GoogleFonts.spaceGrotesk(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      );

  // ── Body ───────────────────────────────────────────────────────────────────

  /// 16 / normal / height 1.5 — auth screen subtitles, body paragraphs.
  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        height: 1.5,
      );

  /// 15 / normal / height 1.6 — add receipt description, OCR body text.
  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 15,
        height: 1.6,
      );

  /// 14 / normal — "Don't have an account?", OR divider, small body.
  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 14,
      );

  /// 13 / normal — receipt detail cell text, line item rows.
  static TextStyle get bodyXSmall => GoogleFonts.inter(
        fontSize: 13,
      );

  // ── Form ───────────────────────────────────────────────────────────────────

  /// 14 / w600 — form field labels.
  static TextStyle get formLabel => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      );

  /// 16 / bold — primary button labels.
  static TextStyle get button => GoogleFonts.spaceGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      );

  /// 14 / bold — text button labels (Sign Up, Log In).
  static TextStyle get buttonSmall => GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.bold,
      );

  // ── Captions / metadata ────────────────────────────────────────────────────

  /// 12 / normal — small metadata, timestamps.
  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
      );

  /// 12 / bold / letterSpacing 0.7 — "SELECTED FILES" all-caps labels.
  static TextStyle get capsLabel => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.7,
      );

  /// 11 / w700 — status badge text, table column headers.
  static TextStyle get badgeText => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
      );

  /// 11 / w600 — table header labels.
  static TextStyle get tableHeader => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
      );

  // ── Countdown ─────────────────────────────────────────────────────────────

  /// 52 / bold / height 1.0 — expiry countdown hero number.
  static TextStyle get countdownHero => GoogleFonts.inter(
        fontSize: 52,
        fontWeight: FontWeight.bold,
        height: 1.0,
      );


  static TextStyle get spaceGrotesk => GoogleFonts.spaceGrotesk(
      );
}
