import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/services/socket_service.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';
import 'package:wish_listy/features/notifications/data/models/notification_model.dart';
import 'package:wish_listy/features/events/data/repository/event_repository.dart';
import 'package:wish_listy/features/wishlists/data/repository/wishlist_repository.dart';
import 'package:wish_listy/features/wishlists/data/models/wishlist_model.dart';

/// Notifications State
abstract class NotificationsState extends Equatable {
  const NotificationsState();

  @override
  List<Object?> get props => [];
}

class NotificationsInitial extends NotificationsState {}

class NotificationsLoading extends NotificationsState {}

class NotificationsLoaded extends NotificationsState {
  final List<AppNotification> notifications;
  final int unreadCount;
  final bool isNewNotification; // Flag to indicate if this is a new notification from Socket

  const NotificationsLoaded({
    required this.notifications,
    required this.unreadCount,
    this.isNewNotification = false, // Default to false (for API loads)
  });

  @override
  List<Object?> get props => [notifications, unreadCount, isNewNotification];

  NotificationsLoaded copyWith({
    List<AppNotification>? notifications,
    int? unreadCount,
    bool? isNewNotification,
  }) {
    return NotificationsLoaded(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isNewNotification: isNewNotification ?? this.isNewNotification,
    );
  }
}

class NotificationsError extends NotificationsState {
  final String message;

  const NotificationsError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Notifications Cubit
class NotificationsCubit extends Cubit<NotificationsState> {
  final SocketService _socketService = SocketService();
  final ApiService _apiService = ApiService();
  final EventRepository _eventRepository = EventRepository();
  final AuthRepository _authRepository = AuthRepository();
  
  // StreamController to notify EventDetailsScreen when event is updated
  final StreamController<String> _eventUpdateController = StreamController<String>.broadcast();
  Stream<String> get eventUpdateStream => _eventUpdateController.stream;

