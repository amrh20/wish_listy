import 'package:wish_listy/core/services/api_service.dart';

/// Repository for handling profile image upload and delete operations
class ProfileRepository {
  final ApiService _apiService;

  ProfileRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Upload profile image (for new uploads)
  /// [imagePath] - Path to the compressed image file
  /// Returns response data containing imageUrl and updated user data
  Future<Map<String, dynamic>> uploadProfileImage(String imagePath) async {
    try {
      final response = await _apiService.postMultipart(
        '/upload/profile',
        fields: {},
        fileKey: 'image',
        filePath: imagePath,
      );

      // Response structure: {success: true, message: "...", data: {imageUrl: "...", user: {...}}}
      return response;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  /// Edit/Update existing profile image
  /// [imagePath] - Path to the compressed image file
  /// Returns response data containing imageUrl and updated user data
  Future<Map<String, dynamic>> editProfileImage(String imagePath) async {
    try {
      final response = await _apiService.postMultipart(
        '/upload/edit-profile-image',
        fields: {},
        fileKey: 'image',
        filePath: imagePath,
      );

      // Response structure: {success: true, message: "...", data: {imageUrl: "...", user: {...}}}
      return response;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to edit profile image: $e');
    }
  }

  /// Delete profile image
  /// Returns response data
  Future<Map<String, dynamic>> deleteProfileImage() async {
    try {
      final response = await _apiService.delete('/upload/profile');

      // Response structure: {success: true, message: "Profile image deleted successfully"}
      return response;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to delete profile image: $e');
    }
  }
}

