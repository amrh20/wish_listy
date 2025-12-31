import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';

/// Widget for wishlist creation option
class WishlistOptionWidget extends StatelessWidget {
  final String? wishlistOption; // 'create', 'link', 'none'
  final String? linkedWishlistName; // Name of linked wishlist if 'link' is selected
  final ValueChanged<String?> onWishlistChanged;
  final VoidCallback? onLinkWishlistPressed;

  const WishlistOptionWidget({
    super.key,
    required this.wishlistOption,
    this.linkedWishlistName,
    required this.onWishlistChanged,
    this.onLinkWishlistPressed,
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
              // Option 1: Link Existing Wishlist
              GestureDetector(
                onTap: () {
                  if (onLinkWishlistPressed != null) {
                    onLinkWishlistPressed!();
                  } else {
                    onWishlistChanged('link');
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: wishlistOption == 'link'
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: wishlistOption == 'link'
                          ? AppColors.primary
                          : AppColors.textTertiary.withOpacity(0.3),
                      width: wishlistOption == 'link' ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.link,
                        color: wishlistOption == 'link'
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
                              localization.translate(
                                'events.linkExistingWishlist',
                              ),
                              style: AppStyles.bodyMedium.copyWith(
                                fontWeight: wishlistOption == 'link'
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: wishlistOption == 'link'
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            if (linkedWishlistName != null &&
                                linkedWishlistName!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                linkedWishlistName!,
                                style: AppStyles.bodySmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ] else
                              Text(
                                localization.translate(
                                  'events.linkExistingWishlistDescription',
                                ),
                                style: AppStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (wishlistOption == 'link')
                        Icon(
                          Icons.check_circle,
                          color: AppColors.primary,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Option 3: No Wishlist
              GestureDetector(
                onTap: () => onWishlistChanged('none'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: wishlistOption == 'none'
                        ? AppColors.info.withOpacity(0.1)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: wishlistOption == 'none'
                          ? AppColors.info
                          : AppColors.textTertiary.withOpacity(0.3),
                      width: wishlistOption == 'none' ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cancel_outlined,
                        color: wishlistOption == 'none'
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
                                fontWeight: wishlistOption == 'none'
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: wishlistOption == 'none'
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
                      if (wishlistOption == 'none')
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
