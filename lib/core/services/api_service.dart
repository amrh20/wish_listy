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
      
      const String androidIP = '192.168.1.5'; // Physical device - Your computer's IP
      // const String androidIP = '10.0.2.2'; // Uncomment for Android Emulator
      
      final url = 'http://$androidIP:4000/api';
      
      if (kDebugMode) {
        debugPrint('🔗 ANDROID API URL: $url');
        debugPrint('📱 Device Type: Physical Device (Samsung)');
        debugPrint('⚠️ If login fails, check:');
        debugPrint('   1. Is backend server running on port 4000?');
        debugPrint('   2. Is IP address correct? (Current: $androidIP)');
        debugPrint('   3. Are both devices on same WiFi network?');
        debugPrint('   4. Is firewall blocking port 4000?');
        debugPrint('   5. Backend should listen on 0.0.0.0, not just localhost');
      }
      
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
      debugPrint('🔗 API Base URL: $baseUrl');
      debugPrint(
        '📱 Platform: ${kIsWeb
            ? "Web"
            : _isAndroid
            ? "Android"
            : _isIOS
            ? "iOS"
            : "Other"}',
      );
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
      // Logging interceptor - only in debug mode
      if (kDebugMode)
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: true,
          responseHeader: true, // Show response headers for debugging
          error: true, // Show error details
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
      debugPrint('🔴 API Error Details:');
      debugPrint('   Type: ${error.type}');
      debugPrint('   Message: ${error.message}');
      debugPrint('   URL: ${error.requestOptions.uri}');
      if (error.response != null) {
        debugPrint('   Status Code: ${error.response?.statusCode}');
        debugPrint('   Response: ${error.response?.data}');
      }
      if (error.type == DioExceptionType.connectionError) {
        debugPrint('   ⚠️ Connection Error - Check:');
        debugPrint('      - Is backend server running?');
        debugPrint('      - Is IP address correct? (Current: ${_baseUrl})');
        debugPrint('      - Are devices on same network?');
        debugPrint('      - Is firewall blocking connection?');
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
          debugPrint('❌ API Error [${statusCode}]:');
          debugPrint('   URL: ${error.requestOptions.uri}');
          debugPrint('   Method: ${error.requestOptions.method}');
          debugPrint('   Request Headers: ${error.requestOptions.headers}');
          debugPrint('   Request Data: ${error.requestOptions.data}');
          debugPrint('   Response Status Code: ${error.response?.statusCode}');
          debugPrint(
            '   Response Status Message: ${error.response?.statusMessage}',
          );
          debugPrint('   Response Data: $data');
          debugPrint('   Response Data Type: ${data?.runtimeType}');
          if (error.response?.headers != null) {
            debugPrint('   Response Headers:');
            final headers = error.response!.headers;
            final headerKeys = <String>[];
            headers.forEach((key, values) {
              debugPrint('      $key: $values');
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
              debugPrint('   ⚠️  Missing CORS Headers: $missingCors');
              debugPrint(
                '   💡 This suggests a CORS configuration issue in the backend',
              );
            }
          } else {
            debugPrint('   ⚠️  No response headers available');
          }
          if (data == null || (data is String && data.isEmpty)) {
            debugPrint(
              '   ⚠️  Empty response body - This often indicates a CORS issue!',
            );
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
          debugPrint(
            '   📝 Extracted Error Message: ${errorMessage ?? "No error message found"}',
          );
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
                debugPrint('⚠️  403 Error - Empty response body detected');
                debugPrint(
                  '   This strongly indicates a CORS configuration issue in the backend',
                );
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
                debugPrint(
                  '⚠️  403 Error - Response body exists but no error message found',
                );
                debugPrint('   Response: $data');
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
