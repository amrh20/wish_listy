import 'package:flutter/material.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/features/events/data/models/event_model.dart';

/// Event Repository
/// Handles all event-related API operations
class EventRepository {
  final ApiService _apiService = ApiService();

  /// Create a new event
  ///
  /// [name] - Event name (required)
  /// [description] - Event description (optional)
  /// [date] - Event date in ISO 8601 UTC format (required)
  /// [time] - Event time in HH:mm format (required)
  /// [type] - Event type: 'birthday', 'wedding', 'anniversary', etc. (required)
  /// [privacy] - Privacy setting: 'public', 'private', or 'friends_only' (required)
  /// [mode] - Event mode: 'in_person', 'online', or 'hybrid' (required)
  /// [location] - Event location (optional for online events)
  /// [meetingLink] - Online meeting link (required for online/hybrid, null for in_person)
  /// [wishlistId] - Linked wishlist ID (optional)
  /// [invitedFriends] - List of invited friend IDs (optional, can be empty)
  ///
  /// Returns the created event data
  Future<Event> createEvent({
    required String name,
    String? description,
    required String date, // ISO 8601 UTC format
    required String time, // HH:mm format
    required String type,
    required String privacy,
    required String mode,
    String? location,
    String? meetingLink,
    String? wishlistId,
    List<String>? invitedFriends,
  }) async {
    try {
      // Prepare request body according to API specification
      final requestData = <String, dynamic>{
        'name': name,
        'date': date,
        'time': time,
        'type': type,
        'privacy': privacy,
        'mode': mode,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (location != null && location.isNotEmpty) 'location': location,
        'meeting_link': meetingLink,
        if (wishlistId != null && wishlistId.isNotEmpty)
          'wishlist_id': wishlistId,
        'invited_friends': invitedFriends ?? [],
      };

      // Make API call to create event
      // Endpoint: POST /api/events
      final response = await _apiService.post('/events', data: requestData);

      // Parse response and create Event object
      // API response structure: {success: true, data: {...}} or {id, name, ...}
      final eventData = response['data'] ?? response;

      if (eventData is! Map<String, dynamic>) {
        throw Exception('Invalid response format from server');
      }

      // Create Event object from response
      final event = Event.fromJson(eventData);

      return event;
    } on ApiException {
      // Re-throw ApiException to preserve error details
      rethrow;
    } catch (e) {
      // Handle any unexpected errors

      throw Exception('Failed to create event. Please try again.');
    }
  }

  /// Update an existing event
  ///
  /// [eventId] - Event ID to update (required)
  /// [name] - Event name (required)
  /// [description] - Event description (optional)
  /// [date] - Event date in ISO 8601 UTC format (required)
  /// [time] - Event time in HH:mm format (required)
  /// [type] - Event type: 'birthday', 'wedding', 'anniversary', etc. (required)
  /// [privacy] - Privacy setting: 'public', 'private', or 'friends_only' (required)
  /// [mode] - Event mode: 'in_person', 'online', or 'hybrid' (required)
  /// [location] - Event location (optional for online events)
  /// [meetingLink] - Online meeting link (required for online/hybrid, null for in_person)
  /// [wishlistId] - Linked wishlist ID (optional)
  /// [invitedFriends] - List of invited friend IDs (optional, can be empty)
  ///
  /// Returns the updated event data
  Future<Event> updateEvent({
    required String eventId,
    required String name,
    String? description,
    required String date, // ISO 8601 UTC format
    required String time, // HH:mm format
    required String type,
    required String privacy,
    required String mode,
    String? location,
    String? meetingLink,
    String? wishlistId,
    List<String>? invitedFriends,
  }) async {
    try {
      // Prepare request body according to API specification
      final requestData = <String, dynamic>{
        'name': name,
        'date': date,
        'time': time,
        'type': type,
        'privacy': privacy,
        'mode': mode,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (location != null && location.isNotEmpty) 'location': location,
        'meeting_link': meetingLink,
        if (wishlistId != null && wishlistId.isNotEmpty)
          'wishlist_id': wishlistId,
        'invited_friends': invitedFriends ?? [],
      };

      // Make API call to update event
      // Endpoint: PUT /api/events/:id
      final response = await _apiService.put(
        '/events/$eventId',
        data: requestData,
      );

      // Parse response and create Event object
      // API response structure: {success: true, data: {...}} or {id, name, ...}
      final eventData = response['data'] ?? response;

      if (eventData is! Map<String, dynamic>) {
        throw Exception('Invalid response format from server');
      }

      // Create Event object from response
      final event = Event.fromJson(eventData);

      return event;
    } on ApiException {
      // Re-throw ApiException to preserve error details
      rethrow;
    } catch (e) {
      // Handle any unexpected errors

      throw Exception('Failed to update event. Please try again.');
    }
  }

