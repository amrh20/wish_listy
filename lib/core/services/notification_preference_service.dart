import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing notification permission preferences.
///
/// Handles:
/// - Tracking when the permission dialog was last shown
/// - Determining if enough time has passed to show it again (7-day cooldown)
class NotificationPreferenceService {
  NotificationPreferenceService._internal();
  static final NotificationPreferenceService _instance =
      NotificationPreferenceService._internal();
  factory NotificationPreferenceService() => _instance;

  static const String _lastPermissionRequestTimeKey = 'last_permission_request_time';
  static const String _pushNotificationsEnabledKey = 'push_notifications_enabled';
  static const Duration _cooldownPeriod = Duration(days: 7);

  /// Save the timestamp when user clicks "Maybe later".
  ///
  /// This is called when the user dismisses the permission dialog
  /// without granting permissions.
  Future<void> saveLastPermissionRequestTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(_lastPermissionRequestTimeKey, now);
    } catch (e) {
    }
  }

  /// Check if enough time has passed since the last permission request.
  ///
  /// Returns `true` if:
  /// - No previous timestamp exists (first time)
  /// - OR at least 7 days have passed since the last request
  ///
  /// Returns `false` if less than 7 days have passed.
  Future<bool> shouldShowPermissionDialog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastRequestTimestamp = prefs.getInt(_lastPermissionRequestTimeKey);

      // First time - no timestamp exists
      if (lastRequestTimestamp == null) {
        return true;
      }

      // Calculate time difference
      final lastRequestTime = DateTime.fromMillisecondsSinceEpoch(lastRequestTimestamp);
      final now = DateTime.now();
      final timeDifference = now.difference(lastRequestTime);

      if (timeDifference >= _cooldownPeriod) {
        return true;
      } else {
        final daysRemaining = (_cooldownPeriod - timeDifference).inDays;
        return false;
      }
    } catch (e) {
      // On error, allow showing the dialog (fail open)
      return true;
    }
  }

  /// Clear the stored timestamp (useful for testing or reset).
  Future<void> clearLastPermissionRequestTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastPermissionRequestTimeKey);
    } catch (e) {
    }
  }

  /// Check if user has explicitly disabled push notifications in Profile.
  /// Returns true if user toggled OFF; false if enabled or no choice yet.
  Future<bool> hasUserDisabledPushNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(_pushNotificationsEnabledKey);
      return value == 'false';
    } catch (e) {
      return false;
    }
  }

  /// Get user's push notification preference. null = no explicit choice yet.
  Future<bool?> getPushNotificationsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(_pushNotificationsEnabledKey);
      if (value == null) return null;
      return value == 'true';
    } catch (e) {
      return null;
    }
  }

  /// Save user's push notification preference (from Profile toggle).
  Future<void> setPushNotificationsEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pushNotificationsEnabledKey, enabled ? 'true' : 'false');
    } catch (e) {
    }
  }
}
