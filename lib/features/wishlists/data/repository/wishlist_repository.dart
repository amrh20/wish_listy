import 'package:flutter/material.dart';
import 'package:wish_listy/core/services/api_service.dart';

/// Wishlist Repository
/// Handles all wishlist-related API operations
class WishlistRepository {
  final ApiService _apiService = ApiService();

  /// Create a new wishlist
  ///
  /// [name] - Wishlist name (required)
  /// [privacy] - Privacy setting: 'public', 'private', or 'friends' (required)
  /// [category] - Category: 'general', 'birthday', 'wedding', etc. (optional)
  /// [items] - Optional list of items to create with the wishlist (optional)
  ///
  /// Returns the created wishlist data
  Future<Map<String, dynamic>> createWishlist({
    required String name,
    required String privacy,
    String? category,
    List<Map<String, dynamic>>? items,
  }) async {
    try {
      // Prepare request body according to API specification
      final requestData = <String, dynamic>{
        'name': name,
        'privacy': privacy,
        if (category != null) 'category': category,
        if (items != null && items.isNotEmpty) 'items': items,
      };

      // Make API call to create wishlist
      // Endpoint: POST /api/wishlists
      final response = await _apiService.post('/wishlists', data: requestData);

      // Return the response data
      return response;
    } on ApiException {
      // Re-throw ApiException to preserve error details
      rethrow;
    } catch (e) {
      // Handle any unexpected errors

      throw Exception('Failed to create wishlist. Please try again.');
    }
  }

  /// Get all wishlists for the current user
  Future<List<Map<String, dynamic>>> getWishlists() async {
    try {

      final response = await _apiService.get('/wishlists');

      // API returns: {success: true, count: 2, wishlists: [...]}
      // Try 'wishlists' first, then 'data' as fallback
      final wishlistsList =
          response['wishlists'] as List<dynamic>? ??
          response['data'] as List<dynamic>?;

      if (wishlistsList == null) {

        return [];
      }

      final result = wishlistsList
          .map((item) => item as Map<String, dynamic>)
          .toList();

      return result;
    } on ApiException {
      rethrow;
    } catch (e) {

      throw Exception('Failed to load wishlists. Please try again.');
    }
  }

  /// Get a specific wishlist by ID
  Future<Map<String, dynamic>> getWishlistById(String wishlistId) async {
    try {
      if (wishlistId.isEmpty) {
        throw Exception('Wishlist ID cannot be empty');
      }

      final response = await _apiService.get('/wishlists/$wishlistId');

      // Validate response
      if (response is! Map<String, dynamic>) {
        throw Exception('Invalid response format from API');
      }

      // API might return: {success: true, wishlist: {...}} or {success: true, data: {...}} or directly the wishlist object
      final wishlistData =
          response['wishlist'] as Map<String, dynamic>? ??
          response['data'] as Map<String, dynamic>? ??
          response;

      if (wishlistData.isEmpty) {
        throw Exception('Wishlist data not found in response');
      }

      return wishlistData;
    } on ApiException catch (e) {

      rethrow;
    } catch (e) {

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

      final response = await _apiService.put(
        '/wishlists/$wishlistId',
        data: requestData,
      );

      return response;
    } on ApiException {
      rethrow;
    } catch (e) {

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

      // Make API call to add item
      // Endpoint: POST /api/items
      final response = await _apiService.post('/items', data: requestData);

      // Return the response data
      return response;
    } on ApiException {
      // Re-throw ApiException to preserve error details
      rethrow;
    } catch (e) {
      // Handle any unexpected errors

      throw Exception('Failed to add item. Please try again.');
    }
  }

