import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:wish_listy/core/constants/app_colors.dart';

/// Top-level callback for notification taps when the app is in the background.
@pragma('vm:entry-point')
void onChatNotificationTapBackground(NotificationResponse response) {
  LocalNotificationService.instance.handleNotificationResponse(response);
}

/// Displays local notifications for foreground chat messages (FCM data payloads).
class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String chatChannelId = 'wishlisty_chat_messages';
  static const int _chatNotificationIdBase = 10000;

  bool _isInitialized = false;
  void Function(Map<String, dynamic> payload)? onChatNotificationTap;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: onChatNotificationTapBackground,
    );

    if (Platform.isAndroid) {
      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          chatChannelId,
          'Chat Messages',
          description: 'New chat message notifications',
          importance: Importance.high,
        ),
      );
    }

    _isInitialized = true;
  }

  void handleNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) return;
      if (decoded['type']?.toString() != 'chat_message') return;
      onChatNotificationTap?.call(decoded);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('LocalNotificationService tap parse error: $e');
      }
    }
  }

  Future<void> showChatMessage({
    required String senderId,
    required String chatRoomId,
    required String senderName,
    required String body,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final payload = jsonEncode({
      'type': 'chat_message',
      'senderId': senderId,
      'chatRoomId': chatRoomId,
      'senderName': senderName,
    });

    final notificationId =
        _chatNotificationIdBase + (senderId.hashCode % 10000).abs();

    await _plugin.show(
      notificationId,
      senderName,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          chatChannelId,
          'Chat Messages',
          channelDescription: 'New chat message notifications',
          importance: Importance.high,
          priority: Priority.high,
          color: AppColors.primary,
          icon: '@mipmap/launcher_icon',
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          threadIdentifier: 'wishlisty_chat',
        ),
      ),
      payload: payload,
    );
  }
}
