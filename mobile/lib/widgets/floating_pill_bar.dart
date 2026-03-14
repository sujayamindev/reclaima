import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';

/// A single item displayed inside the [FloatingPillBar].
class PillBarItem {
  final IconData icon;
  final String? label;
  final VoidCallback onTap;
  final bool isActive;

  const PillBarItem({
    required this.icon,
    this.label,
    required this.onTap,
    this.isActive = false,
  });
}

/// A reusable dark floating pill bar that renders a list of icon actions.
///
/// Used as the bottom navigation on the home screen and as a floating
/// quick-actions bar on the product detail screen.
///
/// ```dart
/// FloatingPillBar(
///   items: [
///     PillBarItem(icon: Icons.home_rounded, onTap: () {}, isActive: true),
///     PillBarItem(icon: Icons.settings_outlined, onTap: () {}),
///   ],
/// )
/// ```
class FloatingPillBar extends StatelessWidget {
  const FloatingPillBar({
    super.key,
    required this.items,
    this.horizontalPadding = 24.0,
    this.bottomPadding = 20.0,
  });

  final List<PillBarItem> items;

  /// Horizontal padding around the pill (default matches home screen: 24).
  final double horizontalPadding;

  /// Bottom padding below the pill (default 20).
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = AppColors.textSecondary(isDark);

    return Padding(
      padding: EdgeInsets.fromLTRB(
          horizontalPadding, 0, horizontalPadding, bottomPadding),
      child: Container(
        height: AppDimensions.navBarHeight,
        decoration: BoxDecoration(
          color: AppColors.navBar(isDark),
          borderRadius: BorderRadius.circular(AppDimensions.radiusNavBar),
        ),
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: item.onTap,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.icon,
                      size: 22,
                      color:
                          item.isActive ? AppColors.primary : inactiveColor,
                    ),
                    if (item.label != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        item.label!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: item.isActive
                              ? AppColors.primary
                              : inactiveColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
