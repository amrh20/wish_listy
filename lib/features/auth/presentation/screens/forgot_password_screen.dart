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

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _emailController = TextEditingController();

  late AnimationController _animationController;
  late AnimationController _successController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _successScaleAnimation;

  bool _isLoading = false;
  bool _isLoadingCheck = false; // Loading state for check account
  bool _isLoadingReset = false; // Loading state for reset request
  bool _isSuccess = false;
  String? _linkedEmail;
  bool _emailLinked = false;
  bool _accountChecked = false;
  String? _identifier; // Store the identifier for reset request

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
    _identifierController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleCheckAccount(BuildContext context, AuthCubit cubit) async {
    
    // Step 1: Validate form
    if (_formKey.currentState == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Provider.of<LocalizationService>(context, listen: false).translate('auth.unexpectedError')),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
      return;
    }
    
    final isValid = _formKey.currentState!.validate();
    
    if (!isValid) {
      // Form validation errors will be shown automatically by the TextFields
      // Trigger validation to show errors
      _formKey.currentState!.validate();
      return;
    }

    // Step 2: Get and validate identifier
    final identifier = _identifierController.text.trim();
    
    if (identifier.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Provider.of<LocalizationService>(context, listen: false).translate('auth.phoneOrEmailRequired')),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
      return;
    }

    _identifier = identifier;

    // Step 3: Verify cubit is not null (already passed as parameter)
    if (cubit == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to access authentication service. Please try again.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
      return;
    }

    // Step 4: Call checkAccount
    try {
      cubit.checkAccount(identifier);
    } catch (e, stackTrace) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to check account. Please try again.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  Future<void> _handleRequestReset(BuildContext context, AuthCubit cubit) async {
    
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_identifier == null || _identifier!.isEmpty) {
      return;
    }

    final email = _emailController.text.trim();

    // AuthCubit handles all errors internally and emits error states
    // BlocListener will handle those error states and show appropriate messages
    if (_emailLinked && _linkedEmail != null) {
      // Account has email, just request reset
      cubit.requestReset(_identifier!);
    } else {
      // Need to bind email first
      cubit.requestReset(_identifier!, newEmail: email);
    }
  }

  void _handleResendEmail(BuildContext context) async {
    if (_identifier == null || _identifier!.isEmpty) {
      return;
    }
    try {
      final cubit = context.read<AuthCubit>();
      await cubit.requestReset(_identifier!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(Provider.of<LocalizationService>(context, listen: false).translate('auth.checkEmail')),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e, stackTrace) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Provider.of<LocalizationService>(context, listen: false).translate('auth.unexpectedError')),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  void _handleBackNavigation() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // BlocProvider<AuthCubit> is now provided at the route level in app_routes.dart
    return BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is CheckAccountSuccess) {
            setState(() {
              _accountChecked = true;
              _emailLinked = state.emailLinked;
              _linkedEmail = state.email;
            });
          } else if (state is CheckAccountError) {
            setState(() {
              _isLoading = false;
              _isLoadingCheck = false; // Ensure loading state is reset
            });
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
          } else if (state is AuthForgotPasswordEmailRequired) {
            // Handle requiresEmail case - show email field dynamically
            setState(() {
              _isLoading = false;
              _isLoadingCheck = false;
              _accountChecked = true; // Mark as checked to show email field
              _emailLinked = false; // Show email input field
            });
            // Don't show error snackbar - just show email field
          } else if (state is RequestResetSuccess) {
            // Navigate to OTP verification screen (NewPasswordScreen) with identifier
            if (_identifier != null && _identifier!.isNotEmpty) {
              Navigator.pushNamed(
                context,
                AppRoutes.resetPassword,
                arguments: {'identifier': _identifier!},
              );
            } else {
              setState(() {
                _isLoading = false;
                _isSuccess = true;
              });
              _successController.forward();
            }
          } else if (state is RequestResetError) {
            setState(() {
              _isLoading = false;
              _isLoadingReset = false; // Ensure loading state is reset
            });
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
            // Only show loading when checking account (not when requesting reset)
            final wasLoadingCheck = _isLoadingCheck;
            final wasLoadingReset = _isLoadingReset;
            
            _isLoadingCheck = state is AuthLoading && !_accountChecked;
            _isLoadingReset = state is AuthLoading && _accountChecked;
            _isLoading = _isLoadingCheck || _isLoadingReset;
            
            // Debug logging for state changes
            // Debug button state

            return PopScope(
              canPop: false,
              onPopInvoked: (didPop) async {
                if (!didPop) {
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
                                        onPressed: _handleBackNavigation,
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
                                      ..._buildResetForm(state)
                                    else
                                      ..._buildSuccessContent(context),
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
    );
  }

  List<Widget> _buildResetForm(AuthState state) {
    final localization = Provider.of<LocalizationService>(context, listen: false);

    return [
      // Header
      Column(
        children: [
          Text(
            localization.translate('auth.forgotPassword'),
            style: AppStyles.headingLarge.copyWith(
              fontSize: 28,
              fontFamily: 'Alexandria',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            _accountChecked
                ? (_emailLinked
                    ? localization.translate('auth.emailLinked')
                    : localization.translate('auth.emailNotLinked'))
                : localization.translate('auth.forgotPasswordDescription'),
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
            // Identifier Field (Phone/Email) - shown first
            if (!_accountChecked)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(
                    controller: _identifierController,
                    label: localization.translate('auth.phoneOrEmail'),
                    hint: localization.translate('auth.enterPhoneOrEmail'),
                    keyboardType: TextInputType.text,
                    prefixIcon: Icons.person_outline,
                    isRequired: true,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return localization.translate('auth.phoneOrEmailRequired');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Text(
                      localization.translate('auth.phoneOrEmailHint'),
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                        fontFamily: 'Alexandria',
                      ),
                    ),
                  ),
                ],
              ),

            // Email Field - shown if account checked and email linked (read-only)
            if (_accountChecked && _emailLinked && _linkedEmail != null) ...[
              const SizedBox(height: 24),
              CustomTextField(
                controller: TextEditingController(text: _linkedEmail)
                  ..selection = TextSelection.fromPosition(
                    TextPosition(offset: _linkedEmail!.length),
                  ),
                label: localization.translate('auth.email'),
                hint: _linkedEmail,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                readOnly: true,
                enabled: false,
              ),
            ],

            // Email Field - shown if account checked but no email linked
            if (_accountChecked && !_emailLinked) ...[
              const SizedBox(height: 24),
              CustomTextField(
                controller: _emailController,
                label: localization.translate('auth.email'),
                hint: localization.translate('auth.enterEmailToBind'),
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                isRequired: true,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return localization.translate('auth.emailRequired');
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value!)) {
                    return localization.translate('auth.invalidEmail');
                  }
                  return null;
                },
              ),
            ],

            const SizedBox(height: 32),

            // Action Button
            CustomButton(
              text: _accountChecked
                  ? localization.translate('auth.sendResetLink')
                  : localization.translate('auth.checkAccount'),
              onPressed: (_isLoadingCheck || _isLoadingReset)
                  ? null
                  : () {
                      // Get cubit from context here, before calling async function
                      try {
                        final cubit = context.read<AuthCubit>();
                        if (_accountChecked) {
                          _handleRequestReset(context, cubit);
                        } else {
                          _handleCheckAccount(context, cubit);
                        }
                      } catch (e, stackTrace) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to access authentication service. Please try again.'),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        );
                      }
                    },
              isLoading: _isLoadingCheck, // Only show loading spinner when checking account
              variant: ButtonVariant.gradient,
              gradientColors: [AppColors.accent, AppColors.primary],
            ),

            const SizedBox(height: 24),

            // Back to Login
            CustomButton(
              text: localization.translate('auth.backToSignIn'),
              onPressed: () => Navigator.pop(context),
              variant: ButtonVariant.text,
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildSuccessContent(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    final email = _emailLinked && _linkedEmail != null
        ? _linkedEmail!
        : _emailController.text;

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
                  localization.translate('auth.checkEmail'),
                  style: AppStyles.headingMedium.copyWith(
                    color: AppColors.success,
                    fontFamily: 'Alexandria',
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Success Message
                Text(
                  localization.translate('auth.resetLinkSentMessage'),
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontFamily: 'Alexandria',
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
                    email,
                    style: AppStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Alexandria',
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Instructions
                Text(
                  localization.translate('auth.resetLinkInstructions'),
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                    fontFamily: 'Alexandria',
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Action Buttons
                Column(
                  children: [
                    CustomButton(
                      text: localization.translate('auth.openEmailApp'),
                      onPressed: () {
                        // TODO: Implement open email app functionality
                      },
                      variant: ButtonVariant.primary,
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: localization.translate('auth.resendEmail'),
                            onPressed: _isLoading ? null : () => _handleResendEmail(context),
                            variant: ButtonVariant.outline,
                            isLoading: _isLoading,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomButton(
                            text: localization.translate('auth.backToSignIn'),
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
