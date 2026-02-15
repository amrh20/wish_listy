import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/utils/interest_translation_extension.dart';

class ProfileInterestsSectionWidget extends StatelessWidget {
  final List<String> interests;
  final String emptyStateTitle;
  final String emptyStateSubtitle;
  final String interestsTitle;
  final String editButtonText;
  final VoidCallback onEditInterests;

  const ProfileInterestsSectionWidget({
    super.key,
    required this.interests,
    required this.emptyStateTitle,
    required this.emptyStateSubtitle,
    required this.interestsTitle,
    required this.editButtonText,
    required this.onEditInterests,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = interests.isEmpty;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isEmpty 
            ? Colors.purple.withOpacity(0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isEmpty
            ? Border.all(
                color: Colors.purple.withOpacity(0.2),
                width: 1.5,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.textTertiary.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: isEmpty ? _buildEmptyState() : _buildPopulatedState(context),
    );
  }

  Widget _buildEmptyState() {
    return InkWell(
      onTap: onEditInterests,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Icon(
              Icons.lightbulb_outline,
              color: Colors.amber,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$emptyStateTitle 🎁',
                    style: AppStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    emptyStateSubtitle,
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopulatedState(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              interestsTitle,
              style: AppStyles.headingSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: onEditInterests,
              icon: const Icon(
                Icons.edit_outlined,
                size: 16,
                color: AppColors.primary,
              ),
              label: Text(
                editButtonText,
                style: AppStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 32),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Interest Chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: interests.map((interest) {
            return Chip(
              label: Text(
                interest.translateInterest(context),
                style: AppStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor: Colors.purple.withOpacity(0.1),
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      ],
    );
  }
}

