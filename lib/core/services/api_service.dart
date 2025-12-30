import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      // iOS Physical Device - use Mac's IP address
      // iOS Simulator can use localhost, but for physical device we need Mac's IP
      // Note: On physical iPhone, localhost refers to the iPhone itself, not the Mac
      // 
      // TO FIX CONNECTION REFUSED ON PHYSICAL iPhone:
      // 1. Find your Mac's IP: ifconfig | grep "inet " | grep -v 127.0.0.1
      // 2. Make sure backend listens on 0.0.0.0, not just localhost
      // 3. Ensure both Mac and iPhone are on the same WiFi network
      // 4. Check firewall settings on your Mac
      //
      // For iOS Simulator: localhost works (can keep using this)
      // For Physical iPhone: use Mac's IP address (found: 192.168.1.11)
      
      const String iosIP = '192.168.1.11'; // Physical iPhone - Your Mac's IP
      // For iOS Simulator, you can use 'localhost' if needed:
      // const String iosIP = 'localhost'; // Uncomment for iOS Simulator
      
      final url = 'http://$iosIP:4000/api';
      return url;
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
  String _storedLanguageCode = 'en'; // Cache language code (default to English)
  
  /// Initialize language code from SharedPreferences
  Future<void> _initializeLanguageCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _storedLanguageCode = prefs.getString('selected_language') ?? 'en';
      _dio.options.headers['Accept-Language'] = _storedLanguageCode;
    } catch (e) {
      _storedLanguageCode = 'en';
      _dio.options.headers['Accept-Language'] = 'en';
    }
  }

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
      // Language header interceptor - adds Accept-Language to all requests
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Use cached language code (initialized on app start)
          options.headers['Accept-Language'] = _storedLanguageCode;
          handler.next(options);
        },
      ),

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

    ]);
  }

  static String _extractBackendMessage(dynamic data) {
    if (data == null) return 'Something went wrong';

    if (data is Map) {
      final dynamic msg =
          data['message'] ?? data['error'] ?? data['msg'] ?? data['errorMessage'];
      final msgStr = msg?.toString().trim();
      if (msgStr != null && msgStr.isNotEmpty) return msgStr;

      final dynamic errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        final firstStr = first?.toString().trim();
        if (firstStr != null && firstStr.isNotEmpty) return firstStr;
      }
      if (errors is List && errors.isNotEmpty) {
        final first = errors.first;
        final firstStr = first?.toString().trim();
        if (firstStr != null && firstStr.isNotEmpty) return firstStr;
      }
    }

    if (data is String) {
      final s = data.trim();
      if (s.isNotEmpty) return s;
    }

    return 'Something went wrong';
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
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = _extractBackendMessage(data);
      throw ApiException(msg, statusCode: e.response?.statusCode, data: data);
    } catch (e) {
      throw ApiException(e.toString());
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
    } on DioException catch (e) {
      final resData = e.response?.data;
      final msg = _extractBackendMessage(resData);
      throw ApiException(msg, statusCode: e.response?.statusCode, data: resData);
    } catch (e) {
      throw ApiException(e.toString());
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
    } on DioException catch (e) {
      final resData = e.response?.data;
      final msg = _extractBackendMessage(resData);
      throw ApiException(msg, statusCode: e.response?.statusCode, data: resData);
    } catch (e) {
      throw ApiException(e.toString());
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
    } on DioException catch (e) {
      final resData = e.response?.data;
      final msg = _extractBackendMessage(resData);
      throw ApiException(msg, statusCode: e.response?.statusCode, data: resData);
    } catch (e) {
      throw ApiException(e.toString());
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
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = _extractBackendMessage(data);
      throw ApiException(msg, statusCode: e.response?.statusCode, data: data);
    } catch (e) {
      throw ApiException(e.toString());
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

  /// Set language code for Accept-Language header
  /// This will be used by the interceptor to add the header to all requests
  void setLanguageCode(String languageCode) {
    _storedLanguageCode = languageCode;
    // Update the default headers
    _dio.options.headers['Accept-Language'] = languageCode;
  }
  
  /// Initialize language code from SharedPreferences
  /// Should be called after LocalizationService is initialized
  Future<void> initializeLanguageCode() async {
    await _initializeLanguageCode();
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

  ApiException(String message, {this.statusCode, this.data})
      : message = _sanitizeMessage(_extractMessageFromData(data) ?? message);

  static String? _extractMessageFromData(dynamic data) {
    try {
      if (data is Map) {
        final dynamic msg =
            data['message'] ?? data['error'] ?? data['msg'] ?? data['errorMessage'];
        if (msg != null) return msg.toString();

        final dynamic errors = data['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first != null) return first.toString();
        }
        if (errors is List && errors.isNotEmpty) {
          final first = errors.first;
          if (first != null) return first.toString();
        }
      }
      if (data is String && data.trim().isNotEmpty) {
        return data;
      }
    } catch (_) {
      // Ignore parsing issues; fall back to provided message
    }
    return null;
  }

  static String _sanitizeMessage(String input) {
    var s = input.trim();

    // Common wrappers seen in Flutter Web / Dart runtime
    s = s.replaceAll(RegExp(r'^Error:\s*'), '');
    s = s.replaceAll(RegExp(r'^ApiException:\s*'), '');
    s = s.replaceAll(RegExp(r'^Exception:\s*'), '');
    s = s.replaceAll(RegExp(r'^DioException\s*\[.*?\]:\s*'), '');

    // Common suffixes / duplicated chains
    s = s.replaceAll(RegExp(r':\s*Error:\s*ApiException.*$'), '');
    s = s.replaceAll(RegExp(r':\s*ApiException.*$'), '');
    s = s.replaceAll(RegExp(r':\s*DioException.*$'), '');

    // Remove stray "null" tokens
    s = s.replaceAll(RegExp(r'\bnull\b'), '').trim();

    return s.trim();
  }

  @override
  String toString() => 'ApiException: $message';
}
