import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'wishlist_card_widget.dart';

/// Personal wishlists tab widget with trendy stacked cards scroll effect
class PersonalWishlistsTabWidget extends StatelessWidget {
  final List<WishlistSummary> personalWishlists;
  final Function(WishlistSummary) onWishlistTap;
  final Function(WishlistSummary) onAddItem;
  final Function(String, WishlistSummary) onMenuAction;
  final VoidCallback? onCreateWishlist;
  final Future<void> Function() onRefresh;

  const PersonalWishlistsTabWidget({
    super.key,
    required this.personalWishlists,
    required this.onWishlistTap,
    required this.onAddItem,
    required this.onMenuAction,
    this.onCreateWishlist,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context);

    if (personalWishlists.isEmpty) {
      return _buildEmptyState(localization);
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.secondary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: personalWishlists.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final wishlist = personalWishlists[index];
          return WishlistCardWidget(
            wishlist: wishlist,
            isEvent: false,
            onTap: () => onWishlistTap(wishlist),
            onAddItem: () => onAddItem(wishlist),
            onMenuAction: (action) => onMenuAction(action, wishlist),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(LocalizationService localization) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                Icons.favorite_border_rounded,
                size: 36,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              localization.translate('wishlists.noWishlistsYet'),
              style: AppStyles.headingMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              localization.translate(
                'wishlists.createFirstWishlistDescription',
              ),
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (onCreateWishlist != null)
              CustomButton(
                text: localization.translate('wishlists.createWishlist'),
                onPressed: onCreateWishlist,
                customColor: AppColors.primary,
                icon: Icons.add_rounded,
              ),
          ],
        ),
      ),
    );
  }
}
