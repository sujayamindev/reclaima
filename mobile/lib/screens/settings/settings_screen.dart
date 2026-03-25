import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'subscreens/profile_settings_screen.dart';
import 'subscreens/notification_settings_screen.dart';
import 'subscreens/privacy_settings_screen.dart';

/// Settings Hub Screen
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _appVersion = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    if (mounted) {
      setState(() {
        _appVersion = '1.0.0';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Top bar ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppDimensions.paddingPage, 20, AppDimensions.paddingPage, 16),
                child: Text(
                  'Settings',
                  style: AppTextStyles.headingLarge.copyWith(
                    color: AppColors.textPrimary(isDark),
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  AppDimensions.paddingPage, 16, AppDimensions.paddingPage, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Hub Links ─────────────────────────────────────
                  _buildSectionCard(
                    isDark,
                    'Account & Preferences',
                    Symbols.settings,
                    [
                      _buildTapRow(
                        isDark,
                        icon: Symbols.person,
                        title: 'Profile & Security',
                        subtitle: 'Update details & change password',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileSettingsScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTapRow(
                        isDark,
                        icon: Symbols.notifications_active,
                        title: 'Notifications & Reminders',
                        subtitle: 'Manage alerts & quiet hours',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const NotificationSettingsScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTapRow(
                        isDark,
                        icon: Symbols.shield,
                        title: 'Data & Privacy',
                        subtitle: 'Export data & policies',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrivacySettingsScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── About ────────────────────────────────────────────
                  _buildSectionCard(
                    isDark,
                    'About',
                    Symbols.info,
                    [
                      _buildInfoRow(isDark, 'App Version', _appVersion),
                    ],
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section card ──────────────────────────────────────────────────────────
  Widget _buildSectionCard(
    bool isDark,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(color: AppColors.border(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary, weight: 800.0),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: AppTextStyles.sectionTitle
                      .copyWith(color: AppColors.textPrimary(isDark)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  // ── Tappable row ──────────────────────────────────────────────────────────
  Widget _buildTapRow(
    bool isDark, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          child: Row(
            children: [
              Icon(icon,
                  size: 20, weight: 600.0, color: AppColors.textSecondary(isDark)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.listTitle.copyWith(
                        color: AppColors.label(isDark),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary(isDark)),
                    ),
                  ],
                ),
              ),
              Icon(Symbols.chevron_right,
                  size: 20, color: AppColors.muted(isDark), weight: 600.0),
            ],
          ),
        ),
      ),
    );
  }

  // ── Info row ──────────────────────────────────────────────────────────────
  Widget _buildInfoRow(bool isDark, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: Row(
        children: [
          Icon(Symbols.circle,
              size: 6, color: AppColors.muted(isDark), weight: 600.0),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.listTitle.copyWith(
                color: AppColors.textPrimary(isDark),
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary(isDark)),
          ),
        ],
      ),
    );
  }
}
