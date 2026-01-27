import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';
import 'package:wish_listy/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:wish_listy/features/notifications/presentation/widgets/notification_permission_dialog.dart';
import 'package:wish_listy/main.dart';

/// Global background handler for FCM messages.
///
/// This must be a top-level function and annotated with [vm:entry-point]
/// so that it can be invoked from a background isolate on both Android and iOS.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('⚠️ FCM background: Firebase initialization failed: $e');
  }

  debugPrint('🔔 FCM background message: ${message.messageId} '
      'data=${message.data}');
}

/// Centralized service for Firebase Cloud Messaging (FCM) integration.
///
/// Responsibilities:
/// - Manage FCM initialization and token lifecycle.
/// - Request and manage notification permissions via a dedicated dialog.
/// - Wire foreground/background/terminated notification taps into
///   existing navigation and notifications logic.
class FcmService {
  FcmService._internal();
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  bool _isInitialized = false;
  bool _permissionDialogShownInSession = false;

  /// Initialize FCM integration.
  ///
  /// - Sets foreground presentation options (iOS).
  /// - Ensures current token is synced to backend when authenticated.
  /// - Listens for token refresh and keeps backend in sync.
  /// - Wires notification tap handling for background/terminated states.
  Future<void> initialize({
    required AuthRepository authRepository,
    required NotificationsCubit notificationsCubit,
  }) async {
    if (_isInitialized) {
      return;
    }
    _isInitialized = true;

    debugPrint('🔔 FcmService: Initializing FCM...');

    // iOS: avoid system heads-up banners while app is in foreground.
    // We rely on Socket.io for real-time in-app notifications instead.
    try {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint(
        '⚠️ FcmService: Failed to set foreground presentation options: $e',
      );
    }

    // Ensure initial token is sent to backend when user is already authenticated.
    try {
      final token = await _messaging.getToken();
      debugPrint('🔔 FcmService: Initial FCM token: $token');
      if (token != null && authRepository.isAuthenticated) {
        await authRepository.updateFcmToken(token);
      }
    } catch (e) {
      debugPrint('⚠️ FcmService: Failed to fetch initial FCM token: $e');
    }

    // Keep backend updated when the FCM token changes.
    _messaging.onTokenRefresh.listen((token) async {
      debugPrint('🔔 FcmService: onTokenRefresh: $token');
      if (!authRepository.isAuthenticated) {
        debugPrint(
          '🔔 FcmService: User not authenticated, skipping token update.',
        );
        return;
      }

      try {
        await authRepository.updateFcmToken(token);
      } catch (e) {
        debugPrint('⚠️ FcmService: Failed to update FCM token on refresh: $e');
      }
    });

    // Foreground messages:
    // We intentionally do NOT show a system notification here to avoid
    // duplicates with Socket.io. Socket.io remains the primary real-time
    // channel while the app is in the foreground.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
        '🔔 FcmService: Foreground message received. '
        'messageId=${message.messageId}, data=${message.data}',
      );
      // No UI shown here by design to avoid duplicates with Socket.io.
    });

    // Handle notification taps when app is in background.
    FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) {
        debugPrint(
          '🔔 FcmService: onMessageOpenedApp: '
          'messageId=${message.messageId}, data=${message.data}',
        );
        _handleNotificationTap(
          message,
          notificationsCubit: notificationsCubit,
        );
      },
    );

    // Handle the case where the app was launched from a terminated state
    // via tapping on a notification.
    try {
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint(
          '🔔 FcmService: getInitialMessage: '
          'messageId=${initialMessage.messageId}, data=${initialMessage.data}',
        );
        _handleNotificationTap(
          initialMessage,
          notificationsCubit: notificationsCubit,
        );
      }
    } catch (e) {
      debugPrint('⚠️ FcmService: Error in getInitialMessage: $e');
    }
  }

  /// Get the current FCM token (may be null if not yet available).
  Future<String?> getToken() {
    return _messaging.getToken();
  }

  /// Show a professional permission dialog and, if the user accepts,
  /// request notification permissions from the OS.
  ///
  /// This method is intentionally UI-aware and should be called from
  /// a screen where a [BuildContext] is available (e.g., home screen
  /// after onboarding or login).
  Future<void> ensurePermissionRequested(BuildContext context) async {
    // Avoid spamming the user with the dialog in a single app session.
    if (_permissionDialogShownInSession) {
      return;
    }

    final settings = await _messaging.getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus ==
            AuthorizationStatus.provisional) {
      // Already authorized; nothing to do.
      return;
    }

    _permissionDialogShownInSession = true;

    final shouldRequest = await NotificationPermissionDialog.show(context);
    if (shouldRequest != true) {
      return;
    }

    try {
      final result = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint(
        '🔔 FcmService: Permission result: ${result.authorizationStatus}',
      );
    } catch (e) {
      debugPrint('⚠️ FcmService: Failed to request notification permission: $e');
    }
  }

  void _handleNotificationTap(
    RemoteMessage message, {
    required NotificationsCubit notificationsCubit,
  }) {
    final context = MyApp.navigatorKey.currentContext;
    if (context == null) {
      debugPrint(
        '⚠️ FcmService: navigatorKey.currentContext is null, '
        'cannot handle notification tap.',
      );
      return;
    }

    // Prefer data payload for navigation; fall back to notification fields.
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
}

