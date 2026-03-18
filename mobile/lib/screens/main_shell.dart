import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../core/constants/app_constants.dart';
import 'home/home_screen.dart';
import 'settings/settings_screen.dart';

// ── Nav index provider ────────────────────────────────────────────────────────

final _navIndexProvider = StateProvider<int>((ref) => 0);

// ── Main shell ────────────────────────────────────────────────────────────────

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  static const _screens = <Widget>[
    HomeScreen(),
    _VaultScreen(),
    _StatsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(_navIndexProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: index, children: _screens),
      bottomNavigationBar: _BottomNavBar(
        currentIndex: index,
        isDark: isDark,
        onTap: (i) => ref.read(_navIndexProvider.notifier).state = i,
      ),
    );
  }
}

// ── Bottom nav bar ────────────────────────────────────────────────────────────

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.currentIndex,
    required this.isDark,
    required this.onTap,
  });

  final int currentIndex;
  final bool isDark;
  final ValueChanged<int> onTap;

  static const _items = [
    _NavItem(label: 'Home', symbol: Symbols.home_rounded),
    _NavItem(label: 'Vault', symbol: Symbols.view_object_track_rounded),
    _NavItem(label: 'Stats', symbol: Symbols.fiber_smart_record_rounded),
    _NavItem(label: 'Settings', symbol: Symbols.menu_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1A2F27) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: AppColors.border(isDark)),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.0 : 0.0),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 70,
            child: Row(
              children: List.generate(_items.length, (i) {
                final item = _items[i];
                final active = i == currentIndex;
                final color = active
                    ? AppColors.primary
                    : AppColors.textSecondary(isDark);

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.symbol,
                          fill: active ? 1.0 : 0.0,
                          weight: 600.0,
                          color: color,
                          size: 26,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.label, required this.symbol});
  final String label;
  final IconData symbol;
}

// ── Placeholder screens ───────────────────────────────────────────────────────

class _VaultScreen extends StatelessWidget {
  const _VaultScreen();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      body: SafeArea(
        child: Center(
          child: Text(
            'Vault',
            style: AppTextStyles.headingLarge
                .copyWith(color: AppColors.textPrimary(isDark)),
          ),
        ),
      ),
    );
  }
}

class _StatsScreen extends StatelessWidget {
  const _StatsScreen();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      body: SafeArea(
        child: Center(
          child: Text(
            'Stats',
            style: AppTextStyles.headingLarge
                .copyWith(color: AppColors.textPrimary(isDark)),
          ),
        ),
      ),
    );
  }
}
