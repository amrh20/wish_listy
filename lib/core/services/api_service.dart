import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/main.dart';

/// High-level classification of API errors (used by UI to show the right state)
enum ApiErrorKind {
  noInternet,
  timeout,
  server,
  unauthorized,
  notFound,
  validation,
  unknown,
}

/// API Service - Main service for handling all HTTP requests
/// This service uses Dio for advanced HTTP operations with interceptors
/// and comprehensive error handling
class ApiService {
  /// Global connectivity hint for UI (e.g., hide bottom navigation when offline).
  /// We flip this to true when requests fail with a connectivity error, and back
  /// to false on any successful request.
  static final ValueNotifier<bool> isOffline = ValueNotifier<bool>(false);

  // Backend API Base URL
  // Production API endpoint on Render.com
  static String get _baseUrl {
    // Use the production API URL for all platforms
    return 'https://wish-listy-backend.onrender.com/api';
  }

  /// Public base URL used by Dio (includes `/api`)
  /// Useful for other services (e.g., Socket) to stay in sync with API host/port.
  static String get baseUrl => _baseUrl;

  /// Public base URI parsed from [baseUrl]
  static Uri get baseUri => Uri.parse(baseUrl);

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
      debugPrint('🌐 ApiService baseUrl: $baseUrl');
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

