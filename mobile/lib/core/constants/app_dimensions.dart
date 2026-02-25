/// Shared spacing, border-radius, and size constants for the entire app.
///
/// Usage:
/// ```dart
/// BorderRadius.circular(AppDimensions.radiusXL)
/// EdgeInsets.all(AppDimensions.paddingPage)
/// ```
abstract final class AppDimensions {
  // ── Border radius ──────────────────────────────────────────────────────────

  /// 8 — input fields in AppTheme default, small chips.
  static const double radiusSmall = 8;

  /// 10 — icon-container backgrounds.
  static const double radiusIconContainer = 10;

  /// 12 — cards (default Material 3 card radius), list items.
  static const double radiusMedium = 12;

  /// 16 — thumbnail image containers.
  static const double radiusLarge = 16;

  /// 20 — primary card containers / bottom sheets.
  static const double radiusXL = 20;

  /// 24 — buttons, input fields (pill shape), modals.
  static const double radiusPill = 24;

  /// 31 — bottom navigation pill (height / 2).
  static const double radiusNavBar = 31;

  /// 32 — upload button large, large containers.
  static const double radiusXXL = 32;

  // ── Padding / spacing ──────────────────────────────────────────────────────

  /// 24 — standard horizontal page padding.
  static const double paddingPage = 24;

  /// 20 — card internal padding.
  static const double paddingCard = 20;

  /// 16 — dense card / list item padding.
  static const double paddingCardSmall = 16;

  // ── Component sizes ────────────────────────────────────────────────────────

  /// 48 — standard button height, social button height.
  static const double buttonHeight = 48;

  /// 62 — bottom navigation pill height.
  static const double navBarHeight = 62;

  /// 39 — circular icon button size (search / notification).
  static const double circleButtonSize = 39;
}
