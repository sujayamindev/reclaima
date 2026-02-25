import 'package:flutter/material.dart';

/// Central color palette for the entire app.
///
/// Usage:
///   ```dart
///   final isDark = Theme.of(context).brightness == Brightness.dark;
///   color: AppColors.textPrimary(isDark)
///   color: AppColors.primary   // always the brand green
///   ```
abstract final class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────────────

  /// Emerald green — the primary brand color used for buttons, FABs,
  /// focused borders, active icons, and status badges.
  static const Color primary = Color(0xFF12E28C);

  /// Dark navy foreground used on top of [primary] (button labels, icons).
  static const Color onPrimary = Color(0xFF0F172A);

  // ── Backgrounds ────────────────────────────────────────────────────────────

  static const Color _backgroundDark = Color(0xFF10221B);
  static const Color _backgroundLight = Color(0xFFF6F8F7);

  /// Page / scaffold background.
  static Color background(bool isDark) =>
      isDark ? _backgroundDark : _backgroundLight;

  // ── Cards / Surfaces ───────────────────────────────────────────────────────

  static const Color _cardDark = Color(0xFF1E3A32);
  static const Color _cardLight = Colors.white;

  /// Card / sheet / input fill background.
  static Color card(bool isDark) => isDark ? _cardDark : _cardLight;

  // ── Borders ────────────────────────────────────────────────────────────────

  static const Color _borderDark = Color(0xFF334155);
  static const Color _borderLight = Color(0xFFE2E8F0);

  /// Default border / divider color.
  static Color border(bool isDark) => isDark ? _borderDark : _borderLight;

  // ── Footer divider (slightly different from border) ────────────────────────

  static const Color _footerBorderDark = Color(0xFF1E3A32);
  static const Color _footerBorderLight = Color(0xFFF1F5F9);

  /// Border color used on the top of bottom footer containers.
  static Color footerBorder(bool isDark) =>
      isDark ? _footerBorderDark : _footerBorderLight;

  // ── Text ───────────────────────────────────────────────────────────────────

  static const Color _textPrimaryDark = Color(0xFFF1F5F9);
  static const Color _textPrimaryLight = Color(0xFF0F172A);

  /// Headings, body text.
  static Color textPrimary(bool isDark) =>
      isDark ? _textPrimaryDark : _textPrimaryLight;

  static const Color _textSecondaryDark = Color(0xFF94A3B8);
  static const Color _textSecondaryLight = Color(0xFF475569);

  /// Subtitles, hint text, less-prominent body.
  static Color textSecondary(bool isDark) =>
      isDark ? _textSecondaryDark : _textSecondaryLight;

  static const Color _labelDark = Color(0xFFCBD5E1);
  static const Color _labelLight = Color(0xFF334155);

  /// Form field labels (slightly different shade from secondary).
  static Color label(bool isDark) => isDark ? _labelDark : _labelLight;

  static const Color _mutedDark = Color(0xFF64748B);
  static const Color _mutedLight = Color(0xFF94A3B8);

  /// Muted / de-emphasised text (e.g. "SELECTED FILES" caps label).
  static Color muted(bool isDark) => isDark ? _mutedDark : _mutedLight;

  // ── Navigation bar ─────────────────────────────────────────────────────────

  static const Color _navBarDark = Color(0xFF1E293B);
  static const Color _navBarLight = Color(0xFF0F172A);

  /// Background of the bottom navigation pill.
  static Color navBar(bool isDark) => isDark ? _navBarDark : _navBarLight;

  // ── Status / Semantic ──────────────────────────────────────────────────────

  /// Success / warranty-active — same as [primary].
  static const Color success = primary;

  /// Error / expired.
  static const Color error = Color(0xFFEF4444);

  /// Warning / expiring-soon.
  static const Color warning = Color(0xFFF59E0B);

  /// Info / return-window active.
  static const Color info = Color(0xFF3B82F6);

  // ── Google brand colors (used only in GoogleIconPainter) ───────────────────

  static const Color googleBlue = Color(0xFF4285F4);
  static const Color googleGreen = Color(0xFF34A853);
  static const Color googleYellow = Color(0xFFFBBC05);
  static const Color googleRed = Color(0xFFEA4335);
}
