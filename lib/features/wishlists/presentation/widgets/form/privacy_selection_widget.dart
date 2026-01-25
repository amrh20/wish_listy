import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';

/// Widget for selecting privacy option when creating/editing wishlist
class PrivacySelectionWidget extends StatelessWidget {
  final List<String> privacyOptions;
  final String selectedPrivacy;
  final Function(String) onPrivacySelected;
  final IconData Function(String) getPrivacyIcon;
  final String Function(String) getPrivacyTitle;
  final String Function(String) getPrivacyDescription;
  final String Function() getTitle;

  const PrivacySelectionWidget({
    super.key,
    required this.privacyOptions,
    required this.selectedPrivacy,
    required this.onPrivacySelected,
    required this.getPrivacyIcon,
    required this.getPrivacyTitle,
    required this.getPrivacyDescription,
    required this.getTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                getTitle(),
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: privacyOptions.map((privacy) {
              final isSelected = selectedPrivacy == privacy;
              return GestureDetector(
                onTap: () => onPrivacySelected(privacy),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textTertiary.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        getPrivacyIcon(privacy),
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textTertiary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              getPrivacyTitle(privacy),
                              style: AppStyles.bodyMedium.copyWith(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            Text(
                              getPrivacyDescription(privacy),
                              style: AppStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: AppColors.primary,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
