import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/core/services/fcm_service.dart';
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';
import 'package:wish_listy/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:wish_listy/core/utils/app_routes.dart';

class VerificationScreen extends StatefulWidget {
  final String username;
  final bool isPhone;
  final String? verificationId; // Required for phone verification
  final String? userId; // User ID from registration/login response

  const VerificationScreen({
    super.key,
    required this.username,
    required this.isPhone,
    this.verificationId,
    this.userId,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen>
    with SingleTickerProviderStateMixin {
  final _otpController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isLoading = false;
  String? _errorMessage;
  int _resendTimer = 60; // Will be set based on isPhone in initState
  Timer? _timer;
  /// Email only: OTP validity countdown (10 minutes = 600 seconds).
  int _otpValidityRemaining = 0;
  Timer? _otpValidityTimer;
  String? _currentVerificationId;
  late AnimationController _shakeController;
  static const String _timerKeyPrefix = 'verification_timer_';
  String get _timerKey => '$_timerKeyPrefix${widget.username}';
  
  // Resend timer: 60 seconds for both email and phone
  static const int _timerDuration = 60;
  // Email only: OTP valid for 10 minutes
  static const int _otpValidityDuration = 600;

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.verificationId;
    
    // Debug: Log verificationId received from route arguments
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadTimerState();
    // Email: start 10-minute OTP validity countdown
    if (!widget.isPhone && mounted) {
      setState(() => _otpValidityRemaining = _otpValidityDuration);
      _startOtpValidityTimer();
    }
    // Listen to OTP input changes
    _otpController.addListener(() {
      if (mounted) {
        setState(() {
          // Clear error message when user starts typing again
          if (_otpController.text.isNotEmpty && _errorMessage != null) {
            _errorMessage = null;
          }
          // Trigger rebuild to update button state
        });
      }
    });
    // Auto-focus on OTP input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  /// Load timer state from SharedPreferences to persist across app lifecycle
  Future<void> _loadTimerState() async {
    if (!mounted) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTimestamp = prefs.getInt(_timerKey);
      
      if (savedTimestamp != null) {
        final elapsed = DateTime.now().millisecondsSinceEpoch - savedTimestamp;
        final remainingSeconds = _timerDuration - (elapsed ~/ 1000);
        
        if (remainingSeconds > 0 && mounted) {
          setState(() {
            _resendTimer = remainingSeconds;
          });
          if (mounted) {
            _startResendTimer();
          }
        } else if (mounted) {
          // Timer expired, start fresh
          _startResendTimer();
        }
      } else if (mounted) {
        // No saved timer, start fresh
        _startResendTimer();
      }
    } catch (e) {
      // Start fresh if loading fails
      if (mounted) {
        _startResendTimer();
      }
    }
  }

  /// Save timer state to SharedPreferences
  Future<void> _saveTimerState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_timerKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
    }
  }

