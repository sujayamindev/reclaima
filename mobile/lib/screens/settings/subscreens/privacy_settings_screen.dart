// coverage:ignore-file
import '../../../widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // ignore: avoid_print
      print('Could not launch $url');
    }
  }

  void _handleExport(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card(isDark),
        title: Text(
          'Export Data',
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textPrimary(isDark),
          ),
        ),
        content: Text(
          'Your receipt and warranty data will be compiled into a CSV file and sent to your registered email address.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary(isDark),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary(isDark)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(ctx);
              AppSnackBar.showSuccess(
                context,
                message: 'Export started. Check your email shortly.',
              );
            },
            child: const Text(
              'Confirm Export',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

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
              Icon(
                icon,
                size: AppDimensions.iconMedium,
                color: AppColors.primary,
                weight: AppDimensions.iconWeightHeavy,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: AppTextStyles.sectionTitle.copyWith(
                  color: AppColors.textPrimary(isDark),
                ),
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
              Icon(
                icon,
                size: AppDimensions.iconMedium,
                weight: AppDimensions.iconWeightBold,
                color: AppColors.textSecondary(isDark),
              ),
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
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary(isDark),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Symbols.chevron_right_rounded,
                size: AppDimensions.iconMedium,
                color: AppColors.muted(isDark),
                weight: 600.0,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    AppSnackBar.showInfo(context, message: '$feature coming soon');
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
            AppDimensions.paddingPage,
            8,
            AppDimensions.paddingPage,
            40,
          ),
          child: Column(
            children: [
              _buildSectionCard(
                isDark,
                'Data Management',
                Symbols.database_rounded,
                [
                  _buildTapRow(
                    isDark,
                    icon: Symbols.download_rounded,
                    title: 'Export My Data',
                    subtitle: 'Download a copy of your receipts',
                    onTap: () => _handleExport(context),
                  ),
                  _buildTapRow(
                    isDark,
                    icon: Symbols.sync_rounded,
                    title: 'Sync Status',
                    subtitle: 'Manage cloud synchronization',
                    onTap: () => _showComingSoon(context, 'Sync Status'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                isDark,
                'Legal & Policies',
                Symbols.policy_rounded,
                [
                  _buildTapRow(
                    isDark,
                    icon: Symbols.description_rounded,
                    title: 'Terms of Service',
                    subtitle: 'Read our terms of service',
                    onTap: () => _launchUrl('https://receipta.app/terms'),
                  ),
                  _buildTapRow(
                    isDark,
                    icon: Symbols.privacy_tip_rounded,
                    title: 'Privacy Policy',
                    subtitle: 'Read our privacy policy',
                    onTap: () => _launchUrl('https://receipta.app/privacy'),
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
