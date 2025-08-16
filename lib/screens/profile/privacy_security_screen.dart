import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../services/localization_service.dart';
import '../../widgets/custom_button.dart';

class PrivacySecurityScreen extends StatefulWidget {
  final Map<String, dynamic> privacySettings;

  const PrivacySecurityScreen({super.key, required this.privacySettings});

  @override
  _PrivacySecurityScreenState createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _showOnlineStatus = true;
  bool _allowFriendRequests = true;
  bool _showWishlistActivity = true;
  bool _showProfileToPublic = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _showOnlineStatus = widget.privacySettings['showOnlineStatus'] ?? true;
    _allowFriendRequests =
        widget.privacySettings['allowFriendRequests'] ?? true;
    _showWishlistActivity =
        widget.privacySettings['showWishlistActivity'] ?? true;
    _showProfileToPublic =
        widget.privacySettings['showProfileToPublic'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localization, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Privacy & Security'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
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

                    // Privacy Options Section
                    _buildPrivacyOptionsSection(localization),
                    const SizedBox(height: 32),

                    // Security Section
                    _buildSecuritySection(localization),
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
          'Profile Visibility',
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
                title: 'Public Profile',
                subtitle: 'Anyone can see your profile and wishlists',
                value: _showProfileToPublic,
                onChanged: (value) {
                  setState(() {
                    _showProfileToPublic = value;
                  });
                },
              ),
              Divider(height: 1, color: AppColors.surfaceVariant),
              _buildVisibilityOption(
                title: 'Friends Only',
                subtitle: 'Only your friends can see your profile',
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

  Widget _buildPrivacyOptionsSection(LocalizationService localization) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Privacy Options',
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
                title: 'Show Online Status',
                subtitle: 'Let friends know when you\'re online',
                value: _showOnlineStatus,
                onChanged: (value) {
                  setState(() {
                    _showOnlineStatus = value;
                  });
                },
              ),
              Divider(height: 1, color: AppColors.surfaceVariant),
              _buildSwitchOption(
                title: 'Allow Friend Requests',
                subtitle: 'Let others send you friend requests',
                value: _allowFriendRequests,
                onChanged: (value) {
                  setState(() {
                    _allowFriendRequests = value;
                  });
                },
              ),
              Divider(height: 1, color: AppColors.surfaceVariant),
              _buildSwitchOption(
                title: 'Show Wishlist Activity',
                subtitle: 'Share your wishlist updates with friends',
                value: _showWishlistActivity,
                onChanged: (value) {
                  setState(() {
                    _showWishlistActivity = value;
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
          'Security',
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
                title: 'Change Password',
                subtitle: 'Update your account password',
                icon: Icons.lock_outline,
                onTap: _changePassword,
              ),
              Divider(height: 1, color: AppColors.surfaceVariant),
              _buildActionOption(
                title: 'Two-Factor Authentication',
                subtitle: 'Add an extra layer of security',
                icon: Icons.security_outlined,
                onTap: _setupTwoFactor,
              ),
              Divider(height: 1, color: AppColors.surfaceVariant),
              _buildActionOption(
                title: 'Login Sessions',
                subtitle: 'Manage your active sessions',
                icon: Icons.devices_outlined,
                onTap: _manageSessions,
              ),
            ],
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
        text: 'Save Privacy Settings',
        onPressed: _isLoading ? null : _savePrivacySettings,
        variant: ButtonVariant.primary,
        isLoading: _isLoading,
      ),
    );
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'A password reset link will be sent to your email address.',
              style: AppStyles.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          CustomButton(
            text: 'Send Reset Link',
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement password reset
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Password reset link sent to your email!'),
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

  void _setupTwoFactor() {
    Navigator.pushNamed(context, '/two-factor-setup');
  }

  void _manageSessions() {
    Navigator.pushNamed(context, '/login-sessions');
  }

  Future<void> _savePrivacySettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement API call to save privacy settings
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Privacy settings updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, {
          'showOnlineStatus': _showOnlineStatus,
          'allowFriendRequests': _allowFriendRequests,
          'showWishlistActivity': _showWishlistActivity,
          'showProfileToPublic': _showProfileToPublic,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update privacy settings. Please try again.',
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
