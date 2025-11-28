import 'package:flutter/material.dart';
import 'package:wish_listy/core/services/api_service.dart';

/// Wishlist Repository
/// Handles all wishlist-related API operations
class WishlistRepository {
  final ApiService _apiService = ApiService();

  /// Create a new wishlist
  /// 
  /// [name] - Wishlist name (required)
  /// [description] - Wishlist description (optional)
  /// [privacy] - Privacy setting: 'public', 'private', or 'friendsOnly' (required)
  /// [category] - Category: 'general', 'birthday', 'wedding', etc. (required)
  /// 
  /// Returns the created wishlist data
  Future<Map<String, dynamic>> createWishlist({
    required String name,
    String? description,
    required String privacy,
    required String category,
  }) async {
    try {
      // Prepare request body according to API specification
      final requestData = {
        'name': name,
        if (description != null && description.isNotEmpty) 'description': description,
        'privacy': privacy,
        'category': category,
      };

      debugPrint('📤 WishlistRepository: Creating wishlist');
      debugPrint('   Request Data: $requestData');
      debugPrint('   Endpoint: POST /api/wishlists');

      // Make API call to create wishlist
      // Endpoint: POST /api/wishlists
      final response = await _apiService.post(
        '/wishlists',
        data: requestData,
      );

      debugPrint('📥 WishlistRepository: Response received');
      debugPrint('   Response: $response');

      // Return the response data
      return response;
    } on ApiException {
      // Re-throw ApiException to preserve error details
      rethrow;
    } catch (e) {
      // Handle any unexpected errors
      debugPrint('Unexpected create wishlist error: $e');
      throw Exception('Failed to create wishlist. Please try again.');
    }
  }

  /// Get all wishlists for the current user
  Future<List<Map<String, dynamic>>> getWishlists() async {
    try {
      debugPrint('📥 WishlistRepository: Getting wishlists');
      final response = await _apiService.get('/wishlists');
      debugPrint('📥 WishlistRepository: Response received: $response');
      
      // API returns: {success: true, count: 2, wishlists: [...]}
      // Try 'wishlists' first, then 'data' as fallback
      final wishlistsList = response['wishlists'] as List<dynamic>? ??
          response['data'] as List<dynamic>?;
      
      if (wishlistsList == null) {
        debugPrint('⚠️ WishlistRepository: No wishlists found in response');
        return [];
      }
      
      final result = wishlistsList
          .map((item) => item as Map<String, dynamic>)
          .toList();
      
      debugPrint('✅ WishlistRepository: Parsed ${result.length} wishlists');
      return result;
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('Unexpected get wishlists error: $e');
      throw Exception('Failed to load wishlists. Please try again.');
    }
  }

  /// Get a specific wishlist by ID
  Future<Map<String, dynamic>> getWishlistById(String wishlistId) async {
    try {
      debugPrint('📥 WishlistRepository: Getting wishlist by ID: $wishlistId');
      final response = await _apiService.get('/wishlists/$wishlistId');
      debugPrint('📥 WishlistRepository: Response received: $response');
      
      // API might return: {success: true, wishlist: {...}} or {success: true, data: {...}} or directly the wishlist object
      final wishlistData = response['wishlist'] as Map<String, dynamic>? ??
          response['data'] as Map<String, dynamic>? ??
          response;
      
      debugPrint('✅ WishlistRepository: Parsed wishlist data');
      return wishlistData;
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('Unexpected get wishlist error: $e');
      throw Exception('Failed to load wishlist. Please try again.');
    }
  }

  /// Update a wishlist
  Future<Map<String, dynamic>> updateWishlist({
    required String wishlistId,
    String? name,
    String? description,
    String? privacy,
    String? category,
  }) async {
    try {
      final requestData = <String, dynamic>{};
      if (name != null) requestData['name'] = name;
      if (description != null) requestData['description'] = description;
      if (privacy != null) requestData['privacy'] = privacy;
      if (category != null) requestData['category'] = category;

      final response = await _apiService.put(
        '/wishlists/$wishlistId',
        data: requestData,
      );

      return response;
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('Unexpected update wishlist error: $e');
      throw Exception('Failed to update wishlist. Please try again.');
    }
  }

  /// Delete a wishlist
  Future<void> deleteWishlist(String wishlistId) async {
    try {
      await _apiService.delete('/wishlists/$wishlistId');
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('Unexpected delete wishlist error: $e');
      throw Exception('Failed to delete wishlist. Please try again.');
    }
  }

  /// Add an item to a wishlist
  /// 
  /// [name] - Item name (required)
  /// [description] - Item description (optional)
  /// [url] - Product URL (optional, only for online store)
  /// [priority] - Priority: 'low', 'medium', 'high', 'urgent' (required)
  /// [wishlistId] - Wishlist ID (required)
  /// 
  /// Returns the created item data
  Future<Map<String, dynamic>> addItemToWishlist({
    required String name,
    String? description,
    String? url,
    required String priority,
    required String wishlistId,
  }) async {
    try {
      // Prepare request body according to API specification
      final requestData = <String, dynamic>{
        'name': name,
        'priority': priority,
        'wishlistId': wishlistId,
      };

      // Add optional fields
      if (description != null && description.isNotEmpty) {
        requestData['description'] = description;
      }

      // Add URL only if provided (for online store)
      if (url != null && url.isNotEmpty) {
        requestData['url'] = url;
      }

      debugPrint('📤 WishlistRepository: Adding item to wishlist');
      debugPrint('   Request Data: $requestData');
      debugPrint('   Endpoint: POST /api/items');

      // Make API call to add item
      // Endpoint: POST /api/items
      final response = await _apiService.post(
        '/items',
        data: requestData,
      );

      debugPrint('📥 WishlistRepository: Response received');
      debugPrint('   Response: $response');

      // Return the response data
      return response;
    } on ApiException {
      // Re-throw ApiException to preserve error details
      rethrow;
    } catch (e) {
      // Handle any unexpected errors
      debugPrint('Unexpected add item error: $e');
      throw Exception('Failed to add item. Please try again.');
    }
  }

  /// Delete an item from a wishlist
  /// 
  /// [itemId] - Item ID (required)
  /// 
  /// Returns nothing on success
  Future<void> deleteItem(String itemId) async {
    try {
      debugPrint('🗑️ WishlistRepository: Deleting item: $itemId');
      debugPrint('   Endpoint: DELETE /api/items/$itemId');

      // Make API call to delete item
      // Endpoint: DELETE /api/items/:id
      await _apiService.delete('/items/$itemId');

      debugPrint('✅ WishlistRepository: Item deleted successfully');
    } on ApiException {
      // Re-throw ApiException to preserve error details
      rethrow;
    } catch (e) {
      // Handle any unexpected errors
      debugPrint('Unexpected delete item error: $e');
      throw Exception('Failed to delete item. Please try again.');
    }
  }
}

