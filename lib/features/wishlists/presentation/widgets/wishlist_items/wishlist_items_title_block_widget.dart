import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';

/// Title + stats subtitle (e.g. "X wishes • Y gifted").
class WishlistItemsTitleBlockWidget extends StatelessWidget {
  final String title;
  final int totalItems;
  final int purchasedItems;
  final bool isGuest;
  final LocalizationService localization;

  const WishlistItemsTitleBlockWidget({
    super.key,
    required this.title,
    required this.totalItems,
    required this.purchasedItems,
    required this.isGuest,
    required this.localization,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppStyles.headingLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontSize: 28,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          isGuest
              ? '$totalItems ${localization.translate('cards.wishes')}'
              : '$totalItems ${localization.translate('cards.wishes')} • $purchasedItems ${localization.translate('ui.gifted')}',
          style: AppStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
