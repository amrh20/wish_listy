import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';

/// Service that checks for app updates via Firebase Remote Config
/// and shows Force Update or Flexible Update dialogs when needed.
class UpdateService {
  static const String _minVersionKey = 'min_app_version';
  static const String _latestVersionKey = 'latest_app_version';

  /// Android Play Store link. Replace with real link when published.
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.amr.wishlisty';

  /// iOS App Store link. Replace YOUR_APP_ID with real App Store ID when published.
  static const String _appStoreUrl =
      'https://apps.apple.com/app/idYOUR_APP_ID';

  /// Returns the appropriate store URL based on platform.
  static String get _storeUrl {
    if (kIsWeb) return _playStoreUrl; // Fallback for web
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return _appStoreUrl;
      case TargetPlatform.android:
        return _playStoreUrl;
      default:
        return _playStoreUrl;
    }
  }

  /// Checks for updates and shows the appropriate dialog if needed.
  Future<void> checkForUpdates(BuildContext context) async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          // For production: use const Duration(hours: 12)
          minimumFetchInterval: Duration.zero,
        ),
      );
      await remoteConfig.fetchAndActivate();

      final minVersion = remoteConfig.getString(_minVersionKey).trim();
      final latestVersion = remoteConfig.getString(_latestVersionKey).trim();

      if (minVersion.isEmpty && latestVersion.isEmpty) {
        return;
      }

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = _normalizeVersion(packageInfo.version);

      if (minVersion.isNotEmpty && _isVersionGreaterThan(minVersion, currentVersion)) {
        if (context.mounted) {
          _showForceUpdateDialog(context);
        }
        return;
      }

      if (latestVersion.isNotEmpty &&
          _isVersionGreaterThan(latestVersion, currentVersion)) {
        if (context.mounted) {
          _showFlexibleUpdateDialog(context);
        }
      }
    } catch (e) {
      debugPrint('UpdateService: Failed to check for updates: $e');
    }
  }

  /// Normalizes version string by stripping build suffix (e.g. "1.0.0+65" -> "1.0.0").
  String _normalizeVersion(String version) {
    final plusIndex = version.indexOf('+');
    if (plusIndex >= 0) {
      return version.substring(0, plusIndex);
    }
    return version;
  }

  /// Returns true if v1 is greater than v2 (semantic version comparison).
  bool _isVersionGreaterThan(String v1, String v2) {
    final parts1 = _normalizeVersion(v1).split('.').map(_parseVersionPart).toList();
    final parts2 = _normalizeVersion(v2).split('.').map(_parseVersionPart).toList();
    final len = parts1.length > parts2.length ? parts1.length : parts2.length;
    for (int i = 0; i < len; i++) {
      final a = i < parts1.length ? parts1[i] : 0;
      final b = i < parts2.length ? parts2[i] : 0;
      if (a > b) return true;
      if (a < b) return false;
    }
    return false;
  }

  int _parseVersionPart(String s) {
    final cleaned = s.trim();
    if (cleaned.isEmpty) return 0;
    return int.tryParse(cleaned) ?? 0;
  }

  void _showForceUpdateDialog(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text(
            localization.translate('app_update.forceTitle'),
            style: AppStyles.headingMediumWithContext(context),
          ),
          content: Text(
            localization.translate('app_update.forceMessage'),
            style: AppStyles.bodyLargeWithContext(context).copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            CustomButton(
              text: localization.translate('app_update.updateNow'),
              onPressed: () => _launchStore(context),
              variant: ButtonVariant.gradient,
              gradientColors: [AppColors.primary, AppColors.secondary],
              size: ButtonSize.large,
            ),
          ],
        ),
      ),
    );
  }

  void _showFlexibleUpdateDialog(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Text(
          localization.translate('app_update.flexibleTitle'),
          style: AppStyles.headingMediumWithContext(context),
        ),
        content: Text(
          localization.translate('app_update.flexibleMessage'),
          style: AppStyles.bodyLargeWithContext(context).copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              localization.translate('app_update.later'),
              style: AppStyles.bodyMediumWithContext(context).copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          CustomButton(
            text: localization.translate('app_update.update'),
            onPressed: () {
              Navigator.of(context).pop();
              _launchStore(context);
            },
            variant: ButtonVariant.primary,
            size: ButtonSize.medium,
          ),
        ],
      ),
    );
  }

  Future<void> _launchStore(BuildContext context) async {
    try {
      final uri = Uri.parse(_storeUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('UpdateService: Could not launch store URL: $_storeUrl');
      }
    } catch (e) {
      debugPrint('UpdateService: Failed to launch store: $e');
    }
  }
}
