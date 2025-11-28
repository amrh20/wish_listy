import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';
import '../widgets/signup_header_widget.dart';
import '../widgets/signup_form_widget.dart';
import '../widgets/signup_terms_widget.dart';
import '../widgets/signup_actions_widget.dart';

/// Refactored Signup Screen
/// Now uses separate widgets for better organization and maintainability
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  bool _isFormValid = false;

  // Error messages for each field
  String? _fullNameError;
  String? _usernameError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    _setupFormValidation();
  }

  /// Setup form validation listeners
  void _setupFormValidation() {
    _fullNameController.addListener(_validateForm);
    _usernameController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);
  }

  /// Initialize animations
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

  /// Start animations
  void _startAnimations() {
    _animationController.forward();
  }

  /// Validate the entire form and update button state
  void _validateForm() {
    final localization = Provider.of<LocalizationService>(
      context,
      listen: false,
    );

    // Check if all fields have content
    final hasFullName = _fullNameController.text.trim().isNotEmpty;
    final hasUsername = _usernameController.text.trim().isNotEmpty;
    final hasPassword = _passwordController.text.isNotEmpty;
    final hasConfirmPassword = _confirmPasswordController.text.isNotEmpty;

    // Simple validation for now
    String? fullNameError;
    String? usernameError;
    String? passwordError;
    String? confirmPasswordError;

    // Full name validation
    if (hasFullName && _fullNameController.text.trim().length < 2) {
      fullNameError = localization.translate('auth.nameMinLength');
    }

    // Username validation (email or phone)
    if (hasUsername) {
      final username = _usernameController.text.trim();
      final authRepository = Provider.of<AuthRepository>(
        context,
        listen: false,
      );
      if (!authRepository.isValidUsername(username)) {
        usernameError = localization.translate('auth.invalidEmailOrPhone');
      }
    }

    // Password validation - minimum 6 characters
    if (hasPassword && _passwordController.text.length < 6) {
      passwordError = localization.translate('auth.passwordMinLength');
    }

    // Confirm password validation
    if (hasConfirmPassword &&
        _passwordController.text != _confirmPasswordController.text) {
      confirmPasswordError = localization.translate('auth.passwordsDoNotMatch');
    }

    // Check if all fields are valid
    final fullNameValid = hasFullName && fullNameError == null;
    final usernameValid = hasUsername && usernameError == null;
    final passwordValid = hasPassword && passwordError == null;
    final confirmPasswordValid =
        hasConfirmPassword && confirmPasswordError == null;

    // Update form validity state
    final isFormValid =
        fullNameValid &&
        usernameValid &&
        passwordValid &&
        confirmPasswordValid &&
        _agreeToTerms;

    // Update state if there are changes
    if (_isFormValid != isFormValid ||
        _fullNameError != fullNameError ||
        _usernameError != usernameError ||
        _passwordError != passwordError ||
        _confirmPasswordError != confirmPasswordError) {
      setState(() {
        _isFormValid = isFormValid;
        _fullNameError = fullNameError;
        _usernameError = usernameError;
        _passwordError = passwordError;
        _confirmPasswordError = confirmPasswordError;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fullNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Handle user registration using API
  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeToTerms) {
      final localization = Provider.of<LocalizationService>(
        context,
        listen: false,
      );
      _showErrorSnackBar(localization.translate('auth.agreeToTermsError'));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Get AuthRepository instance
      final authRepository = Provider.of<AuthRepository>(
        context,
        listen: false,
      );

      // Call register API with form data
      final response = await authRepository.register(
        fullName: _fullNameController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      setState(() => _isLoading = false);

      // Check if registration was successful
      if (response['success'] == true) {
        // Show success toast message
        if (mounted) {
          _showSuccessSnackBar('تم التسجيل بنجاح');

          // Wait a bit for the toast to be visible, then redirect to login
          await Future.delayed(const Duration(milliseconds: 1500));

          // Navigate to login screen with username and password pre-filled
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.login,
              arguments: {
                'username': _usernameController.text.trim(),
                'password': _passwordController.text,
              },
            );
          }
        }
      } else {
        // Registration failed
        final errorMessage =
            response['message']?.toString() ??
            'Registration failed. Please try again.';
        _showErrorSnackBar(errorMessage);
      }
    } on ApiException catch (e) {
      // Handle API-specific errors
      setState(() => _isLoading = false);
      if (mounted) {
        _showErrorSnackBar(e.message);
      }
    } catch (e) {
      // Handle unexpected errors
      setState(() => _isLoading = false);
      if (mounted) {
        _showErrorSnackBar('An unexpected error occurred. Please try again.');
      }
      // Log error for debugging
      debugPrint('Signup error: $e');
    }
  }

  /// Show success message as a top toast
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Show error message as a top toast
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
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
        margin: const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
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

                              const SizedBox(height: 20),

                              // Header Widget
                              const SignupHeaderWidget(),

                              // Signup Form
                              Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    // Form Fields Widget
                                    SignupFormWidget(
                                      fullNameController: _fullNameController,
                                      usernameController: _usernameController,
                                      passwordController: _passwordController,
                                      confirmPasswordController:
                                          _confirmPasswordController,
                                      obscurePassword: _obscurePassword,
                                      obscureConfirmPassword:
                                          _obscureConfirmPassword,
                                      fullNameError: _fullNameError,
                                      usernameError: _usernameError,
                                      passwordError: _passwordError,
                                      confirmPasswordError:
                                          _confirmPasswordError,
                                      onPasswordToggle: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                      onConfirmPasswordToggle: () {
                                        setState(() {
                                          _obscureConfirmPassword =
                                              !_obscureConfirmPassword;
                                        });
                                      },
                                    ),

                                    // Terms and Conditions Widget
                                    SignupTermsWidget(
                                      agreeToTerms: _agreeToTerms,
                                      onChanged: (value) {
                                        setState(() {
                                          _agreeToTerms = value ?? false;
                                        });
                                        _validateForm();
                                      },
                                    ),

                                    const SizedBox(height: 32),

                                    // Actions Widget (Button and Login Link)
                                    SignupActionsWidget(
                                      isLoading: _isLoading,
                                      isFormValid: _isFormValid,
                                      onSignupPressed: _handleSignup,
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
}
