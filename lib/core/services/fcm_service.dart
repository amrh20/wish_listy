import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';
import 'package:wish_listy/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:wish_listy/features/notifications/presentation/widgets/notification_permission_dialog.dart';
import 'package:wish_listy/core/services/notification_preference_service.dart';
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
  }

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
  NotificationsCubit? _notificationsCubit;

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
    _notificationsCubit = notificationsCubit;

    // iOS: avoid system heads-up banners while app is in foreground.
    // We rely on Socket.io for real-time in-app notifications instead.
    try {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: true,
      );
    } catch (e) {
    }

    // Ensure initial token is sent to backend when user is already authenticated.
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        // Print FCM token in a very visible format for Firebase Console testing
        
        if (authRepository.isAuthenticated) {
          // Use syncFcmToken() which has retry logic and proper error handling
          // Note: This may duplicate with authRepository.initialize() sync, but that's safe
          // as updateFcmToken() handles duplicate calls gracefully
          await authRepository.syncFcmToken();
        } else {
        }
      } else {
      }
    } catch (e) {
    }

    // Keep backend updated when the FCM token changes.
    // This happens when app is reinstalled, data is cleared, or token expires
    _messaging.onTokenRefresh.listen((token) async {
      
      if (!authRepository.isAuthenticated) {
        return;
      }

      try {
        await authRepository.updateFcmToken(token);
      } catch (e) {
      }
    });

    // Foreground messages:
    // We intentionally do NOT show a system notification here to avoid
    // duplicates with Socket.io. Socket.io remains the primary real-time
    // channel while the app is in the foreground. However, we still
    // refresh the unread count so the badge updates if the socket fails.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _notificationsCubit?.getUnreadCount();
    });

    // Handle notification taps when app is in background.
    FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) {
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
        _handleNotificationTap(
          initialMessage,
          notificationsCubit: notificationsCubit,
        );
      }
    } catch (e) {
    }
  }

  /// Get the current FCM token (may be null if not yet available).
  /// 
  /// This method can be used to manually retrieve the token for testing purposes.
  /// The token is automatically printed in logs when FCM initializes or refreshes.
  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      return token;
    } catch (e) {
      return null;
    }
  }

  /// Show a professional permission dialog and, if the user accepts,
  /// request notification permissions from the OS.
  ///
  /// This method is intentionally UI-aware and should be called from
  /// a screen where a [BuildContext] is available (e.g., home screen
  /// after onboarding or login).
  ///
  /// Implements a 7-day cooldown period after "Maybe later" is clicked.
  Future<void> ensurePermissionRequested(BuildContext context) async {
    // Avoid spamming the user with the dialog in a single app session.
    if (_permissionDialogShownInSession) {
      return;
    }

    // Check if permission is already granted
    final settings = await _messaging.getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus ==
            AuthorizationStatus.provisional) {
      // Already authorized; nothing to do.
      return;
    }

    // Check cooldown period (7 days since last "Maybe later")
    final preferenceService = NotificationPreferenceService();
    final shouldShow = await preferenceService.shouldShowPermissionDialog();
    if (!shouldShow) {
      return;
    }

    // Mark as shown in this session
    _permissionDialogShownInSession = true;

    // Show the custom permission dialog
    final shouldRequest = await NotificationPermissionDialog.show(context);
    
    if (shouldRequest != true) {
      // User clicked "Maybe later" or dismissed the dialog
      // Save the timestamp to enforce cooldown
      await preferenceService.saveLastPermissionRequestTime();
      return;
    }

    // User clicked "Allow notifications" - request system permission
    try {
      final result = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      
      // If permission was granted, clear the cooldown timestamp
      // so we don't show the dialog again
      if (result.authorizationStatus == AuthorizationStatus.authorized ||
          result.authorizationStatus == AuthorizationStatus.provisional) {
        await preferenceService.clearLastPermissionRequestTime();
      }
    } catch (e) {
    }
  }

  void _handleNotificationTap(
    RemoteMessage message, {
    required NotificationsCubit notificationsCubit,
  }) {
    final context = MyApp.navigatorKey.currentContext;
    if (context == null) {
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

