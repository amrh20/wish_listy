import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// API Service - Main service for handling all HTTP requests
/// This service uses Dio for advanced HTTP operations with interceptors
/// and comprehensive error handling
class ApiService {
  // Backend API Base URL
  // Automatically detects the correct URL based on platform:
  // - Android Emulator: 10.0.2.2 (special IP that maps to host's localhost)
  // - Android Physical Device: Use your computer's IP address (e.g., 192.168.1.100)
  // - iOS Simulator: localhost (works directly)
  // - Web: localhost (works directly)
  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static bool get _isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static String get _baseUrl {
    if (kIsWeb) {
      // Web platform
      return 'http://localhost:4000/api';
    }

    if (_isAndroid) {
      // Android Emulator uses 10.0.2.2 to access host machine's localhost
      // For physical Android device, use your computer's IP address
      //
      // TO FIX CONNECTION REFUSED ON PHYSICAL DEVICE:
      // 1. Find your computer's IP: ifconfig (Mac/Linux) or ipconfig (Windows)
      // 2. Replace the IP below with your computer's IP (e.g., 192.168.1.3)
      // 3. Make sure backend listens on 0.0.0.0, not just localhost
      // 4. Ensure both devices are on the same WiFi network
      // 5. Check firewall settings on your computer
      //
      // For Emulator: use 'http://10.0.2.2:4000/api'
      // For Physical Device: use 'http://YOUR_COMPUTER_IP:4000/api'
      
      // TODO: UPDATE THIS IP ADDRESS TO MATCH YOUR COMPUTER'S IP
      // Find your IP with: 
      //   - Mac/Linux: ifconfig | grep "inet " | grep -v 127.0.0.1
      //   - Windows: ipconfig | findstr IPv4
      //   - Or check your router's connected devices list
      
      // Try to detect if running on emulator or physical device
      // For Emulator: use '10.0.2.2'
      // For Physical Device: use your computer's IP address (found: 192.168.1.5)
      // 
      // To find your IP: ifconfig (Mac/Linux) or ipconfig (Windows)
      // Make sure both your computer and phone are on the same WiFi network!
      
      const String androidIP = '192.168.1.11'; // Physical device - Your computer's IP
      // const String androidIP = '10.0.2.2'; // Uncomment for Android Emulator
      
      final url = 'http://$androidIP:4000/api';

      return url;
    }

    if (_isIOS) {
      // iOS Simulator - localhost works directly
      return 'http://localhost:4000/api';
    }

    // Default fallback
    return 'http://localhost:4000/api';
  }

