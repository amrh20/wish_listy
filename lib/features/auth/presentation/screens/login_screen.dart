import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/core/services/socket_service.dart';
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'package:wish_listy/core/widgets/custom_text_field.dart';
import 'package:wish_listy/core/widgets/confirmation_dialog.dart';
import 'package:wish_listy/core/widgets/unified_snackbar.dart';
import 'package:wish_listy/core/services/biometric_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wish_listy/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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
  late AnimationController _staggerAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _welcomeFade;
  late Animation<double> _subtitleFade;
  late Animation<double> _formFade;
  late Animation<double> _buttonFade;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _hasLoadedArguments = false;
  bool _isBiometricAvailable = false;
  bool _isCheckingBiometric = false;
  bool _hasAttemptedBiometric = false; // Prevent multiple auto-triggers
  bool _showBiometricIcon = false; // Dynamic visibility based on identifier
  String?
  _lastCheckedIdentifier; // Track last identifier to prevent duplicate auto-triggers

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();

    // Add listener to email field for dynamic biometric icon
    _usernameController.addListener(_onIdentifierChanged);

    // Use addPostFrameCallback to ensure widget is fully built before checking biometrics
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBiometricAvailability();
      _attemptBiometricLogin();
    });
  }

  /// Called whenever the email/phone field changes
  /// Checks if biometric is enabled for the specific identifier
  void _onIdentifierChanged() {
    final identifier = _usernameController.text.trim();

    // Hide icon if field is empty
    if (identifier.isEmpty) {
      if (_showBiometricIcon) {
        setState(() => _showBiometricIcon = false);
      }
      // Reset attempt flag when field is cleared
      _hasAttemptedBiometric = false;
      _lastCheckedIdentifier = null;
      return;
    }

    // Reset attempt flag if identifier changed to allow auto-trigger for new identifier
    if (_lastCheckedIdentifier != null && _lastCheckedIdentifier != identifier) {
      debugPrint('🔄 [LoginScreen] Identifier changed, resetting attempt flag');
      _hasAttemptedBiometric = false;
    }

    // Check if biometric is available and enabled for this specific identifier asynchronously
    if (_isBiometricAvailable) {
      _checkBiometricForIdentifier(identifier);
    }
  }

  /// Asynchronously check if biometric is enabled for the identifier
  Future<void> _checkBiometricForIdentifier(String identifier) async {
    final biometricService = BiometricService();
    final isEnabledForIdentifier = await biometricService
        .isEnabledForIdentifier(identifier);

    // Only update state if it changed to prevent unnecessary rebuilds
    if (mounted && isEnabledForIdentifier != _showBiometricIcon) {
      setState(() => _showBiometricIcon = isEnabledForIdentifier);

      if (isEnabledForIdentifier) {
        debugPrint('✅ [LoginScreen] Biometric icon shown for: $identifier');

        // Auto-trigger biometric authentication if this is a new identifier match
        // and we haven't already attempted it
        if (_lastCheckedIdentifier != identifier && !_isCheckingBiometric) {
          _lastCheckedIdentifier = identifier;
          debugPrint(
            '🔐 [LoginScreen] Auto-triggering biometric for: $identifier',
          );

          // Small delay to allow UI to update
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted && !_isCheckingBiometric) {
              _attemptBiometricLogin(isManual: false);
            }
          });
        }
      }
    }
  }

  /// Check if biometric authentication is available
  Future<void> _checkBiometricAvailability() async {
    final biometricService = BiometricService();
    final isAvailable = await biometricService.isBiometricAvailable();

    // Debug logs
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 [BiometricCheck] isAvailable: $isAvailable');
    debugPrint('═══════════════════════════════════════════════════════');

    if (mounted) {
      setState(() {
        _isBiometricAvailable = isAvailable;
      });

      // Trigger initial check for current identifier
      if (isAvailable && _usernameController.text.trim().isNotEmpty) {
        _onIdentifierChanged();
      }
    }
  }

  /// Attempt to login using biometric authentication
  /// Can be triggered automatically on screen load or manually by user
  Future<void> _attemptBiometricLogin({bool isManual = false}) async {
    // Prevent multiple auto-triggers
    if (!isManual && _hasAttemptedBiometric) {
      debugPrint('⚠️ [BiometricLogin] Already attempted, skipping');
      return;
    }

    if (!isManual) {
      _hasAttemptedBiometric = true;
      // Wait a bit for the screen to render (only for auto-trigger)
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (!mounted) return;

    final biometricService = BiometricService();
    final identifier = _usernameController.text.trim();

    // Validate identifier
    if (identifier.isEmpty) {
      debugPrint('⚠️ [BiometricLogin] No identifier provided');

      // For auto-trigger, try to get identifier from SharedPreferences
      if (!isManual) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final savedEmail = prefs.getString('user_email');
          if (savedEmail != null && savedEmail.isNotEmpty) {
            _usernameController.text = savedEmail;
            // Retry with the saved email
            return _attemptBiometricLogin(isManual: isManual);
          }
        } catch (e) {
          debugPrint('⚠️ [BiometricLogin] Could not retrieve saved email: $e');
        }
      }
      return;
    }

    // Check availability and if biometric is enabled for this specific identifier
    final isAvailable = await biometricService.isBiometricAvailable();
    final isEnabledForIdentifier = await biometricService
        .isEnabledForIdentifier(identifier);

    debugPrint(
      '🔍 [BiometricLogin] Check - isAvailable: $isAvailable, isEnabled: $isEnabledForIdentifier',
    );
    debugPrint('   📧 Identifier: $identifier');

    if (!isAvailable) {
      debugPrint('⚠️ [BiometricLogin] Biometric not available on device');
      return;
    }

    if (!isEnabledForIdentifier) {
      debugPrint(
        '⚠️ [BiometricLogin] Biometric not enabled for this identifier',
      );
      return;
    }

    if (mounted) {
      setState(() => _isCheckingBiometric = true);
    }

    try {
      // FIRST: Authenticate with biometrics
      final localization = Provider.of<LocalizationService>(
        context,
        listen: false,
      );

      debugPrint('🔐 [BiometricLogin] Requesting biometric authentication...');
      final didAuthenticate = await biometricService.authenticate(
        context: context,
        reason:
            localization.translate('auth.biometricReason') ??
            'Authenticate to access your account',
      );

      if (!didAuthenticate) {
        debugPrint('⚠️ [BiometricLogin] Authentication cancelled or failed');

        // Show error message only if it's a manual attempt
        if (isManual && mounted) {
          UnifiedSnackbar.showError(
            context: context,
            message:
                localization.translate('auth.biometricFailed') ??
                'Biometric authentication failed. Please try again or use your password.',
          );
        }
        return;
      }

      debugPrint('✅ [BiometricLogin] Biometric authentication successful');

      // SECOND: Retrieve all credentials (token, userId, userName) from storage
      final credentials = await biometricService.getStoredCredentialsForIdentifier(
        identifier,
      );

      if (credentials != null && credentials['token'] != null && mounted) {
        final token = credentials['token']!;
        final userId = credentials['userId'];
        final userName = credentials['userName'];
        
        debugPrint('✅ [BiometricLogin] Credentials retrieved successfully');
        debugPrint('   📏 Token length: ${token.length}');
        debugPrint('   👤 User ID: ${userId ?? "not stored"}');
        debugPrint('   👤 User Name: ${userName ?? "not stored"}');

        // Token retrieved successfully, proceed with login
        final authService = Provider.of<AuthRepository>(context, listen: false);
        final apiService = ApiService();

        // Set token in API service
        apiService.setAuthToken(token);

        // Populate SharedPreferences with retrieved credentials
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('auth_token', token);
        
        // Use stored userId/userName if available, otherwise try SharedPreferences
        final finalUserId = userId ?? prefs.getString('user_id');
        final finalUserName = userName ?? prefs.getString('user_name');
        final finalUserEmail = identifier; // Use identifier as email
        
        if (finalUserId != null) {
          await prefs.setString('user_id', finalUserId);
        }
        if (finalUserName != null) {
          await prefs.setString('user_name', finalUserName);
        }
        await prefs.setString('user_email', finalUserEmail);

        debugPrint('💾 [BiometricLogin] Saved to SharedPreferences:');
        debugPrint('   👤 User ID: $finalUserId');
        debugPrint('   👤 User Name: $finalUserName');
        debugPrint('   📧 User Email: $finalUserEmail');

        // Re-initialize auth repository with saved data
        // This will set the user state correctly
        await authService.initialize();

        // Authenticate Socket.IO (Option B: emit auth event)
        try {
          await SocketService().authenticateSocket(token);
        } catch (e) {
          debugPrint('⚠️ [BiometricLogin] Socket connection failed: $e');
        }

        // Navigate to main app
        if (mounted) {
          // Ensure NotificationsCubit is initialized
          try {
            final notificationsCubit = context.read<NotificationsCubit>();
            notificationsCubit.getUnreadCount();
          } catch (e) {
            debugPrint('⚠️ [BiometricLogin] NotificationsCubit error: $e');
          }

          debugPrint('🏠 [BiometricLogin] Navigating to home screen');
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.mainNavigation,
            (route) => false,
          );
        }
      } else {
        debugPrint('⚠️ [BiometricLogin] Token retrieval failed or cancelled');
        
        // Cleanup broken biometric data to allow re-enablement
        if (mounted) {
          await biometricService.clearBiometricDataForIdentifier(identifier);
          debugPrint('🧹 [BiometricLogin] Cleared broken biometric data for $identifier');
          
          final localization = Provider.of<LocalizationService>(
            context,
            listen: false,
          );
          UnifiedSnackbar.showError(
            context: context,
            message: localization.translate('auth.biometricTokenMissing') ??
                'Please login manually once to re-sync biometrics.',
          );
        }
      }
    } catch (e) {
      debugPrint('❌ [BiometricLogin] Error: $e');
      // User cancelled or biometric failed - stay on login screen
      // User can try again with manual icon or use password
    } finally {
      if (mounted) {
        setState(() => _isCheckingBiometric = false);
      }
    }
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
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Fetch FCM token before login (may be null on some emulators)
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          debugPrint('');
          debugPrint('═══════════════════════════════════════════════════════════════════');
          debugPrint('🔔 [Login] FCM TOKEN (for Firebase Console testing):');
          debugPrint('');
          debugPrint('   $fcmToken');
          debugPrint('');
          debugPrint('═══════════════════════════════════════════════════════════════════');
          debugPrint('📋 Copy this token to Firebase Console → Cloud Messaging → Test');
          debugPrint('═══════════════════════════════════════════════════════════════════');
          debugPrint('');
        } else {
          debugPrint('⚠️ [Login] FCM Token is null - may need notification permissions');
        }
      } catch (e) {
        debugPrint('⚠️ [Login] Failed to get FCM token: $e');
        // Continue with login even if FCM token fails (e.g., on emulator)
        fcmToken = null;
      }

      final authService = Provider.of<AuthRepository>(context, listen: false);
      final success = await authService.loginUser(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
        fcmToken: fcmToken,
      );

      if (success && mounted) {
        // Ensure NotificationsCubit is initialized and fetch unread count
        try {
          final notificationsCubit = context.read<NotificationsCubit>();
          debugPrint(
            '✅ LoginScreen: NotificationsCubit accessed, fetching unread count...',
          );
          // Fetch unread count immediately after login
          notificationsCubit.getUnreadCount();
        } catch (e) {
          debugPrint('⚠️ LoginScreen: Could not access NotificationsCubit: $e');
        }

        // Check if biometric is available and NOT enabled for THIS specific account
        final biometricService = BiometricService();
        final isAvailable = await biometricService.isBiometricAvailable();

        // Per-account check: has THIS user enabled biometrics?
        final identifier = _usernameController.text
            .trim(); // This is the current user's identifier
        final isEnabledForThisAccount = await biometricService
            .isEnabledForIdentifier(identifier);

        debugPrint('🔍 [Login] Biometric check for $identifier:');
        debugPrint('   - Available: $isAvailable');
        debugPrint('   - Enabled for this account: $isEnabledForThisAccount');

        if (isAvailable && !isEnabledForThisAccount) {
          // Show biometric enablement prompt for this account
          debugPrint(
            '✅ [Login] Showing biometric prompt for new/non-enrolled account',
          );
          
          // Get user data from SharedPreferences to pass to prompt
          final prefs = await SharedPreferences.getInstance();
          final userId = prefs.getString('user_id');
          final userName = prefs.getString('user_name');
          
          _showBiometricEnablementPrompt(
            authService,
            userId: userId,
            userName: userName,
          );
        } else {
          // Navigate to main app directly
          debugPrint(
            '➡️ [Login] Navigating to home (biometrics already enabled or not available)',
          );
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.mainNavigation,
            (route) => false,
          );
        }
      }
      // Note: Login failures now throw ApiException, so no else block needed
    } on ApiException catch (e) {
      // Check if this is an unverified account case
      // New backend contract: 401 + message 'You already have an unverified account'
      final message = e.message.toLowerCase();
      final isUnverifiedByMessage = e.statusCode == 401 &&
          message.contains('unverified account');
      final isUnverifiedByFlag =
          e.data != null && e.data['requiresVerification'] == true;

      if (isUnverifiedByMessage || isUnverifiedByFlag) {
        // Extract userId from error response if available
        final userId = e.data?['userId'] as String? ?? 
                      e.data?['user']?['id'] as String? ??
                      e.data?['user']?['_id'] as String?;
        await _handleUnverifiedAccount(userId: userId);
        return;
      }

      // Handle API-specific errors - show backend error message directly
      if (mounted) {
        final localization = Provider.of<LocalizationService>(
          context,
          listen: false,
        );

        // ApiException now extracts backend `data.message` and sanitizes noisy prefixes
        // so `e.message` should already be the user-facing backend message.
        String errorMessage = e.message.trim();
        if (errorMessage.isEmpty) {
          errorMessage = localization.translate('auth.unexpectedError');
        }

        // Use backend message as the dialog title (localization-friendly via Accept-Language)
        // Keep message empty/minimal.
        final String title = errorMessage;

        // Show error dialog with Lottie animation - only close button
        ConfirmationDialog.show(
          context: context,
          isSuccess: false,
          title: title,
          message: '',
          secondaryActionLabel: localization.translate('auth.close'),
          onSecondaryAction: () {},
          barrierDismissible: true,
        );
      }
    } catch (e) {
      // Handle unexpected errors (network errors, etc.)
      if (mounted) {
        final localization = Provider.of<LocalizationService>(
          context,
          listen: false,
        );

        // Show error dialog with Lottie animation - only close button
        // Title-only dialog for unexpected errors (avoid generic "Error" header)
        ConfirmationDialog.show(
          context: context,
          isSuccess: false,
          title: localization.translate('auth.unexpectedError'),
          message: '',
          secondaryActionLabel: localization.translate('auth.close'),
          onSecondaryAction: () {},
          barrierDismissible: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Handle unverified account during login
  Future<void> _handleUnverifiedAccount({String? userId}) async {
    if (!mounted) return;

    final localization = Provider.of<LocalizationService>(
      context,
      listen: false,
    );
    final authRepository = Provider.of<AuthRepository>(
      context,
      listen: false,
    );

    final username = _usernameController.text.trim();
    final isPhone = authRepository.isValidPhone(username);

    // Show clean snackbar with Alexandria font for Arabic
    _showUnverifiedAccountSnackbar(localization);

    // Handle verification flow based on phone/email
    if (isPhone) {
      // Phone: Trigger Firebase Phone Auth to send SMS
      if (!mounted) return;
      
      // Sanitize phone number to strict E.164 format (no spaces) before calling Firebase
      String sanitizedPhone = username;
      try {
        sanitizedPhone = authRepository.sanitizePhoneForFirebase(username);
        debugPrint('📱 [Login] Sanitized phone (E.164): $sanitizedPhone');
      } catch (e) {
        debugPrint('⚠️ [Login] Error sanitizing phone: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid phone number format. Please check and try again.'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }
      
      if (mounted) {
        setState(() => _isLoading = true);
      }
      
      bool hasNavigated = false; // Prevent multiple navigations
      
      try {
        String? verificationId;
        
        await authRepository.verifyPhoneNumber(
          phoneNumber: sanitizedPhone, // Already sanitized to E.164 format
          onCodeSent: (id) {
            if (!mounted || hasNavigated) return;
            
            verificationId = id;
            hasNavigated = true;
            
            debugPrint('✅ [Login] SMS code sent. VerificationId: $id, UserId: $userId');
            
            if (mounted) {
              setState(() => _isLoading = false);
            }
            
            if (mounted) {
              // Pass sanitized phone number and userId to VerificationScreen
              Navigator.pushNamed(
                context,
                AppRoutes.verification,
                arguments: {
                  'username': sanitizedPhone, // E.164 format: +201064448681
                  'isPhone': true,
                  'verificationId': verificationId, // Persist verificationId
                  'userId': userId, // Ensure userId is passed
                },
              );
            }
          },
          onVerificationCompleted: () {
            if (!mounted || hasNavigated) return;
            
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
          onVerificationFailed: (error) {
            if (!mounted) return;
            
            if (mounted) {
              setState(() => _isLoading = false);
            }
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to send verification code: $error'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          onCodeAutoRetrievalTimeout: (error) {
            if (!mounted || hasNavigated) return;
            
            if (verificationId != null) {
              hasNavigated = true;
              
              debugPrint('⏱️ [Login] Code auto-retrieval timeout. VerificationId: $verificationId, UserId: $userId');
              
              if (mounted) {
                setState(() => _isLoading = false);
              }
              
              if (mounted) {
                // Pass sanitized phone number and userId to VerificationScreen
                Navigator.pushNamed(
                  context,
                  AppRoutes.verification,
                  arguments: {
                    'username': sanitizedPhone, // E.164 format: +201064448681
                    'isPhone': true,
                    'verificationId': verificationId, // Persist verificationId
                    'userId': userId, // Ensure userId is passed
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send verification code'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else {
      // Email: Navigate directly to verification screen
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pushNamed(
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
  }

  /// Show clean snackbar for unverified account with Alexandria font
  void _showUnverifiedAccountSnackbar(LocalizationService localization) {
    if (!mounted) return;

    final message = localization.translate('auth.unverifiedAccountLoginMessage') ??
        'Your account is not verified. Please complete verification first.';
    
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
      // If no route to pop, navigate to onboarding screen
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.onboarding,
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
            resizeToAvoidBottomInset: true,
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

                                  // Header - Simple Login Text
                                  FadeTransition(
                                    opacity: _welcomeFade,
                                    child: Column(
                                      children: [
                                        Center(
                                          child: ShaderMask(
                                            shaderCallback: (bounds) =>
                                                LinearGradient(
                                                  colors: [
                                                    AppColors.primary,
                                                    AppColors.secondary,
                                                  ],
                                                ).createShader(bounds),
                                            child: Text(
                                              localization.translate(
                                                'auth.login',
                                              ),
                                              style: AppStyles.headingLarge
                                                  .copyWith(
                                                    fontSize: 32,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: -0.5,
                                                    color: Colors.white,
                                                  ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        FadeTransition(
                                          opacity: _subtitleFade,
                                          child: Text(
                                            localization.translate(
                                              'auth.welcomeBackMessage',
                                            ),
                                            textAlign: TextAlign.center,
                                            style: AppStyles.bodyLarge.copyWith(
                                              color: AppColors.textSecondary
                                                  .withOpacity(0.7),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 32),

                                  // Login Form
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
                                                // Username Field (Email or Phone)
                                                _buildGlassInputField(
                                                  controller:
                                                      _usernameController,
                                                  label: localization.translate(
                                                    'auth.emailOrPhone',
                                                  ),
                                                  hint: localization.translate(
                                                    'auth.emailOrPhone',
                                                  ),
                                                  keyboardType:
                                                      TextInputType.text,
                                                  prefixIcon:
                                                      Icons.person_outline,
                                                  validator: (value) {
                                                    if (value?.isEmpty ??
                                                        true) {
                                                      return localization.translate(
                                                        'auth.pleaseEnterEmail',
                                                      );
                                                    }
                                                    // Validate as email or phone
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
                                                      return localization.translate(
                                                        'auth.invalidEmailOrPhone',
                                                      );
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

                                                const SizedBox(height: 16),

                                                // Forgot Password
                                                Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: AnimatedContainer(
                                                    duration: const Duration(
                                                      milliseconds: 200,
                                                    ),
                                                    child: TextButton(
                                                      onPressed: () {
                                                        AppRoutes.pushNamed(
                                                          context,
                                                          AppRoutes
                                                              .forgotPassword,
                                                        );
                                                      },
                                                      style: TextButton.styleFrom(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        localization.translate(
                                                          'auth.forgotPassword',
                                                        ),
                                                        style: AppStyles
                                                            .bodyMedium
                                                            .copyWith(
                                                              color: AppColors
                                                                  .primary,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              decoration:
                                                                  TextDecoration
                                                                      .underline,
                                                              decorationColor:
                                                                  AppColors
                                                                      .primary
                                                                      .withOpacity(
                                                                        0.3,
                                                                      ),
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ),

                                                const SizedBox(height: 32),

                                                // Login Button and Biometric Button
                                                FadeTransition(
                                                  opacity: _buttonFade,
                                                  child: Column(
                                                    children: [
                                                      CustomButton(
                                                        text: localization
                                                            .translate(
                                                              'auth.signIn',
                                                            ),
                                                        onPressed: _handleLogin,
                                                        isLoading: _isLoading,
                                                        variant: ButtonVariant
                                                            .gradient,
                                                        gradientColors: [
                                                          AppColors.primary,
                                                          AppColors.info,
                                                          AppColors.secondary,
                                                        ],
                                                      ),
                                                      // Biometric Button (if available for this identifier)
                                                      if (_showBiometricIcon)
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                top: 16,
                                                              ),
                                                          child: InkWell(
                                                            onTap:
                                                                (_isLoading ||
                                                                    _isCheckingBiometric)
                                                                ? null
                                                                : () => _attemptBiometricLogin(
                                                                    isManual:
                                                                        true,
                                                                  ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        24,
                                                                    vertical:
                                                                        16,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                border: Border.all(
                                                                  color:
                                                                      (_isLoading ||
                                                                          _isCheckingBiometric)
                                                                      ? AppColors
                                                                            .textTertiary
                                                                            .withOpacity(
                                                                              0.3,
                                                                            )
                                                                      : AppColors
                                                                            .primary,
                                                                  width: 1.5,
                                                                ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      12,
                                                                    ),
                                                                color: Colors
                                                                    .transparent,
                                                              ),
                                                              child: Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .fingerprint,
                                                                    color:
                                                                        (_isLoading ||
                                                                            _isCheckingBiometric)
                                                                        ? AppColors
                                                                              .textTertiary
                                                                        : AppColors
                                                                              .primary,
                                                                    size: 24,
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 8,
                                                                  ),
                                                                  Text(
                                                                    localization.translate(
                                                                          'auth.useBiometric',
                                                                        ) ??
                                                                        'Use Fingerprint or Face ID',
                                                                    style: AppStyles.bodyMedium.copyWith(
                                                                      color:
                                                                          (_isLoading ||
                                                                              _isCheckingBiometric)
                                                                          ? AppColors.textTertiary
                                                                          : AppColors.primary,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      fontFamily:
                                                                          'Alexandria',
                                                                    ),
                                                                  ),
                                                                  if (_isCheckingBiometric) ...[
                                                                    const SizedBox(
                                                                      width: 12,
                                                                    ),
                                                                    SizedBox(
                                                                      width: 16,
                                                                      height:
                                                                          16,
                                                                      child: CircularProgressIndicator(
                                                                        strokeWidth:
                                                                            2,
                                                                        valueColor:
                                                                            AlwaysStoppedAnimation<
                                                                              Color
                                                                            >(
                                                                              AppColors.primary,
                                                                            ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
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
                                      AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        child: TextButton(
                                          onPressed: () {
                                            AppRoutes.pushReplacementNamed(
                                              context,
                                              AppRoutes.signup,
                                            );
                                          },
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                          ),
                                          child: Text(
                                            localization.translate(
                                              'auth.signup',
                                            ),
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

  List<Widget> _buildDecorativeCircles() {
    final screenSize = MediaQuery.of(context).size;

    return [
      // Decorative dots pattern
      ..._buildDotsPattern(screenSize),

      // Top-left quarter circles (layered)
      // Large quarter circle
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
      // Small quarter circle on top
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

    // Create scattered dots
    for (int i = 0; i < 20; i++) {
      final randomX = (i * 87) % screenSize.width.toInt();
      final randomY = (i * 123) % screenSize.height.toInt();
      final size = (i % 3 + 1) * 4.0; // 4, 8, or 12px
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
              color: color.withOpacity(0.03),
            ),
          ),
        ),
      );
    }

    return dots;
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

  /// Show bottom sheet to enable biometric login
  Future<void> _showBiometricEnablementPrompt(
    AuthRepository authService, {
    String? userId,
    String? userName,
  }) async {
    if (!mounted) return;

    final localization = Provider.of<LocalizationService>(
      context,
      listen: false,
    );
    final biometricService = BiometricService();
    final biometricType = await biometricService.getBiometricType();

    // Get token from SharedPreferences (saved during login)
    // This is the current active token from the successful login
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    debugPrint(
      '🔍 [BiometricEnable] Token from SharedPreferences: ${token != null ? "exists (${token.length} chars)" : "null"}',
    );

    if (token == null || token.isEmpty) {
      debugPrint('❌ [BiometricEnable] No token found in SharedPreferences');
      // No token, navigate directly
      if (mounted) {
        UnifiedSnackbar.showError(
          context: context,
          message:
              localization.translate('auth.biometricTokenMissing') ??
              'Please login manually once to re-sync biometrics.',
        );
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.mainNavigation,
          (route) => false,
        );
      }
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        bottom: true,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 24.0,
              right: 24.0,
              top: 24.0,
              bottom: MediaQuery.of(context).padding.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),

                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.fingerprint,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  localization.translate('auth.enableBiometricTitle') ??
                      'Enable Biometric Login for faster access?',
                  style: AppStyles.headingMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Alexandria',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Message
                Text(
                  localization.translate('auth.enableBiometricMessage') ??
                      'You can use your $biometricType to quickly sign in to your account without entering your password.',
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontFamily: 'Alexandria',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Buttons
                Row(
                  children: [
                    // Not Now
                    Expanded(
                      child: SizedBox(
                        height: 56.0,
                        child: OutlinedButton(
                          onPressed: () {
                            debugPrint(
                              '⏭️ [BiometricPrompt] User clicked "Not Now"',
                            );

                            // Option A: Don't save any "declined" flag
                            // This means the prompt will show again next manual login
                            // until the user actually enables biometrics

                            // CRITICAL: Save reference to parent navigator BEFORE closing bottom sheet
                            final parentNavigator = Navigator.of(context, rootNavigator: true);

                            // Close the bottom sheet first
                            parentNavigator.pop();

                            // Navigate to home screen IMMEDIATELY (user already logged in)
                            debugPrint(
                              '🏠 [BiometricPrompt] Redirecting to home after "Not Now"',
                            );
                            parentNavigator.pushNamedAndRemoveUntil(
                              AppRoutes.mainNavigation,
                              (route) => false,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: AppColors.textTertiary,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.transparent,
                          ),
                          child: Text(
                            localization.translate('auth.notNow') ?? 'Not Now',
                            style: AppStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Alexandria',
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Enable
                    Expanded(
                      child: SizedBox(
                        height: 56.0,
                        child: CustomButton(
                          text:
                              localization.translate('auth.enable') ?? 'Enable',
                          onPressed: () async {
                            debugPrint(
                              '✅ [BiometricPrompt] User clicked "Enable"',
                            );

                            // CRITICAL: Save references to parent navigator and scaffold messenger
                            // BEFORE closing the bottom sheet, because the context will be invalid after pop()
                            final parentNavigator = Navigator.of(context, rootNavigator: true);
                            final scaffoldMessenger = ScaffoldMessenger.of(context);

                            // Close the bottom sheet first
                            parentNavigator.pop();

                            // Show loading indicator using saved reference
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      localization.translate('common.pleaseWait') ?? 'Please wait...',
                                      style: const TextStyle(fontFamily: 'Alexandria'),
                                    ),
                                  ],
                                ),
                                backgroundColor: AppColors.warning,
                                duration: const Duration(seconds: 30),
                              ),
                            );

                            // Verify token exists and is not empty
                            if (token == null || token.isEmpty) {
                              debugPrint(
                                '❌ [BiometricEnable] Token is null or empty',
                              );
                              scaffoldMessenger.hideCurrentSnackBar();
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    localization.translate('auth.biometricFailed') ??
                                        'Failed to enable biometric login. Please try again.',
                                    style: const TextStyle(fontFamily: 'Alexandria'),
                                  ),
                                  backgroundColor: AppColors.error,
                                ),
                              );

                              // Navigate to home anyway (user already logged in)
                              debugPrint(
                                '🏠 [BiometricEnable] Redirecting to home after error (no token)',
                              );
                              parentNavigator.pushNamedAndRemoveUntil(
                                AppRoutes.mainNavigation,
                                (route) => false,
                              );
                              return;
                            }

                            // Get the current user's identifier (email or phone)
                            final identifier = _usernameController.text.trim();

                            if (identifier.isEmpty) {
                              debugPrint(
                                '❌ [BiometricEnable] No identifier available',
                              );
                              scaffoldMessenger.hideCurrentSnackBar();
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    localization.translate('auth.biometricFailed') ??
                                        'Failed to enable biometric login. Please try again.',
                                    style: const TextStyle(fontFamily: 'Alexandria'),
                                  ),
                                  backgroundColor: AppColors.error,
                                ),
                              );

                              // Navigate to home anyway (user already logged in)
                              debugPrint(
                                '🏠 [BiometricEnable] Redirecting to home after error (no identifier)',
                              );
                              parentNavigator.pushNamedAndRemoveUntil(
                                AppRoutes.mainNavigation,
                                (route) => false,
                              );
                              return;
                            }

                            debugPrint(
                              '🔍 [BiometricEnable] Saving token for account: $identifier (length: ${token.length})',
                            );

                            // Get user ID and Name from SharedPreferences if not provided
                            final prefs = await SharedPreferences.getInstance();
                            final finalUserId = userId ?? prefs.getString('user_id');
                            final finalUserName = userName ?? prefs.getString('user_name');

                            debugPrint('🔍 [BiometricEnable] User data:');
                            debugPrint('   👤 User ID: ${finalUserId ?? "not available"}');
                            debugPrint('   👤 User Name: ${finalUserName ?? "not available"}');

                            // Save token and user data to secure storage with THIS account's identifier
                            // This creates a per-account biometric profile
                            final success = await biometricService
                                .saveTokenSecurely(
                              token,
                              identifier: identifier,
                              userId: finalUserId,
                              userName: finalUserName,
                            );

                            debugPrint(
                              '🔍 [BiometricEnable] Save result for $identifier: $success',
                            );

                            // Hide loading and show result using saved reference
                            scaffoldMessenger.hideCurrentSnackBar();

                            if (success) {
                              debugPrint(
                                '✅ [BiometricEnable] Biometric enabled successfully for $identifier',
                              );
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    localization.translate('auth.biometricEnabled') ??
                                        'Biometric login enabled successfully!',
                                    style: const TextStyle(fontFamily: 'Alexandria'),
                                  ),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            } else {
                              debugPrint(
                                '❌ [BiometricEnable] Failed to enable for $identifier',
                              );
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    localization.translate('auth.biometricFailed') ??
                                        'Failed to enable biometric login. Please try again.',
                                    style: const TextStyle(fontFamily: 'Alexandria'),
                                  ),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }

                            // Authenticate Socket.IO after enabling biometric (user already logged in)
                            try {
                              await SocketService().authenticateSocket(token);
                              debugPrint('✅ [BiometricEnable] Socket authenticated');
                            } catch (e) {
                              debugPrint('⚠️ [BiometricEnable] Socket authentication failed: $e');
                            }

                            // Navigate to main app IMMEDIATELY after enabling (or failing)
                            // User already logged in, so redirect right away
                            debugPrint(
                              '🏠 [BiometricPrompt] Redirecting to home after "Enable"',
                            );
                            parentNavigator.pushNamedAndRemoveUntil(
                              AppRoutes.mainNavigation,
                              (route) => false,
                            );
                          },
                          variant: ButtonVariant.gradient,
                          gradientColors: [
                            AppColors.primary,
                            AppColors.secondary,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
