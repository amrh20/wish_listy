import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/features/friends/data/models/user_model.dart';

/// Repository for block, unblock, report and get blocked users.
/// Calls backend: POST /users/block/:id, POST /users/unblock/:id,
/// POST /users/report/:id, GET /users/blocked.
class PrivacyRepository {
  final ApiService _apiService = ApiService();

  /// Block a user. Backend removes friendship and adds target to blockedUsers.
  /// Throws [ApiException] on failure.
  Future<void> blockUser(String userId) async {
    await _apiService.post('/users/block/$userId');
  }

  /// Unblock a user. Backend removes target from blockedUsers.
  /// Throws [ApiException] on failure.
  Future<void> unblockUser(String userId) async {
    await _apiService.post('/users/unblock/$userId');
  }

  /// Report a user with optional reason. Backend creates a Report.
  /// Throws [ApiException] on failure.
  Future<void> reportUser(String userId, String reason) async {
    await _apiService.post(
      '/users/report/$userId',
      data: {'reason': reason},
    );
  }

  /// Get list of blocked users. Backend returns array of user objects
  /// with _id, fullName, username, handle, profileImage.
  Future<List<User>> getBlockedUsers() async {
    final response = await _apiService.get('/users/blocked');
    final raw = response['data'] ?? response;
    final list = raw is List ? raw : <dynamic>[];
    return list
        .whereType<Map<String, dynamic>>()
        .map((json) => User.fromJson(json))
        .toList();
  }
}