  /// Clear saved timer state
  Future<void> _clearTimerState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_timerKey);
    } catch (e) {
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    _focusNode.dispose();
    _timer?.cancel();
    _otpValidityTimer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  /// Email only: countdown for OTP validity (10 minutes).
  void _startOtpValidityTimer() {
    if (!mounted || widget.isPhone) return;
    _otpValidityTimer?.cancel();
    _otpValidityTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_otpValidityRemaining > 0) {
        setState(() => _otpValidityRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  void _startResendTimer() {
    if (!mounted) return;
    
    _resendTimer = _timerDuration;
    _saveTimerState(); // Save timestamp when timer starts
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      if (_resendTimer > 0) {
        if (mounted) {
          setState(() {
            _resendTimer--;
          });
        }
        // Save state every 5 seconds to reduce I/O
        if (_resendTimer % 5 == 0) {
          _saveTimerState();
        }
      } else {
        timer.cancel();
        _clearTimerState(); // Clear saved state when timer expires
      }
    });
  }

  Future<void> _handleVerify() async {
    if (!mounted) return;

    // OTP is always a String (trimmed); do not use int.parse before sending to API.
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      if (mounted) {
        final localization = Provider.of<LocalizationService>(context, listen: false);
        setState(() {
          _errorMessage = localization.translate('auth.otpInvalid') ??
              'Please enter a 6-digit code';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final authRepository = Provider.of<AuthRepository>(context, listen: false);
      final localization = Provider.of<LocalizationService>(context, listen: false);

      // Add timeout to prevent hanging on network issues
      final response = await Future.any([
        _performVerification(authRepository),
        Future.delayed(const Duration(seconds: 30), () {
          throw TimeoutException(
            localization.translate('auth.verificationFailed') ??
                'Verification timed out. Please check your connection and try again.',
          );
        }),
      ]) as Map<String, dynamic>;

      // Only navigate on successful verification
      // On error, user stays on verification screen to retry
      if (response['success'] == true && mounted) {
        // Extract token from verification response (if available)
        String? token = response['token'];
        Map<String, dynamic>? userData = response['user'] ?? response['data'];
        
        // Notify backend that verification flow completed successfully
        // Pass userId from registration/login response - MUST include userId in request body
        Map<String, dynamic>? verifySuccessResponse;
        if (widget.userId != null && widget.userId!.isNotEmpty) {
          try {
            verifySuccessResponse = await authRepository.verifySuccess(widget.userId!);
            // If verifySuccess returns a token, use it (takes precedence)
            if (verifySuccessResponse != null && verifySuccessResponse['token'] != null) {
              token = verifySuccessResponse['token'];
            }
            // If verifySuccess returns user data, use it
            if (verifySuccessResponse != null && verifySuccessResponse['user'] != null) {
              userData = verifySuccessResponse['user'] ?? verifySuccessResponse['data'];
            }
          } on ApiException catch (e) {
            // If verifySuccess fails, show error but don't block navigation
            // The OTP verification already succeeded, so we proceed
            if (mounted) {
              _showErrorSnackBar(
                e.message.isNotEmpty 
                    ? e.message 
                    : 'Verification completed but failed to update status. Please try logging in.',
                localization,
              );
            }
            // Continue with navigation since OTP verification succeeded
          } catch (e) {
            // Continue with navigation since OTP verification succeeded
          }
        } else {
        }

        // Save token and update auth state BEFORE navigating
        // If Firebase verification succeeded but backend call failed, we still proceed
        // Token might come from verifySuccess call instead
        if (token != null && token.isNotEmpty) {
          
          // Save token and refresh token to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
          final refreshToken = verifySuccessResponse?['refreshToken'] ?? verifySuccessResponse?['refresh_token'] ?? response['refreshToken'] ?? response['refresh_token'];
          if (refreshToken != null) {
            await prefs.setString('refresh_token', refreshToken.toString());
          }
          await prefs.setBool('is_logged_in', true);
          
          // Extract and save user data
          if (userData != null) {
            final userId = userData['id'] ?? userData['_id'] ?? widget.userId;
            final userEmail = userData['username'] ?? userData['email'] ?? widget.username;
            final userName = userData['fullName'] ?? userData['name'] ?? '';
            
            if (userId != null) {
              await prefs.setString('user_id', userId.toString());
            }
            if (userEmail != null) {
              await prefs.setString('user_email', userEmail.toString());
            }
            if (userName != null && userName.isNotEmpty) {
              await prefs.setString('user_name', userName.toString());
            }
          }
          
          // Set token in API service
          ApiService().setAuthToken(token);
          
          // Update AuthRepository state
          await authRepository.initialize();
          
          // After JWT/session are fully initialized, sync FCM token with retry logic.
          // This call is awaited BEFORE navigation to ensure the sync has a chance to complete.
          if (authRepository.isAuthenticated) {
            await _syncFcmTokenWithRetries(authRepository);
          }
          
        } else if (response['firebaseVerified'] == true) {
          // Firebase verification succeeded but no token yet
          // This can happen if backend call failed but Firebase verification succeeded
          // Try to get token from verifySuccess, or save userId at least
          
          // Save userId at least so user can login later
          if (widget.userId != null && widget.userId!.isNotEmpty) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_id', widget.userId!);
            await prefs.setString('user_email', widget.username);
          }
          
          // Show info message that verification succeeded but login may be needed
          if (mounted) {
            _showSuccessMessage(localization);
            await Future.delayed(const Duration(milliseconds: 1500));
            // Navigate to login so user can login with their credentials
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                (route) => false,
              );
            }
          }
          return;
        } else {
          // If no token and Firebase verification didn't succeed, show error
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = localization.translate('auth.verificationFailed') ??
                  'Verification failed. No token received. Please try again.';
            });
            _showErrorSnackBar(
              localization.translate('auth.verificationFailed') ??
                  'Verification failed. Please try again.',
              localization,
            );
            _triggerShakeAnimation();
            return;
          }
        }

        if (!mounted) return;
        
        _clearTimerState(); // Clear timer on success
        _showSuccessMessage(localization);
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          // After successful verification, navigate to home (main navigation)
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.mainNavigation,
            (route) => false,
          );
        }
      } else {
        // Verification failed but response didn't throw exception
        // This shouldn't happen, but handle it gracefully
        if (!mounted) return;
        
        final localization = Provider.of<LocalizationService>(context, listen: false);
        final errorMsg = localization.translate('auth.invalidCode') ??
            'Invalid code. Please try again.';
        
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = errorMsg;
          });
        }
        
        _showErrorSnackBar(errorMsg, localization);
        _triggerShakeAnimation();
        _otpController.clear();
        // Re-focus on input field so user can try again immediately
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _focusNode.requestFocus();
          }
        });
        // DO NOT navigate - keep user on verification screen
      }
    } on TimeoutException catch (e) {
      if (!mounted) return;
      
      final localization = Provider.of<LocalizationService>(context, listen: false);
      final errorMsg = localization.translate('auth.verificationFailed') ??
          'Connection timeout. Please try again.';
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = errorMsg;
        });
      }
      
      _showErrorSnackBar(errorMsg, localization);
      _triggerShakeAnimation();
      _otpController.clear();
      // Re-focus on input field so user can try again immediately
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
      // DO NOT navigate - keep user on verification screen
    } on ApiException catch (e) {
      if (!mounted) return;
      
      final localization = Provider.of<LocalizationService>(context, listen: false);
      
      // Check if this is an "already verified" error
      final errorCode = e.data?['code'] as String? ?? '';
      final errorMessage = e.message.toLowerCase();
      final isAlreadyVerified = errorCode == 'auth.already_verified' || 
          errorMessage.contains('already verified') ||
          errorMessage.contains('already_verified');
      
      if (isAlreadyVerified && mounted) {
        // User is already verified - show success and navigate to Home
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        _clearTimerState();
        _showSuccessMessage(localization);
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.mainNavigation,
            (route) => false,
          );
        }
        return;
      }
      
      // Backend 400/401: map errorCode to specific Arabic messages
      String errorMsg;
      final status = e.statusCode;
      final responseData = e.data;
      final backendCode = (responseData is Map)
          ? ((responseData['errorCode'] ?? responseData['code'])?.toString().trim())
          : null;
      if ((status == 400 || status == 401) && backendCode != null && backendCode.isNotEmpty) {
        switch (backendCode) {
          case 'OTP_INVALID':
            errorMsg = 'رقم الكود غير صحيح، تأكد من الأرقام وأعد المحاولة';
            break;
          case 'OTP_EXPIRED':
            errorMsg = 'انتهت صلاحية الكود (10 دقائق). اضغط على إعادة الإرسال للحصول على كود جديد';
            break;
          case 'OTP_NOT_FOUND':
            errorMsg = 'لا يوجد كود نشط حالياً، برجاء طلب كود جديد';
            break;
          default:
            errorMsg = localization.translate('auth.verificationFailed') ??
                (e.message.isNotEmpty ? e.message : 'Verification failed. Please try again.');
        }
      } else {
        // Firebase or other errors
        final isFirebaseError = e.message.contains('Invalid code') ||
            e.message.contains('invalid-verification-code') ||
            e.message.contains('Code expired') ||
            e.message.contains('session-expired') ||
            e.statusCode == 400;
        if (isFirebaseError &&
            (e.message.contains('Invalid') || e.message.contains('invalid') ||
                e.message.contains('incorrect') || e.message.contains('wrong') ||
                e.message.contains('expired'))) {
          errorMsg = localization.translate('auth.invalidCode') ??
              'Invalid code. Please try again.';
        } else {
          errorMsg = localization.translate('auth.verificationFailed') ??
              (e.message.isNotEmpty ? e.message : 'Verification failed. Please try again.');
        }
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = errorMsg;
        });
      }
      
      _showErrorSnackBar(errorMsg, localization);
      _triggerShakeAnimation();
      _otpController.clear();
      // Re-focus on input field so user can try again immediately
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
      // DO NOT navigate - keep user on verification screen
    } catch (e) {
      if (!mounted) return;
      
      final localization = Provider.of<LocalizationService>(context, listen: false);
      final errorMsg = localization.translate('auth.verificationFailed') ??
          'Verification failed. Please check your connection and try again.';
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = errorMsg;
        });
      }
      
      _showErrorSnackBar(errorMsg, localization);
      _triggerShakeAnimation();
      _otpController.clear();
      // Re-focus on input field so user can try again immediately
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
      // DO NOT navigate - keep user on verification screen
    }
  }

  /// Perform verification with retry logic.
  /// For phone: Uses the persisted verificationId to create PhoneAuthCredential.
  /// For email: Uses username and OTP code (String, trimmed; no int.parse).
  Future<Map<String, dynamic>> _performVerification(
    AuthRepository authRepository,
  ) async {
    if (widget.isPhone) {
      // Phone verification - ensure verificationId is available
      if (_currentVerificationId == null) {
        throw Exception('Verification ID is missing. Please request a new code.');
      }

      return await authRepository.verifyPhoneOTP(
        verificationId: _currentVerificationId!, // Use latest verificationId
        smsCode: _otpController.text.trim(),
      );
    } else {
      // Email verification
      return await authRepository.verifyEmailOTP(
        username: widget.username,
        otp: _otpController.text.trim(),
      );
    }
  }

  /// Sync the current device's FCM token to backend with retry + detailed logging.
  ///
  /// - Called only AFTER JWT/session are fully initialized (authRepository.initialize + token saved).
  /// - Logs before starting, logs the actual token value, and retries getToken up to 3 times.
  /// - Waits 2 seconds between retries if token is null.
  /// - Awaits updateFcmToken before navigation so the sync has a chance to complete.
  Future<void> _syncFcmTokenWithRetries(AuthRepository authRepository) async {

    const int maxAttempts = 3;
    String? fcmToken;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        fcmToken = await FcmService().getToken();
      } catch (e) {
        final errorStr = e.toString();
        if (errorStr.contains('FIS_AUTH_ERROR') || errorStr.contains('Firebase Installations Service')) {
        }
        fcmToken = null;
      }

      if (fcmToken != null && fcmToken.isNotEmpty) {
        break;
      }

      if (attempt < maxAttempts) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    if (fcmToken == null || fcmToken.isEmpty) {
      return;
    }

    try {
      await authRepository.updateFcmToken(fcmToken);
    } on ApiException catch (e) {
    } catch (e) {
    }
  }

  /// Trigger shake animation on error
  void _triggerShakeAnimation() {
    _shakeController.forward(from: 0.0).then((_) {
      _shakeController.reverse();
    });
  }

  Future<void> _handleResend() async {
    if (!mounted || _resendTimer > 0) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final authCubit = context.read<AuthCubit>();
      await authCubit.resendOtp(widget.username);

      if (!mounted) return;
      setState(() => _isLoading = false);
      _startResendTimer();

      final localization = Provider.of<LocalizationService>(context, listen: false);
      final message = localization.translate('auth.codeResent') ?? 'Verification code resent';
      final isArabic = localization.currentLanguage == 'ar';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
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
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      final localization = Provider.of<LocalizationService>(context, listen: false);
      setState(() {
        _isLoading = false;
        _errorMessage = e.message.isNotEmpty ? e.message : (localization.translate('auth.verificationFailed') ?? 'Failed to resend code. Please try again.');
      });
      _showErrorSnackBar(e.message.isNotEmpty ? e.message : (localization.translate('auth.verificationFailed') ?? 'Failed to resend code. Please try again.'), localization);
    } catch (e) {
      if (!mounted) return;
      final localization = Provider.of<LocalizationService>(context, listen: false);
      setState(() {
        _isLoading = false;
        _errorMessage = localization.translate('auth.verificationFailed') ?? 'Failed to resend code. Please try again.';
      });
      _showErrorSnackBar(localization.translate('auth.verificationFailed') ?? 'Failed to resend code. Please try again.', localization);
    }
  }

  void _showSuccessMessage(LocalizationService localization) {
    if (!mounted) return;
    
    final isArabic = localization.currentLanguage == 'ar';
    final message = localization.translate('auth.verificationSuccess') ??
        'Verification successful!';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
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
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Show error snackbar with Alexandria font for Arabic
  void _showErrorSnackBar(String message, LocalizationService localization) {
    if (!mounted) return;
    
    final isArabic = localization.currentLanguage == 'ar';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline,
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
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Handle back button: pop if there's a route to go back to, else navigate to Login
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

  /// Format timer seconds as MM:SS and substitute into template (e.g. "يمكنك إعادة إرسال الكود خلال 00:59").
  String _formatTimer(int seconds, LocalizationService localization) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    final formattedTime = '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    final template = localization.translate('auth.resendCodeIn') ?? 'يمكنك إعادة إرسال الكود خلال {seconds}';
    return template.replaceAll('{seconds}', formattedTime);
  }

  /// Format validity countdown as MM:SS (e.g. 10:00, 09:59).
  String _formatValidityCountdown(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _getSubtitle(LocalizationService localization) {
    if (widget.isPhone) {
      return localization.translate('auth.verificationSubtitlePhone')
              ?.replaceAll('{phone}', widget.username) ??
          'Enter the code sent to ${widget.username}';
    } else {
      return localization.translate('auth.verificationSubtitleEmail')
              ?.replaceAll('{email}', widget.username) ??
          'Enter the code sent to ${widget.username}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localization, child) {
        final isRTL = localization.isRTL;

        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) {
            if (!didPop) _handleBackNavigation();
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  isRTL ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
                onPressed: _handleBackNavigation,
              ),
            ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    localization.translate('auth.verificationTitle') ??
                        'Verify Your Account',
                    style: AppStyles.headingLarge.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: isRTL ? TextAlign.right : TextAlign.left,
                  ),

                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    _getSubtitle(localization),
                    style: AppStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: isRTL ? TextAlign.right : TextAlign.left,
                  ),

                  const SizedBox(height: 48),

                  // OTP Input with Shake Animation
                  AnimatedBuilder(
                    animation: _shakeController,
                    builder: (context, child) {
                      // Shake animation: oscillates left-right
                      final shakeOffset = (_shakeController.value < 0.5
                              ? _shakeController.value * 2
                              : (1 - _shakeController.value) * 2) *
                          10 *
                          (_shakeController.value < 0.5 ? -1 : 1);
                      return Transform.translate(
                        offset: Offset(shakeOffset, 0),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Pinput(
                              controller: _otpController,
                              focusNode: _focusNode,
                              length: 6,
                              enabled: !_isLoading,
                              defaultPinTheme: PinTheme(
                                width: 56,
                                height: 56,
                                textStyle: AppStyles.headingMedium.copyWith(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: localization.currentLanguage == 'ar'
                                      ? 'Alexandria'
                                      : null,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _errorMessage != null
                                        ? AppColors.error
                                        : AppColors.border,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              focusedPinTheme: PinTheme(
                                width: 56,
                                height: 56,
                                textStyle: AppStyles.headingMedium.copyWith(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: localization.currentLanguage == 'ar'
                                      ? 'Alexandria'
                                      : null,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                              errorPinTheme: PinTheme(
                                width: 56,
                                height: 56,
                                textStyle: AppStyles.headingMedium.copyWith(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: localization.currentLanguage == 'ar'
                                      ? 'Alexandria'
                                      : null,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.error,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                              showCursor: !_isLoading,
                              onCompleted: (pin) {
                                if (!_isLoading) {
                                  _handleVerify();
                                }
                              },
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                            // Loading Overlay
                            if (_isLoading)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Error Message with Alexandria font for Arabic
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.error.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              textAlign: isRTL ? TextAlign.right : TextAlign.left,
                              style: localization.currentLanguage == 'ar'
                                  ? GoogleFonts.alexandria(
                                      color: AppColors.error,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    )
                                  : AppStyles.bodyMedium.copyWith(
                                      color: AppColors.error,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Verify Button
                  ElevatedButton(
                    onPressed: _isLoading || _otpController.text.length != 6
                        ? null
                        : _handleVerify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            localization.translate('auth.continue') ?? 'Continue',
                            style: AppStyles.bodyLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),

                  const SizedBox(height: 24),

                  // Email only: 10-minute OTP validity countdown; resend in 60s shown in row below
                  if (!widget.isPhone) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                      children: [
                        Text(
                          localization.translate('auth.codeValidFor') ?? 'صلاحية الكود ١٠ دقايق',
                          textAlign: isRTL ? TextAlign.right : TextAlign.left,
                          style: AppStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatValidityCountdown(_otpValidityRemaining),
                          style: AppStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Resend Code: countdown "يمكنك إعادة إرسال الكود خلال 00:59" or clickable "إعادة إرسال الكود"
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                    children: [
                      if (_resendTimer > 0)
                        Text(
                          _formatTimer(_resendTimer, localization),
                          textAlign: isRTL ? TextAlign.right : TextAlign.left,
                          style: AppStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else
                        TextButton(
                          onPressed: _isLoading ? null : _handleResend,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                          child: Text(
                            localization.translate('auth.resendCode') ?? 'إعادة إرسال الكود',
                            textAlign: isRTL ? TextAlign.right : TextAlign.left,
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
          ),
        ),
      );
      },
    );
  }
}
