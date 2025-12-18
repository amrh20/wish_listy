import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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

  /// Get socket server URL based on platform
  /// Important: Use same base URL as API service for consistency
  /// - Android Emulator: Use 'http://10.0.2.2:5000' (maps to host's localhost)
  /// - Android Physical Device: Use your computer's IP (e.g., 'http://192.168.1.11:5000')
  /// - iOS Simulator: Use 'http://localhost:5000' (works directly)
  /// - Web: Use 'http://localhost:5000'
  String get _socketUrl {
    if (kIsWeb) {
      return 'http://localhost:5000'; // Web platform
    }

    // Check if Android - use same detection as ApiService
    try {
      final bool isAndroid = defaultTargetPlatform == TargetPlatform.android;
      if (isAndroid) {
        // For Android Physical Device: use your computer's IP address
        // For Android Emulator: use '10.0.2.2' instead
        const String androidIP = '192.168.1.11'; // Physical device - Your computer's IP
        // const String androidIP = '10.0.2.2'; // Uncomment for Android Emulator
        final url = 'http://$androidIP:5000';
        return url;
      }
    } catch (e) {
      // Platform detection error - fall through to default
    }

    // iOS Simulator - localhost works directly
    return 'http://localhost:5000';
  }

  /// Connect to socket server with JWT token
  Future<void> connect() async {
    if (_isConnected || _isConnecting) {
      return;
    }

    try {
      _isConnecting = true;

      // Get JWT token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        _isConnecting = false;
        return;
      }
      
      _socket = IO.io(
        _socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling']) // Important: Use both for compatibility
            .setAuth({'token': token}) // Send token in auth, not in headers (NOT in extraHeaders)
            .enableAutoConnect()
            .setTimeout(20000) // 20 seconds timeout
            .build(),
      );

      // Connection event handlers
      _socket!.onConnect((_) {
        _isConnected = true;
        _isConnecting = false;
        debugPrint('✅ SocketService: Connected successfully');
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
        _isConnecting = false;
      });

      _socket!.onConnectError((error) {
        _isConnected = false;
        _isConnecting = false;
        debugPrint('❌ SocketService: Connection error: $error');
      });

      _socket!.onError((error) {
        debugPrint('❌ SocketService: Socket error: $error');
      });

      // Listen for notification events
      // Note: We set up listeners before connection is established
      // Socket.IO will queue them and they'll be active once connected
      _setupNotificationListeners();

      // Add a small delay to ensure socket is ready before setting up listeners
      await Future.delayed(const Duration(milliseconds: 100));

    } catch (e) {
      _isConnected = false;
      _isConnecting = false;
      debugPrint('❌ SocketService: Error connecting: $e');
    }
  }

  /// Setup notification event listeners
  void _setupNotificationListeners() {
    if (_socket == null) {
      return;
    }

    // DEBUG: Listen to ALL events to see what's coming from backend
    _socket!.onAny((event, data) {
      debugPrint('🔍 SocketService: Received ANY event: "$event"');
      debugPrint('   Data: $data');
      debugPrint('   Data type: ${data.runtimeType}');
    });

    // Listen for 'notification' event (general notification)
    _socket!.on('notification', (data) {
      debugPrint('📬 SocketService: Received "notification" event: $data');
      try {
        final notification = data is Map<String, dynamic>
            ? data
            : {'data': data, 'type': 'general'};
        _notifyListeners(notification);
      } catch (e) {
        debugPrint('❌ SocketService: Error processing notification event: $e');
      }
    });

    // Listen for 'friend_request_received' event (alternative event name)
    _socket!.on('friend_request_received', (data) {
      debugPrint('👥 SocketService: Received "friend_request_received" event');
      try {
        Map<String, dynamic> notification;
        
        if (data is Map<String, dynamic>) {
          notification = {
            '_id': data['requestId'] ?? data['_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            'userId': data['from']?['_id'] ?? data['from']?['userId'] ?? '',
            'type': 'friendRequest',
            'title': 'Friend Request',
            'message': data['message'] ?? '${data['from']?['fullName'] ?? 'Someone'} sent you a friend request',
            'data': data,
            'isRead': false,
            'createdAt': DateTime.now().toIso8601String(),
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
      } catch (e, stackTrace) {
        debugPrint('❌ SocketService: Error processing friend_request_received: $e');
      }
    });

    // Listen for 'friend_request' event (main event from backend)
    // Backend sends this event when a friend request is received
    _socket!.on('friend_request', (data) {
      debugPrint('👥 SocketService: Received "friend_request" event');
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
            '_id': data['requestId'] ?? data['_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            'userId': data['from']?['_id'] ?? data['from']?['userId'] ?? '',
            'type': 'friendRequest',
            'title': 'Friend Request',
            'message': data['message'] ?? '${data['from']?['fullName'] ?? 'Someone'} sent you a friend request',
            'data': data,
            'isRead': false,
            'createdAt': DateTime.now().toIso8601String(),
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
      } catch (e, stackTrace) {
        debugPrint('❌ SocketService: Error processing friend_request: $e');
      }
    });

    // Listen for 'friend_request_accepted' event
    _socket!.on('friend_request_accepted', (data) {
      debugPrint('✅ SocketService: Received "friend_request_accepted" event');
      try {
        Map<String, dynamic> notification;
        
        if (data is Map<String, dynamic>) {
          notification = {
            '_id': data['requestId'] ?? data['_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            'userId': data['user']?['_id'] ?? data['userId'] ?? '',
            'type': 'friendRequestAccepted',
            'title': 'Friend Request Accepted',
            'message': data['message'] ?? '${data['user']?['fullName'] ?? 'Someone'} accepted your friend request',
            'data': data,
            'isRead': false,
            'createdAt': DateTime.now().toIso8601String(),
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
      } catch (e, stackTrace) {
        debugPrint('❌ SocketService: Error processing friend_request_accepted: $e');
      }
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

  /// Notify all listeners about new notification
  void _notifyListeners(Map<String, dynamic> notification) {
    debugPrint('📢 SocketService: Notifying ${_notificationListeners.length} listener(s)');
    debugPrint('   Notification type: ${notification['type']}');
    debugPrint('   Notification title: ${notification['title']}');
    
    for (int i = 0; i < _notificationListeners.length; i++) {
      try {
        _notificationListeners[i](notification);
        debugPrint('   ✅ Listener #$i notified successfully');
      } catch (e, stackTrace) {
        debugPrint('❌ SocketService: Error in listener: $e');
      }
    }
  }

  /// Disconnect from socket server
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      _isConnecting = false;
      _notificationListeners.clear();
    }
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
    debugPrint('📊 SocketService Status:');
    debugPrint('   Connected: ${status['isConnected']}');
    debugPrint('   Connecting: ${status['isConnecting']}');
    debugPrint('   URL: ${status['socketUrl']}');
    debugPrint('   Socket ID: ${status['socketId']}');
    debugPrint('   Listeners: ${status['listenersCount']}');
  }
}

