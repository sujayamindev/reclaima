import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/logger.dart';

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  Widget _buildSectionCard(
    bool isDark,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.paddingCard),
      decoration: BoxDecoration(
        color: AppColors.card(isDark),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(color: AppColors.border(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

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
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(icon,
                  size: 18,
                  weight: 600.0,
                  color: AppColors.textSecondary(isDark)),
              const SizedBox(width: 12),
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
                  size: 18, color: AppColors.muted(isDark), weight: 600.0),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        title: Text(
          'Data & Privacy',
          style: AppTextStyles.headingLarge.copyWith(
            color: AppColors.textPrimary(isDark),
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary(isDark)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppDimensions.paddingPage, 8, AppDimensions.paddingPage, 40),
          child: Column(
            children: [
              _buildSectionCard(
                isDark,
                'Data Management',
                Symbols.database,
                [
                  _buildTapRow(
                    isDark,
                    icon: Symbols.download,
                    title: 'Export My Data',
                    subtitle: 'Download a copy of your receipts',
                    onTap: () => _showComingSoon(context),
                  ),
                  Divider(color: AppColors.border(isDark), height: 1),
                  _buildTapRow(
                    isDark,
                    icon: Symbols.sync,
                    title: 'Sync Status',
                    subtitle: 'Manage cloud synchronization',
                    onTap: () => _showComingSoon(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                isDark,
                'Legal & Policies',
                Symbols.policy,
                [
                  _buildTapRow(
                    isDark,
                    icon: Symbols.description,
                    title: 'Terms of Service',
                    subtitle: 'Read our terms of service',
                    onTap: () => _showComingSoon(context),
                  ),
                  Divider(color: AppColors.border(isDark), height: 1),
                  _buildTapRow(
                    isDark,
                    icon: Symbols.privacy_tip,
                    title: 'Privacy Policy',
                    subtitle: 'Read our privacy policy',
                    onTap: () => _showComingSoon(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}