import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_styles.dart';
import '../../../services/localization_service.dart';

/// Widget for event privacy selection
class EventPrivacyWidget extends StatelessWidget {
  final String selectedPrivacy;
  final ValueChanged<String> onPrivacyChanged;

  const EventPrivacyWidget({
    super.key,
    required this.selectedPrivacy,
    required this.onPrivacyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security_outlined, color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Text(
                localization.translate('events.eventPrivacy'),
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            localization.translate('events.whoCanSeeThisEvent'),
            style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPrivacyOption(
                'public',
                localization.translate('events.public'),
                localization.translate('events.publicDescription'),
                Icons.public,
                AppColors.success,
                localization,
              ),
              _buildPrivacyOption(
                'friends_only',
                localization.translate('events.friendsOnly'),
                localization.translate('events.friendsOnlyDescription'),
                Icons.people_outline,
                AppColors.info,
                localization,
              ),
              _buildPrivacyOption(
                'private',
                localization.translate('events.private'),
                localization.translate('events.privateDescription'),
                Icons.lock_outline,
                AppColors.warning,
                localization,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyOption(
    String value,
    String title,
    String description,
    IconData icon,
    Color color,
    LocalizationService localization,
  ) {
    final isSelected = selectedPrivacy == value;
    return GestureDetector(
      onTap: () => onPrivacyChanged(value),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.textTertiary.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? color : AppColors.textTertiary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppStyles.bodyMedium.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected ? color : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    description,
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
