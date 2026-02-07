import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:wish_listy/core/services/api_service.dart';

/// Repository for handling profile image upload and delete operations
class ProfileRepository {
  final ApiService _apiService;

  ProfileRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Upload profile image (first time) using POST /api/upload/profile
  /// Uses field name [profileImage] and multipart/form-data.
  /// [imagePath] - Path to the compressed image file
  /// Returns normalized map with [imageUrl] and [user] for consistent parsing.
  Future<Map<String, dynamic>> uploadProfileImage(String imagePath) async {
    try {
      final response = await _apiService.postMultipart(
        '/upload/profile',
        fields: {},
        fileKey: 'profileImage',
        filePath: imagePath,
      );

      return _normalizeProfileImageResponse(response);
    } on ApiException {
      rethrow;
    } on SocketException catch (e) {
      throw ApiException(
        'No internet connection. Please check your network and try again.',
        kind: ApiErrorKind.noInternet,
      );
    } on FormatException catch (e) {
      throw ApiException(
        'Invalid response from server. Please try again.',
        kind: ApiErrorKind.unknown,
      );
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  /// Edit/Update existing profile image using PUT /api/auth/profile/edit
  /// Uses field name [image] and multipart/form-data.
  /// [imagePath] - Path to the compressed image file
  /// Returns normalized map with [imageUrl] and [user] for consistent parsing.
  Future<Map<String, dynamic>> editProfileImage(String imagePath) async {
    try {
      final response = await _apiService.putMultipart(
        '/auth/profile/edit',
        fields: {},
        fileKey: 'image',
        filePath: imagePath,
      );

      return _normalizeProfileImageResponse(response);
    } on ApiException {
      rethrow;
    } on SocketException catch (e) {
      throw ApiException(
        'No internet connection. Please check your network and try again.',
        kind: ApiErrorKind.noInternet,
      );
    } on FormatException catch (e) {
      throw ApiException(
        'Invalid response from server. Please try again.',
        kind: ApiErrorKind.unknown,
      );
    } catch (e) {
      throw Exception('Failed to edit profile image: $e');
    }
  }

  /// Parse server response flexibly and return a normalized map with [imageUrl] and [user].
  /// Handles various shapes: { data: { imageUrl, user } }, { imageUrl, user }, { profileImage }, etc.
  Map<String, dynamic> _normalizeProfileImageResponse(dynamic raw) {
    Map<String, dynamic>? data;
    if (raw is Map<String, dynamic>) {
      data = raw;
    } else if (raw is String) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>?;
        data = decoded;
      } catch (_) {
        throw ApiException('Invalid server response format.');
      }
    }
    if (data == null) {
      throw ApiException('No data in server response.');
    }

    // Prefer nested data (e.g. { data: { user, profileImage } })
    final inner = data['data'] is Map<String, dynamic>
        ? data['data'] as Map<String, dynamic>
        : data;

    // Resolve image URL from common server field names
    final imageUrl = _stringOrNull(inner['imageUrl']) ??
        _stringOrNull(inner['profileImage']) ??
        _stringOrNull(inner['profile_picture']) ??
        _stringOrNull(data['imageUrl']) ??
        _stringOrNull(data['profileImage']) ??
        _stringOrNull(data['profile_picture']);

    // User object for UI
    final userRaw = inner['user'] ?? inner['data'] ?? inner;
    final userData = userRaw is Map<String, dynamic>
        ? userRaw
        : <String, dynamic>{};

    if (imageUrl == null || imageUrl.isEmpty) {
      throw ApiException(
        'No image URL returned from server. Check backend response shape.',
      );
    }

    return {
      'imageUrl': imageUrl,
      'user': userData,
    };
  }

  static String? _stringOrNull(dynamic v) {
    if (v == null) return null;
    if (v is String) return v.isEmpty ? null : v;
    return v.toString();
  }

  /// Delete profile image
  Future<Map<String, dynamic>> deleteProfileImage() async {
    try {
      final response = await _apiService.delete('/upload/profile');
      return response is Map<String, dynamic>
          ? response
          : <String, dynamic>{'data': response};
    } on ApiException {
      rethrow;
    } on SocketException catch (e) {
      if (kDebugMode) debugPrint('📤 [ProfileRepository] SocketException: $e');
      throw ApiException(
        'No internet connection. Please check your network and try again.',
        kind: ApiErrorKind.noInternet,
      );
    } catch (e) {
      throw Exception('Failed to delete profile image: $e');
    }
  }
}