  /// Get a specific item by ID
  ///
  /// Uses API:
  /// GET /api/items/:id
  Future<Map<String, dynamic>> getItemById(String itemId) async {
    try {
      if (itemId.isEmpty) {
        throw Exception('Item ID cannot be empty');
      }

      final response = await _apiService.get('/items/$itemId');

      // Validate response
      if (response is! Map<String, dynamic>) {
        throw Exception('Invalid response format from API');
      }

      // API might return: {success: true, item: {...}} or {success: true, data: {...}} or directly the item object
      final itemData =
          response['item'] as Map<String, dynamic>? ??
          response['data'] as Map<String, dynamic>? ??
          response;

      if (itemData == null || itemData.isEmpty) {
        throw Exception('Item data not found in response');
      }

      return itemData;
    } on ApiException catch (e) {
      rethrow;
    } catch (e, stackTrace) {
      throw Exception('Failed to load item. Please try again.');
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

      final response = await _apiService.get('/items/wishlist/$wishlistId');

      // API might return: {success: true, items: [...]} or {success: true, data: [...]}
      final itemsList =
          response['items'] as List<dynamic>? ??
          response['data'] as List<dynamic>? ??
          (response is List ? response as List<dynamic> : null);

      if (itemsList == null) {

        return [];
      }

      final result = itemsList
          .map((item) => item as Map<String, dynamic>)
          .toList();

      return result;
    } on ApiException {
      // Re-throw ApiException to preserve error details
      rethrow;
    } catch (e) {
      // Handle any unexpected errors

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

      final response = await _apiService.put(
        '/items/$itemId',
        data: requestData,
      );

      return response;
    } on ApiException catch (e) {
      // Re-throw ApiException to preserve error details

      rethrow;
    } catch (e, stackTrace) {
      // Handle any unexpected errors

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

      // Make API call to delete item
      // Endpoint: DELETE /api/items/:id
      await _apiService.delete('/items/$itemId');

    } on ApiException {
      // Re-throw ApiException to preserve error details
      rethrow;
    } catch (e) {
      // Handle any unexpected errors

      throw Exception('Failed to delete item. Please try again.');
    }
  }

  /// Toggle reservation for an item
  ///
  /// [itemId] - Item ID (required)
  /// [action] - Action to perform: 'reserve' or 'cancel' (default: 'reserve')
  /// [quantity] - Quantity for reserve action (default: 1)
  /// [reservedUntil] - Optional expiry date for reserve action (ISO string sent as reservedUntil)
  ///
  /// Returns the updated item data
  /// Uses API: PUT /api/items/:itemId/reserve
  /// Reserve: PUT with body { "action": "reserve", "quantity": 1, "reservedUntil"?: ISO date }
  /// Cancel: PUT with body { "action": "cancel" }
  /// Response contains isReserved in data.isReserved
  Future<Map<String, dynamic>> toggleReservation(
    String itemId, {
    String action = 'reserve',
    int quantity = 1,
    DateTime? reservedUntil,
  }) async {
    try {
      // Prepare request body based on action
      // Reserve: { "action": "reserve", "quantity": 1, "reservedUntil"?: ISO }
      // Cancel: { "action": "cancel" }
      final Map<String, dynamic> requestBody = action == 'cancel'
          ? <String, dynamic>{'action': 'cancel'} // Cancel reservation
          : <String, dynamic>{
              'action': 'reserve',
              'quantity': quantity,
            };
      if (action == 'reserve' && reservedUntil != null) {
        requestBody['reservedUntil'] = reservedUntil.toIso8601String();
      }

      final response = await _apiService.put('/items/$itemId/reserve', data: requestBody);

      // Parse response structure:
      // { success: true, data: { isReserved: true/false, item: {...} } }
      // or { success: true, data: { isReserved: true/false, reservation: {...} } }
      final responseData = response['data'] as Map<String, dynamic>?;
      
      // Get isReserved from response
      final isReserved = responseData?['isReserved'] as bool?;
      
      // Get item data from response
      final itemData = responseData?['item'] as Map<String, dynamic>? ??
          response['item'] as Map<String, dynamic>? ??
          responseData ??
          response;

      if (itemData == null || itemData.isEmpty) {
        throw Exception('Item data not found in response');
      }

      // Add isReserved to item data if available
      if (isReserved != null && itemData is Map<String, dynamic>) {
        itemData['isReserved'] = isReserved;
      }

      return itemData;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to toggle reservation. Please try again.');
    }
  }

