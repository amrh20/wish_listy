import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// API Service - Main service for handling all HTTP requests
/// This service uses Dio for advanced HTTP operations with interceptors
/// and comprehensive error handling
class ApiService {
  static const String _baseUrl = 'https://e-commerce-api-production-ea9f.up.railway.app/api';
  
  // Singleton pattern to ensure single instance across the app
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _initializeDio();
  }

  late Dio _dio;

  /// Initialize Dio with base configuration and interceptors
  void _initializeDio() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30), // 30 seconds timeout
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptors for logging and error handling
    _dio.interceptors.addAll([
      // Logging interceptor - only in debug mode
      if (kDebugMode)
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: true,
          responseHeader: false,
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
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw ApiException('Connection timeout. Please check your internet connection.');
      
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;
        
        if (statusCode == 400) {
          throw ApiException(data?['message'] ?? 'Bad request. Please check your input.');
        } else if (statusCode == 401) {
          throw ApiException('Unauthorized. Please login again.');
        } else if (statusCode == 403) {
          throw ApiException('Forbidden. You don\'t have permission to access this resource.');
        } else if (statusCode == 404) {
          throw ApiException('Resource not found.');
        } else if (statusCode == 422) {
          throw ApiException(data?['message'] ?? 'Validation error. Please check your input.');
        } else if (statusCode == 500) {
          throw ApiException('Server error. Please try again later.');
        } else {
          throw ApiException('An error occurred. Please try again.');
        }
      
      case DioExceptionType.cancel:
        throw ApiException('Request was cancelled.');
      
      case DioExceptionType.connectionError:
        throw ApiException('No internet connection. Please check your network.');
      
      case DioExceptionType.badCertificate:
        throw ApiException('Security error. Please try again.');
      
      case DioExceptionType.unknown:
      default:
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
