import 'package:flutter/foundation.dart';
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
      if (token != null) {
        // Print FCM token in a very visible format for Firebase Console testing
        debugPrint('');
        debugPrint('═══════════════════════════════════════════════════════════════════');
        debugPrint('🔔 [FCM] CURRENT FCM TOKEN (Copy this for Firebase Console):');
        debugPrint('');
        debugPrint('   $token');
        debugPrint('');
        debugPrint('═══════════════════════════════════════════════════════════════════');
        debugPrint('📋 To test notifications in Firebase Console:');
        debugPrint('   1. Copy the token above');
        debugPrint('   2. Go to Firebase Console → Cloud Messaging → Send test message');
        debugPrint('   3. Paste the token in "Add an FCM registration token"');
        debugPrint('   4. Click "Test"');
        debugPrint('═══════════════════════════════════════════════════════════════════');
        debugPrint('');
        
        if (authRepository.isAuthenticated) {
          await authRepository.updateFcmToken(token);
          debugPrint('✅ [FCM] Token sent to backend');
        } else {
          debugPrint('⚠️ [FCM] User not authenticated, token will be sent after login');
        }
      } else {
        debugPrint('⚠️ [FCM] FCM token is null - may need to request notification permissions');
      }
    } catch (e) {
      debugPrint('⚠️ FcmService: Failed to fetch initial FCM token: $e');
    }

    // Keep backend updated when the FCM token changes.
    // This happens when app is reinstalled, data is cleared, or token expires
    _messaging.onTokenRefresh.listen((token) async {
      debugPrint('');
      debugPrint('═══════════════════════════════════════════════════════════════════');
      debugPrint('🔄 [FCM] TOKEN REFRESHED (New token generated):');
      debugPrint('');
      debugPrint('   $token');
      debugPrint('');
      debugPrint('═══════════════════════════════════════════════════════════════════');
      debugPrint('📋 IMPORTANT: Update Firebase Console with new token:');
      debugPrint('   1. Copy the NEW token above');
      debugPrint('   2. Go to Firebase Console → Cloud Messaging → Send test message');
      debugPrint('   3. Remove old token and add this new one');
      debugPrint('   4. Old token is no longer valid after reinstall/clear data');
      debugPrint('═══════════════════════════════════════════════════════════════════');
      debugPrint('');
      
      if (!authRepository.isAuthenticated) {
        debugPrint(
          '⚠️ [FCM] User not authenticated, token will be sent after login',
        );
        return;
      }

      try {
        await authRepository.updateFcmToken(token);
        debugPrint('✅ [FCM] New token sent to backend');
      } catch (e) {
        debugPrint('⚠️ [FCM] Failed to update FCM token on refresh: $e');
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
  /// 
  /// This method can be used to manually retrieve the token for testing purposes.
  /// The token is automatically printed in logs when FCM initializes or refreshes.
  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        debugPrint('');
        debugPrint('═══════════════════════════════════════════════════════════════════');
        debugPrint('🔔 [FCM] CURRENT FCM TOKEN (via getToken()):');
        debugPrint('');
        debugPrint('   $token');
        debugPrint('');
        debugPrint('═══════════════════════════════════════════════════════════════════');
        debugPrint('');
      }
      return token;
    } catch (e) {
      debugPrint('⚠️ [FCM] Failed to get token: $e');
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
      debugPrint('🔔 FcmService: Dialog already shown in this session');
      return;
    }

    // Check if permission is already granted
    final settings = await _messaging.getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus ==
            AuthorizationStatus.provisional) {
      // Already authorized; nothing to do.
      debugPrint('🔔 FcmService: Permission already granted');
      return;
    }

    // Check cooldown period (7 days since last "Maybe later")
    final preferenceService = NotificationPreferenceService();
    final shouldShow = await preferenceService.shouldShowPermissionDialog();
    if (!shouldShow) {
      debugPrint('🔔 FcmService: Cooldown period active - skipping dialog');
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
      debugPrint('🔔 FcmService: User chose "Maybe later" - cooldown started');
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
      debugPrint(
        '🔔 FcmService: Permission result: ${result.authorizationStatus}',
      );
      
      // If permission was granted, clear the cooldown timestamp
      // so we don't show the dialog again
      if (result.authorizationStatus == AuthorizationStatus.authorized ||
          result.authorizationStatus == AuthorizationStatus.provisional) {
        await preferenceService.clearLastPermissionRequestTime();
      }
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

