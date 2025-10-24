import '../models/user_model.dart';
import 'api_service.dart';

/// Authentication API Service
/// Handles all authentication-related API calls including:
/// - User registration
/// - User login
/// - Password validation
/// - Email verification
class AuthApiService {
  static final AuthApiService _instance = AuthApiService._internal();
  factory AuthApiService() => _instance;
  AuthApiService._internal();

  final ApiService _apiService = ApiService();

  /// Register a new user
  /// This method sends user registration data to the API
  /// and returns the created user information
  /// API expects: username (email/phone), fullName, password
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
      final response = await _apiService.post(
        '/auth/signup',
        data: registrationData,
      );

      // Return the response data which should contain user info and token
      return response;
    } on ApiException {
      rethrow; // Re-throw API exceptions to be handled by the UI
    } catch (e) {
      // Handle any unexpected errors
      throw ApiException('Registration failed. Please try again.');
    }
  }

  /// Login user with email and password
  /// Returns user data and authentication token
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final loginData = {'email': email, 'password': password};

      final response = await _apiService.post('/auth/login', data: loginData);
      return response;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Login failed. Please try again.');
    }
  }

  /// Validate email format
  /// This is a client-side validation before sending to API
  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  /// Validate phone number format
  /// This is a client-side validation for phone numbers
  bool isValidPhone(String phone) {
    // Remove all non-digit characters
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    // Check if it's a valid phone number (7-25 digits)
    return cleanPhone.length >= 7 && cleanPhone.length <= 25;
  }

  /// Validate username (email or phone)
  /// This checks if the input is either a valid email or phone
  bool isValidUsername(String username) {
    return isValidEmail(username) || isValidPhone(username);
  }

  /// Validate password strength
  /// This is a client-side validation before sending to API
  String? validatePassword(String password) {
    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    return null; // Password is valid
  }

  /// Validate full name
  /// This is a client-side validation before sending to API
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

  /// Validate username (email or phone)
  /// This is a client-side validation before sending to API
  String? validateUsername(String username) {
    if (username.trim().isEmpty) {
      return 'Email or phone number is required';
    }

    if (!isValidUsername(username)) {
      return 'Please enter a valid email address or phone number';
    }

    return null; // Username is valid
  }

  /// Check if email is already registered
  /// This could be used for real-time email validation
  Future<bool> checkEmailAvailability(String email) async {
    try {
      await _apiService.get(
        '/auth/check-email',
        queryParameters: {'email': email},
      );
      return true; // Email is available
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        return false; // Email is already taken
      }
      rethrow;
    } catch (e) {
      throw ApiException('Failed to check email availability');
    }
  }

  /// Send email verification
  /// This sends a verification email to the user
  Future<void> sendEmailVerification(String email) async {
    try {
      await _apiService.post('/auth/send-verification', data: {'email': email});
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to send verification email');
    }
  }

  /// Verify email with token
  /// This verifies the user's email using the token from the email
  Future<void> verifyEmail(String token) async {
    try {
      await _apiService.post('/auth/verify-email', data: {'token': token});
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to verify email');
    }
  }

  /// Forgot password request
  /// This sends a password reset email to the user
  Future<void> forgotPassword(String email) async {
    try {
      await _apiService.post('/auth/forgot-password', data: {'email': email});
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to send password reset email');
    }
  }

  /// Reset password with token
  /// This resets the user's password using the token from the email
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await _apiService.post(
        '/auth/reset-password',
        data: {'token': token, 'password': newPassword},
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to reset password');
    }
  }

  /// Logout user
  /// This clears the authentication token
  Future<void> logout() async {
    try {
      await _apiService.post('/auth/logout');
    } catch (e) {
      // Even if logout fails on server, clear local token
      _apiService.clearAuthToken();
    }
    _apiService.clearAuthToken();
  }

  /// Refresh authentication token
  /// This gets a new token using the refresh token
  Future<Map<String, dynamic>> refreshToken() async {
    try {
      final response = await _apiService.post('/auth/refresh');
      return response;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Failed to refresh token');
    }
  }
}
