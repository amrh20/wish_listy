import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/core/services/socket_service.dart';
import 'package:wish_listy/core/services/biometric_service.dart';

/// Authentication Repository
/// Handles all authentication-related operations including:
/// - User state management
/// - API calls for login/register
/// - Local storage management
/// - Token management
enum UserState { guest, authenticated, loading }

class AuthRepository extends ChangeNotifier {
  static final AuthRepository _instance = AuthRepository._internal();
  factory AuthRepository() => _instance;
  AuthRepository._internal();

  final ApiService _apiService = ApiService();

  UserState _userState = UserState.loading;
  String? _userId;
  String? _userEmail;
  String? _userName;
  String? _profilePicture; // Global profile picture for sync across screens

  // Getters
  UserState get userState => _userState;
  bool get isGuest => _userState == UserState.guest;
  bool get isAuthenticated => _userState == UserState.authenticated;
  bool get isLoading => _userState == UserState.loading;
  String? get userId => _userId;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  String? get profilePicture => _profilePicture;

  // Update profile picture globally
  void updateProfilePicture(String? imageUrl) {
    _profilePicture = imageUrl;
    notifyListeners();
  }

  // Initialize auth state and load saved token
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

      if (isLoggedIn) {
        _userId = prefs.getString('user_id');
        _userEmail = prefs.getString('user_email');
        _userName = prefs.getString('user_name');
        _userState = UserState.authenticated;

        // Load and set auth token if available
        final token = prefs.getString('auth_token');
        if (token != null) {
          _apiService.setAuthToken(token);
          // Connect to Socket.IO for real-time notifications
          final timestamp = DateTime.now().toIso8601String();
          print('═══════════════════════════════════════════════════════');
          print('🔥 AUTH REPOSITORY: ABOUT TO CALL SOCKET.CONNECT()');
          print('🔥 User ID: $_userId');
          print('🔥 Token exists: ${token.isNotEmpty}');
          print('═══════════════════════════════════════════════════════');

          debugPrint(
            '🔌 [Auth] ⏰ [$timestamp] Calling SocketService.connect() from initialize()',
          );
          debugPrint('🔌 [Auth] ⏰ [$timestamp]    User ID: $_userId');
          debugPrint('🔌 [Auth] ⏰ [$timestamp]    User Email: $_userEmail');

          try {
            // Use timeout to prevent hanging
            await SocketService().connect().timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                print('⚠️ Socket connection timeout - continuing anyway');
              },
            );
            print('✅ SocketService().connect() completed');
          } catch (e) {
            print('❌ ERROR calling SocketService().connect(): $e');
            // Continue anyway - don't block app initialization
          }
        } else {
          print('⚠️ No auth token found in initialize()');
        }
      } else {
        _userState = UserState.guest;
      }
    } catch (e) {
      _userState = UserState.guest;
    }
    notifyListeners();
  }

  // Login as guest (from "Get Started" button)
  Future<void> loginAsGuest() async {
    _userState = UserState.guest;
    _userId = null;
    _userEmail = null;
    _userName = null;

    // Clear auth token from API service to prevent unauthorized API calls
    _apiService.clearAuthToken();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    await prefs.remove('user_id');
    await prefs.remove('user_email');
    await prefs.remove('user_name');
    await prefs.remove('auth_token');

    notifyListeners();
  }

  // Set user as authenticated (for temporary login without API)
  Future<void> setAuthenticatedUser({
    required String userId,
    required String userEmail,
    required String userName,
  }) async {
    _userState = UserState.authenticated;
    _userId = userId;
    _userEmail = userEmail;
    _userName = userName;

    // Save to local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('user_id', _userId!);
    await prefs.setString('user_email', _userEmail!);
    await prefs.setString('user_name', _userName!);

    notifyListeners();
  }

  // Register new user using API
  Future<Map<String, dynamic>> register({
    required String username, // email or phone
    required String fullName,
    required String password,
  }) async {
    try {
      // Prepare registration data according to API format
      final registrationData = {
        'username': username,
        'fullName': fullName,
        'password': password,
      };

      // Make API call to register endpoint
      // Endpoint: POST /api/auth/register
      final response = await _apiService.post(
        '/auth/register',
        data: registrationData,
      );

      // Return the response data which should contain user info and token
      return response;
    } on ApiException {
      // Re-throw ApiException to preserve error details from backend
      rethrow;
    } catch (e) {
      // Handle unexpected errors - convert to ApiException to preserve error handling flow
      // ApiException should have been thrown by ApiService, so this catch is for truly unexpected errors
      throw ApiException(
        e.toString().contains('Exception') || e.toString().contains('Error')
            ? e.toString()
            : 'Registration failed. Please try again.',
      );
    }
  }

  // Login user with username and password using API
  Future<Map<String, dynamic>> login({
    required String username, // username can be email or phone
    required String password,
    String? fcmToken, // Optional FCM token for push notifications
  }) async {
    // ApiException will be thrown by ApiService interceptor if there's an error
    // No need to catch and rethrow - let ApiException propagate naturally
    final loginData = {
      'username': username,
      'password': password,
      if (fcmToken != null) 'fcmToken': fcmToken,
    };
    final response = await _apiService.post('/auth/login', data: loginData);
    return response;
  }

  // Login with credentials using real API
  Future<bool> loginUser(
    String username,
    String password, {
    String? fcmToken,
  }) async {
    try {
      // Call the API to login
      final response = await login(
        username: username,
        password: password,
        fcmToken: fcmToken,
      );

      // Check if user exists but is unverified
      if (response['requiresVerification'] == true) {
        debugPrint('⚠️ [Auth] User exists but is not verified');
        // Throw special exception with requiresVerification flag
        throw ApiException(
          'Account not verified',
          statusCode: 403,
          data: {
            'requiresVerification': true,
            'username': username,
          },
        );
      }

      // Check if login was successful
      if (response['success'] == true) {
        // Extract user data from response
        final userData = response['user'] ?? response['data'];
        final token = response['token'];

        // Update user state
        _userState = UserState.authenticated;
        _userId =
            userData?['id'] ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
        _userEmail = userData?['username'] ?? userData?['email'] ?? username;
        _userName =
            userData?['fullName'] ??
            userData?['name'] ??
            username.split('@').first;

        // Save to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('user_id', _userId!);
        await prefs.setString('user_email', _userEmail!);
        await prefs.setString('user_name', _userName!);

        // Save auth token if available
        if (token != null) {
          // Save to SharedPreferences for backward compatibility
          await prefs.setString('auth_token', token);

          // Note: Token will be saved to secure storage after user enables biometric
          // This happens in the post-login prompt (see login_screen.dart)

          // CRITICAL: Set token in API service BEFORE any subsequent API calls
          // This ensures all API requests (including updateFcmToken) use the new token
          _apiService.setAuthToken(token);
          debugPrint('✅ [Auth] JWT token set in API service headers');
          
          // Authenticate Socket.IO for real-time notifications (Option B: emit auth event)
          // Use forceReconnect=true to ensure clean connection after logout/login
          final timestamp = DateTime.now().toIso8601String();
          debugPrint(
            '🔌 [Auth] ⏰ [$timestamp] Calling SocketService.authenticateSocket() from loginUser()',
          );
          debugPrint('🔌 [Auth] ⏰ [$timestamp]    User ID: $_userId');
          debugPrint('🔌 [Auth] ⏰ [$timestamp]    User Email: $_userEmail');
          debugPrint('🔌 [Auth] ⏰ [$timestamp]    User Name: $_userName');
          debugPrint(
            '🔌 [Auth] ⏰ [$timestamp]    Token length: ${token.length}',
          );
          await SocketService().authenticateSocket(token);

          // Ensure FCM token is synced to backend AFTER JWT token is set
          // This prevents 401 errors from stale/null tokens
          if (fcmToken != null && fcmToken.isNotEmpty) {
            try {
              debugPrint('🔔 [Auth] Updating FCM token after login (JWT token already set)');
              await updateFcmToken(fcmToken);
              debugPrint('✅ [Auth] FCM token updated successfully');
            } catch (e) {
              debugPrint('⚠️ [Auth] Failed to update FCM token after login: $e');
              // Don't throw - FCM token update failure shouldn't block login
            }
          }
        }

        notifyListeners();
        return true;
      } else {
        // Login failed - extract error message from response and throw ApiException
        final errorMessage =
            response['message'] ??
            response['error'] ??
            'Login failed. Please check your credentials.';

        debugPrint('❌ Login failed: $errorMessage');

        // Throw ApiException with the actual error message from backend
        throw ApiException(
          errorMessage,
          statusCode: 400, // Assume 400 for failed login
          data: response,
        );
      }
    } on ApiException catch (e) {
      // Re-throw ApiException so login screen can show proper error message from backend
      rethrow;
    } catch (e) {
      // Handle unexpected errors (should not happen if ApiService is working correctly)
      // Re-throw as ApiException to preserve error handling flow
      // Only use generic message if we truly don't have backend error message
      throw ApiException(
        e.toString().contains('Exception') || e.toString().contains('Error')
            ? e.toString()
            : 'Login failed. Please check your connection and try again.',
      );
    }
  }

  // Register new user using real API
  Future<bool> registerUser({
    required String username, // email or phone
    required String fullName,
    required String password,
  }) async {
    try {
      // Call the API to register
      final response = await register(
        username: username,
        fullName: fullName,
        password: password,
      );

      // Check if registration was successful
      if (response['success'] == true) {
        // Extract user data from response
        final userData = response['user'] ?? response['data'];
        final token = response['token'];

        // Update user state
        _userState = UserState.authenticated;
        _userId =
            userData?['id'] ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
        _userEmail =
            userData?['username'] ??
            username; // username could be email or phone
        _userName = userData?['fullName'] ?? fullName;

        // Save to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('user_id', _userId!);
        await prefs.setString('user_email', _userEmail!);
        await prefs.setString('user_name', _userName!);

        // Save auth token if available
        if (token != null) {
          await prefs.setString('auth_token', token);
          // Set token in API service for future requests
          _apiService.setAuthToken(token);
          // Authenticate Socket.IO for real-time notifications (Option B: emit auth event)
          final timestamp = DateTime.now().toIso8601String();
          debugPrint(
            '🔌 [Auth] ⏰ [$timestamp] Calling SocketService.authenticateSocket() from registerUser()',
          );
          debugPrint('🔌 [Auth] ⏰ [$timestamp]    User ID: $_userId');
          debugPrint('🔌 [Auth] ⏰ [$timestamp]    User Email: $_userEmail');
          debugPrint('🔌 [Auth] ⏰ [$timestamp]    User Name: $_userName');
          debugPrint(
            '🔌 [Auth] ⏰ [$timestamp]    Token length: ${token.length}',
          );
          await SocketService().authenticateSocket(token);
        }

        notifyListeners();
        return true;
      } else {
        // Registration failed
        return false;
      }
    } catch (e) {
      // Handle any errors
      return false;
    }
  }

  // Logout using real API
  Future<void> logout() async {
    debugPrint('🔒 [Auth] Starting logout process');
    
    try {
      // Disconnect from Socket.IO first
      SocketService().disconnect();
      debugPrint('✅ [Auth] Socket.IO disconnected');
    } catch (e) {
      debugPrint('⚠️ [Auth] Error disconnecting Socket.IO: $e');
    }

    // Best-effort: tell backend to stop sending push notifications
    // for this device token. Do this BEFORE logout API call.
    try {
      await deleteFcmToken();
      debugPrint('✅ [Auth] FCM token deleted');
    } catch (e) {
      debugPrint('⚠️ [Auth] Failed to delete FCM token on logout: $e');
      // Continue with logout even if FCM deletion fails
    }

    // Call API to logout (best-effort, don't block on failure)
    try {
      await _apiService.post('/auth/logout');
      debugPrint('✅ [Auth] Logout API call successful');
    } catch (e) {
      debugPrint('⚠️ [Auth] Logout API call failed (continuing with local cleanup): $e');
      // Even if API logout fails, clear local data
    }

    // IMPORTANT: Do NOT clear biometric token on logout!
    // The biometric token should remain in secure storage so the user can
    // log back in using biometrics without needing to re-enable it.
    // We only clear the session token from SharedPreferences.
    // The biometric token will be used on next login if biometrics are enabled.
    
    // Get user identifier before clearing local state (for logging only)
    final currentEmail = _userEmail;

    // Clear local state
    _userState = UserState.guest;
    _userId = null;
    _userEmail = null;
    _userName = null;
    debugPrint('✅ [Auth] Local state cleared');

    // Log that we're keeping biometric data
    if (currentEmail != null && currentEmail.isNotEmpty) {
      debugPrint('🔐 [Auth] Logout: Keeping biometric data for $currentEmail');
      debugPrint('   ✅ User can log back in using biometrics without re-enabling');
    }

    // Clear local storage
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', false);
      await prefs.remove('user_id');
      await prefs.remove('user_email');
      await prefs.remove('user_name');
      await prefs.remove('auth_token');
      debugPrint('✅ [Auth] SharedPreferences cleared');
    } catch (e) {
      debugPrint('⚠️ [Auth] Error clearing SharedPreferences: $e');
    }

    // CRITICAL: Clear API service token and ensure headers are completely removed
    // This prevents stale tokens from being sent in subsequent requests
    try {
      _apiService.clearAuthToken();
      // Double-check: explicitly remove Authorization header to ensure complete cleanup
      _apiService.dio.options.headers.remove('Authorization');
      debugPrint('✅ [Auth] API service token cleared (headers verified)');
    } catch (e) {
      debugPrint('⚠️ [Auth] Error clearing API token: $e');
    }

    notifyListeners();
  }

  /// Silent logout without API calls - used for 401 error handling
  /// This method clears all local state without making any backend requests
  /// to avoid infinite loops when handling unauthorized errors.
  Future<void> logoutSilently() async {
    debugPrint('🔒 [Auth] Performing silent logout (no API calls)');
    
    // Disconnect from Socket.IO
    try {
      SocketService().disconnect();
    } catch (e) {
      debugPrint('⚠️ [Auth] Error disconnecting socket during silent logout: $e');
    }

    // Clear local state
    _userState = UserState.guest;
    _userId = null;
    _userEmail = null;
    _userName = null;

    // Clear local storage
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', false);
      await prefs.remove('user_id');
      await prefs.remove('user_email');
      await prefs.remove('user_name');
      await prefs.remove('auth_token');
      debugPrint('✅ [Auth] Cleared SharedPreferences during silent logout');
    } catch (e) {
      debugPrint('⚠️ [Auth] Error clearing SharedPreferences: $e');
    }

    // Clear API service token
    try {
      _apiService.clearAuthToken();
      // Double-check: explicitly remove Authorization header
      _apiService.dio.options.headers.remove('Authorization');
      debugPrint('✅ [Auth] Cleared API service token');
    } catch (e) {
      debugPrint('⚠️ [Auth] Error clearing API token: $e');
    }

    notifyListeners();
    debugPrint('✅ [Auth] Silent logout completed');
  }

  /// Update the current device's FCM token on the backend.
  ///
  /// Endpoint: PUT /api/auth/fcm-token
  /// Body: { "token": "..." }
  Future<void> updateFcmToken(String token) async {
    if (!isAuthenticated) {
      debugPrint('⚠️ [Auth] updateFcmToken called while user is not authenticated');
      debugPrint('⚠️ [Auth] Token will be sent automatically after login');
      return;
    }

    try {
      debugPrint('📤 [Auth] Sending FCM token to backend: ${token.substring(0, 20)}...');
      await _apiService.put(
        '/auth/fcm-token',
        data: {'token': token},
      );
      debugPrint('✅ [Auth] FCM token updated successfully on backend');
      debugPrint('✅ [Auth] Backend now has the latest FCM token for push notifications');
    } on ApiException catch (e) {
      debugPrint('⚠️ [Auth] Failed to update FCM token on backend: ${e.message}');
      debugPrint('⚠️ [Auth] Token: ${token.substring(0, 20)}...');
      rethrow;
    } catch (e) {
      debugPrint('⚠️ [Auth] Unexpected error updating FCM token: $e');
      rethrow;
    }
  }

  /// Delete the current device's FCM token on the backend so that
  /// push notifications are no longer delivered to this device.
  ///
  /// Endpoint: DELETE /api/auth/fcm-token
  Future<void> deleteFcmToken() async {
    if (!isAuthenticated) {
      // If user is already considered logged out, nothing to do.
      return;
    }

    try {
      await _apiService.delete('/auth/fcm-token');
      debugPrint('✅ [Auth] FCM token deleted on backend');
    } on ApiException catch (e) {
      debugPrint('⚠️ [Auth] Failed to delete FCM token: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('⚠️ [Auth] Unexpected error deleting FCM token: $e');
      rethrow;
    }
  }

  // Delete account using real API
  Future<void> deleteAccount() async {
    try {
      // Disconnect from Socket.IO
      SocketService().disconnect();

      // Call API to delete account
      // Backend endpoint: DELETE /api/auth/delete-account
      await _apiService.delete('/auth/delete-account');
      debugPrint('✅ [Auth] Account deleted successfully via API');
    } on ApiException {
      // Re-throw ApiException so UI can show error message
      rethrow;
    } catch (e) {
      // Convert unexpected errors to ApiException
      debugPrint('⚠️ [Auth] Error deleting account: $e');
      throw ApiException('Failed to delete account: $e');
    }

    // Clear local state (only if API call succeeded)
    _userState = UserState.guest;
    _userId = null;
    _userEmail = null;
    _userName = null;

    // Clear local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    await prefs.remove('user_id');
    await prefs.remove('user_email');
    await prefs.remove('user_name');
    await prefs.remove('auth_token');

    // Clear API service token
    _apiService.clearAuthToken();

    notifyListeners();
  }

  // Validation methods
  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool isValidPhone(String phone) {
    // Accept phone numbers with or without +, spaces, dashes, parentheses
    // Remove all non-digit characters except +
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-()]'), '');

    // Check if starts with + (international format) or just digits
    if (cleanPhone.startsWith('+')) {
      // International format: + followed by 7-15 digits
      final digitsOnly = cleanPhone
          .substring(1)
          .replaceAll(RegExp(r'[^\d]'), '');
      return digitsOnly.length >= 7 && digitsOnly.length <= 15;
    } else {
      // Local format: 7-15 digits only
      final digitsOnly = cleanPhone.replaceAll(RegExp(r'[^\d]'), '');
      return digitsOnly.length >= 7 && digitsOnly.length <= 15;
    }
  }

  bool isValidUsername(String username) {
    return isValidEmail(username) || isValidPhone(username);
  }

  String? validatePassword(String password) {
    // Minimum 6 characters required
    if (password.length < 6) {
      return 'Password must be at least 6 characters long';
    }

    return null; // Password is valid
  }

  String? validateFullName(String name) {
    if (name.trim().isEmpty) {
      return 'Full name is required';
    }

    if (name.trim().length < 2) {
      return 'Full name must be at least 2 characters long';
    }

    if (name.trim().length > 50) {
      return 'Full name must be less than 50 characters';
    }

    return null; // Name is valid
  }

  String? validateUsername(String username) {
    if (username.trim().isEmpty) {
      return 'Email or phone number is required';
    }

    if (!isValidUsername(username)) {
      return 'Please enter a valid email address or phone number';
    }

    return null; // Username is valid
  }

  // Verify JWT token by calling API endpoint
  // Returns user data if token is valid, throws exception if invalid
  Future<Map<String, dynamic>> verifyToken(String token) async {
    try {
      // Temporarily set the token in API service for this request
      _apiService.setAuthToken(token);
      
      // Call API endpoint to verify token (e.g., /auth/me or /users/me)
      // This endpoint should return user data if token is valid
      final response = await _apiService.get('/auth/me');
      
      // Extract user data from response
      final userData = response['user'] ?? response['data'] ?? response;
      
      // Update local state with verified user data
      _userState = UserState.authenticated;
      _userId = userData['id'] ?? userData['_id'];
      _userEmail = userData['username'] ?? userData['email'];
      _userName = userData['fullName'] ?? userData['name'];
      
      return {
        'success': true,
        'user': userData,
        'token': token,
      };
    } on ApiException catch (e) {
      // Token is invalid or expired
      _apiService.clearAuthToken();
      return {
        'success': false,
        'message': e.message,
      };
    } catch (e) {
      _apiService.clearAuthToken();
      return {
        'success': false,
        'message': 'Token verification failed: ${e.toString()}',
      };
    }
  }

  // Additional API methods
  Future<bool> checkEmailAvailability(String email) async {
    try {
      await _apiService.get(
        '/auth/check-email',
        queryParameters: {'email': email},
      );
      return true; // Email is available
    } catch (e) {
      return false; // Email is already taken or error occurred
    }
  }

  Future<void> sendEmailVerification(String email) async {
    try {
      await _apiService.post('/auth/send-verification', data: {'email': email});
    } catch (e) {
      throw Exception('Failed to send verification email');
    }
  }

  Future<void> verifyEmail(String token) async {
    try {
      await _apiService.post('/auth/verify-email', data: {'token': token});
    } catch (e) {
      throw Exception('Failed to verify email');
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _apiService.post('/auth/forgot-password', data: {'email': email});
    } catch (e) {
      throw Exception('Failed to send password reset email');
    }
  }

  /// Check if account exists and has linked email
  /// Returns: {"success": true, "email": "..."} or {"success": true, "email_linked": false} or {"success": false, "message": "..."}
  Future<Map<String, dynamic>> checkAccount(String username) async {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 AuthRepository: checkAccount called');
    debugPrint('🔍 AuthRepository: Username: "$username"');
    try {
      debugPrint('🔍 AuthRepository: Step 1 - Preparing API call...');
      debugPrint('🔍 AuthRepository: Endpoint: POST /auth/check-account');
      debugPrint('🔍 AuthRepository: Request data: {username: "$username"}');

      debugPrint('🔍 AuthRepository: Step 2 - Calling _apiService.post()...');
      final response = await _apiService.post(
        '/auth/check-account',
        data: {'username': username},
      );

      debugPrint('✅ AuthRepository: API call completed successfully');
      debugPrint('🔍 AuthRepository: Response received: $response');
      debugPrint('═══════════════════════════════════════════════════════');
      return response;
    } on ApiException catch (e) {
      debugPrint('❌ AuthRepository: ApiException caught');
      debugPrint('❌ ApiException message: ${e.message}');
      debugPrint('❌ ApiException statusCode: ${e.statusCode}');
      debugPrint('❌ ApiException kind: ${e.kind}');
      debugPrint('═══════════════════════════════════════════════════════');
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('❌ AuthRepository: Unexpected exception caught');
      debugPrint('❌ Error: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      debugPrint('═══════════════════════════════════════════════════════');
      throw Exception('Failed to check account: $e');
    }
  }

  /// Request password reset link
  /// [identifier] can be email or phone
  /// [newEmail] is optional - used when account doesn't have linked email
  /// Returns response or throws ApiException with requiresEmail flag in data
  Future<Map<String, dynamic>> requestReset(
    String identifier, {
    String? newEmail,
  }) async {
    try {
      final data = <String, dynamic>{'identifier': identifier};
      if (newEmail != null && newEmail.isNotEmpty) {
        data['newEmail'] = newEmail;
      }

      final response = await _apiService.post(
        '/auth/request-reset',
        data: data,
      );
      return response;
    } on ApiException catch (e) {
      // Check if this is a 400 error with requiresEmail flag
      if (e.statusCode == 400 &&
          e.data is Map &&
          e.data['requiresEmail'] == true) {
        // Return special response instead of throwing
        return {'success': false, 'requiresEmail': true, 'message': e.message};
      }
      rethrow;
    } catch (e) {
      throw Exception('Failed to request reset: $e');
    }
  }

  /// Reset password using OTP verification
  /// [identifier] is the username/phone used in request-reset
  /// [otp] is the 6-digit OTP code
  /// [newPassword] is the new password
  Future<Map<String, dynamic>> resetPassword({
    required String identifier,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await _apiService.patch(
        '/auth/reset-password',
        data: {
          'identifier': identifier,
          'otp': otp,
          'newPassword': newPassword,
        },
      );
      return response;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to reset password: $e');
    }
  }

  Future<Map<String, dynamic>> refreshToken() async {
    try {
      final response = await _apiService.post('/auth/refresh');
      return response;
    } catch (e) {
      throw Exception('Failed to refresh token');
    }
  }

  /// Change password for authenticated user
  /// Endpoint: PATCH /api/auth/change-password
  /// Request body: { "currentPassword": "...", "newPassword": "..." }
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _apiService.patch(
        '/auth/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
      return response;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to change password. Please try again.');
    }
  }

  // Check if a feature is available for current user
  bool isFeatureAvailable(String feature) {
    if (isAuthenticated) return true;

    // Features available for guest users
    const guestFeatures = {
      'home_view',
      'browse_public_wishlists',
      'view_public_events',
      'language_switcher',
      'browse_friends_public_profiles',
    };

    return guestFeatures.contains(feature);
  }

  // Get restricted message for guests
  String getGuestRestrictionMessage() {
    return 'This feature requires login. Please sign in to continue.';
  }

  // Get current user profile from API
  Future<Map<String, dynamic>> getCurrentUserProfile() async {
    try {
      // Get current user ID
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      // Call API to get user profile
      // Endpoint: GET /api/users/:id/profile
      final response = await _apiService.get('/users/$_userId/profile');

      // Return the response data
      return response;
    } on ApiException {
      // Re-throw ApiException to preserve error details
      rethrow;
    } catch (e) {
      throw Exception('Failed to load profile. Please try again.');
    }
  }

  // Update user profile via PATCH API
  Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> profileData,
  ) async {
    try {
      if (_userId == null) {
        throw Exception('User not authenticated');
      }

      // Call API to update user profile
      // Endpoint: PATCH /api/users/:id/profile
      final response = await _apiService.patch(
        '/users/$_userId/profile',
        data: profileData,
      );

      return response;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to update profile. Please try again.');
    }
  }

  /// Universal sanitizer: Strips ALL spaces and non-digit characters except +
  /// Ensures phone number matches Firebase Console format exactly: +20 followed by 10 digits
  /// Example: "+20 10 6444 8681" or "+20-10-6444-8681" → "+201064448681"
  /// 
  /// IMPORTANT: Firebase Console Display Format vs Actual Format
  /// - Firebase Console DISPLAYS test numbers with spaces for readability: "+20 10 64448681"
  /// - Firebase Phone Auth ACCEPTS E.164 format (NO spaces): "+201064448681"
  /// - Our sanitizer correctly converts to E.164 format (removes spaces)
  /// - Firebase internally normalizes and matches test numbers regardless of display format
  /// - Test numbers should work as long as they match E.164 format after sanitization
  /// 
  /// This function is designed to match Firebase Console test numbers exactly in E.164 format
  String sanitizePhoneForFirebase(String phone) {
    debugPrint('🔍 [Sanitizer] Input phone: "$phone" (length: ${phone.length})');
    
    // Convert Arabic/Eastern digits to Western digits first
    String normalized = phone
        .replaceAll('٠', '0')
        .replaceAll('١', '1')
        .replaceAll('٢', '2')
        .replaceAll('٣', '3')
        .replaceAll('٤', '4')
        .replaceAll('٥', '5')
        .replaceAll('٦', '6')
        .replaceAll('٧', '7')
        .replaceAll('٨', '8')
        .replaceAll('٩', '9')
        .replaceAll('۰', '0')
        .replaceAll('۱', '1')
        .replaceAll('۲', '2')
        .replaceAll('۳', '3')
        .replaceAll('۴', '4')
        .replaceAll('۵', '5')
        .replaceAll('۶', '6')
        .replaceAll('۷', '7')
        .replaceAll('۸', '8')
        .replaceAll('۹', '9');
    
    debugPrint('🔍 [Sanitizer] After Arabic digit conversion: "$normalized"');
    
    // UNIVERSAL SANITIZER: Remove ALL non-digit characters EXCEPT +
    // This removes: spaces, dashes, parentheses, dots, underscores, etc.
    // Only keeps: digits (0-9) and the + sign
    String sanitized = normalized.replaceAll(RegExp(r'[^\d+]'), '');
    
    debugPrint('🔍 [Sanitizer] After removing all non-digits (except +): "$sanitized"');
    
    // Ensure we have at least some digits
    if (sanitized.isEmpty || sanitized == '+') {
      debugPrint('❌ [Sanitizer] Invalid: empty or only + sign');
      throw Exception('Invalid phone number format');
    }
    
    // If it doesn't start with +, normalize it first (handles Egyptian numbers, etc.)
    if (!sanitized.startsWith('+')) {
      debugPrint('🔍 [Sanitizer] No + prefix, normalizing...');
      sanitized = normalizePhoneNumber(sanitized);
      debugPrint('🔍 [Sanitizer] After normalization: "$sanitized"');
    }
    
    // CRITICAL: Ensure exact match with Firebase Console format
    // For Egyptian numbers: +20 followed by exactly 10 digits
    // Note: Firebase Console displays test numbers with spaces (e.g., "+20 10 64448681")
    // but Firebase Phone Auth requires E.164 format without spaces (e.g., "+201064448681")
    // Our sanitizer correctly removes spaces to match E.164 format
    if (sanitized.startsWith('+20')) {
      final digitsAfterCountryCode = sanitized.substring(3); // Everything after "+20"
      debugPrint('🔍 [Sanitizer] Egyptian number detected. Digits after +20: "$digitsAfterCountryCode" (length: ${digitsAfterCountryCode.length})');
      
      // Ensure exactly 10 digits after +20 (matches Firebase Console test numbers in E.164 format)
      // Firebase Console may display "+20 10 64448681" but stores/accepts "+201064448681"
      if (digitsAfterCountryCode.length == 10) {
        final finalPhone = '+20$digitsAfterCountryCode';
        debugPrint('✅ [Sanitizer] FINAL sanitized phone (E.164 format, matches Firebase requirements): "$finalPhone"');
        debugPrint('✅ [Sanitizer] Format: +20 + 10 digits = ${finalPhone.length} characters total');
        debugPrint('✅ [Sanitizer] Note: Firebase Console displays with spaces, but accepts E.164 format (no spaces)');
        return finalPhone;
      } else {
        debugPrint('❌ [Sanitizer] Invalid Egyptian number: expected 10 digits after +20, got ${digitsAfterCountryCode.length}');
        throw Exception('Egyptian phone number must have exactly 10 digits after +20 (e.g., +201064448681)');
      }
    }
    
    // For other countries: validate general E.164 format (+ followed by 7-15 digits)
    final digitsOnly = sanitized.substring(1);
    if (!RegExp(r'^\d{7,15}$').hasMatch(digitsOnly)) {
      debugPrint('❌ [Sanitizer] Invalid: must have 7-15 digits after +');
      throw Exception('Phone number must be between 7 and 15 digits after country code');
    }
    
    debugPrint('✅ [Sanitizer] FINAL sanitized phone (international): "$sanitized"');
    return sanitized;
  }

  /// Normalize phone number to international format
  /// Ensures phone starts with + for Firebase Phone Auth
  /// Handles Arabic/Eastern digits (٠-٩) and removes spaces/special characters
  /// 
  /// Supports:
  /// - Egyptian numbers: 01XXXXXXXXX (11 digits) → +20XXXXXXXXXXX
  /// - International numbers: +XXXXXXXXX or 00XXXXXXXXX → +XXXXXXXXX
  /// - Throws error if no country code detected for non-Egyptian numbers
  String normalizePhoneNumber(String phone) {
    // Convert Arabic/Eastern digits to Western digits
    // Arabic-Indic: ٠١٢٣٤٥٦٧٨٩
    // Extended Arabic-Indic: ۰۱۲۳۴۵۶۷۸۹
    String normalized = phone
        .replaceAll('٠', '0')
        .replaceAll('١', '1')
        .replaceAll('٢', '2')
        .replaceAll('٣', '3')
        .replaceAll('٤', '4')
        .replaceAll('٥', '5')
        .replaceAll('٦', '6')
        .replaceAll('٧', '7')
        .replaceAll('٨', '8')
        .replaceAll('٩', '9')
        .replaceAll('۰', '0')
        .replaceAll('۱', '1')
        .replaceAll('۲', '2')
        .replaceAll('۳', '3')
        .replaceAll('۴', '4')
        .replaceAll('۵', '5')
        .replaceAll('۶', '6')
        .replaceAll('۷', '7')
        .replaceAll('۸', '8')
        .replaceAll('۹', '9');

    // Remove all non-digit characters except +
    // This removes spaces, dashes, parentheses, and any other special characters
    String cleanPhone = normalized.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Ensure we have at least some digits
    if (cleanPhone.isEmpty || cleanPhone == '+') {
      throw Exception('Invalid phone number format');
    }
    
    // Handle international format starting with +
    if (cleanPhone.startsWith('+')) {
      // Already in international format, validate and return
      final digitsOnly = cleanPhone.substring(1).replaceAll(RegExp(r'[^\d]'), '');
      if (digitsOnly.length < 7 || digitsOnly.length > 15) {
        throw Exception('Phone number must be between 7 and 15 digits');
      }
      return cleanPhone;
    }
    
    // Handle international format starting with 00 (common in some regions)
    if (cleanPhone.startsWith('00')) {
      // Convert 00 to +
      cleanPhone = '+${cleanPhone.substring(2)}';
      final digitsOnly = cleanPhone.substring(1).replaceAll(RegExp(r'[^\d]'), '');
      if (digitsOnly.length < 7 || digitsOnly.length > 15) {
        throw Exception('Phone number must be between 7 and 15 digits');
      }
      return cleanPhone;
    }
    
    // Handle Egyptian numbers: 01XXXXXXXXX (11 digits total)
    if (cleanPhone.startsWith('01') && cleanPhone.length == 11) {
      // Egyptian number: replace 0 with +20
      cleanPhone = '+20${cleanPhone.substring(1)}';
      return cleanPhone;
    }
    
    // Handle Egyptian numbers starting with 0 (other formats)
    if (cleanPhone.startsWith('0')) {
      // Remove leading 0 and add +20
      cleanPhone = '+20${cleanPhone.substring(1)}';
      final digitsOnly = cleanPhone.substring(1).replaceAll(RegExp(r'[^\d]'), '');
      if (digitsOnly.length < 7 || digitsOnly.length > 15) {
        throw Exception('Phone number must be between 7 and 15 digits');
      }
      return cleanPhone;
    }
    
    // If we reach here, the number doesn't match Egyptian pattern and has no country code
    // Show error asking user to include country code
    throw Exception(
      'Please include your country code (e.g., +966 for Saudi Arabia, +971 for UAE). '
      'Egyptian numbers should start with 01.',
    );
  }

  /// Verify phone number using Firebase Phone Auth
  /// Returns verificationId on success
  /// Throws exception on failure
  /// Uses sanitizePhoneForFirebase to ensure strict E.164 format (no spaces)
  Future<String> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function() onVerificationCompleted,
    required Function(String error) onVerificationFailed,
    required Function(String error) onCodeAutoRetrievalTimeout,
  }) async {
    try {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('📱 [Auth] verifyPhoneNumber called');
      debugPrint('📱 [Auth] Input phoneNumber: "$phoneNumber"');
      debugPrint('📱 [Auth] Input length: ${phoneNumber.length}');
      debugPrint('📱 [Auth] Input contains spaces: ${phoneNumber.contains(' ')}');
      
      // Use sanitizePhoneForFirebase to ensure exact match with Firebase Console format
      final sanitizedPhone = sanitizePhoneForFirebase(phoneNumber);
      
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('📱 [Auth] FINAL phone number being sent to Firebase:');
      debugPrint('📱 [Auth] Phone: "$sanitizedPhone"');
      debugPrint('📱 [Auth] Length: ${sanitizedPhone.length}');
      debugPrint('📱 [Auth] Format check: ${sanitizedPhone.startsWith('+20') ? 'Egyptian (+20 + 10 digits)' : 'International'}');
      if (sanitizedPhone.startsWith('+20')) {
        final digitsAfter20 = sanitizedPhone.substring(3);
        debugPrint('📱 [Auth] Digits after +20: "$digitsAfter20" (${digitsAfter20.length} digits)');
        debugPrint('📱 [Auth] Expected format: +20XXXXXXXXXX (13 characters total: 1 for +, 2 for 20, 10 for digits)');
        debugPrint('📱 [Auth] Matches Firebase Console: ${sanitizedPhone.length == 13 && digitsAfter20.length == 10 ? '✅ YES' : '❌ NO'}');
        debugPrint('');
        debugPrint('📱 [Auth] Format Explanation:');
        debugPrint('   - Firebase Console DISPLAYS: "+20 10 64448681" (with spaces for readability)');
        debugPrint('   - We SEND: "+201064448681" (E.164 format, no spaces)');
        debugPrint('   - This is CORRECT - Firebase Phone Auth accepts E.164 format');
        debugPrint('   - Firebase internally normalizes and matches test numbers');
      }
      debugPrint('═══════════════════════════════════════════════════════');

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: sanitizedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('✅ [Auth] Phone verification auto-completed');
          debugPrint('✅ [Auth] Phone used: "$sanitizedPhone"');
          onVerificationCompleted();
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('❌ [Auth] Phone verification failed');
          debugPrint('❌ [Auth] Phone used: "$sanitizedPhone"');
          debugPrint('❌ [Auth] Error code: ${e.code}');
          debugPrint('❌ [Auth] Error message: ${e.message}');
          onVerificationFailed(e.message ?? 'Verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('✅ [Auth] SMS code sent successfully');
          debugPrint('✅ [Auth] Phone used: "$sanitizedPhone"');
          debugPrint('✅ [Auth] VerificationId: $verificationId');
          debugPrint('✅ [Auth] VerificationId length: ${verificationId.length}');
          debugPrint('✅ [Auth] ResendToken: $resendToken');
          debugPrint('═══════════════════════════════════════════════════════');
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('⏱️ [Auth] Code auto-retrieval timeout');
          debugPrint('⏱️ [Auth] Phone used: "$sanitizedPhone"');
          debugPrint('⏱️ [Auth] VerificationId: $verificationId');
          onCodeAutoRetrievalTimeout('Code auto-retrieval timeout');
        },
        timeout: const Duration(seconds: 60),
      );

      // Return a placeholder - actual verificationId comes from callback
      return '';
    } catch (e) {
      debugPrint('❌ [Auth] Error in verifyPhoneNumber: $e');
      debugPrint('❌ [Auth] Input phoneNumber was: "$phoneNumber"');
      throw Exception('Failed to send verification code: $e');
    }
  }

  /// Verify phone OTP with Firebase and update backend
  /// Returns success status
  /// Includes timeout and network resilience
  Future<Map<String, dynamic>> verifyPhoneOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('📱 [Auth] verifyPhoneOTP called');
      debugPrint('📱 [Auth] VerificationId: $verificationId');
      debugPrint('📱 [Auth] VerificationId length: ${verificationId.length}');
      debugPrint('📱 [Auth] SMS Code: $smsCode');
      debugPrint('📱 [Auth] SMS Code length: ${smsCode.length}');
      debugPrint('═══════════════════════════════════════════════════════');

      // Create credential from verification ID and SMS code
      // CRITICAL: Use the exact verificationId passed from VerificationScreen
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      
      debugPrint('📱 [Auth] PhoneAuthCredential created');
      debugPrint('📱 [Auth] Using VerificationId: $verificationId');

      // Sign in with credential to verify (with timeout)
      final userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential)
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              throw TimeoutException('Firebase verification timed out');
            },
          );
      
      debugPrint('✅ [Auth] Firebase phone verification successful');
      debugPrint('   User ID: ${userCredential.user?.uid}');

      // Get Firebase ID token (with timeout)
      final idToken = await userCredential.user
          ?.getIdToken()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Failed to get Firebase ID token');
            },
          );
      if (idToken == null) {
        throw Exception('Failed to get Firebase ID token');
      }

      // Call backend API to set isVerified: true (with timeout)
      // Send Firebase ID token in Authorization header for backend authentication
      // Also include it in body for backend to verify and extract user info
      // NOTE: Backend call is optional - if Firebase verification succeeded, we continue
      // even if backend call fails (e.g., 401, network issues)
      debugPrint('📤 [Auth] Calling backend /auth/verify-phone');
      debugPrint('📤 [Auth] Sending Firebase ID token in Authorization header');
      
      Map<String, dynamic>? backendResponse;
      try {
        backendResponse = await _apiService
            .patch(
              '/auth/verify-phone',
              data: {
                'firebaseIdToken': idToken,
              },
              headers: {
                'Authorization': 'Bearer $idToken',
              },
            )
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                throw TimeoutException('Backend verification timed out');
              },
            );

        debugPrint('✅ [Auth] Backend verification update successful');
      } on ApiException catch (e) {
        // Backend call failed, but Firebase verification succeeded
        // Log warning but continue - Firebase verification is the critical part
        debugPrint('⚠️ [Auth] Backend verification failed (${e.statusCode}): ${e.message}');
        debugPrint('⚠️ [Auth] Continuing anyway since Firebase verification succeeded');
        // Don't throw - Firebase verification succeeded, so we proceed
      } catch (e) {
        // Other errors (timeout, network, etc.)
        debugPrint('⚠️ [Auth] Backend verification error: $e');
        debugPrint('⚠️ [Auth] Continuing anyway since Firebase verification succeeded');
        // Don't throw - Firebase verification succeeded, so we proceed
      }

      // Sign out from Firebase (we only use it for verification)
      await FirebaseAuth.instance.signOut().catchError((e) {
        debugPrint('⚠️ [Auth] Error signing out from Firebase: $e');
        // Don't throw - signing out is not critical
      });

      // Return success since Firebase verification succeeded
      // Include backend response if available, otherwise return minimal success response
      return {
        'success': true,
        'message': 'Phone verified successfully',
        'firebaseVerified': true, // Flag to indicate Firebase verification succeeded
        if (backendResponse != null) ...backendResponse,
      };
    } on TimeoutException catch (e) {
      debugPrint('⏱️ [Auth] Verification timeout: ${e.message}');
      throw ApiException(
        'Connection timeout. Please check your internet and try again.',
        statusCode: 408,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ [Auth] Firebase verification error: ${e.code} - ${e.message}');
      
      String errorMessage = 'Verification failed. Please try again.';
      if (e.code == 'invalid-verification-code') {
        errorMessage = 'Invalid code. Please try again.';
      } else if (e.code == 'session-expired') {
        errorMessage = 'Code expired. Please request a new one.';
      } else if (e.code == 'network-request-failed') {
        errorMessage = 'Network error. Please check your connection and try again.';
      }

      throw ApiException(errorMessage, statusCode: 400);
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('❌ [Auth] Error verifying phone OTP: $e');
      if (e.toString().contains('SocketException') ||
          e.toString().contains('network')) {
        throw ApiException(
          'Network error. Please check your connection and try again.',
          statusCode: 0,
        );
      }
      throw Exception('Failed to verify phone: $e');
    }
  }

  /// Verify email OTP with backend
  /// Returns success status
  /// Includes timeout and network resilience
  Future<Map<String, dynamic>> verifyEmailOTP({
    required String username,
    required String otp,
  }) async {
    try {
      debugPrint('📧 [Auth] Verifying email OTP for: $username');

      final response = await _apiService
          .post(
            '/auth/verify-otp',
            data: {
              'username': username,
              'otp': otp,
            },
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('Email verification timed out');
            },
          );

      debugPrint('✅ [Auth] Email OTP verification successful');
      return response;
    } on TimeoutException catch (e) {
      debugPrint('⏱️ [Auth] Email verification timeout: ${e.message}');
      throw ApiException(
        'Connection timeout. Please check your internet and try again.',
        statusCode: 408,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('❌ [Auth] Error verifying email OTP: $e');
      if (e.toString().contains('SocketException') ||
          e.toString().contains('network')) {
        throw ApiException(
          'Network error. Please check your connection and try again.',
          statusCode: 0,
        );
      }
      throw Exception('Failed to verify email OTP: $e');
    }
  }

  /// Notify backend that verification flow completed successfully
  /// Endpoint: POST /api/auth/verify-success
  /// Request body: {'userId': userId}
  /// Uses current JWT token in Authorization header.
  Future<Map<String, dynamic>> verifySuccess(String userId) async {
    try {
      debugPrint('✅ [Auth] Notifying backend of verification success for userId: $userId');
      final response = await _apiService.post(
        '/auth/verify-success',
        data: {'userId': userId},
      );
      return response;
    } on ApiException {
      // Let UI handle ApiException with proper messaging
      rethrow;
    } catch (e) {
      debugPrint('❌ [Auth] Error in verifySuccess: $e');
      throw Exception('Failed to complete verification: $e');
    }
  }

  /// Resend phone verification code
  Future<void> resendPhoneVerification({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onVerificationFailed,
  }) async {
    try {
      await verifyPhoneNumber(
        phoneNumber: phoneNumber,
        onCodeSent: onCodeSent,
        onVerificationCompleted: () {},
        onVerificationFailed: onVerificationFailed,
        onCodeAutoRetrievalTimeout: (error) {},
      );
    } catch (e) {
      debugPrint('❌ [Auth] Error resending phone verification: $e');
      rethrow;
    }
  }

  /// Resend email OTP
  Future<void> resendEmailOTP(String email) async {
    try {
      debugPrint('📧 [Auth] Resending email OTP to: $email');

      await _apiService.post(
        '/auth/resend-otp',
        data: {'email': email},
      );

      debugPrint('✅ [Auth] Email OTP resent successfully');
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('❌ [Auth] Error resending email OTP: $e');
      throw Exception('Failed to resend email OTP: $e');
    }
  }
}
