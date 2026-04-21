import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/logger.dart';
import '../../../providers/auth_provider.dart';
import '../../auth/login_screen.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String _userEmail = '';
  bool _isSaving = false;
  bool _isChangingPassword = false;

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _initializeUserProfile();
  }

  void _initializeUserProfile() {
    Future.microtask(() async {
      final userModel = ref.read(userProfileProvider).value;
      final firebaseUser = ref.read(currentUserProvider);

      if (mounted) {
        setState(() {
          _nameController.text =
              userModel?.displayName ?? firebaseUser?.displayName ?? '';
          _userEmail = userModel?.email ?? firebaseUser?.email ?? '';
          _contactController.text = userModel?.contactNumber ?? '';
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .updateProfile(
            displayName: _nameController.text.trim(),
            contactNumber: _contactController.text.trim(),
          );
      ref.invalidate(userProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(milliseconds: 1500),
          ),
        );
      }
    } catch (e) {
      logger.e('Failed to save profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save profile'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('New passwords do not match'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password must be at least 6 characters long'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isChangingPassword = true);

    try {
      await ref
          .read(authControllerProvider.notifier)
          .changePassword(
            currentPassword: _currentPasswordController.text,
            newPassword: _newPasswordController.text,
          );

      if (mounted) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      logger.e('Failed to change password: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update password: ${e.toString().replaceAll("Exception: ", "")}',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isChangingPassword = false);
    }
  }

  Future<void> _showDeleteAccountDialog(bool isDark) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.card(isDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
          ),
          title: Text(
            'Delete Account',
            style: AppTextStyles.titleLarge.copyWith(color: AppColors.error),
          ),
          content: Text(
            'Are you sure you want to permanently delete your account and all associated data? This action cannot be undone.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary(isDark),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancel',
                style: AppTextStyles.buttonSmall.copyWith(
                  color: AppColors.textPrimary(isDark),
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Delete',
                style: AppTextStyles.buttonSmall.copyWith(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(authControllerProvider.notifier).deleteAccount();
      if (!mounted) return;

      // In case auth change listener doesn't catch it fast enough.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      logger.e('Delete account error: $e');
      if (!mounted) return;

      final isRequiresRecentLogin = e.toString().contains(
        'requires-recent-login',
      );
      if (isRequiresRecentLogin) {
        showDialog(
          context: context,
          builder: (reauthDialogContext) => AlertDialog(
            backgroundColor: AppColors.card(isDark),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
            ),
            title: Text(
              'Re-authentication Required',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.textPrimary(isDark),
              ),
            ),
            content: Text(
              'For security reasons, your account needs recent authentication before it can be deleted. Please log out and log back in, then try again.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary(isDark),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(reauthDialogContext).pop(),
                child: Text(
                  'Cancel',
                  style: AppTextStyles.buttonSmall.copyWith(
                    color: AppColors.textPrimary(isDark),
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusPill,
                    ),
                  ),
                ),
                onPressed: () async {
                  Navigator.of(reauthDialogContext).pop();
                  await ref.read(authControllerProvider.notifier).signOut();
                  if (!mounted) return;

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                },
                child: Text(
                  'Log Out Now',
                  style: AppTextStyles.buttonSmall.copyWith(
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Failed to delete account. Please try again later.',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildTextFieldRow(
    bool isDark, {
    required IconData icon,
    required String title,
    required String hintText,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    bool obscureText = false,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              title,
              style: AppTextStyles.formLabel.copyWith(
                color: AppColors.label(isDark),
              ),
            ),
          ),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            readOnly: readOnly,
            obscureText: obscureText,
            style: AppTextStyles.bodyMedium.copyWith(
              color: readOnly
                  ? AppColors.textSecondary(isDark)
                  : AppColors.textPrimary(isDark),
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary(isDark).withValues(alpha: 0.5),
              ),
              filled: true,
              fillColor: readOnly
                  ? AppColors.background(isDark).withValues(alpha: 0.5)
                  : AppColors.card(isDark),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 16, right: 12),
                child: Icon(
                  icon,
                  color: AppColors.textSecondary(isDark).withValues(alpha: 0.7),
                  size: 20,
                  weight: 600.0,
                ),
              ),
              suffixIcon: suffixIcon,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                borderSide: BorderSide(color: AppColors.border(isDark)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                borderSide: BorderSide(color: AppColors.border(isDark)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                borderSide: BorderSide(
                  color: readOnly
                      ? AppColors.border(isDark)
                      : AppColors.primary,
                  width: 2,
                ),
              ),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      appBar: AppBar(
        title: Text(
          'Profile & Security',
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
                'Personal Information',
                Symbols.person_rounded,
                [
                  _buildTextFieldRow(
                    isDark,
                    icon: Symbols.person_rounded,
                    title: 'Full Name',
                    hintText: 'Enter your name',
                    controller: _nameController,
                  ),
                  const SizedBox(height: 6),
                  _buildTextFieldRow(
                    isDark,
                    icon: Symbols.phone_rounded,
                    title: 'Contact Number',
                    hintText: '+1 234 567 8900',
                    controller: _contactController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ()]')),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _buildTextFieldRow(
                    isDark,
                    icon: Symbols.mail_rounded,
                    title: 'Email',
                    hintText: 'Your email',
                    controller: TextEditingController(text: _userEmail),
                    readOnly: true,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusXL,
                          ),
                        ),
                      ),
                      onPressed: _isSaving ? null : _saveProfile,
                      child: _isSaving
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  AppColors.onPrimary,
                                ),
                              ),
                            )
                          : const Text('Save Profile'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Change Password ──────────────────────────────────────────
              _buildSectionCard(isDark, 'Change Password', Symbols.lock_rounded, [
                if (ref
                        .read(currentUserProvider)
                        ?.providerData
                        .any((p) => p.providerId == 'password') ??
                    false) ...[
                  _buildTextFieldRow(
                    isDark,
                    icon: Symbols.key_rounded,
                    title: 'Current Password',
                    hintText: 'Enter current password',
                    controller: _currentPasswordController,
                    obscureText: _obscureCurrentPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCurrentPassword
                            ? Symbols.visibility_rounded
                            : Symbols.visibility_off_rounded,
                        color: AppColors.textSecondary(isDark),
                      ),
                      onPressed: () {
                        setState(
                          () => _obscureCurrentPassword =
                              !_obscureCurrentPassword,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildTextFieldRow(
                    isDark,
                    icon: Symbols.password_rounded,
                    title: 'New Password',
                    hintText: 'Enter new password',
                    controller: _newPasswordController,
                    obscureText: _obscureNewPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNewPassword
                            ? Symbols.visibility_rounded
                            : Symbols.visibility_off_rounded,
                        color: AppColors.textSecondary(isDark),
                      ),
                      onPressed: () {
                        setState(
                          () => _obscureNewPassword = !_obscureNewPassword,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildTextFieldRow(
                    isDark,
                    icon: Symbols.password_rounded,
                    title: 'Confirm New Password',
                    hintText: 'Confirm new password',
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Symbols.visibility_rounded
                            : Symbols.visibility_off_rounded,
                        color: AppColors.textSecondary(isDark),
                      ),
                      onPressed: () {
                        setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusXL,
                          ),
                        ),
                        side: BorderSide(color: AppColors.primary),
                      ),
                      onPressed: _isChangingPassword ? null : _changePassword,
                      child: _isChangingPassword
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Update Password'),
                    ),
                  ),
                ] else ...[
                  Builder(
                    builder: (context) {
                      final authUser = ref.read(currentUserProvider);
                      final isApple =
                          authUser?.providerData.any(
                            (p) => p.providerId.contains('apple'),
                          ) ??
                          false;
                      final providerName = isApple ? 'an Apple' : 'a Google';
                      final shortName = isApple ? 'Apple' : 'Google';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'You are signed in with $providerName account. Password changes are managed through $shortName.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary(isDark),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ]),
              const SizedBox(height: 16),

              // ── Danger Zone ─────────────────────────────────────────────
              _buildSectionCard(
                isDark,
                'Danger Zone',
                Symbols.warning_rounded,
                [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    horizontalTitleGap: 12,
                    leading: Icon(
                      Symbols.door_open_rounded,
                      color: AppColors.error,
                      weight: AppDimensions.iconWeightBold,
                    ),
                    title: Text(
                      'Log Out',
                      style: AppTextStyles.listTitle.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                    subtitle: Text(
                      'Sign out of your account on this device',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary(isDark),
                      ),
                    ),
                    trailing: Icon(
                      Symbols.chevron_right_rounded,
                      size: AppDimensions.iconMedium,
                      color: AppColors.muted(isDark),
                    ),
                    onTap: () async {
                      await ref.read(authControllerProvider.notifier).signOut();
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    },
                  ),
                  Divider(color: AppColors.border(isDark), height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    horizontalTitleGap: 12,
                    leading: Icon(
                      Symbols.delete_rounded,
                      color: AppColors.error,
                      weight: AppDimensions.iconWeightBold,
                    ),
                    title: Text(
                      'Delete Account',
                      style: AppTextStyles.listTitle.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                    subtitle: Text(
                      'Permanently remove all your data',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary(isDark),
                      ),
                    ),
                    trailing: Icon(
                      Symbols.chevron_right_rounded,
                      size: AppDimensions.iconMedium,
                      color: AppColors.muted(isDark),
                    ),
                    onTap: () => _showDeleteAccountDialog(isDark),
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
