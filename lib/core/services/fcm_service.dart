import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:wish_listy/core/services/local_notification_service.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';
import 'package:wish_listy/features/chat/presentation/cubit/chat_cubit.dart';
import 'package:wish_listy/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:wish_listy/features/notifications/presentation/widgets/notification_permission_dialog.dart';
import 'package:wish_listy/core/services/notification_preference_service.dart';
import 'package:wish_listy/main.dart';

/// Parses chat-related fields from an FCM [data] payload.
class ChatFcmPayload {
  const ChatFcmPayload({
    required this.senderId,
    required this.chatRoomId,
    required this.senderName,
    required this.body,
  });

  final String senderId;
  final String chatRoomId;
  final String senderName;
  final String body;

  bool get isValid => senderId.isNotEmpty;

  static bool isChatMessage(Map<String, dynamic> data) {
    final type = data['type']?.toString().toLowerCase();
    return type == 'chat_message' || type == 'chatmessage';
  }

  static ChatFcmPayload? fromRemoteMessage(RemoteMessage message) {
    return fromData({
      ...message.data,
      if (message.notification?.title != null)
        'notificationTitle': message.notification!.title,
      if (message.notification?.body != null)
        'notificationBody': message.notification!.body,
    });
  }

  static ChatFcmPayload? fromData(Map<String, dynamic> data) {
    if (!isChatMessage(data)) return null;

    final nested = data['data'];
    final nestedMap = nested is Map<String, dynamic> ? nested : const {};

    final senderId = _firstNonEmpty([
      data['senderId'],
      data['sender_id'],
      nestedMap['senderId'],
      nestedMap['sender_id'],
    ]);

    final chatRoomId = _firstNonEmpty([
      data['chatRoomId'],
      data['chat_room_id'],
      nestedMap['chatRoomId'],
      nestedMap['chat_room_id'],
    ]);

    final senderName = _firstNonEmpty([
      data['senderName'],
      data['sender_name'],
      nestedMap['senderName'],
      nestedMap['sender_name'],
      data['notificationTitle'],
      data['title'],
    ]);

    final body = _firstNonEmpty([
      data['message'],
      data['body'],
      data['text'],
      nestedMap['message'],
      nestedMap['body'],
      nestedMap['text'],
      data['notificationBody'],
    ]);

    return ChatFcmPayload(
      senderId: senderId,
      chatRoomId: chatRoomId,
      senderName: senderName.isNotEmpty ? senderName : 'WishListy',
      body: body.isNotEmpty ? body : 'New message',
    );
  }

  static String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
  }
}

/// Global background handler for FCM messages.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}

  final chatPayload = ChatFcmPayload.fromRemoteMessage(message);
  if (chatPayload == null || !chatPayload.isValid) return;

  try {
    await LocalNotificationService.instance.initialize();
    await LocalNotificationService.instance.showChatMessage(
      senderId: chatPayload.senderId,
      chatRoomId: chatPayload.chatRoomId,
      senderName: chatPayload.senderName,
      body: chatPayload.body,
    );
  } catch (_) {}
}

/// Centralized service for Firebase Cloud Messaging (FCM) integration.
class FcmService {
  FcmService._internal();
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final LocalNotificationService _localNotifications =
      LocalNotificationService.instance;

  bool _isInitialized = false;
  bool _permissionDialogShownInSession = false;
  NotificationsCubit? _notificationsCubit;
  ChatCubit? _chatCubit;

  Future<void> initialize({
    required AuthRepository authRepository,
    required NotificationsCubit notificationsCubit,
    ChatCubit? chatCubit,
  }) async {
    if (_isInitialized) {
      return;
    }
    _isInitialized = true;
    _notificationsCubit = notificationsCubit;
    _chatCubit = chatCubit;

    await _localNotifications.initialize();
    _localNotifications.onChatNotificationTap = (payload) {
      _navigateToChatRoom(payload);
    };

    try {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: true,
      );
    } catch (_) {}

    try {
      final token = await _messaging.getToken();
      if (token != null && authRepository.isAuthenticated) {
        await authRepository.syncFcmToken();
      }
    } catch (_) {}

