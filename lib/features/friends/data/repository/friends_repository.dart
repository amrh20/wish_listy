import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/features/friends/data/models/user_model.dart';
import 'package:wish_listy/features/friends/data/models/friendship_model.dart';
import 'package:wish_listy/features/friends/data/models/friend_wishlist_model.dart';
import 'package:wish_listy/features/friends/data/models/friend_event_model.dart';
import 'package:wish_listy/features/friends/data/models/friend_profile_model.dart';

/// Friends Repository
/// Handles all friends-related API operations
class FriendsRepository {
  final ApiService _apiService = ApiService();

  /// Search users by username, email, or phone
  ///
  /// [type] - Search type: 'username', 'email', or 'phone'
  /// [value] - Search value (case-insensitive, starts with)
  ///
  /// Returns list of matching users
  Future<List<User>> searchUsers({
    required String type,
    required String value,
  }) async {
    try {
      if (value.isEmpty || value.length < 2) {
        return [];
      }

      final response = await _apiService.get(
        '/users/search',
        queryParameters: {
          'type': type,
          'value': value,
        },
      );

      // API returns: {success: true, count: 2, data: [...]}
      final data = response['data'] as List<dynamic>?;

      if (data == null || data.isEmpty) {

        return [];
      }

      final users = data
          .map((json) => User.fromJson(json as Map<String, dynamic>))
          .toList();

      return users;
    } on ApiException {
      // Re-throw ApiException to preserve error details
      rethrow;
    } catch (e) {

      throw Exception('Failed to search users. Please try again.');
    }
  }