  NotificationsCubit() : super(NotificationsInitial()) {
    final initTimestamp = DateTime.now().toIso8601String();
    debugPrint('🔔 [NotificationsCubit] ⏰ [$initTimestamp] ========== INITIALIZING ==========');
    debugPrint('🔔 [NotificationsCubit] ⏰ [$initTimestamp] Initializing NotificationsCubit...');
    _setupSocketListeners();
    debugPrint('🔔 [NotificationsCubit] ⏰ [$initTimestamp] ✅ Initialized with socket listener');
    
    // Debug: Check if socket is connected after initialization
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final statusCheckTimestamp = DateTime.now().toIso8601String();
      final status = _socketService.getConnectionStatus();
      debugPrint('🔔 [NotificationsCubit] ⏰ [$statusCheckTimestamp] Socket status check (post-init)');
      debugPrint('🔔 [NotificationsCubit] ⏰ [$statusCheckTimestamp]    Connected: ${status['isConnected']}');
      debugPrint('🔔 [NotificationsCubit] ⏰ [$statusCheckTimestamp]    Connecting: ${status['isConnecting']}');
      debugPrint('🔔 [NotificationsCubit] ⏰ [$statusCheckTimestamp]    Socket ID: ${status['socketId']}');
      debugPrint('🔔 [NotificationsCubit] ⏰ [$statusCheckTimestamp]    Listeners: ${status['listenersCount']}');
      debugPrint('🔔 [NotificationsCubit] ⏰ [$statusCheckTimestamp]    URL: ${status['socketUrl']}');
      
      // If socket is connected but listener count is 0, re-register
      if (status['isConnected'] == true && status['listenersCount'] == 0) {
        debugPrint('🔔 [NotificationsCubit] ⏰ [$statusCheckTimestamp]    ⚠️ Socket connected but no listeners! Re-registering...');
        _setupSocketListeners();
      }
    });
  }

  /// Setup Socket.IO listeners for real-time notifications
  /// This method can be called multiple times safely (e.g., after reconnection)
  void _setupSocketListeners() {
    final setupTimestamp = DateTime.now().toIso8601String();
    debugPrint('🔔 [NotificationsCubit] ⏰ [$setupTimestamp] ========== SETTING UP SOCKET LISTENER ==========');
    debugPrint('🔔 [NotificationsCubit] ⏰ [$setupTimestamp] Setting up socket listener...');
    debugPrint('🔔 [NotificationsCubit] ⏰ [$setupTimestamp]    SocketService instance: ${_socketService.hashCode}');
    debugPrint('🔔 [NotificationsCubit] ⏰ [$setupTimestamp]    Handler function: ${_handleSocketNotification.runtimeType}');
    debugPrint('🔔 [NotificationsCubit] ⏰ [$setupTimestamp]    Handler hash: ${_handleSocketNotification.hashCode}');
    
    // Get status before adding listener
    final statusBefore = _socketService.getConnectionStatus();
    debugPrint('🔔 [NotificationsCubit] ⏰ [$setupTimestamp]    Listeners count BEFORE: ${statusBefore['listenersCount']}');
    debugPrint('🔔 [NotificationsCubit] ⏰ [$setupTimestamp]    Socket connected: ${statusBefore['isConnected']}');
    debugPrint('🔔 [NotificationsCubit] ⏰ [$setupTimestamp]    Socket ID: ${statusBefore['socketId']}');
    
    // Remove existing listener first to avoid duplicates
    _socketService.removeNotificationListener(_handleSocketNotification);
    debugPrint('🔔 [NotificationsCubit] ⏰ [$setupTimestamp]    Removed existing listener (if any)');
    
    // Add the listener
    _socketService.addNotificationListener(_handleSocketNotification);
    debugPrint('🔔 [NotificationsCubit] ⏰ [$setupTimestamp]    ✅ Listener added');
    
    // Get status after adding listener
    final statusAfter = _socketService.getConnectionStatus();
    debugPrint('🔔 [NotificationsCubit] ⏰ [$setupTimestamp]    Listeners count AFTER: ${statusAfter['listenersCount']}');
    debugPrint('🔔 [NotificationsCubit] ⏰ [$setupTimestamp]    Socket exists: ${_socketService.socket != null}');
    debugPrint('🔔 [NotificationsCubit] ⏰ [$setupTimestamp]    Is connected: ${statusAfter['isConnected']}');
    
    // Verify listener was added
    if (statusAfter['listenersCount'] == 0) {
      debugPrint('🔔 [NotificationsCubit] ⏰ [$setupTimestamp]    ❌❌❌ ERROR: Listener count is still 0 after adding!');
      debugPrint('🔔 [NotificationsCubit] ⏰ [$setupTimestamp]    This means the listener was not registered properly.');
    } else {
      debugPrint('🔔 [NotificationsCubit] ⏰ [$setupTimestamp]    ✅✅✅ Listener registered successfully!');
      debugPrint('🔔 [NotificationsCubit] ⏰ [$setupTimestamp]    Ready to receive socket notifications');
    }
    debugPrint('🔔 [NotificationsCubit] ⏰ [$setupTimestamp] ========== SETUP COMPLETE ==========');
  }

  /// Handle notification from Socket.IO
  Future<void> _handleSocketNotification(Map<String, dynamic> data) async {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('🔔 [Notifications] ⏰ [$timestamp] ========== SOCKET NOTIFICATION RECEIVED ==========');
    debugPrint('🔔 [Notifications] ⏰ [$timestamp] Received socket notification from SocketService');
    debugPrint('🔔 [Notifications] ⏰ [$timestamp]    Raw data: $data');
    debugPrint('🔔 [Notifications] ⏰ [$timestamp]    Data type: ${data.runtimeType}');
    debugPrint('🔔 [Notifications] ⏰ [$timestamp]    Current state: ${state.runtimeType}');
    
    // Handle unread_count_update event separately
    if (data['type'] == 'unreadCountUpdate') {
      final updateTimestamp = DateTime.now().toIso8601String();
      final unreadCount = data['unreadCount'] as int? ?? 0;
      debugPrint('🔔 [Notifications] ⏰ [$updateTimestamp] Handling unread_count_update');
      debugPrint('🔔 [Notifications] ⏰ [$updateTimestamp]    New unreadCount: $unreadCount');
      
      if (state is NotificationsLoaded) {
        final currentState = state as NotificationsLoaded;
        debugPrint('🔔 [Notifications] ⏰ [$updateTimestamp]    Current unreadCount: ${currentState.unreadCount}');
        debugPrint('🔔 [Notifications] ⏰ [$updateTimestamp]    Syncing unreadCount to: $unreadCount');
        
        emit(NotificationsLoaded(
          notifications: currentState.notifications,
          unreadCount: unreadCount,
          isNewNotification: false, // This is a sync, not a new notification
        ));
        
        debugPrint('🔔 [Notifications] ⏰ [$updateTimestamp]    ✅ Unread count synced successfully');
        debugPrint('🔔 [Notifications] ⏰ [$updateTimestamp]    ✅ State emitted - BlocBuilder should rebuild now');
      } else {
        debugPrint('🔔 [Notifications] ⏰ [$updateTimestamp]    ⚠️ State not loaded, loading notifications...');
        // Load notifications first, then update count
        await loadNotifications();
        // After loading, update with the unread count from socket
        if (state is NotificationsLoaded) {
          final loadedState = state as NotificationsLoaded;
          emit(loadedState.copyWith(unreadCount: unreadCount));
          debugPrint('🔔 [Notifications] ⏰ [$updateTimestamp]    ✅ Unread count updated after loading');
        }
      }
      return;
    }
    
    try {
      // Try to parse as AppNotification
      AppNotification notification;
      try {
        debugPrint('🔔 [Notifications] ⏰ [$timestamp]    Attempting to parse notification...');
        notification = AppNotification.fromJson(data);
        debugPrint('🔔 [Notifications] ⏰ [$timestamp]    ✅ Parsed successfully');
        debugPrint('🔔 [Notifications] ⏰ [$timestamp]    Notification details:');
        debugPrint('🔔 [Notifications] ⏰ [$timestamp]       - ID: ${notification.id}');
        debugPrint('🔔 [Notifications] ⏰ [$timestamp]       - Type: ${notification.type}');
        debugPrint('🔔 [Notifications] ⏰ [$timestamp]       - Title: ${notification.title}');
        debugPrint('🔔 [Notifications] ⏰ [$timestamp]       - Message: ${notification.message}');
        debugPrint('🔔 [Notifications] ⏰ [$timestamp]       - User ID: ${notification.userId}');
        debugPrint('🔔 [Notifications] ⏰ [$timestamp]       - Is Read: ${notification.isRead}');
        debugPrint('🔔 [Notifications] ⏰ [$timestamp]       - Created At: ${notification.createdAt}');
      } catch (parseError) {
        final parseErrorTimestamp = DateTime.now().toIso8601String();
        debugPrint('🔔 [Notifications] ⏰ [$parseErrorTimestamp]    ⚠️ Failed to parse notification, trying alternative format');
        debugPrint('🔔 [Notifications] ⏰ [$parseErrorTimestamp]       Parse error: $parseError');
        // If direct parsing fails, try wrapping it
        debugPrint('🔔 [Notifications] ⏰ [$parseErrorTimestamp]    Attempting alternative parsing...');
        notification = AppNotification.fromJson({
          '_id': data['_id'] ?? data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          'userId': data['userId'] ?? data['user_id'] ?? '',
          'type': data['type'] ?? 'general',
          'title': data['title'] ?? data['message'] ?? 'New Notification',
          'message': data['message'] ?? data['body'] ?? '',
          'data': data,
          'isRead': false,
          'createdAt': data['createdAt'] ?? data['created_at'] ?? DateTime.now().toIso8601String(),
        });
        debugPrint('🔔 [Notifications] ⏰ [$parseErrorTimestamp]    ✅ Alternative parsing successful');
        debugPrint('🔔 [Notifications] ⏰ [$parseErrorTimestamp]       - Type: ${notification.type}');
        debugPrint('🔔 [Notifications] ⏰ [$parseErrorTimestamp]       - Title: ${notification.title}');
      }
      
      // CRITICAL: Always update state immediately, regardless of current state
      // This ensures instant badge count update for better UX
      final stateUpdateTimestamp = DateTime.now().toIso8601String();
      debugPrint('🔔 [Notifications] ⏰ [$stateUpdateTimestamp] ========== UPDATING STATE IMMEDIATELY ==========');
      
      List<AppNotification> updatedNotifications;
      int currentUnreadCount = 0;
      
      if (state is NotificationsLoaded) {
        final currentState = state as NotificationsLoaded;
        debugPrint('🔔 [Notifications] ⏰ [$stateUpdateTimestamp]    Current state is NotificationsLoaded');
        debugPrint('🔔 [Notifications] ⏰ [$stateUpdateTimestamp]       Current notifications count: ${currentState.notifications.length}');
        debugPrint('🔔 [Notifications] ⏰ [$stateUpdateTimestamp]       Current unread count: ${currentState.unreadCount}');
        
        updatedNotifications = [notification, ...currentState.notifications];
        currentUnreadCount = currentState.unreadCount;
      } else {
        // State is NotificationsInitial or NotificationsLoading
        // Create a minimal state with just this notification for instant feedback
        debugPrint('🔔 [Notifications] ⏰ [$stateUpdateTimestamp]    ⚠️ State is ${state.runtimeType} - Creating immediate state');
        debugPrint('🔔 [Notifications] ⏰ [$stateUpdateTimestamp]       Will load full notifications in background');
        
        updatedNotifications = [notification];
        currentUnreadCount = 0; // Will be incremented to 1 below
        
        // Load full notifications in background (non-blocking)
        loadNotifications().catchError((e) {
          debugPrint('🔔 [Notifications] ⏰ [$stateUpdateTimestamp]    ⚠️ Background load failed: $e');
        });
      }
      
      // IMPORTANT: Always increment unreadCount by 1 immediately for instant visual feedback
      // Extract unreadCount from payload if available, otherwise increment current count
      int newUnreadCount;
      if (data['unreadCount'] != null || data['unread_count'] != null) {
        newUnreadCount = data['unreadCount'] as int? ?? data['unread_count'] as int? ?? 0;
        debugPrint('🔔 [Notifications] ⏰ [$stateUpdateTimestamp]    ✅ Using unreadCount from payload: $newUnreadCount');
      } else {
        // Increment current count by 1 for immediate feedback
        newUnreadCount = currentUnreadCount + 1;
        debugPrint('🔔 [Notifications] ⏰ [$stateUpdateTimestamp]    ⚠️ unreadCount not in payload');
        debugPrint('🔔 [Notifications] ⏰ [$stateUpdateTimestamp]    ✅ Incrementing unreadCount: $currentUnreadCount -> $newUnreadCount (INSTANT UPDATE)');
      }
      
      // Emit state IMMEDIATELY with incremented count
      debugPrint('🔔 [Notifications] ⏰ [$stateUpdateTimestamp]    📤 EMITTING STATE NOW...');
      debugPrint('🔔 [Notifications] ⏰ [$stateUpdateTimestamp]       Notifications: ${updatedNotifications.length}');
      debugPrint('🔔 [Notifications] ⏰ [$stateUpdateTimestamp]       Unread count: $newUnreadCount');
      debugPrint('🔔 [Notifications] ⏰ [$stateUpdateTimestamp]       Is new notification: true');
      
      emit(NotificationsLoaded(
        notifications: updatedNotifications,
        unreadCount: newUnreadCount,
        isNewNotification: true, // Mark as new notification from Socket
      ));
      
      final emitCompleteTimestamp = DateTime.now().toIso8601String();
      debugPrint('🔔 [Notifications] ⏰ [$emitCompleteTimestamp]    ✅✅✅ STATE EMITTED SUCCESSFULLY ✅✅✅');
      debugPrint('🔔 [Notifications] ⏰ [$emitCompleteTimestamp]       BlocBuilder should rebuild NOW');
      debugPrint('🔔 [Notifications] ⏰ [$emitCompleteTimestamp]       Badge count should update to: $newUnreadCount');
      
      // If unreadCount was not in payload, fetch accurate count from backend (async, non-blocking)
      if (data['unreadCount'] == null && data['unread_count'] == null) {
        debugPrint('🔔 [Notifications] ⏰ [$emitCompleteTimestamp]    🔄 Fetching accurate count from backend (async)...');
        try {
          final accurateCount = await getUnreadCount();
          debugPrint('🔔 [Notifications] ⏰ [$emitCompleteTimestamp]    ✅ Fetched accurate unreadCount: $accurateCount');
          
          // Update state with accurate count (only if state hasn't changed)
          if (state is NotificationsLoaded) {
            final latestState = state as NotificationsLoaded;
            if (latestState.unreadCount != accurateCount) {
              debugPrint('🔔 [Notifications] ⏰ [$emitCompleteTimestamp]    🔄 Syncing unreadCount: ${latestState.unreadCount} -> $accurateCount');
              emit(latestState.copyWith(
                unreadCount: accurateCount,
                isNewNotification: false, // Don't show snackbar again
              ));
              debugPrint('🔔 [Notifications] ⏰ [$emitCompleteTimestamp]    ✅ Count synced successfully');
            } else {
              debugPrint('🔔 [Notifications] ⏰ [$emitCompleteTimestamp]    ✅ Count already accurate, no update needed');
            }
          }
        } catch (e) {
          debugPrint('🔔 [Notifications] ⏰ [$emitCompleteTimestamp]    ⚠️ Failed to fetch accurate count: $e');
          debugPrint('🔔 [Notifications] ⏰ [$emitCompleteTimestamp]       Keeping optimistic count: $newUnreadCount');
          // Keep the optimistic count - it's better than showing nothing
        }
      }
      
      debugPrint('🔔 [Notifications] ⏰ [$emitCompleteTimestamp] ========== HANDLING COMPLETE ==========');
    } catch (e, stackTrace) {
      final errorTimestamp = DateTime.now().toIso8601String();
      debugPrint('🔔 [Notifications] ⏰ [$errorTimestamp]    ❌❌❌ ERROR HANDLING SOCKET NOTIFICATION ❌❌❌');
      debugPrint('🔔 [Notifications] ⏰ [$errorTimestamp]       Error: $e');
      debugPrint('🔔 [Notifications] ⏰ [$errorTimestamp]       Error type: ${e.runtimeType}');
      debugPrint('🔔 [Notifications] ⏰ [$errorTimestamp]       Stack trace: $stackTrace');
      
      // Even on error, try to increment count if state is loaded
      if (state is NotificationsLoaded) {
        final currentState = state as NotificationsLoaded;
        final errorCount = currentState.unreadCount + 1;
        debugPrint('🔔 [Notifications] ⏰ [$errorTimestamp]    ⚠️ Attempting fallback: incrementing count to $errorCount');
        emit(currentState.copyWith(
          unreadCount: errorCount,
          isNewNotification: false,
        ));
      }
    }
  }

  /// Load notifications from API
  Future<void> loadNotifications() async {
    // Don't make API calls for guest users
    if (_authRepository.isGuest) {
      debugPrint('⚠️ NotificationsCubit: Skipping API call for guest user');
      emit(NotificationsLoaded(
        notifications: [],
        unreadCount: 0,
        isNewNotification: false,
      ));
      return;
    }

    try {
      emit(NotificationsLoading());

      final response = await _apiService.get('/notifications');

      debugPrint('📥 NotificationsCubit: API Response: $response');

      // Handle different response formats
      List<dynamic> notificationsList = [];
      int unreadCount = 0;

      // IMPORTANT: unreadCount MUST come from backend (calculated based on lastBadgeSeenAt)
      // We cannot calculate it locally because backend uses lastBadgeSeenAt logic
      
      // Get unreadCount from response (backend calculates it based on lastBadgeSeenAt)
      // Try multiple possible locations in response
      if (response.containsKey('unreadCount')) {
        unreadCount = response['unreadCount'] as int? ?? 0;
        debugPrint('📥 NotificationsCubit: Found unreadCount at top level: $unreadCount');
      } else if (response.containsKey('unread_count')) {
        unreadCount = response['unread_count'] as int? ?? 0;
        debugPrint('📥 NotificationsCubit: Found unread_count at top level: $unreadCount');
      } else if (response.containsKey('data') && response['data'] is Map<String, dynamic>) {
        final data = response['data'] as Map<String, dynamic>;
        if (data.containsKey('unreadCount')) {
          unreadCount = data['unreadCount'] as int? ?? 0;
          debugPrint('📥 NotificationsCubit: Found unreadCount in data object: $unreadCount');
        } else if (data.containsKey('unread_count')) {
          unreadCount = data['unread_count'] as int? ?? 0;
          debugPrint('📥 NotificationsCubit: Found unread_count in data object: $unreadCount');
        }
      }

      // Check if response has 'data' field for notifications list
      if (response.containsKey('data')) {
        final data = response['data'];
        
        // Case 1: data is an array directly (actual API response)
        if (data is List) {
          notificationsList = data;
          debugPrint('📥 NotificationsCubit: Found notifications array in data (${notificationsList.length} items)');
        }
        // Case 2: data is an object with 'notifications' field (documentation format)
        else if (data is Map<String, dynamic>) {
          notificationsList = data['notifications'] as List<dynamic>? ?? [];
          debugPrint('📥 NotificationsCubit: Found notifications in data.notifications (${notificationsList.length} items)');
        }
      } else if (response is List) {
        // Case 3: Response is directly an array
        notificationsList = response as List<dynamic>;
        debugPrint('📥 NotificationsCubit: Response is directly an array (${notificationsList.length} items)');
      }

      // WARNING: Do NOT calculate unreadCount locally!
      // Backend calculates it based on lastBadgeSeenAt, which we don't have access to
      // If unreadCount is missing from response, fetch it from the dedicated endpoint
      if (unreadCount == 0 && !response.containsKey('unreadCount') && 
          !response.containsKey('unread_count') &&
          !(response.containsKey('data') && response['data'] is Map && 
            (response['data'] as Map).containsKey('unreadCount'))) {
        debugPrint('⚠️ NotificationsCubit: unreadCount not found in response, fetching from dedicated endpoint...');
        try {
          // Note: getUnreadCount() is defined below, but we need to call it here
          // For now, we'll fetch it directly
          final unreadResponse = await _apiService.get('/notifications/unread-count');
          if (unreadResponse is Map<String, dynamic>) {
            unreadCount = unreadResponse['unreadCount'] as int? ?? 
                         unreadResponse['unread_count'] as int? ?? 
                         unreadResponse['data']?['unreadCount'] as int? ??
                         unreadResponse['data']?['unread_count'] as int? ??
                         0;
          } else if (unreadResponse is int) {
            unreadCount = unreadResponse as int;
          } else {
            debugPrint('⚠️ NotificationsCubit: Unexpected unreadResponse type: ${unreadResponse.runtimeType}');
            unreadCount = 0;
          }
          debugPrint('📥 NotificationsCubit: Fetched unreadCount from /notifications/unread-count: $unreadCount');
        } catch (e) {
          debugPrint('⚠️ NotificationsCubit: Failed to fetch unreadCount, using 0: $e');
          unreadCount = 0;
        }
      }

      // Parse notifications
      final notifications = notificationsList
          .map((json) {
            try {
              return AppNotification.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              debugPrint('⚠️ NotificationsCubit: Failed to parse notification: $e');
              debugPrint('   Notification data: $json');
              return null;
            }
          })
          .whereType<AppNotification>()
          .toList();

      debugPrint('✅ NotificationsCubit: Loaded ${notifications.length} notifications, $unreadCount unread');

      emit(NotificationsLoaded(
        notifications: notifications,
        unreadCount: unreadCount,
        isNewNotification: false, // This is from API load, not new Socket notification
      ));
    } on ApiException catch (e) {
      debugPrint('❌ NotificationsCubit: API Error: ${e.message}');
      emit(NotificationsError(e.message));
    } catch (e, stackTrace) {
      debugPrint('❌ NotificationsCubit: Error loading notifications: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      emit(NotificationsError('Failed to load notifications. Please try again.'));
    }
  }

  /// Mark notification as read (individual notification)
  Future<void> markAsRead(String notificationId) async {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('🔔 [Notifications] ⏰ [$timestamp] Marking notification as read');
    debugPrint('🔔 [Notifications] ⏰ [$timestamp]    Notification ID: $notificationId');
    
    try {
      if (state is! NotificationsLoaded) {
        debugPrint('🔔 [Notifications] ⏰ [$timestamp]    ⚠️ State is not loaded, skipping');
        return;
      }

      final currentState = state as NotificationsLoaded;
      debugPrint('🔔 [Notifications] ⏰ [$timestamp]    Current unread count: ${currentState.unreadCount}');
      
      // Optimistically update UI
      final updatedNotifications = currentState.notifications.map((n) {
        if (n.id == notificationId && !n.isRead) {
          debugPrint('🔔 [Notifications] ⏰ [$timestamp]    Found notification to mark as read');
          return n.markAsRead();
        }
        return n;
      }).toList();

      final unreadCount = updatedNotifications.where((n) => !n.isRead).length;
      debugPrint('🔔 [Notifications] ⏰ [$timestamp]    New unread count: $unreadCount');

      emit(NotificationsLoaded(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
        isNewNotification: false, // This is a state update, not new Socket notification
      ));

      // Update on backend using PATCH as per requirements
      debugPrint('🔔 [Notifications] ⏰ [$timestamp]    Calling API: PATCH /notifications/$notificationId/read');
      await _apiService.patch('/notifications/$notificationId/read');
      debugPrint('🔔 [Notifications] ⏰ [$timestamp]    ✅ Notification marked as read successfully');
    } on ApiException catch (e) {
      debugPrint('❌ NotificationsCubit: Error marking as read: ${e.message}');
      // Reload to sync with backend
      loadNotifications();
    } catch (e) {
      debugPrint('❌ NotificationsCubit: Error marking as read: $e');
      loadNotifications();
    }
  }

  /// Get unread count from backend (uses lastBadgeSeenAt logic)
  /// This endpoint returns the count of notifications where:
  /// - createdAt > lastBadgeSeenAt
  /// - AND isRead == false
  Future<int> getUnreadCount() async {
    // Don't make API calls for guest users
    if (_authRepository.isGuest) {
      debugPrint('⚠️ NotificationsCubit: Skipping unread count API call for guest user');
      return 0;
    }

    final timestamp = DateTime.now().toIso8601String();
    debugPrint('🔔 [Notifications] ⏰ [$timestamp] Fetching unread count from backend');
    
    try {
      final response = await _apiService.get('/notifications/unread-count');
      debugPrint('🔔 [Notifications] ⏰ [$timestamp]    API Response: $response');
      
      // Handle different response formats
      int unreadCount = 0;
      if (response is Map<String, dynamic>) {
        unreadCount = response['unreadCount'] as int? ?? 
                     response['unread_count'] as int? ?? 
                     (response['data'] as Map<String, dynamic>?)?['unreadCount'] as int? ??
                     (response['data'] as Map<String, dynamic>?)?['unread_count'] as int? ??
                     0;
      } else if (response is int) {
        unreadCount = response as int;
      } else {
        debugPrint('⚠️ NotificationsCubit: Unexpected response type for unread count: ${response.runtimeType}');
        unreadCount = 0;
      }
      
      debugPrint('🔔 [Notifications] ⏰ [$timestamp]    Unread count: $unreadCount');
      
      // Update state - if loaded, update it; if not loaded, create a minimal state with unreadCount
      if (state is NotificationsLoaded) {
        final currentState = state as NotificationsLoaded;
        emit(currentState.copyWith(
          unreadCount: unreadCount,
          isNewNotification: false,
        ));
      } else if (state is! NotificationsLoading) {
        // If state is not loaded and not loading, create a minimal state with unreadCount
        // This allows the badge to show the correct count even before notifications are loaded
        emit(NotificationsLoaded(
          notifications: [],
          unreadCount: unreadCount,
          isNewNotification: false,
        ));
      }
      
      return unreadCount;
    } on ApiException catch (e) {
      debugPrint('❌ NotificationsCubit: Error fetching unread count: ${e.message}');
      return 0;
    } catch (e) {
      debugPrint('❌ NotificationsCubit: Error fetching unread count: $e');
      return 0;
    }
  }

  /// Dismiss badge (update lastBadgeSeenAt on backend)
  /// This is used when opening the notification dropdown - just hide the badge
  /// Individual notifications will be marked as read when clicked
  Future<void> dismissBadge() async {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('🔔 [Notifications] ⏰ [$timestamp] Dismissing badge (updating lastBadgeSeenAt)');
    
    try {
      if (state is! NotificationsLoaded) {
        debugPrint('🔔 [Notifications] ⏰ [$timestamp]    ⚠️ State is not loaded, skipping');
        return;
      }

      final currentState = state as NotificationsLoaded;
      debugPrint('🔔 [Notifications] ⏰ [$timestamp]    Current unreadCount: ${currentState.unreadCount}');
      
      // Optimistically set unreadCount to 0 immediately (better UX)
      emit(NotificationsLoaded(
        notifications: currentState.notifications,
        unreadCount: 0,
        isNewNotification: false,
      ));
      
      // Call backend API to update lastBadgeSeenAt (fire and forget)
      debugPrint('🔔 [Notifications] ⏰ [$timestamp]    Calling API: PATCH /api/notifications/dismiss-badge');
      _apiService.patch('/notifications/dismiss-badge').then((_) {
        // After API call succeeds, fetch accurate unreadCount from backend
        // This ensures sync but doesn't block UI
        getUnreadCount().then((unreadCount) {
          if (state is NotificationsLoaded) {
            final currentState = state as NotificationsLoaded;
            emit(NotificationsLoaded(
              notifications: currentState.notifications,
              unreadCount: unreadCount,
              isNewNotification: false,
            ));
          }
        }).catchError((e) {
          debugPrint('🔔 [Notifications] ⏰ [$timestamp]    ⚠️ Error fetching unreadCount: $e');
        });
      }).catchError((e) {
        debugPrint('❌ NotificationsCubit: Error dismissing badge: ${e.message}');
        // On error, revert to original unreadCount
        if (state is NotificationsLoaded) {
          final currentState = state as NotificationsLoaded;
          // Recalculate unreadCount from notifications
          final unreadCount = currentState.notifications.where((n) => !n.isRead).length;
          emit(NotificationsLoaded(
            notifications: currentState.notifications,
            unreadCount: unreadCount,
            isNewNotification: false,
          ));
        }
      });
      
      debugPrint('🔔 [Notifications] ⏰ [$timestamp]    ✅ Badge dismissed (optimistic update)');
    } catch (e) {
      debugPrint('❌ NotificationsCubit: Error dismissing badge: $e');
      // Don't reload on error - just log it
    }
  }

  /// Mark all notifications as read (API call)
  Future<void> markAllAsRead() async {
    try {
      if (state is! NotificationsLoaded) return;

      await _apiService.patch('/notifications/read-all');

      // Reload notifications
      await loadNotifications();
    } on ApiException catch (e) {
      debugPrint('❌ NotificationsCubit: Error marking all as read: ${e.message}');
    } catch (e) {
      debugPrint('❌ NotificationsCubit: Error marking all as read: $e');
    }
  }

  /// Respond to an event invitation (RSVP)
  /// 
  /// [eventId] - Event ID to respond to
  /// [status] - RSVP status: 'accepted', 'declined', or 'maybe'
  Future<void> respondToEvent(String eventId, String status) async {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('🔔 [Notifications] ⏰ [$timestamp] Responding to event invitation');
    debugPrint('🔔 [Notifications] ⏰ [$timestamp]    Event ID: $eventId');
    debugPrint('🔔 [Notifications] ⏰ [$timestamp]    Status: $status');
    
    try {
      // Call EventRepository to respond to invitation
      await _eventRepository.respondToEventInvitation(
        eventId: eventId,
        status: status,
      );
      
      debugPrint('🔔 [Notifications] ⏰ [$timestamp]    ✅ Successfully responded to event invitation');
      
      // Notify EventDetailsScreen to refresh if it's open
      if (!_eventUpdateController.isClosed) {
        _eventUpdateController.add(eventId);
        debugPrint('🔔 [Notifications] ⏰ [$timestamp]    📢 Sent event update signal for: $eventId');
      }
      
      // Note: loadNotifications() is called by deleteNotification() if needed
      // No need to reload here to avoid race conditions
    } on ApiException catch (e) {
      debugPrint('❌ NotificationsCubit: Error responding to event: ${e.message}');
      rethrow; // Re-throw to allow UI to handle the error
    } catch (e, stackTrace) {
      debugPrint('❌ NotificationsCubit: Error responding to event: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      rethrow; // Re-throw to allow UI to handle the error
    }
  }

  /// Handle notification tap with smart navigation
  /// 
  /// Centralized redirection logic for all notification types.
  /// First marks the notification as read, then navigates to the appropriate screen
  /// based on the notification type.
  /// 
  /// Navigation Rules:
  /// - Social (friend_request, friend_request_accepted): User Profile Screen (relatedUser._id)
  /// - Events (event_invite, event_update, event_response): Event Details Screen (relatedId)
  /// - Gifts (item_reserved, item_unreserved, item_purchased, item_received): Item Details Screen (relatedId + relatedWishlistId)
  Future<void> handleNotificationTap(AppNotification notification, BuildContext context) async {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('🔔 [Notifications] ⏰ [$timestamp] ========== NOTIFICATION TAP HANDLER ==========');
    debugPrint('🔔 [Notifications] ⏰ [$timestamp]    ID: ${notification.id}');
    debugPrint('🔔 [Notifications] ⏰ [$timestamp]    Type: ${notification.type}');
    debugPrint('🔔 [Notifications] ⏰ [$timestamp]    RelatedId: ${notification.relatedId}');
    debugPrint('🔔 [Notifications] ⏰ [$timestamp]    RelatedWishlistId: ${notification.relatedWishlistId}');
    debugPrint('🔔 [Notifications] ⏰ [$timestamp]    Data keys: ${notification.data?.keys.toList()}');
    
    // Get localization service early
    final localization = Provider.of<LocalizationService>(context, listen: false);
    
    // First, mark as read (non-blocking for better UX)
    markAsRead(notification.id);
    
    // Helper to show error toast
    void showErrorToast(String messageKey) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localization.translate(messageKey)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
    
    // Helper to extract user ID from notification data
    String? extractUserId() {
      final data = notification.data;
      if (data == null) return null;
      
      // Check relatedUser first (most common)
      final relatedUser = data['relatedUser'];
      if (relatedUser is Map<String, dynamic>) {
        final id = relatedUser['_id']?.toString() ?? relatedUser['id']?.toString();
        if (id != null && id.isNotEmpty) return id;
      }
      
      // Fallback to other fields
      return data['relatedUserId']?.toString() ??
             data['related_user_id']?.toString() ??
             (data['from'] is Map ? data['from']['_id']?.toString() ?? data['from']['id']?.toString() : null) ??
             data['fromUserId']?.toString() ??
             data['from_user_id']?.toString();
    }
    
    // Helper to extract event ID
    String? extractEventId() {
      return notification.relatedId ?? 
             notification.data?['eventId']?.toString() ??
             notification.data?['event_id']?.toString() ??
             (notification.data?['event'] is Map ? notification.data!['event']['_id']?.toString() ?? notification.data!['event']['id']?.toString() : null);
    }
    
    // Helper to extract item ID
    String? extractItemId() {
      return notification.relatedId ?? 
             notification.data?['itemId']?.toString() ??
             notification.data?['item_id']?.toString() ??
             (notification.data?['item'] is Map ? notification.data!['item']['_id']?.toString() ?? notification.data!['item']['id']?.toString() : null);
    }
    
    // Helper to extract wishlist ID
    String? extractWishlistId() {
      return notification.relatedWishlistId ?? 
             notification.data?['wishlistId']?.toString() ??
             notification.data?['wishlist_id']?.toString() ??
             (notification.data?['wishlist'] is Map ? notification.data!['wishlist']['_id']?.toString() ?? notification.data!['wishlist']['id']?.toString() : null);
    }
    
    // Navigate based on notification type
    try {
      if (!context.mounted) return;
      
      switch (notification.type) {
        // ==========================================
        // SOCIAL (Friendships) - Navigate to User Profile
        // Types: friend_request, friend_request_accepted
        // ==========================================
        case NotificationType.friendRequest:
        case NotificationType.friendRequestAccepted:
          final userId = extractUserId();
          
          if (userId != null && userId.isNotEmpty) {
            debugPrint('🔔 [Notifications] ⏰ [$timestamp]    → Navigating to friend profile: $userId');
            Navigator.pushNamed(
              context,
              AppRoutes.friendProfile,
              arguments: {'friendId': userId},
            );
          } else {
            debugPrint('⚠️ [Notifications] ⏰ [$timestamp]    Missing userId for ${notification.type}');
            showErrorToast('dialogs.userNoLongerAvailable');
            // Fallback to friends screen
            Navigator.pushNamed(
              context,
              AppRoutes.friends,
              arguments: {'initialTabIndex': notification.type == NotificationType.friendRequest ? 1 : 0},
            );
          }
          break;
        
        // Friend request rejected - navigate to friends screen (Requests tab)
        case NotificationType.friendRequestRejected:
          debugPrint('🔔 [Notifications] ⏰ [$timestamp]    → Navigating to friends screen (Requests tab)');
          Navigator.pushNamed(
            context,
            AppRoutes.friends,
            arguments: {'initialTabIndex': 1}, // Requests tab
          );
          break;
        
        // ==========================================
        // EVENTS (Occasions) - Navigate to Event Details
        // Types: event_invite, event_update, event_response
        // ==========================================
        case NotificationType.eventInvitation:
        case NotificationType.eventUpdate:
        case NotificationType.eventReminder:
        case NotificationType.eventResponse:
          final eventId = extractEventId();
          
          if (eventId != null && eventId.isNotEmpty) {
            debugPrint('🔔 [Notifications] ⏰ [$timestamp]    → Navigating to event details: $eventId');
            Navigator.pushNamed(
              context,
              AppRoutes.eventDetails,
              arguments: {'eventId': eventId},
            );
          } else {
            debugPrint('⚠️ [Notifications] ⏰ [$timestamp]    Missing eventId for ${notification.type}');
            showErrorToast('dialogs.eventNoLongerAvailable');
          }
          break;
        
        // ==========================================
        // GIFTS & WISHLISTS - Navigate to Item Details
        // Types: item_reserved, item_unreserved, item_purchased, item_received
        // ==========================================
        case NotificationType.itemReserved:
        case NotificationType.itemUnreserved:
        case NotificationType.itemPurchased:
          final itemId = extractItemId();
          final wishlistId = extractWishlistId();
          
          debugPrint('🔔 [Notifications] ⏰ [$timestamp]    Item notification - itemId: $itemId, wishlistId: $wishlistId');
          
          // IMPORTANT: Capture navigator BEFORE any async operations
          // The context may become invalid after the dropdown is closed
          final navigator = Navigator.of(context);
          
          if (itemId != null && itemId.isNotEmpty && wishlistId != null && wishlistId.isNotEmpty) {
            debugPrint('🔔 [Notifications] ⏰ [$timestamp]    → Navigating to item details: $itemId');
            try {
              // Fetch item details and navigate
              final wishlistRepository = WishlistRepository();
              final itemData = await wishlistRepository.getItemById(itemId);
              final item = WishlistItem.fromJson(itemData);
              
              debugPrint('🔔 [Notifications] ⏰ [$timestamp]    ✅ Item fetched, navigating...');
              navigator.pushNamed(
                AppRoutes.itemDetails,
                arguments: item,
              );
            } catch (e) {
              debugPrint('⚠️ [Notifications] ⏰ [$timestamp]    Failed to fetch item: $e');
              // Fallback to wishlist items screen
              navigator.pushNamed(
                AppRoutes.wishlistItems,
                arguments: {
                  'wishlistId': wishlistId,
                  'wishlistName': notification.title,
                },
              );
            }
          } else if (wishlistId != null && wishlistId.isNotEmpty) {
            // Navigate to wishlist if only wishlistId is available
            debugPrint('🔔 [Notifications] ⏰ [$timestamp]    → Navigating to wishlist items: $wishlistId');
            navigator.pushNamed(
              AppRoutes.wishlistItems,
              arguments: {
                'wishlistId': wishlistId,
                'wishlistName': notification.title,
              },
            );
          } else {
            debugPrint('⚠️ [Notifications] ⏰ [$timestamp]    Missing required IDs for item notification');
            showErrorToast('dialogs.itemNoLongerAvailable');
          }
          break;
        
        // Wishlist shared - navigate to wishlist items
        case NotificationType.wishlistShared:
          final wishlistId = extractWishlistId();
          
          if (wishlistId != null && wishlistId.isNotEmpty) {
            debugPrint('🔔 [Notifications] ⏰ [$timestamp]    → Navigating to shared wishlist: $wishlistId');
            Navigator.pushNamed(
              context,
              AppRoutes.wishlistItems,
              arguments: {
                'wishlistId': wishlistId,
                'wishlistName': notification.title,
              },
            );
          } else {
            debugPrint('⚠️ [Notifications] ⏰ [$timestamp]    Missing wishlistId for wishlist shared notification');
            showErrorToast('dialogs.wishlistNoLongerAvailable');
          }
          break;
        
        // Default - show message as snackbar
        default:
          debugPrint('🔔 [Notifications] ⏰ [$timestamp]    Unknown type, showing message');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(notification.message),
              backgroundColor: Colors.blue,
              behavior: SnackBarBehavior.floating,
            ),
          );
          break;
      }
      
      debugPrint('🔔 [Notifications] ⏰ [$timestamp] ========== NAVIGATION COMPLETE ==========');
    } catch (e, stackTrace) {
      debugPrint('❌ NotificationsCubit: Error handling notification tap: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      showErrorToast('dialogs.errorOpeningNotification');
    }
  }

  /// Handle a notification tap coming from an external source (e.g., FCM).
  ///
  /// This method normalizes the raw payload into an [AppNotification] and then
  /// delegates to [handleNotificationTap] so that navigation logic remains
  /// centralized in a single place.
  Future<void> handleRemoteNotificationTap(
    Map<String, dynamic> data,
    BuildContext context,
  ) async {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('🔔 [Notifications] ⏰ [$timestamp] ========== REMOTE NOTIFICATION TAP ==========');
    debugPrint('🔔 [Notifications] ⏰ [$timestamp] Raw FCM data: $data');

    try {
      AppNotification notification;
      try {
        // Try direct parsing first if backend already sends a full notification object.
        notification = AppNotification.fromJson(data);
        debugPrint('🔔 [Notifications] ⏰ [$timestamp] Parsed AppNotification directly from data.');
      } catch (e) {
        debugPrint('⚠️ [Notifications] ⏰ [$timestamp] Failed direct parse, building fallback AppNotification: $e');

        final id = data['_id'] ??
            data['id'] ??
            data['notificationId'] ??
            data['notification_id'] ??
            DateTime.now().millisecondsSinceEpoch.toString();

        final typeString = data['type']?.toString() ?? 'general';
        NotificationType type;
        try {
          type = NotificationType.values.firstWhere(
            (t) => t.name == typeString,
            orElse: () => NotificationType.general,
          );
        } catch (_) {
          type = NotificationType.general;
        }

        final title =
            data['title']?.toString() ?? data['notificationTitle']?.toString() ?? 'Wish Listy';
        final message =
            data['message']?.toString() ?? data['notificationBody']?.toString() ?? '';

        notification = AppNotification(
          id: id.toString(),
          userId: data['userId']?.toString() ?? data['user_id']?.toString() ?? '',
          type: type,
          title: title,
          message: message,
          data: data,
          isRead: false,
          createdAt: DateTime.tryParse(
                data['createdAt']?.toString() ?? data['created_at']?.toString() ?? '',
              ) ??
              DateTime.now(),
          relatedId: data['relatedId']?.toString() ??
              data['related_id']?.toString() ??
              data['eventId']?.toString() ??
              data['itemId']?.toString(),
          relatedWishlistId: data['relatedWishlistId']?.toString() ??
              data['related_wishlist_id']?.toString() ??
              data['wishlistId']?.toString(),
        );
      }

      await handleNotificationTap(notification, context);
    } catch (e, stackTrace) {
      final errorTimestamp = DateTime.now().toIso8601String();
      debugPrint('❌ [Notifications] ⏰ [$errorTimestamp] Error in handleRemoteNotificationTap: $e');
      debugPrint('❌ [Notifications] ⏰ [$errorTimestamp] Stack trace: $stackTrace');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      if (state is! NotificationsLoaded) return;

      final currentState = state as NotificationsLoaded;
      final toDelete = currentState.notifications
          .cast<AppNotification?>()
          .firstWhere((n) => n?.id == notificationId, orElse: () => null);

      // Optimistically remove from UI
      final updatedNotifications =
          currentState.notifications.where((n) => n.id != notificationId).toList();

      // IMPORTANT: unreadCount is backend-driven (lastBadgeSeenAt), but for immediate UX
      // we can decrement if the removed notification was unread, then sync in background.
      final updatedUnreadCount = (toDelete != null && !toDelete.isRead)
          ? (currentState.unreadCount - 1).clamp(0, 1 << 30)
          : currentState.unreadCount;

      emit(NotificationsLoaded(
        notifications: updatedNotifications,
        unreadCount: updatedUnreadCount,
        isNewNotification: false, // This is a state update, not new Socket notification
      ));

      // Delete on backend
      await _apiService.delete('/notifications/$notificationId');

      // Sync unreadCount from backend (lastBadgeSeenAt logic)
      unawaited(getUnreadCount());
    } on ApiException catch (e) {
      debugPrint('❌ NotificationsCubit: Error deleting notification: ${e.message}');
      // Reload to sync with backend
      loadNotifications();
    } catch (e) {
      debugPrint('❌ NotificationsCubit: Error deleting notification: $e');
      loadNotifications();
    }
  }

  String? _extractFriendRequestId(AppNotification notification) {
    final d = notification.data;
    if (d == null) return null;
    final requestId = d['relatedId'] ??
        d['related_id'] ??
        d['requestId'] ??
        d['request_id'] ??
        d['id'] ??
        d['_id'];
    return requestId?.toString();
  }

  String? _extractFriendRequesterUserId(AppNotification notification) {
    final d = notification.data;
    if (d == null) return null;
    final friendId = d['relatedUser']?['_id']?.toString() ??
        d['relatedUser']?['id']?.toString() ??
        d['relatedUserId']?.toString() ??
        d['related_user_id']?.toString() ??
        d['from']?['_id']?.toString() ??
        d['from']?['id']?.toString() ??
        d['fromUserId']?.toString() ??
        d['from_user_id']?.toString();
    return friendId;
  }

  /// When a friend request is accepted/declined outside Notifications UI (e.g., Friend Profile),
  /// remove the corresponding notification from dropdown & notifications screen.
  ///
  /// We match by:
  /// - friendUserId (requester user id) extracted from notification payload
  /// - OR requestId if provided (best match)
  Future<void> resolveFriendRequestNotification({
    required String friendUserId,
    String? requestId,
  }) async {
    try {
      if (state is! NotificationsLoaded) return;
      final currentState = state as NotificationsLoaded;

      final matches = currentState.notifications.where((n) {
        if (n.type != NotificationType.friendRequest) return false;
        final extractedFriendId = _extractFriendRequesterUserId(n);
        if (extractedFriendId != null && extractedFriendId == friendUserId) {
          return true;
        }
        if (requestId != null && requestId.isNotEmpty) {
          final extractedRequestId = _extractFriendRequestId(n);
          return extractedRequestId != null && extractedRequestId == requestId;
        }
        return false;
      }).toList();

      if (matches.isEmpty) return;

      final idsToRemove = matches.map((e) => e.id).toSet();
      final updatedNotifications =
          currentState.notifications.where((n) => !idsToRemove.contains(n.id)).toList();
      final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

      emit(NotificationsLoaded(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
        isNewNotification: false,
      ));

      // Delete on backend (best effort). If it fails, reload to stay in sync.
      for (final id in idsToRemove) {
        await _apiService.delete('/notifications/$id');
      }
    } on ApiException catch (e) {
      debugPrint('❌ NotificationsCubit: Error resolving friend request notification: ${e.message}');
      loadNotifications();
    } catch (e) {
      debugPrint('❌ NotificationsCubit: Error resolving friend request notification: $e');
      loadNotifications();
    }
  }

  /// Optimistically remove a notification from the list
  /// Used for immediate UI feedback before API call completes
  void removeNotificationOptimistically(String notificationId) {
    final currentState = state;
    if (currentState is NotificationsLoaded) {
      final updatedNotifications = currentState.notifications
          .where((n) => n.id != notificationId)
          .toList();
      
      final newUnreadCount = currentState.unreadCount > 0 
          ? currentState.unreadCount - 1 
          : 0;
      
      emit(NotificationsLoaded(
        notifications: updatedNotifications,
        unreadCount: newUnreadCount,
        isNewNotification: false,
      ));
      
      debugPrint('🔔 NotificationsCubit: Optimistically removed notification: $notificationId');
    }
  }

  /// Update a specific notification in the list
  /// Used to update notification state without reloading entire list
  void updateNotification(AppNotification updatedNotification) {
    final currentState = state;
    if (currentState is NotificationsLoaded) {
      final updatedNotifications = currentState.notifications.map((n) {
        if (n.id == updatedNotification.id) {
          return updatedNotification;
        }
        return n;
      }).toList();
      
      final newUnreadCount = updatedNotifications.where((n) => !n.isRead).length;
      
      emit(NotificationsLoaded(
        notifications: updatedNotifications,
        unreadCount: newUnreadCount,
        isNewNotification: false,
      ));
      
      debugPrint('🔔 NotificationsCubit: Updated notification: ${updatedNotification.id}');
    }
  }

  @override
  Future<void> close() {
    _socketService.removeNotificationListener(_handleSocketNotification);
    _eventUpdateController.close();
    return super.close();
  }
}

