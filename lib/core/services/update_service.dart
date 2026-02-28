import 'package:flutter/foundation.dart' show defaultTargetPlatform, kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:pub_semver/pub_semver.dart';
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
  static const String _defaultVersion = '0.0.0';

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

  /// Sets default Remote Config values so getString never returns empty
  /// when keys are missing or fetch fails.
  void _setDefaults(FirebaseRemoteConfig remoteConfig) {
    remoteConfig.setDefaults(<String, dynamic>{
      _minVersionKey: _defaultVersion,
      _latestVersionKey: _defaultVersion,
    });
  }

  /// Checks for updates and shows the appropriate dialog if needed.
  Future<void> checkForUpdates(BuildContext context) async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;

      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: kDebugMode ? Duration.zero : const Duration(hours: 12),
        ),
      );

      _setDefaults(remoteConfig);

      final activated = await remoteConfig.fetchAndActivate();
      debugPrint('📡 [UpdateService] fetchAndActivate: activated=$activated');

      final minVersion = remoteConfig.getString(_minVersionKey).trim();
      final latestVersion = remoteConfig.getString(_latestVersionKey).trim();

      if (minVersion.isEmpty || latestVersion.isEmpty) {
        debugPrint(
          '⚠️ [UpdateService] Remote config returned empty values '
          '(min=$minVersion, latest=$latestVersion). Using defaults.',
        );
      }

      final effectiveMin = minVersion.isEmpty ? _defaultVersion : minVersion;
      final effectiveLatest = latestVersion.isEmpty ? _defaultVersion : latestVersion;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = _normalizeVersion(packageInfo.version);

      debugPrint('🚀 [UpdateService] Local App Version: $currentVersion');
      debugPrint('☁️ [UpdateService] Firebase Min Version: $effectiveMin');
      debugPrint('☁️ [UpdateService] Firebase Latest Version: $effectiveLatest');

      if (effectiveMin == _defaultVersion && effectiveLatest == _defaultVersion) {
        debugPrint(
          'ℹ️ [UpdateService] Both remote values are default (0.0.0). '
          'Skipping update check (keys may be unset or fetch failed).',
        );
        return;
      }

      if (_isVersionGreaterThan(effectiveMin, currentVersion)) {
        if (!context.mounted) return;
        _showForceUpdateDialog(context);
        return;
      }

      if (_isVersionGreaterThan(effectiveLatest, currentVersion)) {
        if (!context.mounted) return;
        _showFlexibleUpdateDialog(context);
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

  /// Returns true if remote version is greater than current version (semantic version comparison).
  bool _isVersionGreaterThan(String remoteVersion, String currentVersion) {
    try {
      final remote = Version.parse(_normalizeVersion(remoteVersion));
      final current = Version.parse(_normalizeVersion(currentVersion));
      return remote > current;
    } catch (e) {
      debugPrint('UpdateService: Version parse error: $e (remote=$remoteVersion, current=$currentVersion)');
      return false;
    }
  }

  void _showForceUpdateDialog(BuildContext context) {
    if (!context.mounted) return;
    final localization = Provider.of<LocalizationService>(context, listen: false);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text(
            localization.translate('app_update.forceTitle'),
            style: AppStyles.headingMediumWithContext(ctx),
          ),
          content: Text(
            localization.translate('app_update.forceMessage'),
            style: AppStyles.bodyLargeWithContext(ctx).copyWith(
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
    if (!context.mounted) return;
    final localization = Provider.of<LocalizationService>(context, listen: false);
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: Text(
          localization.translate('app_update.flexibleTitle'),
          style: AppStyles.headingMediumWithContext(ctx),
        ),
        content: Text(
          localization.translate('app_update.flexibleMessage'),
          style: AppStyles.bodyLargeWithContext(ctx).copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              localization.translate('app_update.later'),
              style: AppStyles.bodyMediumWithContext(ctx).copyWith(
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
