import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/core/services/socket_service.dart';

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

  // Getters
  UserState get userState => _userState;
  bool get isGuest => _userState == UserState.guest;
  bool get isAuthenticated => _userState == UserState.authenticated;
  bool get isLoading => _userState == UserState.loading;
  String? get userId => _userId;
  String? get userEmail => _userEmail;
  String? get userName => _userName;

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
          SocketService().connect();
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

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    await prefs.remove('user_id');
    await prefs.remove('user_email');
    await prefs.remove('user_name');

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
      // Re-throw ApiException to preserve error details
      rethrow;
    } catch (e) {
      // Handle any unexpected errors

      throw Exception('Registration failed. Please try again.');
    }
  }

  // Login user with username and password using API
  Future<Map<String, dynamic>> login({
    required String username, // username can be email or phone
    required String password,
  }) async {
    try {
      final loginData = {'username': username, 'password': password};
      final response = await _apiService.post('/auth/login', data: loginData);
      return response;
    } on ApiException {
      // Re-throw ApiException to preserve error details
      rethrow;
    } catch (e) {

      // Convert to ApiException so it can be handled properly
      throw ApiException(
        'Login failed. Please check your connection and try again.',
      );
    }
  }

  // Login with credentials using real API
  Future<bool> loginUser(String username, String password) async {
    try {
      // Call the API to login
      final response = await login(username: username, password: password);

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
        _userName = userData?['fullName'] ?? userData?['name'] ?? username.split('@').first;

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
          // Connect to Socket.IO for real-time notifications
          await SocketService().connect();
        }

        notifyListeners();
        return true;
      } else {
        // Login failed - check for error message in response

        return false;
      }
    } on ApiException catch (e) {
      // Re-throw ApiException so login screen can show proper error message

      rethrow;
    } catch (e) {
      // Handle any unexpected errors

      // Convert to ApiException so it can be handled properly by login screen
      throw ApiException(
        'Login failed. Please check your connection and try again.',
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
          // Connect to Socket.IO for real-time notifications
          await SocketService().connect();
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
    try {
      // Disconnect from Socket.IO
      SocketService().disconnect();
      
      // Call API to logout
      await _apiService.post('/auth/logout');
    } catch (e) {
      // Even if API logout fails, clear local data
    }

    // Clear local state
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
      final digitsOnly = cleanPhone.substring(1).replaceAll(RegExp(r'[^\d]'), '');
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

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await _apiService.post(
        '/auth/reset-password',
        data: {'token': token, 'password': newPassword},
      );
    } catch (e) {
      throw Exception('Failed to reset password');
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
}
