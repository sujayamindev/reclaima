import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../home/home_screen.dart';
import 'signup_screen.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${state.error}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Listen to auth state changes and navigate directly to HomeScreen
    ref.listen<AsyncValue<dynamic>>(authStateProvider, (previous, next) {
      next.whenData((user) {
        if (user != null && mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        }
      });
    });
    
    final backgroundColor = AppColors.background(isDark);
    final cardColor = AppColors.card(isDark);
    final borderColor = AppColors.border(isDark);
    final textPrimaryColor = AppColors.textPrimary(isDark);
    final textSecondaryColor = AppColors.textSecondary(isDark);
    final labelColor = AppColors.label(isDark);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Back button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.arrow_back, color: textPrimaryColor),
                  padding: const EdgeInsets.all(8),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shape: const CircleBorder(),
                  ),
                ),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Email Address
                      _buildInputField(
                        label: 'Email Address',
                        controller: _emailController,
                        icon: Icons.mail_outline,
                        placeholder: 'name@example.com',
                        keyboardType: TextInputType.emailAddress,
                        cardColor: cardColor,
                        borderColor: borderColor,
                        labelColor: labelColor,
                        textColor: textPrimaryColor,
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
                      _buildInputField(
                        label: 'Password',
                        controller: _passwordController,
                        icon: Icons.lock_outline,
                        placeholder: 'Enter your password',
                        obscureText: _obscurePassword,
                        cardColor: cardColor,
                        borderColor: borderColor,
                        labelColor: labelColor,
                        textColor: textPrimaryColor,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: textSecondaryColor,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
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
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: authState.isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: const Color(0xFF0F172A),
                            elevation: 8,
                            shadowColor: AppColors.primary.withValues(alpha: 0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: authState.isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Color(0xFF0F172A),
                                  ),
                                )
                              : const Text('Sign In'),
                        ),
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
                                    builder: (context) => const SignupScreen(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              child: const Text(
                                'Sign Up',
                                style: AppTextStyles.buttonSmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
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
                              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                            child: _buildSocialButton(
                              label: 'Google',
                              icon: _buildGoogleIcon(),
                              onPressed: () {
                                // TODO: Implement Google Sign In
                              },
                              cardColor: cardColor,
                              borderColor: borderColor,
                              textColor: labelColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildSocialButton(
                              label: 'Apple',
                              icon: Icon(
                                Icons.apple,
                                color: isDark ? Colors.white : AppColors.onPrimary,
                                size: 20,
                              ),
                              onPressed: () {
                                // TODO: Implement Apple Sign In
                              },
                              cardColor: cardColor,
                              borderColor: borderColor,
                              textColor: labelColor,
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
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String placeholder,
    required Color cardColor,
    required Color borderColor,
    required Color labelColor,
    required Color textColor,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: AppTextStyles.formLabel.copyWith(color: labelColor),
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: AppTextStyles.bodyMedium.copyWith(color: textColor),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: labelColor.withValues(alpha: 0.5)),
            filled: true,
            fillColor: cardColor,
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: Icon(icon, color: labelColor.withValues(alpha: 0.7), size: 20),
            ),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required String label,
    required Widget icon,
    required VoidCallback onPressed,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return SizedBox(
      height: AppDimensions.buttonHeight,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: cardColor,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTextStyles.formLabel.copyWith(color: textColor),
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
      child: CustomPaint(
        painter: GoogleIconPainter(),
      ),
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
        ..cubicTo(size.width * 0.94, size.height * 0.48, size.width * 0.94, size.height * 0.45, size.width * 0.93, size.height * 0.42)
        ..lineTo(size.width * 0.5, size.height * 0.42)
        ..lineTo(size.width * 0.5, size.height * 0.60)
        ..lineTo(size.width * 0.75, size.height * 0.60)
        ..cubicTo(size.width * 0.74, size.height * 0.66, size.width * 0.71, size.height * 0.71, size.width * 0.66, size.height * 0.74)
        ..lineTo(size.width * 0.66, size.height * 0.86)
        ..lineTo(size.width * 0.815, size.height * 0.86)
        ..cubicTo(size.width * 0.90, size.height * 0.78, size.width * 0.94, size.height * 0.65, size.width * 0.94, size.height * 0.51),
      paint,
    );
    
    // Green
    paint.color = AppColors.googleGreen;
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.5, size.height * 0.96)
        ..cubicTo(size.width * 0.62, size.height * 0.96, size.width * 0.73, size.height * 0.92, size.width * 0.815, size.height * 0.86)
        ..lineTo(size.width * 0.66, size.height * 0.74)
        ..cubicTo(size.width * 0.63, size.height * 0.77, size.width * 0.59, size.height * 0.79, size.width * 0.545, size.height * 0.79)
        ..cubicTo(size.width * 0.42, size.height * 0.79, size.width * 0.315, size.height * 0.71, size.width * 0.26, size.height * 0.59)
        ..lineTo(size.width * 0.09, size.height * 0.71)
        ..cubicTo(size.width * 0.17, size.height * 0.86, size.width * 0.32, size.height * 0.96, size.width * 0.5, size.height * 0.96),
      paint,
    );
    
    // Yellow
    paint.color = AppColors.googleYellow;
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.26, size.height * 0.59)
        ..cubicTo(size.width * 0.245, size.height * 0.56, size.width * 0.235, size.height * 0.53, size.width * 0.235, size.height * 0.5)
        ..cubicTo(size.width * 0.235, size.height * 0.47, size.width * 0.245, size.height * 0.44, size.width * 0.26, size.height * 0.41)
        ..lineTo(size.width * 0.26, size.height * 0.29)
        ..lineTo(size.width * 0.09, size.height * 0.29)
        ..cubicTo(size.width * 0.06, size.height * 0.36, size.width * 0.04, size.height * 0.43, size.width * 0.04, size.height * 0.5)
        ..cubicTo(size.width * 0.04, size.height * 0.57, size.width * 0.06, size.height * 0.64, size.width * 0.09, size.height * 0.71)
        ..lineTo(size.width * 0.26, size.height * 0.59),
      paint,
    );
    
    // Red
    paint.color = AppColors.googleRed;
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.5, size.height * 0.22)
        ..cubicTo(size.width * 0.57, size.height * 0.22, size.width * 0.64, size.height * 0.24, size.width * 0.68, size.height * 0.29)
        ..lineTo(size.width * 0.82, size.height * 0.16)
        ..cubicTo(size.width * 0.73, size.height * 0.09, size.width * 0.62, size.height * 0.04, size.width * 0.5, size.height * 0.04)
        ..cubicTo(size.width * 0.32, size.height * 0.04, size.width * 0.17, size.height * 0.14, size.width * 0.09, size.height * 0.29)
        ..lineTo(size.width * 0.26, size.height * 0.41)
        ..cubicTo(size.width * 0.31, size.height * 0.29, size.width * 0.40, size.height * 0.22, size.width * 0.5, size.height * 0.22),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
