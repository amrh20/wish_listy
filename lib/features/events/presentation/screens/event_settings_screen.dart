import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'package:wish_listy/core/widgets/animated_background.dart';
import 'package:wish_listy/features/events/data/models/event_model.dart';

class EventSettingsScreen extends StatefulWidget {
  final EventSummary event;

  const EventSettingsScreen({super.key, required this.event});

  @override
  _EventSettingsScreenState createState() => _EventSettingsScreenState();
}

class _EventSettingsScreenState extends State<EventSettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Settings state
  bool _isPublic = true;
  bool _allowGuestsToInvite = false;
  bool _showGuestList = true;
  bool _allowComments = true;
  bool _notifyOnRSVP = true;
  bool _notifyOnWishlistUpdate = true;
  bool _notifyOnEventUpdate = true;
  bool _reminderEnabled = true;
  int _reminderDays = 1;
  String _timezone = 'UTC';
  String _language = 'English';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
          ),
        );
  }

  void _startAnimations() {
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Background
          AnimatedBackground(
            colors: [
              AppColors.background,
              AppColors.secondary.withOpacity(0.03),
              AppColors.primary.withOpacity(0.02),
            ],
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(),

                // Content
                Expanded(
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Privacy Settings
                                _buildPrivacySettings(),

                                const SizedBox(height: 24),

                                // Notification Settings
                                _buildNotificationSettings(),

                                const SizedBox(height: 24),

                                // Reminder Settings
                                _buildReminderSettings(),

                                const SizedBox(height: 24),

                                // Regional Settings
                                _buildRegionalSettings(),

                                const SizedBox(height: 32),

                                // Action Buttons
                                _buildActionButtons(),

                                const SizedBox(height: 100), // Bottom padding
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: AppColors.textTertiary.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(8),
              shape: const CircleBorder(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Provider.of<LocalizationService>(context, listen: false).translate('events.eventSettings'),
                  style: AppStyles.headingSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.event.name,
                  style: AppStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Help Button
          IconButton(
            onPressed: _showHelpDialog,
            icon: const Icon(Icons.help_outline),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceVariant,
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySettings() {
    final t = Provider.of<LocalizationService>(context, listen: false);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.privacy_tip_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                t.translate('events.privacySettings'),
                style: AppStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Public/Private Toggle
          _buildSettingRow(
            icon: Icons.public,
            title: t.translate('events.publicEvent'),
            subtitle: t.translate('events.publicEventSubtitle'),
            trailing: Switch(
              value: _isPublic,
              onChanged: (value) {
                setState(() {
                  _isPublic = value;
                });
              },
              activeColor: AppColors.secondary,
            ),
          ),

          const SizedBox(height: 16),

          // Allow Guests to Invite
          _buildSettingRow(
            icon: Icons.person_add_outlined,
            title: t.translate('events.allowGuestsToInvite'),
            subtitle: t.translate('events.allowGuestsToInviteSubtitle'),
            trailing: Switch(
              value: _allowGuestsToInvite,
              onChanged: (value) {
                setState(() {
                  _allowGuestsToInvite = value;
                });
              },
              activeColor: AppColors.secondary,
            ),
          ),

          const SizedBox(height: 16),

          // Show Guest List
          _buildSettingRow(
            icon: Icons.people_outline,
            title: t.translate('events.showGuestList'),
            subtitle: t.translate('events.showGuestListSubtitle'),
            trailing: Switch(
              value: _showGuestList,
              onChanged: (value) {
                setState(() {
                  _showGuestList = value;
                });
              },
              activeColor: AppColors.secondary,
            ),
          ),

          const SizedBox(height: 16),

          // Allow Comments
          _buildSettingRow(
            icon: Icons.chat_bubble_outline,
            title: t.translate('events.allowComments'),
            subtitle: t.translate('events.allowCommentsSubtitle'),
            trailing: Switch(
              value: _allowComments,
              onChanged: (value) {
                setState(() {
                  _allowComments = value;
                });
              },
              activeColor: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    final t = Provider.of<LocalizationService>(context, listen: false);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_outlined,
                color: AppColors.info,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                t.translate('events.notificationSettingsSection'),
                style: AppStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Notify on RSVP
          _buildSettingRow(
            icon: Icons.check_circle_outline,
            title: t.translate('events.rsvpNotifications'),
            subtitle: t.translate('events.rsvpNotificationsSubtitle'),
            trailing: Switch(
              value: _notifyOnRSVP,
              onChanged: (value) {
                setState(() {
                  _notifyOnRSVP = value;
                });
              },
              activeColor: AppColors.secondary,
            ),
          ),

          const SizedBox(height: 16),

          // Notify on Wishlist Update
          _buildSettingRow(
            icon: Icons.card_giftcard_outlined,
            title: t.translate('events.wishlistUpdatesEvent'),
            subtitle: t.translate('events.wishlistUpdatesEventSubtitle'),
            trailing: Switch(
              value: _notifyOnWishlistUpdate,
              onChanged: (value) {
                setState(() {
                  _notifyOnWishlistUpdate = value;
                });
              },
              activeColor: AppColors.secondary,
            ),
          ),

          const SizedBox(height: 16),

          // Notify on Event Update
          _buildSettingRow(
            icon: Icons.event_outlined,
            title: t.translate('events.eventUpdates'),
            subtitle: t.translate('events.eventUpdatesSubtitle'),
            trailing: Switch(
              value: _notifyOnEventUpdate,
              onChanged: (value) {
                setState(() {
                  _notifyOnEventUpdate = value;
                });
              },
              activeColor: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderSettings() {
    final t = Provider.of<LocalizationService>(context, listen: false);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule_outlined, color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Text(
                t.translate('events.reminderSettings'),
                style: AppStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Enable Reminders
          _buildSettingRow(
            icon: Icons.alarm_outlined,
            title: t.translate('events.enableReminders'),
            subtitle: t.translate('events.enableRemindersSubtitle'),
            trailing: Switch(
              value: _reminderEnabled,
              onChanged: (value) {
                setState(() {
                  _reminderEnabled = value;
                });
              },
              activeColor: AppColors.secondary,
            ),
          ),

          if (_reminderEnabled) ...[
            const SizedBox(height: 16),

            // Reminder Days
            _buildSettingRow(
              icon: Icons.calendar_today_outlined,
              title: t.translate('events.reminderTiming'),
              subtitle: t.translate('events.reminderTimingSubtitle').replaceAll('{days}', '$_reminderDays'),
              trailing: DropdownButton<int>(
                value: _reminderDays,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _reminderDays = value;
                    });
                  }
                },
                items: [1, 2, 3, 7, 14].map((days) {
                  return DropdownMenuItem<int>(
                    value: days,
                    child: Text('$days'),
                  );
                }).toList(),
                underline: Container(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRegionalSettings() {
    final t = Provider.of<LocalizationService>(context, listen: false);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.language_outlined, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                t.translate('events.regionalSettings'),
                style: AppStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Timezone
          _buildSettingRow(
            icon: Icons.access_time_outlined,
            title: t.translate('events.timezone'),
            subtitle: t.translate('events.timezoneSubtitle').replaceAll('{timezone}', _timezone),
            trailing: DropdownButton<String>(
              value: _timezone,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _timezone = value;
                  });
                }
              },
              items: ['UTC', 'EST', 'PST', 'GMT', 'CET'].map((tz) {
                return DropdownMenuItem<String>(value: tz, child: Text(tz));
              }).toList(),
              underline: Container(),
            ),
          ),

          const SizedBox(height: 16),

          // Language
          _buildSettingRow(
            icon: Icons.translate_outlined,
            title: t.translate('events.language'),
            subtitle: t.translate('events.languageSubtitle').replaceAll('{language}', _language),
            trailing: DropdownButton<String>(
              value: _language,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _language = value;
                  });
                }
              },
              items: ['English', 'Spanish', 'French', 'Arabic', 'Chinese'].map((
                lang,
              ) {
                return DropdownMenuItem<String>(value: lang, child: Text(lang));
              }).toList(),
              underline: Container(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.textTertiary, size: 20),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        trailing,
      ],
    );
  }

  Widget _buildActionButtons() {
    final t = Provider.of<LocalizationService>(context, listen: false);
    return Column(
      children: [
        // Save Settings Button
        CustomButton(
          text: t.translate('events.saveSettings'),
          onPressed: _saveSettings,
          variant: ButtonVariant.primary,
          customColor: AppColors.secondary,
          icon: Icons.save_outlined,
        ),

        const SizedBox(height: 12),

        // Reset to Default Button
        CustomButton(
          text: t.translate('events.resetToDefault'),
          onPressed: _resetToDefault,
          variant: ButtonVariant.outline,
          customColor: AppColors.textTertiary,
          icon: Icons.restore_outlined,
        ),

        const SizedBox(height: 12),

        // Export Settings Button
        CustomButton(
          text: t.translate('events.exportSettings'),
          onPressed: _exportSettings,
          variant: ButtonVariant.outline,
          customColor: AppColors.info,
          icon: Icons.download_outlined,
        ),
      ],
    );
  }

  // Action Handlers
  void _saveSettings() {
    final t = Provider.of<LocalizationService>(context, listen: false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t.translate('events.settingsSavedSuccessfully')),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _resetToDefault() {
    final t = Provider.of<LocalizationService>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.translate('events.resetSettings')),
        content: Text(
          t.translate('events.resetSettingsConfirmMessage'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.translate('app.cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetSettings();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(t.translate('events.settingsResetToDefault')),
                  backgroundColor: AppColors.info,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.warning),
            child: Text(t.translate('events.reset')),
          ),
        ],
      ),
    );
  }

  void _resetSettings() {
    setState(() {
      _isPublic = true;
      _allowGuestsToInvite = false;
      _showGuestList = true;
      _allowComments = true;
      _notifyOnRSVP = true;
      _notifyOnWishlistUpdate = true;
      _notifyOnEventUpdate = true;
      _reminderEnabled = true;
      _reminderDays = 1;
      _timezone = 'UTC';
      _language = 'English';
    });
  }

  void _exportSettings() {
    final t = Provider.of<LocalizationService>(context, listen: false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t.translate('events.settingsExportedSuccessfully')),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _showHelpDialog() {
    final t = Provider.of<LocalizationService>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.translate('events.eventSettingsHelp')),
        content: Text(t.translate('events.eventSettingsHelpContent')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.translate('events.gotIt')),
          ),
        ],
      ),
    );
  }
}
