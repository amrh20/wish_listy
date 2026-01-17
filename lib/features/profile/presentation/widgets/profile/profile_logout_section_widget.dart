import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';

class ProfileLogoutSectionWidget extends StatelessWidget {
  final String logoutText;
  final String logoutSubtitle;
  final String deleteAccountText;
  final String deleteAccountSubtitle;
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;

  const ProfileLogoutSectionWidget({
    super.key,
    required this.logoutText,
    required this.logoutSubtitle,
    required this.deleteAccountText,
    required this.deleteAccountSubtitle,
    required this.onLogout,
    required this.onDeleteAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.textTertiary.withOpacity(0.1),
            offset: const Offset(0, 4),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logout Item
          _buildActionItem(
            icon: Icons.logout_outlined,
            title: logoutText,
            subtitle: logoutSubtitle,
            color: AppColors.error,
            onTap: onLogout,
            showDivider: true,
          ),
          
          // Delete Account Item
          _buildActionItem(
            icon: Icons.delete_forever_outlined,
            title: deleteAccountText,
            subtitle: deleteAccountSubtitle,
            color: AppColors.error,
            onTap: onDeleteAccount,
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required bool showDivider,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 22),
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
                            fontSize: 15,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: AppStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.textTertiary,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 58),
            child: Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey.withOpacity(0.1),
            ),
          ),
      ],
    );
  }
}

