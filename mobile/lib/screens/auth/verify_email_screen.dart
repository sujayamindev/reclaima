import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_primary_button.dart';
import '../main_shell.dart';
import 'login_screen.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  Timer? _timer;
  bool _isChecking = false;
  bool _canResend = true;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    // Start polling to check if email is verified
    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _checkEmailVerified(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkEmailVerified() async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      final isVerified = await ref
          .read(authControllerProvider.notifier)
          .checkEmailVerified();
      if (isVerified && mounted) {
        _timer?.cancel();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email successfully verified!'),
            backgroundColor: Colors.white,
          ),
        );

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainShell()),
          (route) => false,
        );
      }
    } finally {
      if (mounted) {
        _isChecking = false;
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResend) return;

    setState(() {
      _canResend = false;
      _resendCooldown = 60; // 60 seconds cooldown
    });

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendCooldown > 0) {
          _resendCooldown--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });

    await ref.read(authControllerProvider.notifier).sendEmailVerification();

    if (mounted) {
      final state = ref.read(authControllerProvider);
      if (state.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to resend: ${state.error}'),
            backgroundColor: AppColors.error,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email resent.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  Future<void> _cancelAndLogout() async {
    _timer?.cancel();
    await ref.read(authControllerProvider.notifier).signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimaryColor = AppColors.textPrimary(isDark);
    final textSecondaryColor = AppColors.textSecondary(isDark);
    final user = ref.read(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background(isDark),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingPage,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Symbols.mark_email_unread_rounded,
                size: 80,
                color: AppColors.primary,
                weight: AppDimensions.iconWeightHeavy,
              ),
              const SizedBox(height: 32),
              Text(
                'Verify your email',
                style: AppTextStyles.displayLarge.copyWith(
                  color: textPrimaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'We\'ve sent a verification email to:',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                user?.email ?? '',
                style: AppTextStyles.headingSmall.copyWith(
                  color: textPrimaryColor,
                ),
                textAlign: TextAlign.center,
                textScaler: TextScaler.linear(0.75),
              ),
              const SizedBox(height: 24),
              Text(
                'Please check your inbox and tap the link to verify your account. We will automatically log you in once verified.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              AppPrimaryButton(
                text: _canResend
                    ? 'Resend Email'
                    : 'Resend Email ($_resendCooldown s)',
                onPressed: _canResend ? _resendVerificationEmail : () {},
                isLoading: ref.watch(authControllerProvider).isLoading,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _cancelAndLogout,
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusPill,
                    ),
                  ),
                ),
                child: Text(
                  'Cancel & Logout',
                  style: AppTextStyles.button.copyWith(color: AppColors.error),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
