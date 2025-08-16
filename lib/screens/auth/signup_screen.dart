import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../services/localization_service.dart';
import '../../utils/app_routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/animated_background.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  final int _currentStep = 0;

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
  }

  void _startAnimations() {
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      // Get localization service from context
      final localization = Provider.of<LocalizationService>(
        context,
        listen: false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localization.translate('auth.agreeToTermsError')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isLoading = false);

    // Show success message and navigate to verification or main app
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Consumer<LocalizationService>(
        builder: (context, localization, child) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    color: AppColors.success,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  localization.translate('auth.accountCreated'),
                  style: AppStyles.headingMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  localization.translate('auth.verifyEmail'),
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: localization.translate('auth.continue'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    AppRoutes.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.mainNavigation,
                    );
                  },
                  variant: ButtonVariant.primary,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localization, child) {
        return Scaffold(
          body: Stack(
            children: [
              // Animated Background
              AnimatedBackground(
                colors: [
                  AppColors.background,
                  AppColors.secondary.withOpacity(0.05),
                  AppColors.accent.withOpacity(0.03),
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

                              const SizedBox(height: 20),

                              // Progress Indicator
                              _buildProgressIndicator(),

                              const SizedBox(height: 40),

                              // Header
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    localization.translate(
                                      'auth.createAccount',
                                    ),
                                    style: AppStyles.headingLarge.copyWith(
                                      fontSize: 32,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    localization.translate('welcome.subtitle'),
                                    style: AppStyles.bodyLarge.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 48),

                              // Signup Form
                              Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    // Name Field
                                    CustomTextField(
                                      controller: _nameController,
                                      label: localization.translate(
                                        'auth.fullName',
                                      ),
                                      hint: localization.translate(
                                        'auth.enterFullName',
                                      ),
                                      prefixIcon: Icons.person_outlined,
                                      isRequired: true,
                                      validator: (value) {
                                        if (value?.isEmpty ?? true) {
                                          return localization.translate(
                                            'auth.pleaseEnterFullName',
                                          );
                                        }
                                        if (value!.length < 2) {
                                          return localization.translate(
                                            'auth.nameMinLength',
                                          );
                                        }
                                        return null;
                                      },
                                    ),

                                    const SizedBox(height: 20),

                                    // Email Field
                                    CustomTextField(
                                      controller: _emailController,
                                      label: localization.translate(
                                        'auth.email',
                                      ),
                                      hint: localization.translate(
                                        'auth.enterEmail',
                                      ),
                                      keyboardType: TextInputType.emailAddress,
                                      prefixIcon: Icons.email_outlined,
                                      isRequired: true,
                                      validator: (value) {
                                        if (value?.isEmpty ?? true) {
                                          return localization.translate(
                                            'auth.pleaseEnterEmail',
                                          );
                                        }
                                        if (!RegExp(
                                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                        ).hasMatch(value!)) {
                                          return localization.translate(
                                            'auth.pleaseEnterValidEmail',
                                          );
                                        }
                                        return null;
                                      },
                                    ),

                                    const SizedBox(height: 20),

                                    // Password Field
                                    CustomTextField(
                                      controller: _passwordController,
                                      label: localization.translate(
                                        'auth.password',
                                      ),
                                      hint: localization.translate(
                                        'auth.createPassword',
                                      ),
                                      obscureText: _obscurePassword,
                                      prefixIcon: Icons.lock_outlined,
                                      isRequired: true,
                                      suffixIcon: IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value?.isEmpty ?? true) {
                                          return 'Please enter a password';
                                        }
                                        if (value!.length < 8) {
                                          return 'Password must be at least 8 characters';
                                        }
                                        return null;
                                      },
                                    ),

                                    const SizedBox(height: 20),

                                    // Confirm Password Field
                                    CustomTextField(
                                      controller: _confirmPasswordController,
                                      label: localization.translate(
                                        'auth.confirmPassword',
                                      ),
                                      hint: localization.translate(
                                        'auth.confirmPasswordHint',
                                      ),
                                      obscureText: _obscureConfirmPassword,
                                      prefixIcon: Icons.lock_outlined,
                                      isRequired: true,
                                      suffixIcon: IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _obscureConfirmPassword =
                                                !_obscureConfirmPassword;
                                          });
                                        },
                                        icon: Icon(
                                          _obscureConfirmPassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value?.isEmpty ?? true) {
                                          return localization.translate(
                                            'auth.pleaseConfirmPassword',
                                          );
                                        }
                                        if (value != _passwordController.text) {
                                          return localization.translate(
                                            'auth.passwordsDoNotMatch',
                                          );
                                        }
                                        return null;
                                      },
                                    ),

                                    const SizedBox(height: 32),

                                    // Terms and Conditions
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: _agreeToTerms,
                                          onChanged: (value) {
                                            setState(() {
                                              _agreeToTerms = value ?? false;
                                            });
                                          },
                                          activeColor: AppColors.primary,
                                        ),
                                        Expanded(
                                          child: Text(
                                            localization.translate(
                                              'auth.termsAndConditions',
                                            ),
                                            style: AppStyles.bodyMedium
                                                .copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 32),

                                    // Signup Button
                                    CustomButton(
                                      text: _isLoading
                                          ? localization.translate(
                                              'auth.creatingAccount',
                                            )
                                          : localization.translate(
                                              'auth.signup',
                                            ),
                                      onPressed: _isLoading
                                          ? null
                                          : _handleSignup,
                                      variant: ButtonVariant.primary,
                                    ),

                                    const SizedBox(height: 24),

                                    // Login Link
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          localization.translate(
                                            'auth.alreadyHaveAccount',
                                          ),
                                          style: AppStyles.bodyMedium.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.pushReplacementNamed(
                                              context,
                                              AppRoutes.login,
                                            );
                                          },
                                          child: Text(
                                            localization.translate(
                                              'auth.login',
                                            ),
                                            style: AppStyles.bodyMedium
                                                .copyWith(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
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
      },
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          for (int i = 0; i < 3; i++)
            Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: i <= _currentStep
                      ? AppColors.primary
                      : AppColors.textTertiary.withOpacity(0.3),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
