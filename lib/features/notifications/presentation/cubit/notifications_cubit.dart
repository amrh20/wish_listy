import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:wish_listy/core/services/socket_service.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/features/notifications/data/models/notification_model.dart';

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

  NotificationsCubit() : super(NotificationsInitial()) {
    debugPrint('🔔 NotificationsCubit: Initializing...');
    _setupSocketListeners();
    debugPrint('🔔 NotificationsCubit: Initialized with socket listener');
    
    // Debug: Check if socket is connected after initialization
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final status = _socketService.getConnectionStatus();
      debugPrint('🔔 NotificationsCubit: Socket status check (post-init)');
      debugPrint('   Connected: ${status['isConnected']}');
      debugPrint('   Connecting: ${status['isConnecting']}');
      debugPrint('   Socket ID: ${status['socketId']}');
      debugPrint('   Listeners: ${status['listenersCount']}');
      debugPrint('   URL: ${status['socketUrl']}');
    });
  }

  /// Setup Socket.IO listeners for real-time notifications
  void _setupSocketListeners() {
    debugPrint('🔔 NotificationsCubit: Setting up socket listener...');
    debugPrint('   SocketService instance: ${_socketService.hashCode}');
    debugPrint('   Handler function: ${_handleSocketNotification.runtimeType}');
    debugPrint('   Handler hash: ${_handleSocketNotification.hashCode}');
    
    // Get status before adding listener
    final statusBefore = _socketService.getConnectionStatus();
    debugPrint('   Listeners count BEFORE: ${statusBefore['listenersCount']}');
    
    // Add the listener
    _socketService.addNotificationListener(_handleSocketNotification);
    
    // Get status after adding listener
    final statusAfter = _socketService.getConnectionStatus();
    debugPrint('🔔 NotificationsCubit: Socket listener added');
    debugPrint('   Listeners count AFTER: ${statusAfter['listenersCount']}');
    debugPrint('   Socket exists: ${_socketService.socket != null}');
    debugPrint('   Is connected: ${statusAfter['isConnected']}');
    
    // Verify listener was added
    if (statusAfter['listenersCount'] == 0) {
      debugPrint('   ❌ ERROR: Listener count is still 0 after adding!');
      debugPrint('   This means the listener was not registered properly.');
    } else {
      debugPrint('   ✅ Listener registered successfully!');
    }
  }

  /// Handle notification from Socket.IO
  Future<void> _handleSocketNotification(Map<String, dynamic> data) async {
    final timestamp = DateTime.now().toIso8601String();
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
      } else {
        debugPrint('🔔 [Notifications] ⏰ [$updateTimestamp]    ⚠️ State not loaded, loading notifications...');
        loadNotifications();
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
      
      if (state is NotificationsLoaded) {
        final stateUpdateTimestamp = DateTime.now().toIso8601String();
        final currentState = state as NotificationsLoaded;
        debugPrint('🔔 [Notifications] ⏰ [$stateUpdateTimestamp]    Current state is NotificationsLoaded');
        debugPrint('🔔 [Notifications] ⏰ [$stateUpdateTimestamp]       Current notifications count: ${currentState.notifications.length}');
        debugPrint('🔔 [Notifications] ⏰ [$stateUpdateTimestamp]       Current unread count: ${currentState.unreadCount}');
        
        final updatedNotifications = [notification, ...currentState.notifications];
        
        // IMPORTANT: Extract unreadCount from payload if available
        // If not available, fetch from backend to ensure accuracy (considers lastBadgeSeenAt)
        int unreadCount;
        if (data['unreadCount'] != null || data['unread_count'] != null) {
          unreadCount = data['unreadCount'] as int? ?? data['unread_count'] as int? ?? 0;
          debugPrint('🔔 [Notifications] ⏰ [$stateUpdateTimestamp]    Using unreadCount from payload: $unreadCount');
          
          // Emit state immediately with payload count
          emit(NotificationsLoaded(
            notifications: updatedNotifications,
            unreadCount: unreadCount,
            isNewNotification: true, // Mark as new notification from Socket
          ));
        } else {
          // If unreadCount not in payload, fetch from backend
          debugPrint('🔔 [Notifications] ⏰ [$stateUpdateTimestamp]    ⚠️ unreadCount not in payload, fetching from backend...');
          
          // Increment current unreadCount by 1 (new notification received)
          // This ensures immediate visual feedback
          final newCount = currentState.unreadCount + 1;
          debugPrint('🔔 [Notifications] ⏰ [$stateUpdateTimestamp]    Incrementing unreadCount: ${currentState.unreadCount} -> $newCount');
          
          emit(NotificationsLoaded(
            notifications: updatedNotifications,
            unreadCount: newCount,
            isNewNotification: true,
          ));
          
          // Then fetch accurate count from backend (async)
          try {
            final accurateCount = await getUnreadCount();
            debugPrint('🔔 [Notifications] ⏰ [$stateUpdateTimestamp]    ✅ Fetched accurate unreadCount: $accurateCount');
            
            // Update state with accurate count
            if (state is NotificationsLoaded) {
              final latestState = state as NotificationsLoaded;
              emit(latestState.copyWith(
                unreadCount: accurateCount,
                isNewNotification: false, // Don't show snackbar again
              ));
            }
          } catch (e) {
            debugPrint('🔔 [Notifications] ⏰ [$stateUpdateTimestamp]    ⚠️ Failed to fetch accurate count: $e');
            // Keep the temporary count
          }
          
          return; // Exit early since we already emitted
        }
        
        debugPrint('🔔 [Notifications] ⏰ [$stateUpdateTimestamp]    Updating state...');
        debugPrint('🔔 [Notifications] ⏰ [$stateUpdateTimestamp]       New notifications count: ${updatedNotifications.length}');
        debugPrint('🔔 [Notifications] ⏰ [$stateUpdateTimestamp]       New unread count: $unreadCount');
        debugPrint('🔔 [Notifications] ⏰ [$stateUpdateTimestamp]       Added notification: ${notification.type} - ${notification.title}');
        
        final emitCompleteTimestamp = DateTime.now().toIso8601String();
        debugPrint('🔔 [Notifications] ⏰ [$emitCompleteTimestamp]    ✅ State updated and emitted successfully');
        debugPrint('🔔 [Notifications] ⏰ [$emitCompleteTimestamp]       UI should now show the new notification');
        debugPrint('🔔 [Notifications] ⏰ [$emitCompleteTimestamp]       BlocBuilder and BlocListener should rebuild now');
      } else {
        final loadTimestamp = DateTime.now().toIso8601String();
        debugPrint('🔔 [Notifications] ⏰ [$loadTimestamp]    ⚠️ State not loaded yet (current: ${state.runtimeType})');
        debugPrint('🔔 [Notifications] ⏰ [$loadTimestamp]    Loading notifications from API first...');
        // If not loaded yet, load notifications first
        loadNotifications();
      }
    } catch (e, stackTrace) {
      final errorTimestamp = DateTime.now().toIso8601String();
      debugPrint('🔔 [Notifications] ⏰ [$errorTimestamp]    ❌ Error handling socket notification: $e');
      debugPrint('🔔 [Notifications] ⏰ [$errorTimestamp]       Error type: ${e.runtimeType}');
      debugPrint('🔔 [Notifications] ⏰ [$errorTimestamp]       Stack trace: $stackTrace');
    }
  }

  /// Load notifications from API
  Future<void> loadNotifications() async {
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
      
      // Update state if loaded
      if (state is NotificationsLoaded) {
        final currentState = state as NotificationsLoaded;
        emit(currentState.copyWith(
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
      
      // Call backend API to update lastBadgeSeenAt
      debugPrint('🔔 [Notifications] ⏰ [$timestamp]    Calling API: PATCH /api/notifications/dismiss-badge');
      await _apiService.patch('/notifications/dismiss-badge');
      
      // Reload notifications to get updated unreadCount from backend
      // Backend will now calculate unreadCount based on lastBadgeSeenAt
      debugPrint('🔔 [Notifications] ⏰ [$timestamp]    Reloading notifications to get updated unreadCount...');
      await loadNotifications();
      
      debugPrint('🔔 [Notifications] ⏰ [$timestamp]    ✅ Badge dismissed successfully');
    } on ApiException catch (e) {
      debugPrint('❌ NotificationsCubit: Error dismissing badge: ${e.message}');
      // On error, still try to reload to sync state
      loadNotifications();
    } catch (e) {
      debugPrint('❌ NotificationsCubit: Error dismissing badge: $e');
      loadNotifications();
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

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      if (state is! NotificationsLoaded) return;

      final currentState = state as NotificationsLoaded;
      
      // Optimistically remove from UI
      final updatedNotifications = currentState.notifications
          .where((n) => n.id != notificationId)
          .toList();

      final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

      emit(NotificationsLoaded(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
        isNewNotification: false, // This is a state update, not new Socket notification
      ));

      // Delete on backend
      await _apiService.delete('/notifications/$notificationId');
    } on ApiException catch (e) {
      debugPrint('❌ NotificationsCubit: Error deleting notification: ${e.message}');
      // Reload to sync with backend
      loadNotifications();
    } catch (e) {
      debugPrint('❌ NotificationsCubit: Error deleting notification: $e');
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
    return super.close();
  }
}