    _messaging.onTokenRefresh.listen((token) async {
      if (!authRepository.isAuthenticated) return;
      try {
        await authRepository.updateFcmToken(token);
      } catch (_) {}
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message, notificationsCubit: notificationsCubit);
    });

    try {
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(
          initialMessage,
          notificationsCubit: notificationsCubit,
        );
      }
    } catch (_) {}
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final chatPayload = ChatFcmPayload.fromRemoteMessage(message);
    if (chatPayload != null && chatPayload.isValid) {
      _handleForegroundChatMessage(chatPayload);
      return;
    }

    _notificationsCubit?.getUnreadCount();
  }

  Future<void> _handleForegroundChatMessage(ChatFcmPayload payload) async {
    final chatCubit = _chatCubit;
    if (chatCubit != null) {
      await chatCubit.onForegroundChatPush(
        senderId: payload.senderId,
        chatRoomId: payload.chatRoomId,
      );

      if (chatCubit.isViewingChatRoom(
        senderId: payload.senderId,
        chatRoomId: payload.chatRoomId,
      )) {
        return;
      }
    }

    await _localNotifications.showChatMessage(
      senderId: payload.senderId,
      chatRoomId: payload.chatRoomId,
      senderName: payload.senderName,
      body: payload.body,
    );
  }

  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (_) {
      return null;
    }
  }

  Future<void> ensurePermissionRequested(BuildContext context) async {
    final preferenceService = NotificationPreferenceService();
    final userDisabled =
        await preferenceService.hasUserDisabledPushNotifications();
    if (userDisabled) return;

    if (_permissionDialogShownInSession) return;

    final settings = await _messaging.getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      return;
    }

    final shouldShow = await preferenceService.shouldShowPermissionDialog();
    if (!shouldShow) return;

    _permissionDialogShownInSession = true;

    final shouldRequest = await NotificationPermissionDialog.show(context);
    if (shouldRequest != true) {
      await preferenceService.saveLastPermissionRequestTime();
      return;
    }

    try {
      final result = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (result.authorizationStatus == AuthorizationStatus.authorized ||
          result.authorizationStatus == AuthorizationStatus.provisional) {
        await preferenceService.setPushNotificationsEnabled(true);
        await preferenceService.clearLastPermissionRequestTime();
      }
    } catch (_) {}
  }

  Future<bool> requestPermissionDirectly() async {
    try {
      final result = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      final granted =
          result.authorizationStatus == AuthorizationStatus.authorized ||
          result.authorizationStatus == AuthorizationStatus.provisional;
      if (granted) {
        await NotificationPreferenceService().clearLastPermissionRequestTime();
      }
      return granted;
    } catch (_) {
      return false;
    }
  }

  Future<AuthorizationStatus> getAuthorizationStatus() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus;
  }

  void _handleNotificationTap(
    RemoteMessage message, {
    required NotificationsCubit notificationsCubit,
  }) {
    final chatPayload = ChatFcmPayload.fromRemoteMessage(message);
    if (chatPayload != null && chatPayload.isValid) {
      _navigateToChatRoom({
        'senderId': chatPayload.senderId,
        'chatRoomId': chatPayload.chatRoomId,
        'senderName': chatPayload.senderName,
      });
      return;
    }

    final context = MyApp.navigatorKey.currentContext;
    if (context == null) return;

    final Map<String, dynamic> data = {
      ...message.data,
      if (message.messageId != null) 'fcmMessageId': message.messageId,
      if (message.notification?.title != null)
        'notificationTitle': message.notification!.title,
      if (message.notification?.body != null)
        'notificationBody': message.notification!.body,
    };

    notificationsCubit.handleRemoteNotificationTap(data, context);
  }

  void _navigateToChatRoom(Map<String, dynamic> data) {
    final context = MyApp.navigatorKey.currentContext;
    if (context == null) return;

    final senderId =
        data['senderId']?.toString() ?? data['sender_id']?.toString() ?? '';
    if (senderId.isEmpty) return;

    final chatRoomId =
        data['chatRoomId']?.toString() ?? data['chat_room_id']?.toString();
    final senderName =
        data['senderName']?.toString() ?? data['sender_name']?.toString();

    Navigator.of(context).pushNamed(
      AppRoutes.chatRoom,
      arguments: {
        'userId': senderId,
        if (senderName != null && senderName.isNotEmpty)
          'displayName': senderName,
        if (chatRoomId != null && chatRoomId.isNotEmpty) 'chatRoomId': chatRoomId,
      },
    );
  }
}
