import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String? _currentVerificationId;
  late AnimationController _shakeController;
  static const String _timerKeyPrefix = 'verification_timer_';
  String get _timerKey => '$_timerKeyPrefix${widget.username}';
  
  // Timer duration: 10 minutes (600 seconds) for Email, 60 seconds for Phone
  int get _timerDuration => widget.isPhone ? 60 : 600;

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.verificationId;
    
    // Debug: Log verificationId received from route arguments
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('📱 [VerificationScreen] initState called');
    debugPrint('📱 [VerificationScreen] Phone/Email: ${widget.username}');
    debugPrint('📱 [VerificationScreen] Is Phone: ${widget.isPhone}');
    debugPrint('📱 [VerificationScreen] VerificationId received: ${widget.verificationId}');
    debugPrint('📱 [VerificationScreen] VerificationId length: ${widget.verificationId?.length ?? 0}');
    debugPrint('📱 [VerificationScreen] UserId received: ${widget.userId}');
    debugPrint('📱 [VerificationScreen] _currentVerificationId set to: $_currentVerificationId');
    debugPrint('═══════════════════════════════════════════════════════');
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadTimerState();
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
      debugPrint('⚠️ [Verification] Failed to load timer state: $e');
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
      debugPrint('⚠️ [Verification] Failed to save timer state: $e');
    }
  }

  /// Clear saved timer state
  Future<void> _clearTimerState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_timerKey);
    } catch (e) {
      debugPrint('⚠️ [Verification] Failed to clear timer state: $e');
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    _focusNode.dispose();
    _timer?.cancel();
    _shakeController.dispose();
    super.dispose();
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
          debugPrint('📤 [Verification] Calling verifySuccess with userId: ${widget.userId}');
          try {
            verifySuccessResponse = await authRepository.verifySuccess(widget.userId!);
            debugPrint('✅ [Verification] verifySuccess completed successfully');
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
            debugPrint('⚠️ [Verification] verifySuccess failed: ${e.message}');
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
            debugPrint('⚠️ [Verification] verifySuccess error: $e');
            // Continue with navigation since OTP verification succeeded
          }
        } else {
          debugPrint('⚠️ [Verification] userId is missing, skipping verifySuccess call');
        }

        // Save token and update auth state BEFORE navigating
        // If Firebase verification succeeded but backend call failed, we still proceed
        // Token might come from verifySuccess call instead
        if (token != null && token.isNotEmpty) {
          debugPrint('💾 [Verification] Saving token and updating auth state...');
          
          // Save token to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
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
          
          // Sync FCM token to backend so push notifications work (non-blocking on failure)
          if (authRepository.isAuthenticated) {
            try {
              final fcmToken = await FcmService().getToken().timeout(
                const Duration(seconds: 5),
                onTimeout: () => null,
              );
              if (fcmToken != null && fcmToken.isNotEmpty) {
                await authRepository.updateFcmToken(fcmToken).timeout(
                  const Duration(seconds: 5),
                  onTimeout: () {
                    debugPrint('⚠️ [Verification] FCM token sync timed out - continuing anyway');
                  },
                );
                debugPrint('✅ [Verification] FCM token synced to backend');
              }
            } catch (e) {
              debugPrint('⚠️ [Verification] FCM token sync skipped (non-blocking): $e');
            }
          }
          
          debugPrint('✅ [Verification] Token saved and auth state updated');
        } else if (response['firebaseVerified'] == true) {
          // Firebase verification succeeded but no token yet
          // This can happen if backend call failed but Firebase verification succeeded
          // Try to get token from verifySuccess, or save userId at least
          debugPrint('⚠️ [Verification] Firebase verified but no token yet');
          debugPrint('⚠️ [Verification] This might be due to backend call failure');
          debugPrint('⚠️ [Verification] Will try to proceed with userId: ${widget.userId}');
          
          // Save userId at least so user can login later
          if (widget.userId != null && widget.userId!.isNotEmpty) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_id', widget.userId!);
            await prefs.setString('user_email', widget.username);
            debugPrint('✅ [Verification] Saved userId for later login');
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
          debugPrint('❌ [Verification] No token and Firebase verification may have failed');
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
      
      // Check if this is a Firebase verification error (invalid code, expired, etc.)
      // vs a backend API error (401, network, etc.)
      final isFirebaseError = e.message.contains('Invalid code') || 
          e.message.contains('invalid-verification-code') ||
          e.message.contains('Code expired') ||
          e.message.contains('session-expired') ||
          e.statusCode == 400; // Firebase errors typically return 400
      
      // Regular error - show error message
      String errorMsg;
      if (isFirebaseError && 
          (e.message.contains('Invalid') || e.message.contains('invalid') || 
           e.message.contains('incorrect') || e.message.contains('wrong') ||
           e.message.contains('expired'))) {
        // This is a Firebase OTP error - show invalid code message
        errorMsg = localization.translate('auth.invalidCode') ??
            'Invalid code. Please try again.';
      } else {
        // This might be a backend error - show generic verification failed message
        errorMsg = localization.translate('auth.verificationFailed') ??
            (e.message.isNotEmpty ? e.message : 'Verification failed. Please try again.');
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

  /// Perform verification with retry logic
  /// For phone: Uses the persisted verificationId to create PhoneAuthCredential
  /// For email: Uses username and OTP code
  Future<Map<String, dynamic>> _performVerification(
    AuthRepository authRepository,
  ) async {
    if (widget.isPhone) {
      // Phone verification - ensure verificationId is available
      if (_currentVerificationId == null) {
        debugPrint('❌ [Verification] Verification ID is missing');
        throw Exception('Verification ID is missing. Please request a new code.');
      }

      debugPrint('📱 [Verification] Verifying OTP with verificationId: $_currentVerificationId');
      debugPrint('📱 [Verification] OTP Code: ${_otpController.text.trim()}');
      debugPrint('📱 [Verification] Phone: ${widget.username}');
      debugPrint('📱 [Verification] UserId: ${widget.userId}');

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
      final authRepository = Provider.of<AuthRepository>(context, listen: false);

      if (widget.isPhone) {
        // Resend phone verification - ensure phone is sanitized to E.164 format
        // widget.username should already be in E.164 format from signup/login
        // but we sanitize again to be safe
        String sanitizedPhone = widget.username;
        try {
          sanitizedPhone = authRepository.sanitizePhoneForFirebase(widget.username);
          debugPrint('📱 [Verification] Resending code to sanitized phone (E.164): $sanitizedPhone');
        } catch (e) {
          debugPrint('⚠️ [Verification] Error sanitizing phone for resend: $e');
          // Use original phone if sanitization fails (shouldn't happen if it was sanitized before)
          sanitizedPhone = widget.username;
        }
        
        await authRepository.resendPhoneVerification(
          phoneNumber: sanitizedPhone, // Use sanitized phone
          onCodeSent: (verificationId) {
            if (!mounted) return;
            
            debugPrint('═══════════════════════════════════════════════════════');
            debugPrint('📱 [VerificationScreen] Resend: Code sent callback');
            debugPrint('📱 [VerificationScreen] New VerificationId: $verificationId');
            debugPrint('📱 [VerificationScreen] VerificationId length: ${verificationId.length}');
            debugPrint('📱 [VerificationScreen] Phone: ${widget.username}');
            debugPrint('═══════════════════════════════════════════════════════');
            
            setState(() {
              _currentVerificationId = verificationId; // Update with latest verificationId
              _isLoading = false;
            });
            if (mounted) {
              _startResendTimer();
            }
            if (mounted) {
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
            }
          },
          onVerificationFailed: (error) {
            if (!mounted) return;
            
            final localization = Provider.of<LocalizationService>(context, listen: false);
            
            setState(() {
              _isLoading = false;
              _errorMessage = error;
            });
            
            _showErrorSnackBar(error, localization);
          },
        );
      } else {
        // Resend email OTP
        await authRepository.resendEmailOTP(widget.username);
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        if (mounted) {
          _startResendTimer();
        }
        if (mounted) {
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
        }
      }
    } catch (e) {
      if (!mounted) return;
      
      final localization = Provider.of<LocalizationService>(context, listen: false);
      setState(() {
        _isLoading = false;
        _errorMessage = localization.translate('auth.verificationFailed') ??
            'Failed to resend code. Please try again.';
      });
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

  /// Format timer seconds as MM:SS
  String _formatTimer(int seconds, LocalizationService localization) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    final formattedTime = '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    
    // Use localized string if available, otherwise use default format
    final template = localization.translate('auth.resendCodeIn') ?? 'Resend code in {seconds}s';
    return template.replaceAll('{seconds}', formattedTime);
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

                  // Resend Code
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                    children: [
                      Text(
                        localization.translate('auth.resendCode') ??
                            'Didn\'t receive the code? ',
                        textAlign: isRTL ? TextAlign.right : TextAlign.left,
                        style: AppStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
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
                            localization.translate('auth.resendCode') ?? 'Resend Code',
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