  /// Get user profile by ID
  ///
  /// [userId] - The user ID to get profile for
  ///
  /// Returns user profile data
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {

      final response = await _apiService.get('/users/$userId/profile');

      final data = response['data'] ?? response;
      return data as Map<String, dynamic>;
    } on ApiException {
      rethrow;
    } catch (e) {

      throw Exception('Failed to load user profile. Please try again.');
    }
  }

  /// Friend profile (screen header + counts)
  /// GET /api/users/:friendUserId/profile
  Future<FriendProfileModel> getFriendProfile(String friendUserId) async {
    try {
      final response = await _apiService.get('/users/$friendUserId/profile');
      final data = (response['data'] as Map<String, dynamic>?) ?? response;
      return FriendProfileModel.fromJson(data as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to load friend profile. Please try again.');
    }
  }

  /// Friend wishlists (profile tab)
  /// GET /api/users/:friendUserId/wishlists
  Future<List<FriendWishlistModel>> getFriendWishlists(String friendUserId) async {
    try {
      if (friendUserId.isEmpty) return [];
      final response = await _apiService.get('/users/$friendUserId/wishlists');
      final data = response['data'] as Map<String, dynamic>? ?? const {};
      final list = data['wishlists'] as List<dynamic>? ?? const [];
      return list
          .whereType<Map>()
          .map((e) => FriendWishlistModel.fromJson(e.cast<String, dynamic>()))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to load friend wishlists. Please try again.');
    }
  }

  /// Friend events (profile tab)
  /// GET /api/users/:friendUserId/events
  Future<List<FriendEventModel>> getFriendEvents(String friendUserId) async {
    try {
      if (friendUserId.isEmpty) return [];
      final response = await _apiService.get('/users/$friendUserId/events');
      final data = response['data'] as Map<String, dynamic>? ?? const {};
      final list = data['events'] as List<dynamic>? ?? const [];
      return list
          .whereType<Map>()
          .map((e) => FriendEventModel.fromJson(e.cast<String, dynamic>()))
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to load friend events. Please try again.');
    }
  }

  /// Send friend request
  ///
  /// [toUserId] - The user ID to send friend request to
  /// [message] - Optional message to include with the request
  ///
  /// Returns friend request data
  Future<Map<String, dynamic>> sendFriendRequest({
    required String toUserId,
    String? message,
  }) async {
    try {

      final response = await _apiService.post(
        '/friends/request',
        data: {
          'toUserId': toUserId,
          if (message != null && message.isNotEmpty) 'message': message,
        },
      );

      final data = response['data'] ?? response;
      return data as Map<String, dynamic>;
    } on ApiException {
      rethrow;
    } catch (e) {

      throw Exception('Failed to send friend request. Please try again.');
    }
  }

  /// Accept friend request
  ///
  /// [requestId] - The friend request ID to accept (required)
  ///
  /// Returns friendship data
  Future<Map<String, dynamic>> acceptFriendRequest({
    required String requestId,
  }) async {
    try {
      if (requestId.isEmpty) {
        throw Exception('Request ID is required');
      }

      final response = await _apiService.post(
        '/friends/request/$requestId/respond',
        data: {
          'action': 'accept',
        },
      );

      // Handle different response structures
      if (response is Map<String, dynamic>) {
        final data = response['data'] ?? response;
        if (data is Map<String, dynamic>) {
          return data;
        }
        // If data is not a Map, return the response itself
        return response;
      }
      
      // If response is not a Map, return empty map (success case)
      return {'success': true};
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('❌ FriendsRepository: Error accepting friend request: $e');
      throw Exception('Failed to accept friend request. Please try again.');
    }
  }

  /// Reject friend request
  ///
  /// [requestId] - The friend request ID to reject (required)
  ///
  /// Returns success response
  Future<Map<String, dynamic>> rejectFriendRequest({
    required String requestId,
  }) async {
    try {
      if (requestId.isEmpty) {
        throw Exception('Request ID is required');
      }

      final response = await _apiService.post(
        '/friends/request/$requestId/respond',
        data: {
          'action': 'reject',
        },
      );

      // Handle different response structures
      if (response is Map<String, dynamic>) {
        final data = response['data'] ?? response;
        if (data is Map<String, dynamic>) {
          return data;
        }
        // If data is not a Map, return the response itself
        return response;
      }
      
      // If response is not a Map, return empty map (success case)
      return {'success': true};
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('❌ FriendsRepository: Error rejecting friend request: $e');
      throw Exception('Failed to reject friend request. Please try again.');
    }
  }

  /// Get friend requests
  ///
  /// Returns list of friend request objects
  /// Response format: {success: true, count: 3, data: [...]}
  Future<List<FriendRequest>> getFriendRequests() async {
    try {
      final response = await _apiService.get('/friends/requests');

      // Parse response: {success: true, count: 3, data: [...]}
      final data = response['data'] as List<dynamic>?;

      if (data == null || data.isEmpty) {
        return [];
      }

      final requests = data
          .map((json) => FriendRequest.fromJson(json as Map<String, dynamic>))
          .toList();

      return requests;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to load friend requests. Please try again.');
    }
  }

  /// Get friends list with pagination
  ///
  /// [page] - Page number (default: 1)
  /// [limit] - Number of items per page (default: 20)
  ///
  /// Returns a map with:
  /// - 'friends': List<Friend> - List of friends
  /// - 'total': int - Total number of friends
  /// - 'page': int - Current page number
  /// - 'limit': int - Items per page
  /// Response format: {success: true, count: 5, total: 15, page: 1, limit: 100, data: [...]}
  Future<Map<String, dynamic>> getFriends({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiService.get(
        '/friends',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      // Parse response: {success: true, count: 5, total: 15, page: 1, limit: 100, data: [...]}
      final data = response['data'] as List<dynamic>? ?? [];
      
      final friends = data
          .map((json) => Friend.fromJson(json as Map<String, dynamic>))
          .toList();

      // Extract pagination metadata
      final total = response['total'] as int? ?? friends.length;
      final currentPage = response['page'] as int? ?? page;
      final currentLimit = response['limit'] as int? ?? limit;

      return {
        'friends': friends,
        'total': total,
        'page': currentPage,
        'limit': currentLimit,
      };
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to load friends. Please try again.');
    }
  }

  /// Remove/Unfriend a friend
  ///
  /// [friendId] - The friend user ID to remove (required)
  ///
  /// Returns success response
  Future<Map<String, dynamic>> removeFriend({
    required String friendId,
  }) async {
    try {
      if (friendId.isEmpty) {
        throw Exception('Friend ID is required');
      }

      final response = await _apiService.delete('/friends/$friendId');

      // Handle different response structures
      if (response is Map<String, dynamic>) {
        final data = response['data'] ?? response;
        if (data is Map<String, dynamic>) {
          return data;
        }
        // If data is not a Map, return the response itself
        return response;
      }
      
      // If response is not a Map, return empty map (success case)
      return {'success': true};
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('❌ FriendsRepository: Error removing friend: $e');
      throw Exception('Failed to remove friend. Please try again.');
    }
  }
}

