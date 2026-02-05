import 'package:flutter/foundation.dart';
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
    debugPrint('🔔 FCM: Starting token sync from AuthCubit...');

    const int maxAttempts = 3;
    String? fcmToken;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      debugPrint('🔔 FCM: Starting token sync... (attempt $attempt/$maxAttempts)');
      try {
        fcmToken = await FcmService().getToken();
      } catch (e) {
        debugPrint('⚠️ FCM: getToken() threw exception on attempt $attempt: $e');
        final errorStr = e.toString();
        if (errorStr.contains('FIS_AUTH_ERROR') || errorStr.contains('Firebase Installations Service')) {
          debugPrint('❌ FCM: Firebase Installations Service error detected.');
          debugPrint('   This usually means:');
          debugPrint('   1. Google Play Services needs update');
          debugPrint('   2. Firebase configuration issue (check google-services.json)');
          debugPrint('   3. Network/Firebase server issue');
        }
        fcmToken = null;
      }

      if (fcmToken != null && fcmToken.isNotEmpty) {
        debugPrint('🔔 FCM: Token acquired (length=${fcmToken.length}): $fcmToken');
        break;
      }

      debugPrint('⚠️ FCM: getToken() returned null/empty on attempt $attempt');
      if (attempt < maxAttempts) {
        debugPrint('⏱️ FCM: Waiting 2 seconds before retrying getToken()...');
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    if (fcmToken == null || fcmToken.isEmpty) {
      debugPrint('❌ FCM: Unable to obtain FCM token after $maxAttempts attempts. Skipping sync.');
      debugPrint('❌ FCM: No API call will be made to /auth/fcm-token because token is null.');
      return;
    }

    // Repository should already be authenticated and JWT stored before this is called.
    try {
      debugPrint('📤 FCM: Calling updateFcmToken on backend...');
      await _repository.updateFcmToken(fcmToken);
      debugPrint('✅ FCM: Token synced successfully via AuthCubit');
    } on ApiException catch (e) {
      debugPrint(
        '❌ FCM: updateFcmToken failed. '
        'status=${e.statusCode}, kind=${e.kind}, message=${e.message}, data=${e.data}',
      );
    } catch (e) {
      debugPrint('❌ FCM: Unexpected error during token sync: $e');
    }
  }

  Future<void> checkAccount(String identifier) async {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 AuthCubit: checkAccount called');
    debugPrint('🔍 AuthCubit: Identifier: "$identifier"');
    debugPrint('═══════════════════════════════════════════════════════');
    try {
      debugPrint('🔍 AuthCubit: Step 1 - Emitting AuthLoading state...');
      emit(AuthLoading());
      debugPrint('✅ AuthCubit: AuthLoading state emitted successfully');

      debugPrint('🔍 AuthCubit: Step 2 - Calling _repository.checkAccount("$identifier")...');
      final response = await _repository.checkAccount(identifier);
      debugPrint('✅ AuthCubit: Repository call completed');
      debugPrint('🔍 AuthCubit: Response received: $response');

      debugPrint('🔍 AuthCubit: Step 3 - Processing response...');
      debugPrint('🔍 AuthCubit: response["success"] = ${response['success']}');
      
      if (response['success'] == true) {
        debugPrint('✅ AuthCubit: Success response received');
        if (response.containsKey('email') && response['email'] != null) {
          // Email is linked
          debugPrint('🔍 AuthCubit: Email is linked: ${response['email']}');
          emit(CheckAccountSuccess(
            email: response['email'],
            emailLinked: true,
          ));
          debugPrint('✅ AuthCubit: CheckAccountSuccess state emitted (email linked)');
        } else if (response['email_linked'] == false) {
          // No email linked
          debugPrint('🔍 AuthCubit: No email linked to account');
          emit(CheckAccountSuccess(
            email: null,
            emailLinked: false,
          ));
          debugPrint('✅ AuthCubit: CheckAccountSuccess state emitted (no email)');
        } else {
          debugPrint('⚠️ AuthCubit: Unexpected success response format');
          emit(CheckAccountError(
            response['message'] ?? 'Unknown response from server',
          ));
          debugPrint('❌ AuthCubit: CheckAccountError state emitted');
        }
      } else {
        debugPrint('❌ AuthCubit: Failed response received');
        emit(CheckAccountError(
          response['message'] ?? 'User not found',
        ));
        debugPrint('❌ AuthCubit: CheckAccountError state emitted: ${response['message'] ?? 'User not found'}');
      }
      debugPrint('═══════════════════════════════════════════════════════');
    } on ApiException catch (e) {
      debugPrint('❌ AuthCubit: ApiException caught: ${e.message}');
      emit(CheckAccountError(e.message));
      debugPrint('❌ AuthCubit: CheckAccountError state emitted: ${e.message}');
      debugPrint('═══════════════════════════════════════════════════════');
    } catch (e, stackTrace) {
      debugPrint('❌ AuthCubit: Unexpected exception caught');
      debugPrint('❌ Error: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      emit(CheckAccountError(
        'Failed to check account: ${e.toString()}',
      ));
      debugPrint('❌ AuthCubit: CheckAccountError state emitted: Failed to check account: ${e.toString()}');
      debugPrint('═══════════════════════════════════════════════════════');
    }
  }

  Future<void> requestReset(String identifier, {String? newEmail}) async {
    try {
      emit(AuthLoading());

      final response = await _repository.requestReset(
        identifier,
        newEmail: newEmail,
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
  }) async {
    try {
      emit(AuthLoading());

      final response = await _repository.resetPassword(
        identifier: identifier,
        otp: otp,
        newPassword: newPassword,
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
  Future<void> resendOtp(String username) async {
    await _repository.resendOtp(username);
  }
}

