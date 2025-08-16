import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../utils/app_routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/animated_background.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  late AnimationController _animationController;
  late AnimationController _successController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _successScaleAnimation;

  bool _isLoading = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _successController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    _successScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );
  }

  void _startAnimations() {
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _successController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
      _isSuccess = true;
    });

    _successController.forward();
  }

  void _handleResendEmail() async {
    setState(() => _isLoading = true);

    // Simulate resend API call
    await Future.delayed(const Duration(seconds: 1));

    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('Email sent successfully!'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Background
          AnimatedBackground(
            colors: [
              AppColors.background,
              AppColors.accent.withOpacity(0.05),
              AppColors.primary.withOpacity(0.03),
            ],
          ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 40),

                          // Back Button
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_ios),
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.surface,
                                padding: const EdgeInsets.all(12),
                              ),
                            ),
                          ),

                          const SizedBox(height: 60),

                          // Illustration
                          Center(
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(60),
                              ),
                              child: Icon(
                                _isSuccess
                                    ? Icons.mark_email_read_outlined
                                    : Icons.lock_reset,
                                size: 60,
                                color: _isSuccess
                                    ? AppColors.success
                                    : AppColors.accent,
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Content based on state
                          if (!_isSuccess)
                            ..._buildResetForm()
                          else
                            ..._buildSuccessContent(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildResetForm() {
    return [
      // Header
      Column(
        children: [
          Text(
            'Forgot Password?',
            style: AppStyles.headingLarge.copyWith(fontSize: 28),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Don\'t worry! Enter your email address and we\'ll send you a link to reset your password.',
            style: AppStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),

      const SizedBox(height: 48),

      // Reset Form
      Form(
        key: _formKey,
        child: Column(
          children: [
            // Email Field
            CustomTextField(
              controller: _emailController,
              label: 'Email Address',
              hint: 'Enter your registered email',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              isRequired: true,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter your email address';
                }
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value!)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),

            const SizedBox(height: 32),

            // Reset Button
            CustomButton(
              text: 'Send Reset Link',
              onPressed: _handleResetPassword,
              isLoading: _isLoading,
              variant: ButtonVariant.gradient,
              gradientColors: [AppColors.accent, AppColors.primary],
            ),

            const SizedBox(height: 24),

            // Back to Login
            CustomButton(
              text: 'Back to Sign In',
              onPressed: () => Navigator.pop(context),
              variant: ButtonVariant.text,
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildSuccessContent() {
    return [
      // Success Animation
      AnimatedBuilder(
        animation: _successController,
        builder: (context, child) {
          return ScaleTransition(
            scale: _successScaleAnimation,
            child: Column(
              children: [
                // Success Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    size: 50,
                    color: AppColors.success,
                  ),
                ),

                const SizedBox(height: 32),

                // Success Header
                Text(
                  'Check Your Email!',
                  style: AppStyles.headingMedium.copyWith(
                    color: AppColors.success,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Success Message
                Text(
                  'We\'ve sent a password reset link to:',
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Email
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _emailController.text,
                    style: AppStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Instructions
                Text(
                  'Please check your email and click on the link to reset your password. The link will expire in 15 minutes.',
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Action Buttons
                Column(
                  children: [
                    CustomButton(
                      text: 'Open Email App',
                      onPressed: () {
                        // Open default email app
                      },
                      variant: ButtonVariant.primary,
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: 'Resend Email',
                            onPressed: _handleResendEmail,
                            variant: ButtonVariant.outline,
                            isLoading: _isLoading,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomButton(
                            text: 'Back to Login',
                            onPressed: () {
                              AppRoutes.pushReplacementNamed(
                                context,
                                AppRoutes.login,
                              );
                            },
                            variant: ButtonVariant.text,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    ];
  }
}
