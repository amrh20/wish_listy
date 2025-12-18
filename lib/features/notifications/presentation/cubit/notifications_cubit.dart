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

  const NotificationsLoaded({
    required this.notifications,
    required this.unreadCount,
  });

  @override
  List<Object?> get props => [notifications, unreadCount];

  NotificationsLoaded copyWith({
    List<AppNotification>? notifications,
    int? unreadCount,
  }) {
    return NotificationsLoaded(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
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
  void _handleSocketNotification(Map<String, dynamic> data) {
    try {
      debugPrint('🔔 NotificationsCubit: Received socket notification: $data');
      
      // Try to parse as AppNotification
      AppNotification notification;
      try {
        notification = AppNotification.fromJson(data);
        debugPrint('✅ NotificationsCubit: Parsed notification: ${notification.type} - ${notification.title}');
      } catch (parseError) {
        debugPrint('⚠️ NotificationsCubit: Failed to parse notification, trying alternative format: $parseError');
        // If direct parsing fails, try wrapping it
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
      }
      
      if (state is NotificationsLoaded) {
        final currentState = state as NotificationsLoaded;
        final updatedNotifications = [notification, ...currentState.notifications];
        final unreadCount = updatedNotifications.where((n) => !n.isRead).length;
        
        debugPrint('📊 NotificationsCubit: Updated state - Total: ${updatedNotifications.length}, Unread: $unreadCount');
        
        emit(NotificationsLoaded(
          notifications: updatedNotifications,
          unreadCount: unreadCount,
        ));
      } else {
        debugPrint('📥 NotificationsCubit: State not loaded yet, loading notifications...');
        // If not loaded yet, load notifications first
        loadNotifications();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ NotificationsCubit: Error handling socket notification: $e');
      debugPrint('❌ Stack trace: $stackTrace');
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

      // Get unreadCount from response if available (at top level)
      unreadCount = response['unreadCount'] as int? ?? 
                   response['unread_count'] as int? ?? 
                   0;

      // Check if response has 'data' field
      if (response.containsKey('data')) {
        final data = response['data'];
        
        // Case 1: data is an array directly (actual API response)
        if (data is List) {
          notificationsList = data;
        }
        // Case 2: data is an object with 'notifications' field (documentation format)
        else if (data is Map<String, dynamic>) {
          notificationsList = data['notifications'] as List<dynamic>? ?? [];
          // Override unreadCount if found in data object
          if (data.containsKey('unreadCount') || data.containsKey('unread_count')) {
            unreadCount = data['unreadCount'] as int? ?? 
                         data['unread_count'] as int? ?? 
                         0;
          }
        }
      }

      // If unreadCount not found in response, calculate from notifications
      if (unreadCount == 0 && notificationsList.isNotEmpty) {
        final parsedNotifications = notificationsList
            .map((json) {
              try {
                return AppNotification.fromJson(json as Map<String, dynamic>);
              } catch (e) {
                debugPrint('⚠️ NotificationsCubit: Failed to parse notification: $e');
                return null;
              }
            })
            .whereType<AppNotification>()
            .toList();
        unreadCount = parsedNotifications.where((n) => !n.isRead).length;
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

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      if (state is! NotificationsLoaded) return;

      final currentState = state as NotificationsLoaded;
      
      // Optimistically update UI
      final updatedNotifications = currentState.notifications.map((n) {
        if (n.id == notificationId && !n.isRead) {
          return n.markAsRead();
        }
        return n;
      }).toList();

      final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

      emit(NotificationsLoaded(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
      ));

      // Update on backend
      await _apiService.put('/notifications/$notificationId/read');
    } on ApiException catch (e) {
      debugPrint('❌ NotificationsCubit: Error marking as read: ${e.message}');
      // Reload to sync with backend
      loadNotifications();
    } catch (e) {
      debugPrint('❌ NotificationsCubit: Error marking as read: $e');
      loadNotifications();
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      if (state is! NotificationsLoaded) return;

      await _apiService.put('/notifications/read-all');

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

  @override
  Future<void> close() {
    _socketService.removeNotificationListener(_handleSocketNotification);
    return super.close();
  }
}

