import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'wishlist_card_widget.dart';

/// Personal wishlists tab widget
class PersonalWishlistsTabWidget extends StatelessWidget {
  final List<WishlistSummary> personalWishlists;
  final List<WishlistSummary> eventWishlists;
  final Function(WishlistSummary) onWishlistTap;
  final Function(WishlistSummary) onAddItem;
  final Function(String, WishlistSummary) onMenuAction;
  final VoidCallback onCreateEventWishlist;
  final Future<void> Function() onRefresh;

  const PersonalWishlistsTabWidget({
    super.key,
    required this.personalWishlists,
    required this.eventWishlists,
    required this.onWishlistTap,
    required this.onAddItem,
    required this.onMenuAction,
    required this.onCreateEventWishlist,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context);

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.secondary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Personal Wishlists Section
            if (personalWishlists.isNotEmpty || eventWishlists.isNotEmpty)
              _buildSectionHeader(
                localization.translate('wishlists.personalWishlists'),
                Icons.favorite_border_rounded,
                AppColors.primary,
              ),
            const SizedBox(height: 12),
            if (personalWishlists.isEmpty && eventWishlists.isEmpty)
              _buildEmptyState(localization)
            else
              ...personalWishlists
                  .map(
                    (wishlist) => WishlistCardWidget(
                      wishlist: wishlist,
                      isEvent: false,
                      onTap: () => onWishlistTap(wishlist),
                      onAddItem: () => onAddItem(wishlist),
                      onMenuAction: (action) => onMenuAction(action, wishlist),
                    ),
                  )
                  .toList(),

            const SizedBox(height: 24),

            // Event Wishlists Section (only show if there are any wishlists)
            if (personalWishlists.isNotEmpty || eventWishlists.isNotEmpty) ...[
              _buildSectionHeader(
                localization.translate('wishlists.eventWishlists'),
                Icons.celebration_rounded,
                AppColors.accent,
              ),
              const SizedBox(height: 12),

              if (eventWishlists.isEmpty)
                _buildEmptyEventWishlists(localization)
              else
                ...eventWishlists
                    .map(
                      (wishlist) => WishlistCardWidget(
                        wishlist: wishlist,
                        isEvent: true,
                        onTap: () => onWishlistTap(wishlist),
                        onAddItem: () => onAddItem(wishlist),
                        onMenuAction: (action) =>
                            onMenuAction(action, wishlist),
                      ),
                    )
                    .toList(),
            ],

            const SizedBox(height: 100), // Bottom padding for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: AppStyles.headingSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
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
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.favorite_border_rounded,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
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
            CustomButton(
              text: localization.translate('wishlists.createWishlist'),
              onPressed: onCreateEventWishlist,
              customColor: AppColors.primary,
              icon: Icons.add_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyEventWishlists(LocalizationService localization) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.textTertiary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.celebration_outlined,
              size: 40,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            localization.translate('wishlists.noEventWishlists'),
            style: AppStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            localization.translate('wishlists.createEventWishlistDescription'),
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: localization.translate('wishlists.createEventWishlist'),
            onPressed: onCreateEventWishlist,
            customColor: AppColors.accent,
            icon: Icons.add_rounded,
          ),
        ],
      ),
    );
  }
}