  /// Get all events for the current user
  ///
  /// Returns a list of events (both created by user and invited to)
  Future<List<Event>> getEvents() async {
    try {

      // Make API call to get events
      // Endpoint: GET /api/events
      final response = await _apiService.get('/events');

      // Parse response
      // API response structure: {success: true, data: {created: [...], invited: [...]}}
      List<dynamic> eventsList = [];

      if (response is Map) {
        final data = response['data'];
        if (data != null && data is Map) {
          // API returns: {data: {created: [...], invited: [...]}}
          final created = data['created'];
          final invited = data['invited'];

          if (created != null && created is List) {
            eventsList.addAll(created);
          }
          if (invited != null && invited is List) {
            eventsList.addAll(invited);
          }
        } else if (data != null && data is List) {
          // Fallback: if data is directly a list
          eventsList = data;
        } else {
          final events = response['events'];
          if (events != null && events is List) {
            eventsList = events;
          }
        }
      } else if (response is List) {
        eventsList = response as List<dynamic>;
      }

      if (eventsList.isEmpty) {

        return [];
      }

      // Convert to Event objects
      final events = eventsList
          .map((item) {
            try {
              return Event.fromJson(item as Map<String, dynamic>);
            } catch (e) {

              return null;
            }
          })
          .whereType<Event>()
          .toList();

      return events;
    } on ApiException {
      // Re-throw ApiException to preserve error details
      rethrow;
    } catch (e) {
      // Handle any unexpected errors

      throw Exception('Failed to load events. Please try again.');
    }
  }

  /// Get a single event by ID
  ///
  /// [id] - Event ID (required)
  ///
  /// Returns the event data
  Future<Event> getEventById(String id) async {
    try {

      // Make API call to get event by ID
      // Endpoint: GET /api/events/:id
      final response = await _apiService.get('/events/$id');

      // Parse response
      // API response structure: {success: true, data: {...}} or direct object
      Map<String, dynamic> eventData;

      if (response is Map) {
        final data = response['data'];
        if (data != null && data is Map<String, dynamic>) {
          // API returns: {success: true, data: {...}}
          eventData = data;
        } else {
          // Direct object format
          eventData = response as Map<String, dynamic>;
        }
      } else {

        throw Exception('Invalid response format from server');
      }

      // Create Event object from response
      final event = Event.fromJson(eventData);

      return event;
    } on ApiException catch (e) {
      // Re-throw ApiException to preserve error details

      rethrow;
    } catch (e) {
      // Handle any unexpected errors

      throw Exception('Failed to load event. Please try again.');
    }
  }

  /// Delete an event by ID
  ///
  /// [eventId] - Event ID to delete (required)
  ///
  /// Returns true if deletion was successful
  Future<bool> deleteEvent(String eventId) async {
    try {

      // Make API call to delete event
      // Endpoint: DELETE /api/events/:id
      await _apiService.delete('/events/$eventId');

      return true;
    } on ApiException catch (e) {
      // Re-throw ApiException to preserve error details

      rethrow;
    } catch (e) {
      // Handle any unexpected errors

      throw Exception('Failed to delete event. Please try again.');
    }
  }

  /// Link a wishlist to an event
  ///
  /// [eventId] - Event ID to link wishlist to (required)
  /// [wishlistId] - Wishlist ID to link (required)
  ///
  /// Returns the updated event data
  Future<Event> linkWishlistToEvent({
    required String eventId,
    required String wishlistId,
  }) async {
    try {

      // Prepare request body
      final requestData = <String, dynamic>{'wishlist_id': wishlistId};

      // Make API call to link wishlist
      // Endpoint: PUT /api/events/:id/wishlist
      final response = await _apiService.put(
        '/events/$eventId/wishlist',
        data: requestData,
      );

      // Parse response and create Event object
      // API response structure: {success: true, data: {...}} or {id, name, ...}
      final eventData = response['data'] ?? response;

      if (eventData is! Map<String, dynamic>) {
        throw Exception('Invalid response format from server');
      }

      // Create Event object from response
      final event = Event.fromJson(eventData);

      return event;
    } on ApiException catch (e) {
      // Re-throw ApiException to preserve error details

      rethrow;
    } catch (e) {
      // Handle any unexpected errors

      throw Exception('Failed to link wishlist to event. Please try again.');
    }
  }

  /// Unlink a wishlist from an event
  ///
  /// [eventId] - Event ID to unlink wishlist from (required)
  ///
  /// Returns the updated event data
  Future<Event> unlinkWishlistFromEvent({
    required String eventId,
  }) async {
    try {

      // Prepare request body with null wishlist_id to unlink
      final requestData = <String, dynamic>{'wishlist_id': null};

      // Make API call to unlink wishlist
      // Endpoint: PUT /api/events/:id/wishlist
      final response = await _apiService.put(
        '/events/$eventId/wishlist',
        data: requestData,
      );

      // Parse response and create Event object
      // API response structure: {success: true, data: {...}} or {id, name, ...}
      final eventData = response['data'] ?? response;

      if (eventData is! Map<String, dynamic>) {
        throw Exception('Invalid response format from server');
      }

      // Create Event object from response
      final event = Event.fromJson(eventData);

      return event;
    } on ApiException catch (e) {
      // Re-throw ApiException to preserve error details

      rethrow;
    } catch (e) {
      // Handle any unexpected errors

      throw Exception('Failed to unlink wishlist from event. Please try again.');
    }
  }
}
