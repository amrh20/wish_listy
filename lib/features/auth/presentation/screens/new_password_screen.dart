import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'package:wish_listy/core/widgets/custom_text_field.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:wish_listy/features/auth/presentation/cubit/auth_state.dart';

class NewPasswordScreen extends StatefulWidget {
  final String? token;

  const NewPasswordScreen({super.key, this.token});

  @override
  _NewPasswordScreenState createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late AnimationController _animationController;
  late AnimationController _successController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _successScaleAnimation;

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSuccess = false;

  String? get _token {
    // Get token from widget parameter or route arguments
    if (widget.token != null) return widget.token;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['token'] != null) {
      return args['token'] as String;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();

    // Validate token on init
    if (_token == null || _token!.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showTokenError();
      });
    }
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

  void _showTokenError() {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(localization.translate('auth.invalidResetToken')),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: localization.translate('auth.backToSignIn'),
          textColor: Colors.white,
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.login,
              (route) => false,
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _successController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_token == null || _token!.isEmpty) {
      _showTokenError();
      return;
    }

    final newPassword = _newPasswordController.text.trim();
    context.read<AuthCubit>().resetPassword(_token!, newPassword);
  }

  void _handleBackNavigation() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthCubit(),
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is ResetPasswordSuccess) {
            setState(() {
              _isSuccess = true;
            });
            _successController.forward();

            // Navigate to login after 2 seconds
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                  (route) => false,
                );
              }
            });
          } else if (state is ResetPasswordError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }
        },
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return PopScope(
              canPop: false,
              onPopInvoked: (didPop) async {
                if (!didPop && !_isSuccess) {
                  _handleBackNavigation();
                }
              },
              child: Scaffold(
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

                                    // Back Button
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: IconButton(
                                        onPressed: _isSuccess
                                            ? null
                                            : _handleBackNavigation,
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
                                          color: _isSuccess
                                              ? AppColors.success.withOpacity(0.1)
                                              : AppColors.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(60),
                                        ),
                                        child: Icon(
                                          _isSuccess
                                              ? Icons.check_circle_outline
                                              : Icons.lock_outline,
                                          size: 60,
                                          color: _isSuccess
                                              ? AppColors.success
                                              : AppColors.primary,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 40),

                                    // Content based on state
                                    if (!_isSuccess)
                      ..._buildResetForm(isLoading)
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
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildResetForm(bool isLoading) {
    final localization = Provider.of<LocalizationService>(context, listen: false);

    return [
      // Header
      Column(
        children: [
          Text(
            localization.translate('auth.resetPassword'),
            style: AppStyles.headingLarge.copyWith(
              fontSize: 28,
              fontFamily: 'Alexandria',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            localization.translate('auth.resetPasswordDescription'),
            style: AppStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
              fontFamily: 'Alexandria',
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
            // New Password Field
            CustomTextField(
              controller: _newPasswordController,
              label: localization.translate('auth.enterNewPassword'),
              hint: localization.translate('auth.enterNewPasswordHint'),
              obscureText: _obscureNewPassword,
              keyboardType: TextInputType.visiblePassword,
              prefixIcon: Icons.lock_outline,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNewPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.textSecondary,
                ),
                onPressed: () {
                  setState(() {
                    _obscureNewPassword = !_obscureNewPassword;
                  });
                },
              ),
              isRequired: true,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return localization.translate('auth.passwordRequired');
                }
                if (value!.length < 6) {
                  return localization.translate('auth.passwordMinLength');
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Confirm Password Field
            CustomTextField(
              controller: _confirmPasswordController,
              label: localization.translate('auth.confirmPassword'),
              hint: localization.translate('auth.confirmPasswordHint'),
              obscureText: _obscureConfirmPassword,
              keyboardType: TextInputType.visiblePassword,
              prefixIcon: Icons.lock_outline,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.textSecondary,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              isRequired: true,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return localization.translate('auth.confirmPasswordRequired');
                }
                if (value != _newPasswordController.text.trim()) {
                  return localization.translate('auth.passwordsDoNotMatch');
                }
                return null;
              },
            ),

            const SizedBox(height: 32),

            // Reset Button
            CustomButton(
              text: localization.translate('auth.resetPassword'),
              onPressed: isLoading ? null : _handleResetPassword,
              isLoading: isLoading,
              variant: ButtonVariant.gradient,
              gradientColors: [AppColors.primary, AppColors.accent],
            ),

            const SizedBox(height: 24),

            // Back to Login
            CustomButton(
              text: localization.translate('auth.backToSignIn'),
              onPressed: _handleBackNavigation,
              variant: ButtonVariant.text,
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildSuccessContent() {
    final localization = Provider.of<LocalizationService>(context, listen: false);

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
                  localization.translate('auth.passwordResetSuccess'),
                  style: AppStyles.headingMedium.copyWith(
                    color: AppColors.success,
                    fontFamily: 'Alexandria',
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Success Message
                Text(
                  localization.translate('auth.passwordResetSuccessMessage'),
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                    fontFamily: 'Alexandria',
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Loading indicator for navigation
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),

                const SizedBox(height: 16),

                Text(
                  localization.translate('auth.redirectingToLogin'),
                  style: AppStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontFamily: 'Alexandria',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    ];
  }
}

