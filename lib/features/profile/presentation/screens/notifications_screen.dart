import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';

class NotificationsScreen extends StatefulWidget {
  final Map<String, dynamic> notificationSettings;

  const NotificationsScreen({super.key, required this.notificationSettings});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _inAppNotifications = true;
  bool _friendRequests = true;
  bool _wishlistUpdates = true;
  bool _eventInvitations = true;
  bool _giftNotifications = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pushNotifications =
        widget.notificationSettings['pushNotifications'] ?? true;
    _emailNotifications =
        widget.notificationSettings['emailNotifications'] ?? true;
    _inAppNotifications =
        widget.notificationSettings['inAppNotifications'] ?? true;
    _friendRequests = widget.notificationSettings['friendRequests'] ?? true;
    _wishlistUpdates = widget.notificationSettings['wishlistUpdates'] ?? true;
    _eventInvitations = widget.notificationSettings['eventInvitations'] ?? true;
    _giftNotifications =
        widget.notificationSettings['giftNotifications'] ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localization, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(localization.translate('notifications.title')),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 18),
              onPressed: () => Navigator.pop(context),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(8),
                shape: const CircleBorder(),
              ),
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.background,
                  AppColors.primary.withValues(alpha: 0.02),
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // General Notification Settings
                    _buildGeneralSettingsSection(localization),
                    const SizedBox(height: 32),

                    // Specific Notification Types
                    _buildNotificationTypesSection(localization),
                    const SizedBox(height: 32),

                    // Quiet Hours
                    _buildQuietHoursSection(localization),
                    const SizedBox(height: 32),

                    // Save Button
                    _buildSaveButton(localization),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGeneralSettingsSection(LocalizationService localization) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localization.translate('profile.generalSettings'),
          style: AppStyles.headingSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSwitchOption(
                title: localization.translate('profile.pushNotifications'),
                subtitle: localization.translate('profile.pushNotificationsSubtitle'),
                value: _pushNotifications,
                onChanged: (value) {
                  setState(() {
                    _pushNotifications = value;
                  });
                },
              ),
              Divider(height: 1, color: AppColors.surfaceVariant),
              _buildSwitchOption(
                title: localization.translate('profile.emailNotifications'),
                subtitle: localization.translate('profile.emailNotificationsSubtitle'),
                value: _emailNotifications,
                onChanged: (value) {
                  setState(() {
                    _emailNotifications = value;
                  });
                },
              ),
              Divider(height: 1, color: AppColors.surfaceVariant),
              _buildSwitchOption(
                title: localization.translate('profile.inAppNotifications'),
                subtitle: localization.translate('profile.inAppNotificationsSubtitle'),
                value: _inAppNotifications,
                onChanged: (value) {
                  setState(() {
                    _inAppNotifications = value;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationTypesSection(LocalizationService localization) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localization.translate('profile.notificationTypes'),
          style: AppStyles.headingSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSwitchOption(
                title: localization.translate('profile.friendRequests'),
                subtitle: localization.translate('profile.friendRequestsSubtitle'),
                value: _friendRequests,
                onChanged: (value) {
                  setState(() {
                    _friendRequests = value;
                  });
                },
              ),
              Divider(height: 1, color: AppColors.surfaceVariant),
              _buildSwitchOption(
                title: localization.translate('profile.wishlistUpdates'),
                subtitle: localization.translate('profile.wishlistUpdatesSubtitle'),
                value: _wishlistUpdates,
                onChanged: (value) {
                  setState(() {
                    _wishlistUpdates = value;
                  });
                },
              ),
              Divider(height: 1, color: AppColors.surfaceVariant),
              _buildSwitchOption(
                title: localization.translate('profile.eventInvitations'),
                subtitle: localization.translate('profile.eventInvitationsSubtitle'),
                value: _eventInvitations,
                onChanged: (value) {
                  setState(() {
                    _eventInvitations = value;
                  });
                },
              ),
              Divider(height: 1, color: AppColors.surfaceVariant),
              _buildSwitchOption(
                title: localization.translate('profile.giftNotifications'),
                subtitle: localization.translate('profile.giftNotificationsSubtitle'),
                value: _giftNotifications,
                onChanged: (value) {
                  setState(() {
                    _giftNotifications = value;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuietHoursSection(LocalizationService localization) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localization.translate('profile.quietHours'),
          style: AppStyles.headingSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            children: [
              _buildActionOption(
                title: localization.translate('profile.setQuietHours'),
                subtitle: localization.translate('profile.setQuietHoursSubtitle'),
                icon: Icons.schedule_outlined,
                onTap: _setQuietHours,
              ),
              Divider(height: 1, color: AppColors.surfaceVariant),
              _buildActionOption(
                title: localization.translate('profile.doNotDisturb'),
                subtitle: localization.translate('profile.doNotDisturbSubtitle'),
                icon: Icons.notifications_off_outlined,
                onTap: _toggleDoNotDisturb,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchOption({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: AppStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }

  Widget _buildActionOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: AppStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: AppColors.textTertiary,
        size: 16,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }

  Widget _buildSaveButton(LocalizationService localization) {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: localization.translate('profile.saveNotificationSettings'),
        onPressed: _isLoading ? null : _saveNotificationSettings,
        variant: ButtonVariant.primary,
        isLoading: _isLoading,
      ),
    );
  }

  void _setQuietHours() {
    final t = Provider.of<LocalizationService>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.translate('profile.setQuietHoursDialogTitle')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t.translate('profile.setQuietHoursDialogContent'),
              style: AppStyles.bodyMedium,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.translate('profile.startTime'), style: AppStyles.bodySmall),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.surfaceVariant),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('10:00 PM', style: AppStyles.bodyMedium),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.translate('profile.endTime'), style: AppStyles.bodySmall),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.surfaceVariant),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('8:00 AM', style: AppStyles.bodyMedium),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.translate('app.cancel')),
          ),
          CustomButton(
            text: t.translate('app.save'),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(t.translate('profile.quietHoursSetSuccess')),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            variant: ButtonVariant.primary,
            size: ButtonSize.small,
            fullWidth: false,
          ),
        ],
      ),
    );
  }

  void _toggleDoNotDisturb() {
    final t = Provider.of<LocalizationService>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.translate('profile.doNotDisturbDialogTitle')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t.translate('profile.doNotDisturbDialogContent'),
              style: AppStyles.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.translate('app.cancel')),
          ),
          CustomButton(
            text: t.translate('profile.pauseNotifications'),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                    t.translate('profile.notificationsPausedResume'),
                  ),
                  backgroundColor: AppColors.warning,
                ),
              );
            },
            variant: ButtonVariant.outline,
            size: ButtonSize.small,
            fullWidth: false,
          ),
        ],
      ),
    );
  }

  Future<void> _saveNotificationSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement API call to save notification settings
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Provider.of<LocalizationService>(context, listen: false).translate('profile.notificationSettingsUpdatedSuccess')),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, {
          'pushNotifications': _pushNotifications,
          'emailNotifications': _emailNotifications,
          'inAppNotifications': _inAppNotifications,
          'friendRequests': _friendRequests,
          'wishlistUpdates': _wishlistUpdates,
          'eventInvitations': _eventInvitations,
          'giftNotifications': _giftNotifications,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Provider.of<LocalizationService>(context, listen: false).translate('profile.failedToUpdateNotificationSettings'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