  /// Extend reservation for an item.
  /// Uses API: PUT /api/items/:itemId/extend-reservation
  /// [reservedUntil] is required and sent in the request body (ISO string).
  /// Returns the updated item data (including new reservedUntil and extensionCount).
  Future<Map<String, dynamic>> extendReservation(String itemId, DateTime reservedUntil) async {
    try {
      final response = await _apiService.put(
        '/items/$itemId/extend-reservation',
        data: <String, dynamic>{'reservedUntil': reservedUntil.toIso8601String()},
      );

      final responseData = response['data'] as Map<String, dynamic>?;
      final itemData = responseData?['item'] as Map<String, dynamic>? ??
          response['item'] as Map<String, dynamic>? ??
          responseData ??
          response;

      if (itemData == null || itemData.isEmpty) {
        throw Exception('Item data not found in response');
      }

      return itemData;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to extend reservation. Please try again.');
    }
  }

  /// Get all reservations (items reserved by the current user)
  ///
  /// Uses API: GET /api/reservations
  /// Optional [status]: 'reserved' (default) or 'cancelled'
  Future<List<Map<String, dynamic>>> fetchMyReservations({
    String status = 'reserved',
  }) async {
    try {
      final response = await _apiService.get(
        '/reservations',
        queryParameters: {'status': status},
      );

      // API returns: { success: true, data: { reservations: [...], count: N } }
      final data = response['data'];
      final reservationsList = data is List
          ? data
          : (data != null && data['reservations'] != null)
              ? data['reservations'] as List<dynamic>
              : <dynamic>[];

      return reservationsList
          .map((r) =>
              r is Map && r['item'] != null
                  ? r['item'] as Map<String, dynamic>
                  : null)
          .whereType<Map<String, dynamic>>()
          .toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to load reservations. Please try again.');
    }
  }

  /// Mark item as purchased
  ///
  /// [itemId] - Item ID (required)
  /// [purchasedBy] - User ID who purchased the item (optional, defaults to current user)
  ///
  /// Returns the updated item data
  /// Uses API: PUT /api/items/:id/purchase
  Future<Map<String, dynamic>> markAsPurchased({
    required String itemId,
    String? purchasedBy,
  }) async {
    try {
      // Request body is optional - if purchasedBy is not provided, API will use current user
      final requestData = <String, dynamic>{};
      if (purchasedBy != null) {
        requestData['purchasedBy'] = purchasedBy;
      }

      final response = await _apiService.put(
        '/items/$itemId/purchase',
        data: requestData.isNotEmpty ? requestData : null,
      );

      // API might return: {success: true, item: {...}} or {success: true, data: {...}} or directly the item object
      final itemData =
          response['item'] as Map<String, dynamic>? ??
          response['data'] as Map<String, dynamic>? ??
          response;

      if (itemData == null || itemData.isEmpty) {
        throw Exception('Item data not found in response');
      }

      return itemData;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to mark item as purchased. Please try again.');
    }
  }

  /// Toggle received status for an item
  ///
  /// [itemId] - Item ID (required)
  /// [isReceived] - New received status (required)
  ///
  /// Returns the updated item data
  /// Uses API: PUT /api/items/:id/status
  Future<Map<String, dynamic>> toggleReceivedStatus({
    required String itemId,
    required bool isReceived,
  }) async {
    try {
      final requestData = <String, dynamic>{
        'isReceived': isReceived,
      };

      final response = await _apiService.put(
        '/items/$itemId/status',
        data: requestData,
      );

      // API might return: {success: true, item: {...}} or {success: true, data: {...}} or directly the item object
      final itemData =
          response['item'] as Map<String, dynamic>? ??
          response['data'] as Map<String, dynamic>? ??
          response;

      if (itemData == null || itemData.isEmpty) {
        throw Exception('Item data not found in response');
      }

      return itemData;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to update received status. Please try again.');
    }
  }

}
