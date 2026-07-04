import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wish_listy/core/services/api_service.dart';

/// Socket Service for real-time notifications
/// Handles Socket.IO connection with JWT authentication
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() {
    return _instance;
  }
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  bool _isConnecting = false;
  final List<Function(Map<String, dynamic>)> _notificationListeners = [];
  final List<Function(Map<String, dynamic>)> _chatMessageListeners = [];
  final List<Function(Map<String, dynamic>)> _chatReadListeners = [];
  final List<Function(Map<String, dynamic>)> _chatUnreadListeners = [];
  final List<Function(Map<String, dynamic>)> _typingListeners = [];
  final List<Function(Map<String, dynamic>)> _userStatusListeners = [];
  final List<void Function()> _onConnectListeners = [];

  /// Get socket server URL based on platform
  /// Important: Use same base URL as API service for consistency
  /// Socket.IO server is typically on the same domain as the API but without /api path
  String get _socketUrl {
    // Derive socket URL from ApiService base URL
    // ApiService baseUrl: https://wish-listy-backend.onrender.com/api
    // Socket URL should be: https://wish-listy-backend.onrender.com (without /api)
    final apiUri = ApiService.baseUri;
    final scheme = apiUri.scheme; // 'https' or 'http'
    final host = apiUri.host;
    final port = apiUri.hasPort ? apiUri.port : (scheme == 'https' ? 443 : 80);

    // Build socket URL: same scheme, host, and port as API, but without /api path
    final socketUrl =
        port == 443 ||
            port == 80 ||
            (scheme == 'https' && port == 443) ||
            (scheme == 'http' && port == 80)
        ? '$scheme://$host' // Omit port for default ports
        : '$scheme://$host:$port';

    return socketUrl;
  }

  /// Connect to socket server with JWT token
  /// [forceReconnect] If true, will disconnect existing socket first, then connect
  /// This is useful after logout/login to ensure clean reconnection
  /// [token] Optional token to use instead of reading from SharedPreferences
  /// This is useful when connecting immediately after login before token is saved
  Future<void> connect({bool forceReconnect = false, String? token}) async {
    // If force reconnect is requested, disconnect first
    if (forceReconnect) {
      disconnect();
      // Add a small delay to ensure cleanup is complete
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (_isConnected || _isConnecting) {
      if (!forceReconnect) {
        return;
      }
      // If forceReconnect is true but flags are still set, force disconnect again
      _isConnected = false;
      _isConnecting = false;
      if (_socket != null) {
        try {
          _socket!.disconnect();
          _socket!.dispose();
        } catch (e) {}
        _socket = null;
      }
    }

    try {
      _isConnecting = true;

      // Get JWT token: use provided token or read from SharedPreferences
      String? finalToken = token;
      if (finalToken == null || finalToken.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        finalToken = prefs.getString('auth_token');
      }

      final socketUrl = _socketUrl;

      if (finalToken == null || finalToken.isEmpty) {
        _isConnecting = false;
        return;
      }

      _socket = IO.io(
        socketUrl,
        IO.OptionBuilder()
            .setTransports([
              'websocket',
              'polling',
            ]) // Important: Use both for compatibility
            .setAuth({'token': finalToken}) // Send token in auth object
            .setExtraHeaders({
              'Authorization': 'Bearer $finalToken',
            }) // Also send in headers as per requirements
            .disableAutoConnect() // Disable auto-connect, we'll connect explicitly
            .setTimeout(20000) // 20 seconds timeout
            .build(),
      );

      // Connection event handlers
      _socket!.onConnect((_) {
        _isConnected = true;
        _isConnecting = false;

        // Re-setup notification listeners after reconnection
        // This ensures listeners are active even after socket reconnects
        _setupNotificationListeners();
        _setupChatListeners();

        // Notify listeners (e.g. NotificationsCubit) to sync badge with backend
        for (final callback in _onConnectListeners) {
          try {
            callback();
          } catch (e) {
            if (kDebugMode) {
              debugPrint('SocketService onConnect callback error: $e');
            }
          }
        }
      });

      _socket!.onDisconnect((reason) {
        _isConnected = false;
        _isConnecting = false;
      });

      _socket!.onConnectError((error) {
        _isConnected = false;
        _isConnecting = false;
      });

      _socket!.onError((error) {});

      // Listen for notification events
      // Note: We set up listeners before connection is established
      // Socket.IO will queue them and they'll be active once connected
      _setupNotificationListeners();
      _setupChatListeners();

      // Add a small delay to ensure socket is ready before setting up listeners
      await Future.delayed(const Duration(milliseconds: 100));

      // Explicitly connect the socket (since auto-connect is disabled)
      _socket!.connect();
    } catch (e, stackTrace) {
      _isConnected = false;
      _isConnecting = false;
    }
  }

  /// Setup notification event listeners
  void _setupNotificationListeners() {
    if (_socket == null) {
      return;
    }

    // DEBUG: Listen to ALL events to see what's coming from backend
    _socket!.onAny((event, data) {});

    // Listen for 'notification' event (general notification)
    _socket!.on('notification', (data) {
      try {
        final notification = data is Map<String, dynamic>
            ? data
            : {'data': data, 'type': 'general'};
        _notifyListeners(notification);
      } catch (e) {}
    });

    // Listen for 'friend_request_received' event (alternative event name)
    _socket!.on('friend_request_received', (data) {
      try {
        Map<String, dynamic> notification;

        if (data is Map<String, dynamic>) {
          notification = {
            '_id':
                data['requestId'] ??
                data['_id'] ??
                DateTime.now().millisecondsSinceEpoch.toString(),
            'userId': data['from']?['_id'] ?? data['from']?['userId'] ?? '',
            'type': 'friendRequest',
            'title': 'Friend Request',
            'message':
                data['message'] ??
                '${data['from']?['fullName'] ?? 'Someone'} sent you a friend request',
            'data': data,
            'isRead': false,
            'createdAt': DateTime.now().toIso8601String(),
            // Extract unreadCount from payload if available
            'unreadCount': data['unreadCount'] ?? data['unread_count'],
          };
        } else {
          notification = {
            'data': data,
            'type': 'friendRequest',
            'title': 'Friend Request',
            'message': 'You received a friend request',
            'isRead': false,
            'createdAt': DateTime.now().toIso8601String(),
          };
        }

        _notifyListeners(notification);
      } catch (e, stackTrace) {}
    });

    // Listen for 'friend_request' event (main event from backend)
    // Backend sends this event when a friend request is received
    _socket!.on('friend_request', (data) {
      try {
        Map<String, dynamic> notification;

        if (data is Map<String, dynamic>) {
          // Backend payload structure:
          // {
          //   "requestId": "request_id",
          //   "from": { "_id": "...", "fullName": "...", ... },
          //   "message": "..."
          // }
          notification = {
            '_id':
                data['requestId'] ??
                data['_id'] ??
                DateTime.now().millisecondsSinceEpoch.toString(),
            'userId': data['from']?['_id'] ?? data['from']?['userId'] ?? '',
            'type': 'friendRequest',
            'title': 'Friend Request',
            'message':
                data['message'] ??
                '${data['from']?['fullName'] ?? 'Someone'} sent you a friend request',
            'data': data,
            'isRead': false,
            'createdAt': DateTime.now().toIso8601String(),
            // Extract unreadCount from payload if available
            'unreadCount': data['unreadCount'] ?? data['unread_count'],
          };
        } else {
          notification = {
            'data': data,
            'type': 'friendRequest',
            'title': 'Friend Request',
            'message': 'You received a friend request',
            'isRead': false,
            'createdAt': DateTime.now().toIso8601String(),
          };
        }

        _notifyListeners(notification);
      } catch (e, stackTrace) {}
    });

    // Listen for 'friend_request_accepted' event
    _socket!.on('friend_request_accepted', (data) {
      try {
        Map<String, dynamic> notification;

        if (data is Map<String, dynamic>) {
          notification = {
            '_id':
                data['requestId'] ??
                data['_id'] ??
                DateTime.now().millisecondsSinceEpoch.toString(),
            'userId': data['user']?['_id'] ?? data['userId'] ?? '',
            'type': 'friendRequestAccepted',
            'title': 'Friend Request Accepted',
            'message':
                data['message'] ??
                '${data['user']?['fullName'] ?? 'Someone'} accepted your friend request',
            'data': data,
            'isRead': false,
            'createdAt': DateTime.now().toIso8601String(),
            // Extract unreadCount from payload if available
            'unreadCount': data['unreadCount'] ?? data['unread_count'],
          };
        } else {
          notification = {
            'data': data,
            'type': 'friendRequestAccepted',
            'title': 'Friend Request Accepted',
            'message': 'Your friend request was accepted',
            'isRead': false,
            'createdAt': DateTime.now().toIso8601String(),
          };
        }

        _notifyListeners(notification);
      } catch (e, stackTrace) {}
    });

    // Listen for 'unread_count_update' event
    _socket!.on('unread_count_update', (data) {
      try {
        Map<String, dynamic> updateData;

        if (data is Map<String, dynamic>) {
          updateData = {
            'type': 'unreadCountUpdate',
            'unreadCount': data['unreadCount'] ?? data['unread_count'] ?? 0,
            'data': data,
            'timestamp': DateTime.now().toIso8601String(),
          };
        } else {
          updateData = {
            'type': 'unreadCountUpdate',
            'unreadCount': 0,
            'data': data,
            'timestamp': DateTime.now().toIso8601String(),
          };
        }

        _notifyListeners(updateData);
      } catch (e, stackTrace) {}
    });
  }

  void _setupChatListeners() {
    if (_socket == null) {
      return;
    }

    _socket!.off('receive_message');
    _socket!.on('receive_message', (data) {
      _notifyChatMessageListeners(_normalizeChatPayload(data));
    });

    _socket!.off('message_sent');
    _socket!.on('message_sent', (data) {
      _notifyChatMessageListeners(_normalizeChatPayload(data));
    });

    _socket!.off('messages_read');
    _socket!.on('messages_read', (data) {
      _notifyChatReadListeners(_normalizeChatPayload(data));
    });

    _socket!.off('chat_unread_update');
    _socket!.on('chat_unread_update', (data) {
      _notifyChatUnreadListeners(_normalizeChatPayload(data));
    });

    _socket!.off('typing');
    _socket!.on('typing', (data) {
      final payload = _normalizeChatPayload(data)..['event'] = 'typing';
      _notifyTypingListeners(payload);
    });

    _socket!.off('stop_typing');
    _socket!.on('stop_typing', (data) {
      final payload = _normalizeChatPayload(data)..['event'] = 'stop_typing';
      _notifyTypingListeners(payload);
    });

    _socket!.off('user_status');
    _socket!.on('user_status', (data) {
      _notifyUserStatusListeners(_normalizeChatPayload(data));
    });
  }

  /// Add notification listener
  void addNotificationListener(Function(Map<String, dynamic>) listener) {
    // Check if listener already exists
    if (_notificationListeners.contains(listener)) {
      return;
    }

    _notificationListeners.add(listener);
  }

  /// Remove notification listener
  void removeNotificationListener(Function(Map<String, dynamic>) listener) {
    _notificationListeners.remove(listener);
  }

  void addChatMessageListener(Function(Map<String, dynamic>) listener) {
    if (_chatMessageListeners.contains(listener)) {
      return;
    }
    _chatMessageListeners.add(listener);
  }

  void removeChatMessageListener(Function(Map<String, dynamic>) listener) {
    _chatMessageListeners.remove(listener);
  }

  void addChatReadListener(Function(Map<String, dynamic>) listener) {
    if (_chatReadListeners.contains(listener)) {
      return;
    }
    _chatReadListeners.add(listener);
  }

  void removeChatReadListener(Function(Map<String, dynamic>) listener) {
    _chatReadListeners.remove(listener);
  }

  void addChatUnreadListener(Function(Map<String, dynamic>) listener) {
    if (_chatUnreadListeners.contains(listener)) {
      return;
    }
    _chatUnreadListeners.add(listener);
  }

  void removeChatUnreadListener(Function(Map<String, dynamic>) listener) {
    _chatUnreadListeners.remove(listener);
  }

  void addTypingListener(Function(Map<String, dynamic>) listener) {
    if (_typingListeners.contains(listener)) {
      return;
    }
    _typingListeners.add(listener);
  }

  void removeTypingListener(Function(Map<String, dynamic>) listener) {
    _typingListeners.remove(listener);
  }

  void addUserStatusListener(Function(Map<String, dynamic>) listener) {
    if (_userStatusListeners.contains(listener)) {
      return;
    }
    _userStatusListeners.add(listener);
  }

  void removeUserStatusListener(Function(Map<String, dynamic>) listener) {
    _userStatusListeners.remove(listener);
  }

  /// Announce this client is online so peers receive `user_status`.
  void announceOnline() {
    if (_socket == null || !_isConnected) return;
    _socket!.emit('user_online');
  }

  /// Add a callback to be invoked when the socket connects or reconnects.
  /// Use this to sync UI (e.g. badge count) with the backend after a network drop.
  /// If already connected, the callback is invoked immediately.
  void addOnConnectListener(void Function() callback) {
    if (!_onConnectListeners.contains(callback)) {
      _onConnectListeners.add(callback);
    }
    if (_isConnected) {
      try {
        callback();
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
            'SocketService addOnConnectListener immediate callback error: $e',
          );
        }
      }
    }
  }

  void removeOnConnectListener(void Function() callback) {
    _onConnectListeners.remove(callback);
  }

  /// Notify all listeners about new notification
  void _notifyListeners(Map<String, dynamic> notification) {
    if (_notificationListeners.isEmpty) {
      return;
    }

    for (int i = 0; i < _notificationListeners.length; i++) {
      try {
        _notificationListeners[i](notification);
      } catch (e, stackTrace) {}
    }
  }

  void _notifyChatMessageListeners(Map<String, dynamic> payload) {
    for (final listener in _chatMessageListeners) {
      try {
        listener(payload);
      } catch (_) {}
    }
  }

  void _notifyChatReadListeners(Map<String, dynamic> payload) {
    for (final listener in _chatReadListeners) {
      try {
        listener(payload);
      } catch (_) {}
    }
  }

  void _notifyChatUnreadListeners(Map<String, dynamic> payload) {
    for (final listener in _chatUnreadListeners) {
      try {
        listener(payload);
      } catch (_) {}
    }
  }

  void _notifyTypingListeners(Map<String, dynamic> payload) {
    for (final listener in _typingListeners) {
      try {
        listener(payload);
      } catch (_) {}
    }
  }

  void _notifyUserStatusListeners(Map<String, dynamic> payload) {
    for (final listener in _userStatusListeners) {
      try {
        listener(payload);
      } catch (_) {}
    }
  }

  Map<String, dynamic> _normalizeMapPayload(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return {'data': data};
  }

  /// Normalizes chat socket payloads and aliases backend `conversationId` to
  /// `chatRoomId` for app-level state. Also maps typing `fromUserId` to `userId`.
  Map<String, dynamic> _normalizeChatPayload(dynamic data) {
    final payload = _normalizeMapPayload(data);

    final conversationId =
        payload['conversationId'] ??
        payload['conversation_id'] ??
        payload['chatRoomId'];
    if (conversationId != null) {
      payload['conversationId'] = conversationId.toString();
      payload['chatRoomId'] = conversationId.toString();
    }

    final fromUserId = payload['fromUserId'] ?? payload['from_user_id'];
    if (fromUserId != null && payload['userId'] == null) {
      payload['userId'] = fromUserId.toString();
    }

    final unreadConversations =
        payload['unreadConversations'] ?? payload['unread_conversations'];
    if (unreadConversations != null && payload['unreadCount'] == null) {
      payload['unreadCount'] = unreadConversations;
    }

    return payload;
  }

  /// Backend routes chat events to user rooms on auth; no room join is required.
  void joinRoom(String chatRoomId) {
    if (chatRoomId.trim().isEmpty) return;
  }

  void leaveRoom(String chatRoomId) {
    if (chatRoomId.trim().isEmpty) return;
  }

  void emitTyping({required String recipientId, String? conversationId}) {
    if (_socket == null || !_isConnected) return;
    if (recipientId.trim().isEmpty) return;
    _socket!.emit('typing', {'toUserId': recipientId.trim()});
  }

  void emitStopTyping({
    required String recipientId,
    String? conversationId,
  }) {
    if (_socket == null || !_isConnected) return;
    if (recipientId.trim().isEmpty) return;
    _socket!.emit('stop_typing', {'toUserId': recipientId.trim()});
  }

  /// Disconnect from socket server
  /// Ensures complete cleanup of socket instance, flags, and listeners
  void disconnect() {
    if (_socket != null) {
      try {
        // Reset flags first to prevent race conditions
        _isConnected = false;
        _isConnecting = false;

        // Disconnect socket
        _socket!.disconnect();

        // Dispose socket instance
        _socket!.dispose();

        // Clear socket reference
        _socket = null;
        // IMPORTANT:
        // Do NOT clear `_notificationListeners` here.
        // These are app-level listeners (e.g., NotificationsCubit) that must survive logout/login
        // and socket reconnects. Clearing them causes real-time notifications to stop until the
        // listener is re-registered manually (often only when opening Notifications screen).
      } catch (e, stackTrace) {
        // Force cleanup even if there's an error
        _socket = null;
        _isConnected = false;
        _isConnecting = false;
      }
    } else {
      // No socket to disconnect, but ensure flags are reset
      _isConnected = false;
      _isConnecting = false;
    }
  }

  /// Authenticate socket with JWT token (Option B: emit auth event without restarting connection)
  /// If socket is not connected, it will connect first using the provided token
  /// Emits 'auth' event with token to authenticate the existing connection
  Future<void> authenticateSocket(String token) async {
    if (_socket == null || !_isConnected) {
      // If not connected, connect first using the provided token
      // This ensures we use the fresh token even if SharedPreferences hasn't been updated yet
      await connect(token: token);

      // Wait for connection to establish and listeners to be set up
      // Use a more reliable approach: wait for _isConnected flag
      int attempts = 0;
      while (!_isConnected && attempts < 20) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }

      if (!_isConnected) {
        return;
      }
    }

    try {
      // Emit 'auth' event with token (Option B: without restarting connection)
      // This is important for immediate authentication after login
      _socket!.emit('auth', {'token': token});
    } catch (e) {}
  }

  /// Check if socket is connected
  bool get isConnected => _isConnected;

  /// Get socket instance (for advanced usage)
  IO.Socket? get socket => _socket;

  /// Get connection status for debugging
  Map<String, dynamic> getConnectionStatus() {
    return {
      'isConnected': _isConnected,
      'isConnecting': _isConnecting,
      'socketUrl': _socketUrl,
      'socketId': _socket?.id,
      'listenersCount': _notificationListeners.length,
    };
  }

  /// Print connection status for debugging
  void printConnectionStatus() {
    final status = getConnectionStatus();
  }
}
