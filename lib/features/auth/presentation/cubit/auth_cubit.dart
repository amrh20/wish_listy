import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/core/services/fcm_service.dart';
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';
import 'package:wish_listy/features/auth/presentation/cubit/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repository;

  AuthCubit({AuthRepository? repository})
      : _repository = repository ?? AuthRepository(),
        super(AuthInitial());

  /// Sync the current FCM token to backend with retry + detailed logging.
  ///
  /// - Logs start/end of each attempt.
  /// - Retries getToken() up to 3 times with 2s delay if it returns null.
  /// - Ensures updateFcmToken is only called when a non-null token is available.
  /// - Logs status code and error message if the backend call fails.
  Future<void> _syncFcmTokenWithRetries() async {

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

    // Repository should already be authenticated and JWT stored before this is called.
    try {
      await _repository.updateFcmToken(fcmToken);
    } on ApiException catch (e) {
    } catch (e) {
    }
  }

  Future<void> checkAccount(String identifier, {String? countryCode}) async {
    try {
      emit(AuthLoading());

      final response = await _repository.checkAccount(
        identifier,
        countryCode: countryCode,
      );

      
      if (response['success'] == true) {
        if (response.containsKey('email') && response['email'] != null) {
          // Email is linked
          emit(CheckAccountSuccess(
            email: response['email'],
            emailLinked: true,
          ));
        } else if (response['email_linked'] == false) {
          // No email linked
          emit(CheckAccountSuccess(
            email: null,
            emailLinked: false,
          ));
        } else {
          emit(CheckAccountError(
            response['message'] ?? 'Unknown response from server',
          ));
        }
      } else {
        emit(CheckAccountError(
          response['message'] ?? 'User not found',
        ));
      }
    } on ApiException catch (e) {
      emit(CheckAccountError(e.message));
    } catch (e, stackTrace) {
      emit(CheckAccountError(
        'Failed to check account: ${e.toString()}',
      ));
    }
  }

  Future<void> requestReset(
    String identifier, {
    String? newEmail,
    String? countryCode,
  }) async {
    try {
      emit(AuthLoading());

      final response = await _repository.requestReset(
        identifier,
        newEmail: newEmail,
        countryCode: countryCode,
      );

      // Check if requiresEmail flag is set (from 400 error)
      if (response['requiresEmail'] == true) {
        emit(AuthForgotPasswordEmailRequired(identifier));
        return;
      }

      if (response['success'] == true) {
        emit(RequestResetSuccess(
          response['message'] ?? 'Reset link sent successfully',
        ));
      } else {
        emit(RequestResetError(
          response['message'] ?? 'Failed to send reset link',
        ));
      }
    } on ApiException catch (e) {
      // Check if this is a requiresEmail case (should be handled above, but double-check)
      if (e.statusCode == 400 && 
          e.data is Map && 
          e.data['requiresEmail'] == true) {
        emit(AuthForgotPasswordEmailRequired(identifier));
      } else {
        emit(RequestResetError(e.message));
      }
    } catch (e) {
      emit(RequestResetError(
        'Failed to request reset: ${e.toString()}',
      ));
    }
  }

  Future<void> resetPassword({
    required String identifier,
    required String otp,
    required String newPassword,
    String? countryCode,
  }) async {
    try {
      emit(AuthLoading());

      final response = await _repository.resetPassword(
        identifier: identifier,
        otp: otp,
        newPassword: newPassword,
        countryCode: countryCode,
      );

      if (response['success'] == true) {
        emit(ResetPasswordSuccess(
          response['message'] ?? 'Password reset successfully',
        ));
      } else {
        emit(ResetPasswordError(
          response['message'] ?? 'Failed to reset password',
        ));
      }
    } on ApiException catch (e) {
      emit(ResetPasswordError(e.message));
    } catch (e) {
      emit(ResetPasswordError(
        'Failed to reset password: ${e.toString()}',
      ));
    }
  }

  /// Login with a stored JWT token (e.g., from biometric authentication)
  /// Verifies the token with the API, syncs to SharedPreferences, and initializes AuthRepository
  Future<void> loginWithToken(String token) async {
    try {
      emit(AuthLoading());

      // Verify token by calling API
      final response = await _repository.verifyToken(token);

      if (response['success'] == true) {
        // Token is valid, sync to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setBool('is_logged_in', true);

        // Extract user data from response
        final userData = response['user'];
        if (userData != null) {
          await prefs.setString('user_id', userData['id'] ?? userData['_id'] ?? '');
          await prefs.setString('user_email', userData['username'] ?? userData['email'] ?? '');
          await prefs.setString('user_name', userData['fullName'] ?? userData['name'] ?? '');
        }

        // Initialize AuthRepository to sync state
        await _repository.initialize();
        // At this point JWT is verified, stored, and API service is configured.
        // Now we can safely sync the FCM token with full retry + logging.
        await _syncFcmTokenWithRetries();

        emit(const AuthAuthenticated());
      } else {
        emit(AuthError(
          response['message'] ?? 'Invalid token. Please login again.',
        ));
      }
    } on ApiException catch (e) {
      emit(AuthError('Token verification failed: ${e.message}'));
    } catch (e) {
      emit(AuthError('Token verification failed: ${e.toString()}'));
    }
  }

  /// Resend OTP (email or phone). Calls repository; exceptions propagate to caller.
  Future<void> resendOtp(String username, {String? countryCode}) async {
    await _repository.resendOtp(username, countryCode: countryCode);
  }
}

