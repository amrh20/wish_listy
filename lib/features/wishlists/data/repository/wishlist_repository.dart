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
  /// [privacy] - Privacy setting: 'public', 'private', or 'friends' (required)
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
        if (description != null && description.isNotEmpty)
          'description': description,
        'privacy': privacy,
        'category': category,
      };

      debugPrint('📤 WishlistRepository: Creating wishlist');
      debugPrint('   Request Data: $requestData');
      debugPrint('   Endpoint: POST /api/wishlists');

      // Make API call to create wishlist
      // Endpoint: POST /api/wishlists
      final response = await _apiService.post('/wishlists', data: requestData);

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
      final wishlistsList =
          response['wishlists'] as List<dynamic>? ??
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
      if (wishlistId.isEmpty) {
        throw Exception('Wishlist ID cannot be empty');
      }

      debugPrint('📥 WishlistRepository: Getting wishlist by ID: $wishlistId');
      debugPrint('   Endpoint: GET /wishlists/$wishlistId');

      final response = await _apiService.get('/wishlists/$wishlistId');
      debugPrint('📥 WishlistRepository: Response received: $response');
      debugPrint('   Response type: ${response.runtimeType}');

      // Validate response
      if (response is! Map<String, dynamic>) {
        throw Exception('Invalid response format from API');
      }

      debugPrint('   Response keys: ${response.keys.toList()}');

      // API might return: {success: true, wishlist: {...}} or {success: true, data: {...}} or directly the wishlist object
      final wishlistData =
          response['wishlist'] as Map<String, dynamic>? ??
          response['data'] as Map<String, dynamic>? ??
          response;

      if (wishlistData.isEmpty) {
        throw Exception('Wishlist data not found in response');
      }

      debugPrint('✅ WishlistRepository: Parsed wishlist data');
      debugPrint('   Wishlist keys: ${wishlistData.keys.toList()}');
      return wishlistData;
    } on ApiException catch (e) {
      debugPrint('❌ WishlistRepository: ApiException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ WishlistRepository: Unexpected get wishlist error: $e');
      debugPrint('   Error type: ${e.runtimeType}');
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
      // Always include description (even if empty string or null)
      // API expects description field in the request
      requestData['description'] = description ?? '';
      if (privacy != null) requestData['privacy'] = privacy;
      if (category != null) requestData['category'] = category;

      debugPrint('📤 WishlistRepository: Updating wishlist: $wishlistId');
      debugPrint('   Request Data: $requestData');
      debugPrint('   Endpoint: PUT /api/wishlists/$wishlistId');

      final response = await _apiService.put(
        '/wishlists/$wishlistId',
        data: requestData,
      );

      debugPrint('📥 WishlistRepository: Response received: $response');
      debugPrint('✅ WishlistRepository: Wishlist updated successfully');

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
  /// [storeName] - Store name (optional, only for physical store)
  /// [storeLocation] - Store location (optional, only for physical store)
  /// [notes] - Notes (optional, only for anywhere)
  /// [priority] - Priority: 'low', 'medium', 'high', 'urgent' (required)
  /// [wishlistId] - Wishlist ID (required)
  ///
  /// Returns the created item data
  Future<Map<String, dynamic>> addItemToWishlist({
    required String name,
    String? description,
    String? url,
    String? storeName,
    String? storeLocation,
    String? notes,
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

      // Add fields based on where to find the gift
      // URL for online store
      if (url != null && url.isNotEmpty) {
        requestData['url'] = url;
      } else {
        requestData['url'] = null;
      }

      // Store name and location for physical store
      if (storeName != null && storeName.isNotEmpty) {
        requestData['storeName'] = storeName;
      } else {
        requestData['storeName'] = null;
      }

      if (storeLocation != null && storeLocation.isNotEmpty) {
        requestData['storeLocation'] = storeLocation;
      } else {
        requestData['storeLocation'] = null;
      }

      // Notes for anywhere
      if (notes != null && notes.isNotEmpty) {
        requestData['notes'] = notes;
      } else {
        requestData['notes'] = null;
      }

      debugPrint('📤 WishlistRepository: Adding item to wishlist');
      debugPrint('   Request Data: $requestData');
      debugPrint('   Endpoint: POST /api/items');

      // Make API call to add item
      // Endpoint: POST /api/items
      final response = await _apiService.post('/items', data: requestData);

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

  /// Get all items for a specific wishlist
  ///
  /// Uses API:
  /// GET /api/items/wishlist/:wishlistId
  Future<List<Map<String, dynamic>>> getItemsForWishlist(
    String wishlistId,
  ) async {
    try {
      debugPrint(
        '📥 WishlistRepository: Getting items for wishlist: $wishlistId',
      );
      debugPrint('   Endpoint: GET /api/items/wishlist/$wishlistId');

      final response = await _apiService.get('/items/wishlist/$wishlistId');

      debugPrint('📥 WishlistRepository: Response received: $response');

      // API might return: {success: true, items: [...]} or {success: true, data: [...]}
      final itemsList =
          response['items'] as List<dynamic>? ??
          response['data'] as List<dynamic>? ??
          (response is List ? response as List<dynamic> : null);

      if (itemsList == null) {
        debugPrint(
          '⚠️ WishlistRepository: No items array found in response for wishlist $wishlistId',
        );
        return [];
      }

      final result = itemsList
          .map((item) => item as Map<String, dynamic>)
          .toList();

      debugPrint(
        '✅ WishlistRepository: Parsed ${result.length} items for wishlist $wishlistId',
      );
      return result;
    } on ApiException {
      // Re-throw ApiException to preserve error details
      rethrow;
    } catch (e) {
      // Handle any unexpected errors
      debugPrint('Unexpected get items error: $e');
      throw Exception('Failed to load items. Please try again.');
    }
  }

  /// Update an existing item in a wishlist
  ///
  /// Uses API:
  /// PUT /api/items/:id
  Future<Map<String, dynamic>> updateItem({
    required String itemId,
    required String wishlistId,
    required String name,
    String? description,
    String? url,
    String? storeName,
    String? storeLocation,
    String? notes,
    required String priority,
  }) async {
    try {
      // Prepare request body according to API specification
      final requestData = <String, dynamic>{
        'name': name,
        'priority': priority,
        'wishlistId': wishlistId,
      };

      // Optional fields follow same rules as addItemToWishlist
      if (description != null && description.isNotEmpty) {
        requestData['description'] = description;
      } else {
        requestData['description'] = null;
      }

      if (url != null && url.isNotEmpty) {
        requestData['url'] = url;
      } else {
        requestData['url'] = null;
      }

      if (storeName != null && storeName.isNotEmpty) {
        requestData['storeName'] = storeName;
      } else {
        requestData['storeName'] = null;
      }

      if (storeLocation != null && storeLocation.isNotEmpty) {
        requestData['storeLocation'] = storeLocation;
      } else {
        requestData['storeLocation'] = null;
      }

      if (notes != null && notes.isNotEmpty) {
        requestData['notes'] = notes;
      } else {
        requestData['notes'] = null;
      }

      debugPrint('📤 WishlistRepository: Updating item: $itemId');
      debugPrint('   Request Data: $requestData');
      debugPrint('   Endpoint: PUT /api/items/$itemId');

      final response = await _apiService.put(
        '/items/$itemId',
        data: requestData,
      );

      debugPrint('📥 WishlistRepository: Response received: $response');
      debugPrint('   Response type: ${response.runtimeType}');
      debugPrint('✅ WishlistRepository: Item updated successfully');

      return response;
    } on ApiException catch (e) {
      // Re-throw ApiException to preserve error details
      debugPrint('❌ WishlistRepository: ApiException: ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      // Handle any unexpected errors
      debugPrint('❌ WishlistRepository: Unexpected update item error: $e');
      debugPrint('   Stack trace: $stackTrace');
      throw Exception('Failed to update item. Please try again.');
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
