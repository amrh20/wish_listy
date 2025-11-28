import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'package:wish_listy/core/widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _hasLoadedArguments = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load arguments from route only once
    if (!_hasLoadedArguments) {
      _hasLoadedArguments = true;
      // Check if username and password were passed from signup
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map<String, dynamic>) {
        final username = args['username'] as String?;
        final password = args['password'] as String?;
        if (username != null) {
          _usernameController.text = username;
        }
        if (password != null) {
          _passwordController.text = password;
        }
      }
    }
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
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthRepository>(context, listen: false);
      final success = await authService.loginUser(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      if (success && mounted) {
        // Navigate to main app
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.mainNavigation,
          (route) => false,
        );
      } else {
        // Login failed
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Login failed. Please check your credentials.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(
                top: 60,
                left: 16,
                right: 16,
                bottom: 0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } on ApiException catch (e) {
      // Handle API-specific errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    e.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(
              top: 60,
              left: 16,
              right: 16,
              bottom: 0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      // Handle unexpected errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'An unexpected error occurred. Please try again.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(
              top: 60,
              left: 16,
              right: 16,
              bottom: 0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      debugPrint('Login error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localization, child) {
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          body: Stack(
            children: [
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

                              // Top Row: Back Button and Language Toggle
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Back Button
                                  IconButton(
                                    onPressed: () => Navigator.pop(context),
                                    icon: const Icon(Icons.arrow_back_ios),
                                    style: IconButton.styleFrom(
                                      backgroundColor: AppColors.surface,
                                      padding: const EdgeInsets.all(12),
                                    ),
                                  ),

                                  // Language Toggle Button
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.border,
                                        width: 1,
                                      ),
                                    ),
                                    child: IconButton(
                                      onPressed: () async {
                                        await localization.toggleLanguage();
                                      },
                                      icon: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            localization
                                                    .currentLanguageInfo?['flag'] ??
                                                '🌐',
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.language,
                                            size: 20,
                                            color: AppColors.primary,
                                          ),
                                        ],
                                      ),
                                      tooltip: localization.translate(
                                        'app.selectLanguage',
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 40),

                              // Header
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    localization.translate('auth.welcomeBack'),
                                    style: AppStyles.headingLarge.copyWith(
                                      fontSize: 32,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    localization.translate(
                                      'auth.signInSubtitle',
                                    ),
                                    style: AppStyles.bodyLarge.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 48),

                              // Login Form
                              Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    // Username Field (Email or Phone)
                                    CustomTextField(
                                      controller: _usernameController,
                                      label: localization.translate(
                                        'auth.email',
                                      ),
                                      hint: 'Email or Phone',
                                      keyboardType: TextInputType.text,
                                      prefixIcon: Icons.person_outline,
                                      validator: (value) {
                                        if (value?.isEmpty ?? true) {
                                          return localization.translate(
                                            'auth.pleaseEnterEmail',
                                          );
                                        }
                                        // Validate as email or phone
                                        final authRepository =
                                            Provider.of<AuthRepository>(
                                              context,
                                              listen: false,
                                            );
                                        if (!authRepository.isValidUsername(
                                          value!,
                                        )) {
                                          return localization.translate(
                                            'auth.invalidEmailOrPhone',
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
                                        'auth.enterPassword',
                                      ),
                                      obscureText: _obscurePassword,
                                      prefixIcon: Icons.lock_outlined,
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
                                          return localization.translate(
                                            'auth.pleaseEnterPassword',
                                          );
                                        }
                                        if (value!.length < 6) {
                                          return localization.translate(
                                            'auth.passwordMinLength',
                                          );
                                        }
                                        return null;
                                      },
                                    ),

                                    const SizedBox(height: 16),

                                    // Remember Me & Forgot Password
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Checkbox(
                                              value: _rememberMe,
                                              onChanged: (value) {
                                                setState(() {
                                                  _rememberMe = value ?? false;
                                                });
                                              },
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                            ),
                                            Text(
                                              localization.translate(
                                                'auth.rememberMe',
                                              ),
                                              style: AppStyles.bodyMedium,
                                            ),
                                          ],
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            AppRoutes.pushNamed(
                                              context,
                                              AppRoutes.forgotPassword,
                                            );
                                          },
                                          child: Text(
                                            localization.translate(
                                              'auth.forgotPassword',
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

                                    const SizedBox(height: 32),

                                    // Login Button
                                    CustomButton(
                                      text: localization.translate(
                                        'auth.signIn',
                                      ),
                                      onPressed: _handleLogin,
                                      isLoading: _isLoading,
                                      variant: ButtonVariant.gradient,
                                    ),

                                    const SizedBox(height: 24),

                                    // Divider
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Divider(
                                            color: AppColors.textTertiary
                                                .withOpacity(0.3),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          child: Text(
                                            localization.translate(
                                              'auth.continueWith',
                                            ),
                                            style: AppStyles.bodySmall.copyWith(
                                              color: AppColors.textTertiary,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(
                                            color: AppColors.textTertiary
                                                .withOpacity(0.3),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 24),

                                    // Social Login Buttons
                                    Row(
                                      children: [
                                        Expanded(
                                          child: CustomButton(
                                            text: localization.translate(
                                              'social.google',
                                            ),
                                            onPressed: () {
                                              // Handle Google login
                                            },
                                            variant: ButtonVariant.outline,
                                            icon: Icons.g_mobiledata,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: CustomButton(
                                            text: localization.translate(
                                              'social.apple',
                                            ),
                                            onPressed: () {
                                              // Handle Apple login
                                            },
                                            variant: ButtonVariant.outline,
                                            icon: Icons.apple,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Sign Up Link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    localization.translate(
                                      'auth.dontHaveAccount',
                                    ),
                                    style: AppStyles.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      AppRoutes.pushReplacementNamed(
                                        context,
                                        AppRoutes.signup,
                                      );
                                    },
                                    child: Text(
                                      localization.translate('auth.signup'),
                                      style: AppStyles.bodyMedium.copyWith(
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
}