      // 401 Unauthorized interceptor - handles token expiration and invalid tokens
      InterceptorsWrapper(
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            debugPrint('🔒 [ApiService] 401 Unauthorized detected - clearing auth and redirecting to login');
            
            // Skip 401 handling for auth endpoints to avoid infinite loops
            final path = error.requestOptions.path.toLowerCase();
            if (path.contains('/auth/login') || 
                path.contains('/auth/register') || 
                path.contains('/auth/logout')) {
              debugPrint('🔒 [ApiService] Skipping 401 handler for auth endpoint: $path');
              handler.next(error);
              return;
            }
            
            // Clear auth token immediately
            clearAuthToken();
            
            // Clear auth data from AuthRepository (silent logout without API calls)
            try {
              final authRepository = AuthRepository();
              authRepository.logoutSilently();
            } catch (e) {
              debugPrint('⚠️ [ApiService] Error during silent logout: $e');
            }
            
            // Redirect to login screen if navigator is available
            try {
              final navigatorKey = MyApp.navigatorKey;
              if (navigatorKey.currentContext != null) {
                final context = navigatorKey.currentContext!;
                // Use post-frame callback to ensure navigation happens after error handling
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (navigatorKey.currentContext != null) {
                    Navigator.of(navigatorKey.currentContext!).pushNamedAndRemoveUntil(
                      AppRoutes.login,
                      (route) => false,
                    );
                    debugPrint('✅ [ApiService] Redirected to login screen');
                  }
                });
              }
            } catch (e) {
              debugPrint('⚠️ [ApiService] Error redirecting to login: $e');
            }
          }
          handler.next(error);
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

  static ApiErrorKind _classifyDioException(DioException e) {
    final statusCode = e.response?.statusCode;

    // 1) True offline / DNS / host lookup errors.
    if (e.type == DioExceptionType.connectionError) {
      return ApiErrorKind.noInternet;
    }

    // Some platforms throw unknown with a SocketException message (avoid dart:io import).
    final msg = (e.message ?? '').toLowerCase();
    final err = (e.error ?? '').toString().toLowerCase();
    if (e.type == DioExceptionType.unknown &&
        (msg.contains('socketexception') ||
            err.contains('socketexception') ||
            msg.contains('failed host lookup') ||
            err.contains('failed host lookup') ||
            msg.contains('network is unreachable') ||
            err.contains('network is unreachable'))) {
      return ApiErrorKind.noInternet;
    }

    // 2) Timeouts (often look like connectivity issues too).
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return ApiErrorKind.timeout;
    }

    // 3) HTTP status-based classification.
    if (statusCode != null) {
      if (statusCode == 401) return ApiErrorKind.unauthorized;
      if (statusCode == 404) return ApiErrorKind.notFound;
      if (statusCode == 422) return ApiErrorKind.validation;
      if (statusCode >= 500) return ApiErrorKind.server;
    }

    return ApiErrorKind.unknown;
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
      isOffline.value = false;
      return response.data;
    } on DioException catch (e) {
      final kind = _classifyDioException(e);
      isOffline.value = kind == ApiErrorKind.noInternet;
      final data = e.response?.data;
      final msg = kind == ApiErrorKind.noInternet
          ? 'No Internet Connection'
          : _extractBackendMessage(data);
      throw ApiException(
        msg,
        statusCode: e.response?.statusCode,
        data: data,
        kind: kind,
      );
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
      isOffline.value = false;
      return response.data;
    } on DioException catch (e) {
      final kind = _classifyDioException(e);
      isOffline.value = kind == ApiErrorKind.noInternet;
      final resData = e.response?.data;
      final msg = kind == ApiErrorKind.noInternet
          ? 'No Internet Connection'
          : _extractBackendMessage(resData);
      throw ApiException(
        msg,
        statusCode: e.response?.statusCode,
        data: resData,
        kind: kind,
      );
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
      isOffline.value = false;
      return response.data;
    } on DioException catch (e) {
      final kind = _classifyDioException(e);
      isOffline.value = kind == ApiErrorKind.noInternet;
      final resData = e.response?.data;
      final msg = kind == ApiErrorKind.noInternet
          ? 'No Internet Connection'
          : _extractBackendMessage(resData);
      throw ApiException(
        msg,
        statusCode: e.response?.statusCode,
        data: resData,
        kind: kind,
      );
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
      isOffline.value = false;
      return response.data;
    } on DioException catch (e) {
      final kind = _classifyDioException(e);
      isOffline.value = kind == ApiErrorKind.noInternet;
      final resData = e.response?.data;
      final msg = kind == ApiErrorKind.noInternet
          ? 'No Internet Connection'
          : _extractBackendMessage(resData);
      throw ApiException(
        msg,
        statusCode: e.response?.statusCode,
        data: resData,
        kind: kind,
      );
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
      isOffline.value = false;
      return response.data;
    } on DioException catch (e) {
      final kind = _classifyDioException(e);
      isOffline.value = kind == ApiErrorKind.noInternet;
      final data = e.response?.data;
      final msg = kind == ApiErrorKind.noInternet
          ? 'No Internet Connection'
          : _extractBackendMessage(data);
      throw ApiException(
        msg,
        statusCode: e.response?.statusCode,
        data: data,
        kind: kind,
      );
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  /// Generic POST request method for multipart/form-data
  /// Used for uploading files (images, documents, etc.)
  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Map<String, dynamic> fields,
    String? fileKey,
    String? filePath,
    Map<String, String>? headers,
  }) async {
    try {
      // Create FormData
      final formData = FormData();

      // Add form fields
      fields.forEach((key, value) {
        formData.fields.add(MapEntry(key, value.toString()));
      });

      // Add file if provided
      if (fileKey != null && filePath != null) {
        final fileName = filePath.split('/').last;
        formData.files.add(
          MapEntry(
            fileKey,
            await MultipartFile.fromFile(
              filePath,
              filename: fileName,
            ),
          ),
        );
      }

      // Merge custom headers with default headers
      final requestHeaders = <String, dynamic>{};
      if (headers != null) {
        requestHeaders.addAll(headers);
      }

      final response = await _dio.post(
        path,
        data: formData,
        options: Options(
          headers: requestHeaders,
          contentType: 'multipart/form-data',
        ),
      );

      isOffline.value = false;
      return response.data;
    } on DioException catch (e) {
      final kind = _classifyDioException(e);
      isOffline.value = kind == ApiErrorKind.noInternet;
      final resData = e.response?.data;
      final msg = kind == ApiErrorKind.noInternet
          ? 'No Internet Connection'
          : _extractBackendMessage(resData);
      throw ApiException(
        msg,
        statusCode: e.response?.statusCode,
        data: resData,
        kind: kind,
      );
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  /// Generic PUT request method for multipart/form-data
  /// Used for updating data with file uploads (profile image edit, etc.)
  Future<Map<String, dynamic>> putMultipart(
    String path, {
    required Map<String, dynamic> fields,
    String? fileKey,
    String? filePath,
    Map<String, String>? headers,
  }) async {
    try {
      // Create FormData
      final formData = FormData();

      // Add form fields
      fields.forEach((key, value) {
        if (value != null) {
          formData.fields.add(MapEntry(key, value.toString()));
        }
      });

      // Add file if provided
      if (fileKey != null && filePath != null) {
        final fileName = filePath.split('/').last;
        formData.files.add(
          MapEntry(
            fileKey,
            await MultipartFile.fromFile(
              filePath,
              filename: fileName,
            ),
          ),
        );
      }

      // Merge custom headers with default headers
      final requestHeaders = <String, dynamic>{};
      if (headers != null) {
        requestHeaders.addAll(headers);
      }

      final response = await _dio.put(
        path,
        data: formData,
        options: Options(
          headers: requestHeaders,
          contentType: 'multipart/form-data',
        ),
      );

      isOffline.value = false;
      return response.data;
    } on DioException catch (e) {
      final kind = _classifyDioException(e);
      isOffline.value = kind == ApiErrorKind.noInternet;
      final resData = e.response?.data;
      final msg = kind == ApiErrorKind.noInternet
          ? 'No Internet Connection'
          : _extractBackendMessage(resData);
      throw ApiException(
        msg,
        statusCode: e.response?.statusCode,
        data: resData,
        kind: kind,
      );
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
  final ApiErrorKind kind;

  ApiException(
    String message, {
    this.statusCode,
    this.data,
    this.kind = ApiErrorKind.unknown,
  }) : message = _sanitizeMessage(_extractMessageFromData(data) ?? message);

  bool get isNoInternet => kind == ApiErrorKind.noInternet;
  bool get isTimeout => kind == ApiErrorKind.timeout;

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
