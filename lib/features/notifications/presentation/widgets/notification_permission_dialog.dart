import 'package:flutter/material.dart';
import 'package:wish_listy/core/theme/app_theme.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:provider/provider.dart';

/// A professional, themed dialog that explains why Wish Listy
/// needs notification permissions and asks the user for consent.
///
/// Returns `true` if the user chose to allow notifications,
/// `false` if they declined or dismissed the dialog.
class NotificationPermissionDialog extends StatelessWidget {
  const NotificationPermissionDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const NotificationPermissionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final localization = Provider.of<LocalizationService>(context, listen: false);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing24,
        vertical: AppTheme.spacing24,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.notifications_active_rounded,
              size: 40,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              localization.translate('notifications.permissionTitle') ??
                  'Stay updated with your wishes',
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              localization.translate('notifications.permissionDescription') ??
                  'Turn on notifications to get updates when friends reserve or purchase items, '
                      'when events change, and when your shared wishlists are active.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.spacing24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    child: Text(
                      localization.translate('notifications.permissionLater') ??
                          'Maybe later',
                      style: textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    child: Text(
                      localization.translate('notifications.permissionAllow') ??
                          'Allow notifications',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

