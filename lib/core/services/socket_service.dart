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
  /// - Android Emulator: Use 'http://10.0.2.2:4000' (maps to host's localhost)
  /// - Android Physical Device: Use your computer's IP (e.g., 'http://192.168.1.11:4000')
  /// - iOS Simulator: Use 'http://localhost:4000' (works directly)
  /// - Web: Use 'http://localhost:4000'
  String get _socketUrl {
    const String serverIP = '192.168.1.11'; // Your Mac IP
    const int serverPort = 4000;
    
    print('════════════════════════════════════════════');
    print('🔌 [Socket URL] Determining connection URL...');
    print('🔌 [Socket URL] Is Web: $kIsWeb');
    print('🔌 [Socket URL] Platform: $defaultTargetPlatform');
    
    if (kIsWeb) {
      // Web platform: use localhost
      const url = 'http://localhost:$serverPort';
      print('🔌 [Socket URL] Web detected → Using: $url');
      print('════════════════════════════════════════════');
      return url;
    }

    // Check if Android
    try {
      final bool isAndroid = defaultTargetPlatform == TargetPlatform.android;
      if (isAndroid) {
        // Android Physical Device: use Mac's IP
        final url = 'http://$serverIP:$serverPort';
        print('🔌 [Socket URL] Android detected → Using: $url');
        print('════════════════════════════════════════════');
        return url;
      }
    } catch (e) {
      print('🔌 [Socket URL] Platform detection error: $e');
    }

    // iOS Physical Device - use Mac's IP address
    // Note: On physical iPhone, localhost refers to the iPhone itself, not the Mac
    // For iOS Simulator, localhost works (but we'll use IP for consistency)
    final url = 'http://$serverIP:$serverPort';
    print('🔌 [Socket URL] iOS/Other detected → Using: $url');
    print('════════════════════════════════════════════');
    return url;
  }

  /// Connect to socket server with JWT token
  /// [forceReconnect] If true, will disconnect existing socket first, then connect
  /// This is useful after logout/login to ensure clean reconnection
  Future<void> connect({bool forceReconnect = false}) async {
    print('═══════════════════════════════════════════════════════');
    print('🚀 SOCKET CONNECT METHOD CALLED!!!');
    print('═══════════════════════════════════════════════════════');
    
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('🔌 [Socket] ⏰ [$timestamp] Starting connection attempt...');
    debugPrint('🔌 [Socket] ⏰ [$timestamp] _isConnected = $_isConnected, _isConnecting = $_isConnecting');
    debugPrint('🔌 [Socket] ⏰ [$timestamp] forceReconnect = $forceReconnect');
    
    // If force reconnect is requested, disconnect first
    if (forceReconnect) {
      debugPrint('🔌 [Socket] ⏰ [$timestamp] 🔄 Force reconnect requested - Disconnecting existing socket first...');
      disconnect();
      // Add a small delay to ensure cleanup is complete
      await Future.delayed(const Duration(milliseconds: 100));
      debugPrint('🔌 [Socket] ⏰ [$timestamp] ✅ Cleanup complete, proceeding with connection...');
    }
    
    if (_isConnected || _isConnecting) {
      debugPrint('🔌 [Socket] ⏰ [$timestamp] Already connected or connecting. Status: connected=$_isConnected, connecting=$_isConnecting');
      if (!forceReconnect) {
        debugPrint('🔌 [Socket] ⏰ [$timestamp] ⚠️ Skipping connection (already connected/connecting). Use forceReconnect=true to force reconnection.');
        return;
      }
      // If forceReconnect is true but flags are still set, force disconnect again
      debugPrint('🔌 [Socket] ⏰ [$timestamp] ⚠️ Flags still set after disconnect, forcing cleanup...');
      _isConnected = false;
      _isConnecting = false;
      if (_socket != null) {
        try {
          _socket!.disconnect();
          _socket!.dispose();
        } catch (e) {
          debugPrint('🔌 [Socket] ⏰ [$timestamp] ⚠️ Error during forced cleanup: $e');
        }
        _socket = null;
      }
    }

    try {
      _isConnecting = true;
      debugPrint('🔌 [Socket] ⏰ [$timestamp] Set _isConnecting = true');

      // Get JWT token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      final socketUrl = _socketUrl;
      debugPrint('🔌 [Socket] ⏰ [$timestamp] Socket URL: $socketUrl');
      debugPrint('🔌 [Socket] ⏰ [$timestamp] Token status: ${token != null && token.isNotEmpty ? "✅ Found (${token.length} chars)" : "❌ Missing or empty"}');

      if (token == null || token.isEmpty) {
        _isConnecting = false;
        debugPrint('🔌 [Socket] ⏰ [$timestamp] ❌ Cannot connect: No token available');
        return;
      }
      
      debugPrint('🔌 [Socket] ⏰ [$timestamp] Creating Socket.IO instance...');
      debugPrint('🔌 [Socket] ⏰ [$timestamp] Socket Options:');
      debugPrint('   - Transports: [websocket, polling]');
      debugPrint('   - Auth: {token: ***${token.substring(token.length > 10 ? token.length - 10 : 0)}}');
      debugPrint('   - Headers: {Authorization: Bearer ***${token.substring(token.length > 10 ? token.length - 10 : 0)}}');
      debugPrint('   - AutoConnect: disabled (will connect explicitly)');
      debugPrint('   - Timeout: 20000ms');
      
      _socket = IO.io(
        socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling']) // Important: Use both for compatibility
            .setAuth({'token': token}) // Send token in auth object
            .setExtraHeaders({'Authorization': 'Bearer $token'}) // Also send in headers as per requirements
            .disableAutoConnect() // Disable auto-connect, we'll connect explicitly
            .setTimeout(20000) // 20 seconds timeout
            .build(),
      );

      debugPrint('🔌 [Socket] ⏰ [$timestamp] Socket instance created, setting up event handlers...');

      // Connection event handlers
      _socket!.onConnect((_) {
        final connectTimestamp = DateTime.now().toIso8601String();
        _isConnected = true;
        _isConnecting = false;
        debugPrint('🔌 [Socket] ⏰ [$connectTimestamp] ✅ Connected successfully!');
        debugPrint('🔌 [Socket] ⏰ [$connectTimestamp] Socket ID: ${_socket?.id}');
        debugPrint('🔌 [Socket] ⏰ [$connectTimestamp] Connection status: isConnected=$_isConnected, isConnecting=$_isConnecting');
        
        // Re-setup notification listeners after reconnection
        // This ensures listeners are active even after socket reconnects
        debugPrint('🔌 [Socket] ⏰ [$connectTimestamp] 🔄 Re-setting up notification listeners after connection...');
        _setupNotificationListeners();
        debugPrint('🔌 [Socket] ⏰ [$connectTimestamp] ✅ Notification listeners re-setup complete');
        debugPrint('🔌 [Socket] ⏰ [$connectTimestamp]    Total listeners: ${_notificationListeners.length}');
      });

      _socket!.onDisconnect((reason) {
        final disconnectTimestamp = DateTime.now().toIso8601String();
        _isConnected = false;
        _isConnecting = false;
        debugPrint('🔌 [Socket] ⏰ [$disconnectTimestamp] ⚠️ Disconnected. Reason: $reason');
        debugPrint('🔌 [Socket] ⏰ [$disconnectTimestamp] Connection status: isConnected=$_isConnected, isConnecting=$_isConnecting');
      });

      _socket!.onConnectError((error) {
        final errorTimestamp = DateTime.now().toIso8601String();
        _isConnected = false;
        _isConnecting = false;
        print('════════════════════════════════════════════════════════════════════');
        print('❌❌❌ SOCKET CONNECTION ERROR ❌❌❌');
        print('════════════════════════════════════════════════════════════════════');
        print('🔌 [Socket] ⏰ [$errorTimestamp] Connection error: $error');
        print('🔌 [Socket] ⏰ [$errorTimestamp] Error type: ${error.runtimeType}');
        print('🔌 [Socket] ⏰ [$errorTimestamp] Error details: ${error.toString()}');
        print('🔌 [Socket] ⏰ [$errorTimestamp] Connection status: isConnected=$_isConnected, isConnecting=$_isConnecting');
        print('════════════════════════════════════════════════════════════════════');
        debugPrint('🔌 [Socket] ⏰ [$errorTimestamp] ❌ Connection error: $error');
        debugPrint('🔌 [Socket] ⏰ [$errorTimestamp] Error type: ${error.runtimeType}');
        debugPrint('🔌 [Socket] ⏰ [$errorTimestamp] Connection status: isConnected=$_isConnected, isConnecting=$_isConnecting');
      });

      _socket!.onError((error) {
        final errorTimestamp = DateTime.now().toIso8601String();
        print('════════════════════════════════════════════════════════════════════');
        print('❌❌❌ SOCKET ERROR ❌❌❌');
        print('════════════════════════════════════════════════════════════════════');
        print('🔌 [Socket] ⏰ [$errorTimestamp] Socket error: $error');
        print('🔌 [Socket] ⏰ [$errorTimestamp] Error type: ${error.runtimeType}');
        print('🔌 [Socket] ⏰ [$errorTimestamp] Error details: ${error.toString()}');
        print('════════════════════════════════════════════════════════════════════');
        debugPrint('🔌 [Socket] ⏰ [$errorTimestamp] ❌ Socket error: $error');
        debugPrint('🔌 [Socket] ⏰ [$errorTimestamp] Error type: ${error.runtimeType}');
      });

      debugPrint('🔌 [Socket] ⏰ [$timestamp] Event handlers registered, setting up notification listeners...');

      // Listen for notification events
      // Note: We set up listeners before connection is established
      // Socket.IO will queue them and they'll be active once connected
      _setupNotificationListeners();

      debugPrint('🔌 [Socket] ⏰ [$timestamp] Notification listeners setup complete, waiting 100ms...');

      // Add a small delay to ensure socket is ready before setting up listeners
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Explicitly connect the socket (since auto-connect is disabled)
      final connectCallTimestamp = DateTime.now().toIso8601String();
      debugPrint('🔌 [Socket] ⏰ [$connectCallTimestamp] 🔌 Calling socket.connect() explicitly...');
      _socket!.connect();
      debugPrint('🔌 [Socket] ⏰ [$connectCallTimestamp] ✅ socket.connect() called');
      
      final afterDelayTimestamp = DateTime.now().toIso8601String();
      debugPrint('🔌 [Socket] ⏰ [$afterDelayTimestamp] Connection setup complete. Socket ID: ${_socket?.id}');
      debugPrint('🔌 [Socket] ⏰ [$afterDelayTimestamp] ⏳ Waiting for connection to establish...');

    } catch (e, stackTrace) {
      final errorTimestamp = DateTime.now().toIso8601String();
      _isConnected = false;
      _isConnecting = false;
      debugPrint('🔌 [Socket] ⏰ [$errorTimestamp] ❌ Error connecting: $e');
      debugPrint('🔌 [Socket] ⏰ [$errorTimestamp] Stack trace: $stackTrace');
    }
  }

  /// Setup notification event listeners
  void _setupNotificationListeners() {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('👂 [Socket] ⏰ [$timestamp] Setting up notification listeners...');
    
    if (_socket == null) {
      debugPrint('👂 [Socket] ⏰ [$timestamp] ❌ Cannot setup listeners: Socket is null');
      return;
    }

    debugPrint('👂 [Socket] ⏰ [$timestamp] Socket exists, registering listeners...');
    debugPrint('👂 [Socket] ⏰ [$timestamp] Will listen for events:');
    debugPrint('   1. onAny (all events)');
    debugPrint('   2. notification');
    debugPrint('   3. friend_request_received');
    debugPrint('   4. friend_request');
    debugPrint('   5. friend_request_accepted');
    debugPrint('   6. unread_count_update');

    // DEBUG: Listen to ALL events to see what's coming from backend
    _socket!.onAny((event, data) {
      final eventTimestamp = DateTime.now().toIso8601String();
      debugPrint('👂 [Socket] ⏰ [$eventTimestamp] 🔍 Received ANY event: "$event"');
      debugPrint('👂 [Socket] ⏰ [$eventTimestamp]    Data: $data');
      debugPrint('👂 [Socket] ⏰ [$eventTimestamp]    Data type: ${data.runtimeType}');
    });
    debugPrint('👂 [Socket] ⏰ [$timestamp] ✅ Registered: onAny listener');

    // Listen for 'notification' event (general notification)
    _socket!.on('notification', (data) {
      final eventTimestamp = DateTime.now().toIso8601String();
      debugPrint('👂 [Socket] ⏰ [$eventTimestamp] 📨 Received "notification" event');
      debugPrint('👂 [Socket] ⏰ [$eventTimestamp]    Data: $data');
      debugPrint('👂 [Socket] ⏰ [$eventTimestamp]    Data type: ${data.runtimeType}');
      try {
        final notification = data is Map<String, dynamic>
            ? data
            : {'data': data, 'type': 'general'};
        debugPrint('👂 [Socket] ⏰ [$eventTimestamp]    Processing notification: type=${notification['type']}');
        _notifyListeners(notification);
      } catch (e) {
        debugPrint('👂 [Socket] ⏰ [$eventTimestamp] ❌ Error processing notification event: $e');
      }
    });
    debugPrint('👂 [Socket] ⏰ [$timestamp] ✅ Registered: notification listener');

    // Listen for 'friend_request_received' event (alternative event name)
    _socket!.on('friend_request_received', (data) {
      final eventTimestamp = DateTime.now().toIso8601String();
      debugPrint('👂 [Socket] ⏰ [$eventTimestamp] 📨 Received "friend_request_received" event');
      debugPrint('👂 [Socket] ⏰ [$eventTimestamp]    Data: $data');
      debugPrint('👂 [Socket] ⏰ [$eventTimestamp]    Data type: ${data.runtimeType}');
      try {
        Map<String, dynamic> notification;
        
        if (data is Map<String, dynamic>) {
          debugPrint('👂 [Socket] ⏰ [$eventTimestamp]    Parsing Map data...');
          debugPrint('👂 [Socket] ⏰ [$eventTimestamp]    - requestId: ${data['requestId'] ?? data['_id']}');
          debugPrint('👂 [Socket] ⏰ [$eventTimestamp]    - from: ${data['from']}');
          debugPrint('👂 [Socket] ⏰ [$eventTimestamp]    - message: ${data['message']}');
          
          notification = {
            '_id': data['requestId'] ?? data['_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            'userId': data['from']?['_id'] ?? data['from']?['userId'] ?? '',
            'type': 'friendRequest',
            'title': 'Friend Request',
            'message': data['message'] ?? '${data['from']?['fullName'] ?? 'Someone'} sent you a friend request',
            'data': data,
            'isRead': false,
            'createdAt': DateTime.now().toIso8601String(),
            // Extract unreadCount from payload if available
            'unreadCount': data['unreadCount'] ?? data['unread_count'],
          };
        } else {
          debugPrint('👂 [Socket] ⏰ [$eventTimestamp]    Data is not Map, using default format');
          notification = {
            'data': data,
            'type': 'friendRequest',
            'title': 'Friend Request',
            'message': 'You received a friend request',
            'isRead': false,
            'createdAt': DateTime.now().toIso8601String(),
          };
        }
        
        debugPrint('👂 [Socket] ⏰ [$eventTimestamp]    Notification created: type=${notification['type']}, title=${notification['title']}');
        _notifyListeners(notification);
      } catch (e, stackTrace) {
        debugPrint('👂 [Socket] ⏰ [$eventTimestamp] ❌ Error processing friend_request_received: $e');
        debugPrint('👂 [Socket] ⏰ [$eventTimestamp]    Stack trace: $stackTrace');
      }
    });
    debugPrint('👂 [Socket] ⏰ [$timestamp] ✅ Registered: friend_request_received listener');

    // Listen for 'friend_request' event (main event from backend)
    // Backend sends this event when a friend request is received
    _socket!.on('friend_request', (data) {
      final eventTimestamp = DateTime.now().toIso8601String();
      debugPrint('👂 [Socket] ⏰ [$eventTimestamp] 📨 Received "friend_request" event');
      debugPrint('👂 [Socket] ⏰ [$eventTimestamp]    Data: $data');
      debugPrint('👂 [Socket] ⏰ [$eventTimestamp]    Data type: ${data.runtimeType}');
      try {
        Map<String, dynamic> notification;
        
        if (data is Map<String, dynamic>) {
          debugPrint('👂 [Socket] ⏰ [$eventTimestamp]    Parsing Map data...');
          debugPrint('👂 [Socket] ⏰ [$eventTimestamp]    - requestId: ${data['requestId'] ?? data['_id']}');
          debugPrint('👂 [Socket] ⏰ [$eventTimestamp]    - from: ${data['from']}');
          debugPrint('👂 [Socket] ⏰ [$eventTimestamp]    - message: ${data['message']}');
          
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
            // Extract unreadCount from payload if available
            'unreadCount': data['unreadCount'] ?? data['unread_count'],
          };
        } else {
          debugPrint('👂 [Socket] ⏰ [$eventTimestamp]    Data is not Map, using default format');
          notification = {
            'data': data,
            'type': 'friendRequest',
            'title': 'Friend Request',
            'message': 'You received a friend request',
            'isRead': false,
            'createdAt': DateTime.now().toIso8601String(),
          };
        }
        
        debugPrint('👂 [Socket] ⏰ [$eventTimestamp]    Notification created: type=${notification['type']}, title=${notification['title']}');
        _notifyListeners(notification);
      } catch (e, stackTrace) {
        debugPrint('👂 [Socket] ⏰ [$eventTimestamp] ❌ Error processing friend_request: $e');
        debugPrint('👂 [Socket] ⏰ [$eventTimestamp]    Stack trace: $stackTrace');
      }
    });
    debugPrint('👂 [Socket] ⏰ [$timestamp] ✅ Registered: friend_request listener');

    // Listen for 'friend_request_accepted' event
    _socket!.on('friend_request_accepted', (data) {
      final eventTimestamp = DateTime.now().toIso8601String();
      debugPrint('👂 [Socket] ⏰ [$eventTimestamp] 📨 Received "friend_request_accepted" event');
      debugPrint('👂 [Socket] ⏰ [$eventTimestamp]    Data: $data');
      debugPrint('👂 [Socket] ⏰ [$eventTimestamp]    Data type: ${data.runtimeType}');
      try {
        Map<String, dynamic> notification;
        
        if (data is Map<String, dynamic>) {
          debugPrint('👂 [Socket] ⏰ [$eventTimestamp]    Parsing Map data...');
          debugPrint('👂 [Socket] ⏰ [$eventTimestamp]    - requestId: ${data['requestId'] ?? data['_id']}');
          debugPrint('👂 [Socket] ⏰ [$eventTimestamp]    - user: ${data['user']}');
          debugPrint('👂 [Socket] ⏰ [$eventTimestamp]    - message: ${data['message']}');
          
          notification = {
            '_id': data['requestId'] ?? data['_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            'userId': data['user']?['_id'] ?? data['userId'] ?? '',
            'type': 'friendRequestAccepted',
            'title': 'Friend Request Accepted',
            'message': data['message'] ?? '${data['user']?['fullName'] ?? 'Someone'} accepted your friend request',
            'data': data,
            'isRead': false,
            'createdAt': DateTime.now().toIso8601String(),
            // Extract unreadCount from payload if available
            'unreadCount': data['unreadCount'] ?? data['unread_count'],
          };
        } else {
          debugPrint('👂 [Socket] ⏰ [$eventTimestamp]    Data is not Map, using default format');
          notification = {
            'data': data,
            'type': 'friendRequestAccepted',
            'title': 'Friend Request Accepted',
            'message': 'Your friend request was accepted',
            'isRead': false,
            'createdAt': DateTime.now().toIso8601String(),
          };
        }
        
        debugPrint('👂 [Socket] ⏰ [$eventTimestamp]    Notification created: type=${notification['type']}, title=${notification['title']}');
        _notifyListeners(notification);
      } catch (e, stackTrace) {
        debugPrint('👂 [Socket] ⏰ [$eventTimestamp] ❌ Error processing friend_request_accepted: $e');
        debugPrint('👂 [Socket] ⏰ [$eventTimestamp]    Stack trace: $stackTrace');
      }
    });
    debugPrint('👂 [Socket] ⏰ [$timestamp] ✅ Registered: friend_request_accepted listener');

    // Listen for 'unread_count_update' event
    _socket!.on('unread_count_update', (data) {
      final eventTimestamp = DateTime.now().toIso8601String();
      debugPrint('👂 [Socket] ⏰ [$eventTimestamp] 📨 Received "unread_count_update" event');
      debugPrint('👂 [Socket] ⏰ [$eventTimestamp]    Data: $data');
      debugPrint('👂 [Socket] ⏰ [$eventTimestamp]    Data type: ${data.runtimeType}');
      try {
        Map<String, dynamic> updateData;
        
        if (data is Map<String, dynamic>) {
          debugPrint('👂 [Socket] ⏰ [$eventTimestamp]    Parsing Map data...');
          debugPrint('👂 [Socket] ⏰ [$eventTimestamp]    - unreadCount: ${data['unreadCount'] ?? data['unread_count']}');
          
          updateData = {
            'type': 'unreadCountUpdate',
            'unreadCount': data['unreadCount'] ?? data['unread_count'] ?? 0,
            'data': data,
            'timestamp': DateTime.now().toIso8601String(),
          };
        } else {
          debugPrint('👂 [Socket] ⏰ [$eventTimestamp]    Data is not Map, using default format');
          updateData = {
            'type': 'unreadCountUpdate',
            'unreadCount': 0,
            'data': data,
            'timestamp': DateTime.now().toIso8601String(),
          };
        }
        
        debugPrint('👂 [Socket] ⏰ [$eventTimestamp]    Update data created: unreadCount=${updateData['unreadCount']}');
        _notifyListeners(updateData);
      } catch (e, stackTrace) {
        debugPrint('👂 [Socket] ⏰ [$eventTimestamp] ❌ Error processing unread_count_update: $e');
        debugPrint('👂 [Socket] ⏰ [$eventTimestamp]    Stack trace: $stackTrace');
      }
    });
    debugPrint('👂 [Socket] ⏰ [$timestamp] ✅ Registered: unread_count_update listener');
    
    final setupCompleteTimestamp = DateTime.now().toIso8601String();
    debugPrint('👂 [Socket] ⏰ [$setupCompleteTimestamp] ✅ All notification listeners setup complete!');
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
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('📢 [Socket] ⏰ [$timestamp] Notifying listeners about new notification');
    debugPrint('📢 [Socket] ⏰ [$timestamp]    Total listeners: ${_notificationListeners.length}');
    debugPrint('📢 [Socket] ⏰ [$timestamp]    Notification details:');
    debugPrint('📢 [Socket] ⏰ [$timestamp]       - Type: ${notification['type']}');
    debugPrint('📢 [Socket] ⏰ [$timestamp]       - Title: ${notification['title']}');
    debugPrint('📢 [Socket] ⏰ [$timestamp]       - Message: ${notification['message']}');
    debugPrint('📢 [Socket] ⏰ [$timestamp]       - ID: ${notification['_id']}');
    debugPrint('📢 [Socket] ⏰ [$timestamp]       - User ID: ${notification['userId']}');
    debugPrint('📢 [Socket] ⏰ [$timestamp]       - Is Read: ${notification['isRead']}');
    
    if (_notificationListeners.isEmpty) {
      debugPrint('📢 [Socket] ⏰ [$timestamp] ⚠️ WARNING: No listeners registered! Notification will be lost.');
      return;
    }
    
    for (int i = 0; i < _notificationListeners.length; i++) {
      final listenerTimestamp = DateTime.now().toIso8601String();
      try {
        debugPrint('📢 [Socket] ⏰ [$listenerTimestamp]    Notifying listener #$i...');
        debugPrint('📢 [Socket] ⏰ [$listenerTimestamp]       Listener type: ${_notificationListeners[i].runtimeType}');
        debugPrint('📢 [Socket] ⏰ [$listenerTimestamp]       Listener hash: ${_notificationListeners[i].hashCode}');
        
        _notificationListeners[i](notification);
        
        final successTimestamp = DateTime.now().toIso8601String();
        debugPrint('📢 [Socket] ⏰ [$successTimestamp]    ✅ Listener #$i notified successfully');
      } catch (e, stackTrace) {
        final errorTimestamp = DateTime.now().toIso8601String();
        debugPrint('📢 [Socket] ⏰ [$errorTimestamp]    ❌ Error in listener #$i: $e');
        debugPrint('📢 [Socket] ⏰ [$errorTimestamp]       Stack trace: $stackTrace');
      }
    }
    
    final completeTimestamp = DateTime.now().toIso8601String();
    debugPrint('📢 [Socket] ⏰ [$completeTimestamp] ✅ Finished notifying all ${_notificationListeners.length} listener(s)');
  }

  /// Disconnect from socket server
  /// Ensures complete cleanup of socket instance, flags, and listeners
  void disconnect() {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('🔌 [Socket] ⏰ [$timestamp] 🔌 Disconnect called');
    debugPrint('🔌 [Socket] ⏰ [$timestamp]    Current state: isConnected=$_isConnected, isConnecting=$_isConnecting');
    debugPrint('🔌 [Socket] ⏰ [$timestamp]    Socket exists: ${_socket != null}');
    debugPrint('🔌 [Socket] ⏰ [$timestamp]    Socket ID: ${_socket?.id}');
    debugPrint('🔌 [Socket] ⏰ [$timestamp]    Listeners count: ${_notificationListeners.length}');
    
    if (_socket != null) {
      try {
        // Reset flags first to prevent race conditions
        _isConnected = false;
        _isConnecting = false;
        debugPrint('🔌 [Socket] ⏰ [$timestamp]    ✅ Flags reset: isConnected=false, isConnecting=false');
        
        // Disconnect socket
        _socket!.disconnect();
        debugPrint('🔌 [Socket] ⏰ [$timestamp]    ✅ Socket disconnected');
        
        // Dispose socket instance
        _socket!.dispose();
        debugPrint('🔌 [Socket] ⏰ [$timestamp]    ✅ Socket disposed');
        
        // Clear socket reference
        _socket = null;
        debugPrint('🔌 [Socket] ⏰ [$timestamp]    ✅ Socket reference cleared');
        // IMPORTANT:
        // Do NOT clear `_notificationListeners` here.
        // These are app-level listeners (e.g., NotificationsCubit) that must survive logout/login
        // and socket reconnects. Clearing them causes real-time notifications to stop until the
        // listener is re-registered manually (often only when opening Notifications screen).
        
        final completeTimestamp = DateTime.now().toIso8601String();
        debugPrint('🔌 [Socket] ⏰ [$completeTimestamp] ✅ Disconnect complete - All resources cleaned up');
      } catch (e, stackTrace) {
        final errorTimestamp = DateTime.now().toIso8601String();
        debugPrint('🔌 [Socket] ⏰ [$errorTimestamp] ❌ Error during disconnect: $e');
        debugPrint('🔌 [Socket] ⏰ [$errorTimestamp]    Stack trace: $stackTrace');
        
        // Force cleanup even if there's an error
        _socket = null;
        _isConnected = false;
        _isConnecting = false;
        debugPrint('🔌 [Socket] ⏰ [$errorTimestamp]    ✅ Forced cleanup completed');
      }
    } else {
      // No socket to disconnect, but ensure flags are reset
      _isConnected = false;
      _isConnecting = false;
      debugPrint('🔌 [Socket] ⏰ [$timestamp]    ⚠️ No socket to disconnect, but flags reset');
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