  // Singleton pattern to ensure single instance across the app
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _initializeDio();
  }

  late Dio _dio;

  /// Initialize Dio with base configuration and interceptors
  void _initializeDio() {
    final baseUrl = _baseUrl;

    // Log the base URL in debug mode for troubleshooting
    if (kDebugMode) {

    }

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(
          seconds: 60,
        ), // 60 seconds timeout for physical devices
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors for logging and error handling
    _dio.interceptors.addAll([
      // Custom logging interceptor - only in debug mode
      // Filters out wishlists requests to reduce console noise
      if (kDebugMode)
        InterceptorsWrapper(
          onRequest: (options, handler) {
            // Skip logging for wishlists endpoints
            if (!options.path.contains('/wishlists') && 
                !options.path.contains('/items')) {
              debugPrint('┌─────────────────────────────────────────────────────────');
              debugPrint('│ REQUEST: ${options.method} ${options.path}');
              debugPrint('│ Headers: ${options.headers}');
              if (options.data != null) {
                debugPrint('│ Body: ${options.data}');
              }
              if (options.queryParameters.isNotEmpty) {
                debugPrint('│ Query: ${options.queryParameters}');
              }
              debugPrint('└─────────────────────────────────────────────────────────');
            }
            handler.next(options);
          },
          onResponse: (response, handler) {
            // Skip logging for wishlists endpoints
            if (!response.requestOptions.path.contains('/wishlists') && 
                !response.requestOptions.path.contains('/items')) {
              debugPrint('┌─────────────────────────────────────────────────────────');
              debugPrint('│ RESPONSE: ${response.requestOptions.method} ${response.requestOptions.path}');
              debugPrint('│ Status: ${response.statusCode}');
              debugPrint('│ Headers: ${response.headers}');
              debugPrint('│ Data: ${response.data}');
              debugPrint('└─────────────────────────────────────────────────────────');
            }
            handler.next(response);
          },
          onError: (error, handler) {
            // Skip logging for wishlists endpoints
            if (!error.requestOptions.path.contains('/wishlists') && 
                !error.requestOptions.path.contains('/items')) {
              debugPrint('┌─────────────────────────────────────────────────────────');
              debugPrint('│ ERROR: ${error.requestOptions.method} ${error.requestOptions.path}');
              debugPrint('│ Type: ${error.type}');
              debugPrint('│ Message: ${error.message}');
              if (error.response != null) {
                debugPrint('│ Status: ${error.response?.statusCode}');
                debugPrint('│ Data: ${error.response?.data}');
              }
              debugPrint('└─────────────────────────────────────────────────────────');
            }
            handler.next(error);
          },
        ),

      // Error handling interceptor
      InterceptorsWrapper(
        onError: (error, handler) {
          _handleError(error);
          handler.next(error);
        },
      ),
    ]);
  }

  /// Handle different types of errors and convert them to user-friendly messages
  void _handleError(DioException error) {
    // Enhanced error logging for debugging
    if (kDebugMode) {

      if (error.response != null) {

      }
      if (error.type == DioExceptionType.connectionError) {


      }
    }
    
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw ApiException(
          'Connection timeout. Please check your internet connection and ensure the server is running.',
        );
      
      case DioExceptionType.connectionError:
        throw ApiException(
          'Cannot connect to server. Please check:\n'
          '1. Backend server is running\n'
          '2. Correct IP address in API settings\n'
          '3. Both devices on same WiFi network\n'
          '4. Firewall is not blocking the connection',
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;

        // Log detailed error information in debug mode
        if (kDebugMode) {

          if (error.response?.headers != null) {

            final headers = error.response!.headers;
            final headerKeys = <String>[];
            headers.forEach((key, values) {

              headerKeys.add(key.toLowerCase());
            });
            // Check for CORS headers specifically
            final corsHeaders = [
              'access-control-allow-origin',
              'access-control-allow-methods',
              'access-control-allow-headers',
              'access-control-allow-credentials',
            ];
            final missingCors = corsHeaders
                .where((h) => !headerKeys.contains(h.toLowerCase()))
                .toList();
            if (missingCors.isNotEmpty && statusCode == 403) {

            }
          } else {

          }
          if (data == null || (data is String && data.isEmpty)) {

          }
        }

        // Extract error message from response
        String? errorMessage;
        if (data != null) {
          if (data is Map<String, dynamic>) {
            errorMessage =
                data['message'] ??
                data['error'] ??
                data['msg'] ??
                data['errorMessage'] ??
                data['errors']?.toString();

            // Try to extract from errors object if it's a map
            if (errorMessage == null && data['errors'] is Map) {
              final errors = data['errors'] as Map;
              if (errors.isNotEmpty) {
                final firstError = errors.values.first;
                errorMessage = firstError?.toString();
              }
            }
          } else if (data is String && data.isNotEmpty) {
            errorMessage = data;
          }
        }

        // Log extracted error message for debugging
        if (kDebugMode) {
          debugPrint('🌐 [API] Error message extracted: $errorMessage');
          debugPrint('🌐 [API] Response data: $data');
        }

        if (statusCode == 400) {
          throw ApiException(
            errorMessage ?? 'Bad request. Please check your input.',
            statusCode: statusCode,
            data: data,
          );
        } else if (statusCode == 401) {
          throw ApiException(
            errorMessage ?? 'Unauthorized. Please login again.',
            statusCode: statusCode,
            data: data,
          );
        } else if (statusCode == 403) {
          // 403 could be CORS, authentication, or permission issue
          String message;
          if (errorMessage != null && errorMessage.isNotEmpty) {
            // Use backend error message if available
            message = errorMessage;
          } else {
            // Check if response body is empty (common with CORS issues)
            final isResponseEmpty =
                data == null ||
                (data is String && data.isEmpty) ||
                (data is Map && data.isEmpty);

            if (isResponseEmpty) {
              message =
                  'Access Denied (403) - Empty Response.\n'
                  'This is usually a CORS issue:\n'
                  '1. Add CORS middleware to your backend\n'
                  '2. Allow origin: * or http://localhost:4000\n'
                  '3. Restart backend server\n'
                  '\nBackend example:\n'
                  'const cors = require(\'cors\');\n'
                  'app.use(cors({ origin: \'*\' }));';

              if (kDebugMode) {

              }
            } else {
              // Response has content but no error message
              message =
                  'Access Denied (403). Possible causes:\n'
                  '• CORS not configured in backend\n'
                  '• Backend validation failed\n'
                  '• Missing required headers\n'
                  '• Check backend logs for details';

              if (kDebugMode) {

              }
            }
          }
          throw ApiException(message, statusCode: statusCode, data: data);
        } else if (statusCode == 404) {
          throw ApiException(
            errorMessage ?? 'Resource not found.',
            statusCode: statusCode,
            data: data,
          );
        } else if (statusCode == 422) {
          throw ApiException(
            errorMessage ?? 'Validation error. Please check your input.',
            statusCode: statusCode,
            data: data,
          );
        } else if (statusCode == 500) {
          throw ApiException(
            errorMessage ?? 'Server error. Please try again later.',
            statusCode: statusCode,
            data: data,
          );
        } else {
          throw ApiException(
            errorMessage ?? 'An error occurred. Please try again.',
            statusCode: statusCode,
            data: data,
          );
        }

      case DioExceptionType.cancel:
        throw ApiException('Request was cancelled.');

      case DioExceptionType.connectionError:
        // Provide more helpful error message for connection errors
        final errorMessage = error.message ?? '';
        if (errorMessage.contains('Connection refused') ||
            errorMessage.contains('Failed host lookup')) {
          if (_isAndroid) {
            throw ApiException(
              'Cannot connect to server. Make sure:\n'
              '1. Backend is running on port 4000\n'
              '2. For physical device, use your computer\'s IP address\n'
              '3. Both devices are on the same network',
            );
          } else {
            throw ApiException(
              'Cannot connect to server. Make sure backend is running on port 4000.',
            );
          }
        }
        throw ApiException(
          'No internet connection. Please check your network.',
        );

      case DioExceptionType.badCertificate:
        throw ApiException('Security error. Please try again.');

      case DioExceptionType.unknown:
        throw ApiException('An unexpected error occurred. Please try again.');
    }
  }

  /// Generic GET request method
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      return response.data;
    } on DioException {
      rethrow; // Let the interceptor handle the error
    }
  }

  /// Generic POST request method
  Future<Map<String, dynamic>> post(
    String path, {
    dynamic data,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        options: Options(headers: headers),
      );
      return response.data;
    } on DioException {
      rethrow; // Let the interceptor handle the error
    }
  }

  /// Generic PUT request method
  Future<Map<String, dynamic>> put(
    String path, {
    dynamic data,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        options: Options(headers: headers),
      );
      return response.data;
    } on DioException {
      rethrow; // Let the interceptor handle the error
    }
  }

  /// Generic PATCH request method
  Future<Map<String, dynamic>> patch(
    String path, {
    dynamic data,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
        options: Options(headers: headers),
      );
      return response.data;
    } on DioException {
      rethrow; // Let the interceptor handle the error
    }
  }

  /// Generic DELETE request method
  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        options: Options(headers: headers),
      );
      return response.data;
    } on DioException {
      rethrow; // Let the interceptor handle the error
    }
  }

  /// Set authorization header for authenticated requests
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Remove authorization header
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  /// Get the Dio instance for advanced operations
  Dio get dio => _dio;

  /// Get dashboard data for Home Screen
  /// Uses /api/dashboard/home endpoint which returns latestActivityPreview (max 3 items)
  Future<Map<String, dynamic>> getDashboardData() async {
    return await get('/dashboard/home');
  }

  /// Get activities with pagination
  /// Uses /api/activities endpoint with pagination support
  /// [page] - Page number (starts from 1)
  /// [limit] - Number of items per page (default: 10)
  Future<Map<String, dynamic>> getActivities({
    int page = 1,
    int limit = 10,
  }) async {
    return await get(
      '/activities',
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );
  }

  /// Get friend activity feed
  /// Note: Uses /dashboard/home endpoint which returns all friendActivity data
  Future<Map<String, dynamic>> getFriendActivity() async {
    return await get('/dashboard/home');
  }
}

/// Custom exception class for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => 'ApiException: $message';
}
