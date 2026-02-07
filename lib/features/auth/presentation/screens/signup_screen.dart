import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/core/utils/legal_content.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'package:wish_listy/core/widgets/custom_text_field.dart';

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
  late AnimationController _staggerAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _welcomeFade;
  late Animation<double> _subtitleFade;
  late Animation<double> _formFade;
  late Animation<double> _buttonFade;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isAgreed = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    _setupTextControllers();
  }

  void _setupTextControllers() {
    // Add listeners to all controllers to check if form is valid
    _fullNameController.addListener(_checkFormValidity);
    _usernameController.addListener(_checkFormValidity);
    _passwordController.addListener(_checkFormValidity);
    _confirmPasswordController.addListener(_checkFormValidity);
  }

  void _checkFormValidity() {
    if (mounted) {
      setState(() {
        // This will trigger rebuild and check _isFormValid
      });
    }
  }

  bool get _isFormValid {
    final fullName = _fullNameController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Check if all fields are filled
    if (fullName.isEmpty ||
        username.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      return false;
    }

    // Check if password matches confirm password
    if (password != confirmPassword) {
      return false;
    }

    // Check minimum length requirements
    if (fullName.length < 2 || password.length < 6) {
      return false;
    }

    return true;
  }

  /// Check if passwords match (for real-time visual feedback)
  bool get _doPasswordsMatch {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    
    // Only check if both fields have content
    if (password.isEmpty || confirmPassword.isEmpty) {
      return true; // Don't show error if fields are empty
    }
    
    return password == confirmPassword;
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _staggerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1600),
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

    // Stagger animations
    _welcomeFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerAnimationController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerAnimationController,
        curve: const Interval(0.1, 0.5, curve: Curves.easeOut),
      ),
    );

    _formFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerAnimationController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );

    _buttonFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _staggerAnimationController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );
  }

  void _startAnimations() {
    _animationController.forward();
    _staggerAnimationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _staggerAnimationController.dispose();
    _fullNameController.removeListener(_checkFormValidity);
    _usernameController.removeListener(_checkFormValidity);
    _passwordController.removeListener(_checkFormValidity);
    _confirmPasswordController.removeListener(_checkFormValidity);
    _fullNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Get repositories outside try-catch so they're available in catch blocks
    final authRepository = Provider.of<AuthRepository>(
      context,
      listen: false,
    );
    final localization = Provider.of<LocalizationService>(
      context,
      listen: false,
    );

    final username = _usernameController.text.trim();
    final isPhone = authRepository.isValidPhone(username);

    try {

      // Register user
      final response = await authRepository.register(
        fullName: _fullNameController.text.trim(),
        username: username,
        password: _passwordController.text,
      );

      // Check if user already exists but is unverified
      if (response['requiresVerification'] == true && mounted) {
        setState(() => _isLoading = false);
        
        // Extract userId from response (may be in user or data field)
        final userData = response['user'] ?? response['data'];
        final userId = userData?['id'] ?? userData?['_id'] ?? userData?['userId'];
        
        // Show clean snackbar message
        _showUnverifiedAccountMessage(localization);
        
        // Handle verification flow based on phone/email
        if (isPhone) {
          // Sanitize phone number to strict E.164 format (no spaces) before calling Firebase
          String sanitizedPhone = username;
          try {
            sanitizedPhone = authRepository.sanitizePhoneForFirebase(username);
          } catch (e) {
            if (mounted) {
              _showErrorSnackBar('Invalid phone number format. Please check and try again.');
            }
            return;
          }
          
          // Phone: Trigger Firebase Phone Auth to send new SMS
          await _handlePhoneVerification(authRepository, sanitizedPhone, userId: userId);
        } else {
          // Email: Navigate directly to verification screen
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.verification,
              arguments: {
                'username': username,
                'isPhone': false,
                'userId': userId,
              },
            );
          }
        }
        return;
      }

      if (response['success'] == true && mounted) {
        // Stop loading indicator
        setState(() => _isLoading = false);

        // Extract userId from registration response
        final userData = response['user'] ?? response['data'];
        final userId = userData?['id'] ?? userData?['_id'] ?? userData?['userId'];

        // On successful registration, immediately start verification flow
        if (isPhone) {
          // Sanitize phone number to strict E.164 format (no spaces) before calling Firebase
          String sanitizedPhone = username;
          try {
            sanitizedPhone = authRepository.sanitizePhoneForFirebase(username);
          } catch (e) {
            if (mounted) {
              _showErrorSnackBar('Invalid phone number format. Please check and try again.');
            }
            return;
          }
          
          // Phone registration: trigger Firebase Phone Auth to send SMS
          await _handlePhoneVerification(authRepository, sanitizedPhone, userId: userId);
        } else {
          // Email registration: navigate directly to verification screen
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.verification,
              arguments: {
                'username': username,
                'isPhone': false,
                'userId': userId,
              },
            );
          }
        }
      } else {
        setState(() => _isLoading = false);
        final errorMessage =
            response['message']?.toString() ??
            'Registration failed. Please try again.';
        _showErrorSnackBar(errorMessage);
      }
    } on ApiException catch (e) {
      setState(() => _isLoading = false);
      
      // Check if this is an unverified account error
      final isUnverifiedAccount = e.data != null && 
          (e.data['requiresVerification'] == true || 
           e.message.toLowerCase().contains('unverified'));
      
      if (isUnverifiedAccount && mounted) {
        // Extract userId from error response
        final errorData = e.data;
        final userData = errorData?['user'] ?? errorData?['data'];
        final userId = userData?['id'] ?? userData?['_id'] ?? userData?['userId'] ?? errorData?['userId'];
        
        // Show clean snackbar message (not error)
        _showUnverifiedAccountMessage(localization);
        
        // Handle verification flow based on phone/email
        if (isPhone) {
          // Sanitize phone number to strict E.164 format (no spaces) before calling Firebase
          String sanitizedPhone = username;
          try {
            sanitizedPhone = authRepository.sanitizePhoneForFirebase(username);
          } catch (e) {
            if (mounted) {
              _showErrorSnackBar('Invalid phone number format. Please check and try again.');
            }
            return;
          }
          
          // Phone: Automatically trigger Firebase Phone Auth to send SMS
          await _handlePhoneVerification(authRepository, sanitizedPhone, userId: userId);
        } else {
          // Email: Navigate directly to verification screen
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.verification,
              arguments: {
                'username': username,
                'isPhone': false,
                'userId': userId,
              },
            );
          }
        }
        return; // Don't show error snackbar
      }
      
      // Regular error - show error snackbar
      if (mounted) {
        // Show backend error message directly
        _showErrorSnackBar(e.message.isNotEmpty 
            ? e.message 
            : 'Registration failed. Please try again.');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        // Only show generic message for truly unexpected errors
        // If e is ApiException but wasn't caught, it means something went wrong
        final errorMessage = e.toString().contains('Exception') || e.toString().contains('Error')
            ? e.toString()
            : 'An unexpected error occurred. Please try again.';
        _showErrorSnackBar(errorMessage);
      }
    }
  }

  Future<void> _handlePhoneVerification(
    AuthRepository authRepository,
    String phoneNumber, {
    String? userId,
  }) async {
    if (!mounted) return;

    if (mounted) {
      setState(() => _isLoading = true);
    }

    bool hasNavigated = false; // Prevent multiple navigations

    try {
      String? verificationId;

      await authRepository.verifyPhoneNumber(
        phoneNumber: phoneNumber, // Already sanitized to E.164 format
        onCodeSent: (id) {
          if (!mounted || hasNavigated) return;
          
          verificationId = id;
          hasNavigated = true;
          
          
          if (mounted) {
            setState(() => _isLoading = false);
          }
          
          if (mounted) {
            // Pass sanitized phone number and userId to VerificationScreen
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.verification,
              arguments: {
                'username': phoneNumber, // E.164 format: +201064448681
                'isPhone': true,
                'verificationId': verificationId, // Persist verificationId
                'userId': userId, // Ensure userId is passed
              },
            );
          }
        },
        onVerificationCompleted: () {
          // Auto-verification completed (rare case)
          if (!mounted || hasNavigated) return;
          hasNavigated = true;
          
          if (mounted) {
            setState(() => _isLoading = false);
          }
          
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.login,
              arguments: {
                'username': phoneNumber,
              },
            );
          }
        },
        onVerificationFailed: (error) {
          if (!mounted) return;
          
          if (mounted) {
            setState(() => _isLoading = false);
          }
          
          if (mounted) {
            _showErrorSnackBar('Failed to send verification code: $error');
          }
        },
        onCodeAutoRetrievalTimeout: (error) {
          // Still navigate to verification screen even if auto-retrieval times out
          if (!mounted || hasNavigated) return;
          
          if (verificationId != null) {
            hasNavigated = true;
            
            if (mounted) {
              setState(() => _isLoading = false);
            }
            
            if (mounted) {
              Navigator.pushReplacementNamed(
                context,
                AppRoutes.verification,
                arguments: {
                  'username': phoneNumber,
                  'isPhone': true,
                  'verificationId': verificationId,
                  'userId': userId,
                },
              );
            }
          } else if (mounted) {
            // If verificationId is null, just stop loading
            setState(() => _isLoading = false);
          }
        },
      );
    } catch (e) {
      if (!mounted) return;
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
      
      if (mounted) {
        _showErrorSnackBar('Failed to send verification code. Please try again.');
      }
    }
  }

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

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
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
      ),
    );
  }

  /// Show clean snackbar message for unverified account
  /// Uses Alexandria font for Arabic text
  void _showUnverifiedAccountMessage(LocalizationService localization) {
    if (!mounted) return;
    
    final message = localization.translate('auth.unverifiedAccountMessage') ??
        'You already have an unverified account. A new code has been sent.';
    
    final isArabic = localization.currentLanguage == 'ar';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: isArabic
                    ? GoogleFonts.alexandria(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      )
                    : AppStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.info,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _handleBackNavigation() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      // If no route to pop, navigate to login screen
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localization, child) {
        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) async {
            if (!didPop) {
              _handleBackNavigation();
            }
          },
          child: Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.authBackground, AppColors.surface],
                ),
              ),
              child: Stack(
                children: [
                  // Decorative Circles
                  ..._buildDecorativeCircles(),
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
                                        onPressed: _handleBackNavigation,
                                        icon: const Icon(
                                          Icons.arrow_back_ios,
                                          color: Colors.black,
                                          size: 18,
                                        ),
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          padding: const EdgeInsets.all(8),
                                          shape: const CircleBorder(),
                                        ),
                                      ),

                                      // Language Selection Dropdown
                                      PopupMenuButton<String>(
                                        onSelected: (languageCode) async {
                                          await localization.changeLanguage(
                                            languageCode,
                                          );
                                        },
                                        color: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        itemBuilder: (context) => localization
                                            .supportedLanguages
                                            .map((language) {
                                              final isSelected =
                                                  localization
                                                      .currentLanguage ==
                                                  language['code'];
                                              final languageCode =
                                                  language['code']!;
                                              final displayCode =
                                                  languageCode == 'en'
                                                  ? 'en'
                                                  : 'ع';
                                              return PopupMenuItem<String>(
                                                value: languageCode,
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      displayCode,
                                                      style: AppStyles
                                                          .bodyMedium
                                                          .copyWith(
                                                            fontWeight:
                                                                isSelected
                                                                ? FontWeight
                                                                      .w600
                                                                : FontWeight
                                                                      .normal,
                                                            color: Colors.black,
                                                            fontSize: 16,
                                                          ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Text(
                                                      language['nativeName']!,
                                                      style: AppStyles
                                                          .bodyMedium
                                                          .copyWith(
                                                            fontWeight:
                                                                isSelected
                                                                ? FontWeight
                                                                      .w600
                                                                : FontWeight
                                                                      .normal,
                                                            color: Colors.black,
                                                          ),
                                                    ),
                                                    if (isSelected) ...[
                                                      const Spacer(),
                                                      Icon(
                                                        Icons.check,
                                                        color:
                                                            AppColors.primary,
                                                        size: 18,
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              );
                                            })
                                            .toList(),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: AppColors.border
                                                  .withOpacity(0.2),
                                              width: 1,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.05,
                                                ),
                                                blurRadius: 10,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  localization.currentLanguage ==
                                                          'en'
                                                      ? 'en'
                                                      : 'ع',
                                                  style: AppStyles.bodyMedium
                                                      .copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.black,
                                                        fontSize: 16,
                                                      ),
                                                ),
                                                const SizedBox(width: 4),
                                                Icon(
                                                  Icons.language,
                                                  size: 20,
                                                  color: AppColors.primary,
                                                ),
                                                const SizedBox(width: 4),
                                                Icon(
                                                  Icons.keyboard_arrow_down,
                                                  size: 16,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 40),

                                  // Header
                                  FadeTransition(
                                    opacity: _welcomeFade,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ShaderMask(
                                          shaderCallback: (bounds) =>
                                              LinearGradient(
                                                colors: [
                                                  AppColors.primary,
                                                  AppColors.secondary,
                                                ],
                                              ).createShader(bounds),
                                          child: Text(
                                            localization.translate('auth.createAccount'),
                                            style: AppStyles.headingLarge
                                                .copyWith(
                                                  fontSize: 30,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: -0.5,
                                                  color: Colors.white,
                                                  height: 1.2,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        FadeTransition(
                                          opacity: _subtitleFade,
                                          child: Text(
                                            localization.translate('auth.createAccountSubtitle'),
                                            style: AppStyles.bodyLarge.copyWith(
                                              color: AppColors.textSecondary
                                                  .withOpacity(0.7),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  // Signup Form
                                  FadeTransition(
                                    opacity: _formFade,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                          sigmaX: 15,
                                          sigmaY: 15,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 32,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.5,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(
                                                0.7,
                                              ),
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppColors.primary
                                                    .withOpacity(0.08),
                                                offset: const Offset(0, 8),
                                                blurRadius: 24,
                                                spreadRadius: 0,
                                              ),
                                            ],
                                          ),
                                          child: Form(
                                            key: _formKey,
                                            child: Column(
                                              children: [
                                                // Full Name Field
                                                _buildGlassInputField(
                                                  controller:
                                                      _fullNameController,
                                                  label: localization.translate('auth.fullName'),
                                                  hint: localization.translate('auth.fullName'),
                                                  keyboardType:
                                                      TextInputType.name,
                                                  prefixIcon:
                                                      Icons.person_outline,
                                                  validator: (value) {
                                                    if (value?.isEmpty ??
                                                        true) {
                                                      return localization.translate('auth.pleaseEnterFullName');
                                                    }
                                                    if (value!.trim().length <
                                                        2) {
                                                      return localization.translate('auth.nameMinLength');
                                                    }
                                                    return null;
                                                  },
                                                ),

                                                const SizedBox(height: 20),

                                                // Email or Phone Field
                                                _buildGlassInputField(
                                                  controller:
                                                      _usernameController,
                                                  label: localization.translate('auth.emailOrPhone'),
                                                  hint: localization.translate('auth.emailOrPhone'),
                                                  keyboardType:
                                                      TextInputType.text,
                                                  prefixIcon:
                                                      Icons.person_outline,
                                                  validator: (value) {
                                                    if (value?.isEmpty ??
                                                        true) {
                                                      return localization.translate('auth.pleaseEnterEmail');
                                                    }
                                                    final authRepository =
                                                        Provider.of<
                                                          AuthRepository
                                                        >(
                                                          context,
                                                          listen: false,
                                                        );
                                                    if (!authRepository
                                                        .isValidUsername(
                                                          value!,
                                                        )) {
                                                      return localization.translate('auth.invalidEmailOrPhone');
                                                    }
                                                    return null;
                                                  },
                                                ),

                                                const SizedBox(height: 20),

                                                // Password Field
                                                _buildGlassInputField(
                                                  controller:
                                                      _passwordController,
                                                  label: localization.translate(
                                                    'auth.password',
                                                  ),
                                                  hint: localization.translate(
                                                    'auth.enterPassword',
                                                  ),
                                                  obscureText: _obscurePassword,
                                                  prefixIcon:
                                                      Icons.lock_outlined,
                                                  suffixIcon: IconButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        _obscurePassword =
                                                            !_obscurePassword;
                                                      });
                                                    },
                                                    icon: Icon(
                                                      _obscurePassword
                                                          ? Icons
                                                                .visibility_outlined
                                                          : Icons
                                                                .visibility_off_outlined,
                                                      color: AppColors
                                                          .textTertiary,
                                                      size: 20,
                                                    ),
                                                  ),
                                                  validator: (value) {
                                                    if (value?.isEmpty ??
                                                        true) {
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

                                                const SizedBox(height: 20),

                                                // Confirm Password Field
                                                _buildGlassInputField(
                                                  controller:
                                                      _confirmPasswordController,
                                                  label: localization.translate('auth.confirmPassword'),
                                                  hint: localization.translate('auth.confirmPassword'),
                                                  obscureText:
                                                      _obscureConfirmPassword,
                                                  prefixIcon:
                                                      Icons.lock_outlined,
                                                  suffixIcon: IconButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        _obscureConfirmPassword =
                                                            !_obscureConfirmPassword;
                                                      });
                                                    },
                                                    icon: Icon(
                                                      _obscureConfirmPassword
                                                          ? Icons
                                                                .visibility_outlined
                                                          : Icons
                                                                .visibility_off_outlined,
                                                      color: AppColors
                                                          .textTertiary,
                                                      size: 20,
                                                    ),
                                                  ),
                                                  validator: (value) {
                                                    if (value?.isEmpty ??
                                                        true) {
                                                      return localization.translate('auth.pleaseConfirmPassword');
                                                    }
                                                    if (value !=
                                                        _passwordController
                                                            .text) {
                                                      return localization.translate('validation.passwordsDoNotMatch');
                                                    }
                                                    return null;
                                                  },
                                                ),

                                                // Real-time password mismatch error message
                                                if (!_doPasswordsMatch &&
                                                    _confirmPasswordController
                                                        .text.isNotEmpty &&
                                                    _passwordController
                                                        .text.isNotEmpty)
                                                  Padding(
                                                    padding: const EdgeInsets.only(
                                                      top: 8.0,
                                                      left: 16.0,
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.error_outline,
                                                          size: 16,
                                                          color: AppColors.error,
                                                        ),
                                                        const SizedBox(width: 6),
                                                        Expanded(
                                                          child: Text(
                                                            localization.translate(
                                                                    'validation.passwordsDoNotMatch') ??
                                                                'Passwords do not match',
                                                            style: AppStyles
                                                                .bodySmall
                                                                .copyWith(
                                                              color:
                                                                  AppColors.error,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),

                                                const SizedBox(height: 24),

                                                // Terms and Conditions Checkbox
                                                _buildTermsCheckbox(localization),

                                                const SizedBox(height: 24),

                                                // Sign Up Button
                                                FadeTransition(
                                                  opacity: _buttonFade,
                                                  child: CustomButton(
                                                    text: localization.translate('auth.signup'),
                                                    onPressed:
                                                        _isFormValid &&
                                                            !_isLoading &&
                                                            _isAgreed
                                                        ? _handleSignup
                                                        : null,
                                                    isLoading: _isLoading,
                                                    variant:
                                                        ButtonVariant.gradient,
                                                    gradientColors: [
                                                      AppColors.primary,
                                                      AppColors.info,
                                                      AppColors.secondary,
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 32),

                                  // Sign In Link
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        localization.translate('auth.alreadyHaveAccount'),
                                        style: AppStyles.bodyMedium.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        child: TextButton(
                                          onPressed: () {
                                            AppRoutes.pushReplacementNamed(
                                              context,
                                              AppRoutes.login,
                                            );
                                          },
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                          ),
                                          child: Text(
                                            localization.translate('auth.signIn'),
                                            style: AppStyles.bodyMedium
                                                .copyWith(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.w600,
                                                  decoration:
                                                      TextDecoration.underline,
                                                  decorationColor: AppColors
                                                      .primary
                                                      .withOpacity(0.3),
                                                ),
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildTermsCheckbox(LocalizationService localization) {
    final isRTL = localization.isRTL;
    final isEn = localization.currentLanguage == 'en';
    
    // Text strings based on language
    final prefixText = localization.translate('auth.agreePrefix');
    final privacyPolicyText = localization.translate('auth.privacyPolicy');
    final middleText = localization.translate('auth.and');
    final termsText = localization.translate('auth.termsAndConditionsShort');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _isAgreed,
          onChanged: (value) {
            setState(() {
              _isAgreed = value ?? false;
            });
          },
          activeColor: AppColors.primary,
          checkColor: Colors.white,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        Expanded(
            child: GestureDetector(
            onTap: () {
              setState(() {
                _isAgreed = !_isAgreed;
              });
            },
            child: RichText(
              text: TextSpan(
                style: AppStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                ),
                children: [
                  TextSpan(text: prefixText),
                  TextSpan(
                    text: privacyPolicyText,
                    style: TextStyle(
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w600,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        final content = isEn
                            ? LegalContent.privacyPolicyEn
                            : LegalContent.privacyPolicyAr;
                        final title = privacyPolicyText;
                        AppRoutes.pushNamed(
                          context,
                          AppRoutes.legalInfo,
                          arguments: {
                            'title': title,
                            'content': content,
                          },
                        );
                      },
                  ),
                  TextSpan(text: middleText),
                  TextSpan(
                    text: termsText,
                    style: TextStyle(
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w600,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        final content = isEn
                            ? LegalContent.termsEn
                            : LegalContent.termsAr;
                        final title = termsText;
                        AppRoutes.pushNamed(
                          context,
                          AppRoutes.legalInfo,
                          arguments: {
                            'title': title,
                            'content': content,
                          },
                        );
                      },
                  ),
                ],
              ),
              textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
              textAlign: isRTL ? TextAlign.right : TextAlign.left,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassInputField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return _GlassInputWrapper(
      controller: controller,
      label: label,
      hint: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  List<Widget> _buildDecorativeCircles() {
    final screenSize = MediaQuery.of(context).size;

    return [
      // Decorative dots pattern
      ..._buildDotsPattern(screenSize),

      // Top-left quarter circles (layered)
      Positioned(
        top: 0,
        left: 0,
        child: Transform.translate(
          offset: const Offset(-50, -50),
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(250),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(0.12),
                  AppColors.accent.withOpacity(0.08),
                ],
              ),
            ),
          ),
        ),
      ),
      Positioned(
        top: 0,
        left: 0,
        child: Transform.translate(
          offset: const Offset(-30, -30),
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(150),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.secondary.withOpacity(0.08),
                  AppColors.info.withOpacity(0.06),
                ],
              ),
            ),
          ),
        ),
      ),

      // Top-right circle
      Positioned(
        top: -100,
        right: -100,
        child: Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [AppColors.primary.withOpacity(0.05), Colors.transparent],
            ),
          ),
        ),
      ),

      // Bottom-left circle
      Positioned(
        bottom: -150,
        left: -150,
        child: Container(
          width: 400,
          height: 400,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.secondary.withOpacity(0.03),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),

      // Bottom-right quarter circle
      Positioned(
        bottom: 0,
        right: 0,
        child: Transform.translate(
          offset: const Offset(50, 50),
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(150),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.accent.withOpacity(0.08),
                  AppColors.primary.withOpacity(0.06),
                ],
              ),
            ),
          ),
        ),
      ),

      // Center circle (smaller)
      Positioned(
        top: screenSize.height * 0.3,
        right: -50,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [AppColors.accent.withOpacity(0.04), Colors.transparent],
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildDotsPattern(Size screenSize) {
    final dots = <Widget>[];
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.info,
      AppColors.accent,
    ];

    for (int i = 0; i < 20; i++) {
      final randomX = (i * 87) % screenSize.width.toInt();
      final randomY = (i * 123) % screenSize.height.toInt();
      final size = (i % 3 + 1) * 4.0;
      final color = colors[i % colors.length];

      dots.add(
        Positioned(
          left: randomX.toDouble(),
          top: randomY.toDouble(),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.05),
            ),
          ),
        ),
      );
    }

    return dots;
  }
}

/// Glass morphism wrapper for input fields
class _GlassInputWrapper extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _GlassInputWrapper({
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  State<_GlassInputWrapper> createState() => _GlassInputWrapperState();
}

class _GlassInputWrapperState extends State<_GlassInputWrapper> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: _isFocused
            ? Colors.white.withOpacity(0.9)
            : Colors.white.withOpacity(0.7),
        boxShadow: [
          BoxShadow(
            color: _isFocused
                ? AppColors.primary.withOpacity(0.15)
                : Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: _isFocused ? 20 : 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: _buildTextField(),
    );
  }

  Widget _buildTextField() {
    return Focus(
      onFocusChange: (hasFocus) {
        setState(() {
          _isFocused = hasFocus;
        });
      },
      child: CustomTextField(
        controller: widget.controller,
        label: widget.label,
        hint: widget.hint,
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.suffixIcon,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
      ),
    );
  }
}
