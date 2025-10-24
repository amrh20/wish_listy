import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_styles.dart';
import '../../../services/localization_service.dart';

/// Widget for wishlist creation option
class WishlistOptionWidget extends StatelessWidget {
  final bool createWishlist;
  final ValueChanged<bool> onWishlistChanged;

  const WishlistOptionWidget({
    super.key,
    required this.createWishlist,
    required this.onWishlistChanged,
  });

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.card_giftcard_outlined,
                color: AppColors.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                localization.translate('events.createWishlist'),
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            localization.translate('events.wishlistQuestion'),
            style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              // Yes Option
              GestureDetector(
                onTap: () => onWishlistChanged(true),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: createWishlist
                        ? AppColors.secondary.withOpacity(0.1)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: createWishlist
                          ? AppColors.secondary
                          : AppColors.textTertiary.withOpacity(0.3),
                      width: createWishlist ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: createWishlist
                            ? AppColors.secondary
                            : AppColors.textTertiary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localization.translate(
                                'events.yesCreateWishlist',
                              ),
                              style: AppStyles.bodyMedium.copyWith(
                                fontWeight: createWishlist
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: createWishlist
                                    ? AppColors.secondary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              localization.translate(
                                'events.yesCreateWishlistDescription',
                              ),
                              style: AppStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (createWishlist)
                        Icon(
                          Icons.check_circle,
                          color: AppColors.secondary,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // No Option
              GestureDetector(
                onTap: () => onWishlistChanged(false),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: !createWishlist
                        ? AppColors.info.withOpacity(0.1)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: !createWishlist
                          ? AppColors.info
                          : AppColors.textTertiary.withOpacity(0.3),
                      width: !createWishlist ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cancel_outlined,
                        color: !createWishlist
                            ? AppColors.info
                            : AppColors.textTertiary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localization.translate('events.noCreateWishlist'),
                              style: AppStyles.bodyMedium.copyWith(
                                fontWeight: !createWishlist
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: !createWishlist
                                    ? AppColors.info
                                    : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              localization.translate(
                                'events.noCreateWishlistDescription',
                              ),
                              style: AppStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!createWishlist)
                        Icon(
                          Icons.check_circle,
                          color: AppColors.info,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
