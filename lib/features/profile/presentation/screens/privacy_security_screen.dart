import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';

class PrivacySecurityScreen extends StatefulWidget {
  final Map<String, dynamic> privacySettings;

  const PrivacySecurityScreen({super.key, required this.privacySettings});

  @override
  _PrivacySecurityScreenState createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _showProfileToPublic = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _showProfileToPublic =
        widget.privacySettings['showProfileToPublic'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localization, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(localization.translate('profile.privacySecurity')),
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
                    // Profile Visibility Section
                    _buildProfileVisibilitySection(localization),
                    const SizedBox(height: 32),

                    // Security Section
                    _buildSecuritySection(localization),
                    const SizedBox(height: 32),

                    // Device Permissions Section
                    _buildDevicePermissionsSection(localization),
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

  Widget _buildProfileVisibilitySection(LocalizationService localization) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localization.translate('profile.profileVisibility'),
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
              _buildVisibilityOption(
                title: localization.translate('profile.publicProfile'),
                subtitle: localization.translate('profile.publicProfileDescription'),
                value: _showProfileToPublic,
                onChanged: (value) {
                  setState(() {
                    _showProfileToPublic = value;
                  });
                },
              ),
              Divider(height: 1, color: AppColors.surfaceVariant),
              _buildVisibilityOption(
                title: localization.translate('profile.friendsOnlyProfile'),
                subtitle: localization.translate('profile.friendsOnlyProfileDescription'),
                value: !_showProfileToPublic,
                onChanged: (value) {
                  setState(() {
                    _showProfileToPublic = !value;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecuritySection(LocalizationService localization) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localization.translate('profile.security'),
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
                title: localization.translate('profile.changePassword'),
                subtitle: localization.translate('profile.changePasswordDescription'),
                icon: Icons.lock_outline,
                onTap: _changePassword,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDevicePermissionsSection(LocalizationService localization) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '6. Device Permissions',
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To provide a full experience, Wish Listy may request access to certain features on your device:',
                style: AppStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              _buildBulletItem(
                'Camera:',
                'We use your camera solely to allow you to take and upload a profile picture or capture images of gift items you wish to add to your list.',
              ),
              const SizedBox(height: 8),
              _buildBulletItem(
                'Storage/Gallery:',
                'We access your photos to let you choose and upload existing images for your profile or gift items.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBulletItem(String label, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '• ',
          style: AppStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              children: [
                TextSpan(
                  text: '$label ',
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: text),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisibilityOption({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return RadioListTile<bool>(
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
      groupValue: true,
      onChanged: (newValue) {
        if (newValue != null) {
          onChanged(newValue);
        }
      },
      activeColor: AppColors.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
        text: localization.translate('profile.savePrivacySettings'),
        onPressed: _isLoading ? null : _savePrivacySettings,
        variant: ButtonVariant.primary,
        isLoading: _isLoading,
      ),
    );
  }

  void _changePassword() {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localization.translate('profile.changePasswordDialogTitle')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              localization.translate('profile.changePasswordDialogMessage'),
              style: AppStyles.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localization.translate('common.cancel')),
          ),
          CustomButton(
            text: localization.translate('profile.sendResetLink'),
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement password reset
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(localization.translate('profile.passwordResetLinkSent')),
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

  Future<void> _savePrivacySettings() async {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement API call to save privacy settings
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localization.translate('profile.privacySettingsUpdated')),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, {
          'showProfileToPublic': _showProfileToPublic,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localization.translate('profile.failedToUpdatePrivacySettings'),
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
