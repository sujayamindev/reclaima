import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_primary_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_social_button.dart';
import '../main_shell.dart';
import 'signup_screen.dart';
import 'verify_email_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authController = ref.read(authControllerProvider.notifier);
    await authController.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    // Widget may have been disposed by the auth state listener navigating away
    if (!mounted) return;

    final state = ref.read(authControllerProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${state.error}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Listen to auth state changes and navigate directly to MainShell or VerifyEmail
    ref.listen<AsyncValue<dynamic>>(authStateProvider, (previous, next) {
      next.whenData((user) {
        if (user != null && mounted) {
          if (!user.emailVerified &&
              user.providerData.any((p) => p.providerId == 'password')) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const VerifyEmailScreen()),
              (route) => false,
            );
          } else {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainShell()),
              (route) => false,
            );
          }
        }
      });
    });

    final backgroundColor = AppColors.background(isDark);
    final borderColor = AppColors.border(isDark);
    final textPrimaryColor = AppColors.textPrimary(isDark);
    final textSecondaryColor = AppColors.textSecondary(isDark);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.paddingPage,
                20,
                AppDimensions.paddingPage,
                0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Receipta.',
                    style: AppTextStyles.appName.copyWith(
                      color: AppColors.textPrimary(isDark),
                    ),
                  ),
                ],
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Log In',
                    style: AppTextStyles.displayLarge.copyWith(
                      color: textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Welcome back! Sign in to continue managing your receipts and warranties.',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Email Address
                              AppTextField(
                                label: 'Email Address',
                                controller: _emailController,
                                icon: Symbols.mail_rounded,
                                placeholder: 'name@example.com',
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Password
                              AppTextField(
                                label: 'Password',
                                controller: _passwordController,
                                icon: Symbols.lock_rounded,
                                placeholder: 'Enter your password',
                                obscureText: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Symbols.visibility_rounded
                                        : Symbols.visibility_off_rounded,
                                    color: textSecondaryColor,
                                  ),
                                  onPressed: () {
                                    setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    );
                                  },
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),

                              // Submit Button
                              const SizedBox(height: 36),
                              AppPrimaryButton(
                                text: 'Sign In',
                                isLoading: authState.isLoading,
                                onPressed: _submit,
                              ),

                              // Don't have an account
                              Padding(
                                padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Don\'t have an account?',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: textSecondaryColor,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pushReplacement(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const SignupScreen(),
                                          ),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.primary,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                      ),
                                      child: Text(
                                        'Sign Up',
                                        style: AppTextStyles.buttonSmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const Spacer(),

                              // Divider
                              Padding(
                                padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        color: borderColor,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Text(
                                        'OR',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: textSecondaryColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        color: borderColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Social Login Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: AppSocialButton(
                                      label: 'Google',
                                      icon: _buildGoogleIcon(),
                                      onPressed: authState.isLoading
                                          ? () {}
                                          : () async {
                                              final authController = ref.read(
                                                authControllerProvider.notifier,
                                              );
                                              await authController
                                                  .signInWithGoogle();

                                              if (!context.mounted) return;
                                              final state = ref.read(
                                                authControllerProvider,
                                              );
                                              if (state.hasError) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Error: ${state.error}',
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: AppSocialButton(
                                      label: 'Apple',
                                      icon: Icon(
                                        Icons.apple,
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.onPrimary,
                                        size: AppDimensions.iconMedium,
                                      ),
                                      onPressed: () {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Apple Sign-In is coming soon!',
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleIcon() {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: GoogleIconPainter()),
    );
  }
}

class GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Blue
    paint.color = AppColors.googleBlue;
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.94, size.height * 0.51)
        ..cubicTo(
          size.width * 0.94,
          size.height * 0.48,
          size.width * 0.94,
          size.height * 0.45,
          size.width * 0.93,
          size.height * 0.42,
        )
        ..lineTo(size.width * 0.5, size.height * 0.42)
        ..lineTo(size.width * 0.5, size.height * 0.60)
        ..lineTo(size.width * 0.75, size.height * 0.60)
        ..cubicTo(
          size.width * 0.74,
          size.height * 0.66,
          size.width * 0.71,
          size.height * 0.71,
          size.width * 0.66,
          size.height * 0.74,
        )
        ..lineTo(size.width * 0.66, size.height * 0.86)
        ..lineTo(size.width * 0.815, size.height * 0.86)
        ..cubicTo(
          size.width * 0.90,
          size.height * 0.78,
          size.width * 0.94,
          size.height * 0.65,
          size.width * 0.94,
          size.height * 0.51,
        ),
      paint,
    );

    // Green
    paint.color = AppColors.googleGreen;
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.5, size.height * 0.96)
        ..cubicTo(
          size.width * 0.62,
          size.height * 0.96,
          size.width * 0.73,
          size.height * 0.92,
          size.width * 0.815,
          size.height * 0.86,
        )
        ..lineTo(size.width * 0.66, size.height * 0.74)
        ..cubicTo(
          size.width * 0.63,
          size.height * 0.77,
          size.width * 0.59,
          size.height * 0.79,
          size.width * 0.545,
          size.height * 0.79,
        )
        ..cubicTo(
          size.width * 0.42,
          size.height * 0.79,
          size.width * 0.315,
          size.height * 0.71,
          size.width * 0.26,
          size.height * 0.59,
        )
        ..lineTo(size.width * 0.09, size.height * 0.71)
        ..cubicTo(
          size.width * 0.17,
          size.height * 0.86,
          size.width * 0.32,
          size.height * 0.96,
          size.width * 0.5,
          size.height * 0.96,
        ),
      paint,
    );

    // Yellow
    paint.color = AppColors.googleYellow;
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.26, size.height * 0.59)
        ..cubicTo(
          size.width * 0.245,
          size.height * 0.56,
          size.width * 0.235,
          size.height * 0.53,
          size.width * 0.235,
          size.height * 0.5,
        )
        ..cubicTo(
          size.width * 0.235,
          size.height * 0.47,
          size.width * 0.245,
          size.height * 0.44,
          size.width * 0.26,
          size.height * 0.41,
        )
        ..lineTo(size.width * 0.26, size.height * 0.29)
        ..lineTo(size.width * 0.09, size.height * 0.29)
        ..cubicTo(
          size.width * 0.06,
          size.height * 0.36,
          size.width * 0.04,
          size.height * 0.43,
          size.width * 0.04,
          size.height * 0.5,
        )
        ..cubicTo(
          size.width * 0.04,
          size.height * 0.57,
          size.width * 0.06,
          size.height * 0.64,
          size.width * 0.09,
          size.height * 0.71,
        )
        ..lineTo(size.width * 0.26, size.height * 0.59),
      paint,
    );

    // Red
    paint.color = AppColors.googleRed;
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.5, size.height * 0.22)
        ..cubicTo(
          size.width * 0.57,
          size.height * 0.22,
          size.width * 0.64,
          size.height * 0.24,
          size.width * 0.68,
          size.height * 0.29,
        )
        ..lineTo(size.width * 0.82, size.height * 0.16)
        ..cubicTo(
          size.width * 0.73,
          size.height * 0.09,
          size.width * 0.62,
          size.height * 0.04,
          size.width * 0.5,
          size.height * 0.04,
        )
        ..cubicTo(
          size.width * 0.32,
          size.height * 0.04,
          size.width * 0.17,
          size.height * 0.14,
          size.width * 0.09,
          size.height * 0.29,
        )
        ..lineTo(size.width * 0.26, size.height * 0.41)
        ..cubicTo(
          size.width * 0.31,
          size.height * 0.29,
          size.width * 0.40,
          size.height * 0.22,
          size.width * 0.5,
          size.height * 0.22,
        ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
