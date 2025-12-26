import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'guest_wishlist_card_widget.dart';
import 'wishlist_card_widget.dart';

/// Personal wishlists tab widget with trendy stacked cards scroll effect
class PersonalWishlistsTabWidget extends StatelessWidget {
  final List<WishlistSummary> personalWishlists;
  final Function(WishlistSummary) onWishlistTap;
  final Function(WishlistSummary) onAddItem;
  final Function(String, WishlistSummary) onMenuAction;
  final VoidCallback? onCreateWishlist;
  final Future<void> Function() onRefresh;
  final bool guestStyle;

  const PersonalWishlistsTabWidget({
    super.key,
    required this.personalWishlists,
    required this.onWishlistTap,
    required this.onAddItem,
    required this.onMenuAction,
    this.onCreateWishlist,
    required this.onRefresh,
    this.guestStyle = false,
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
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom:
              16 +
              MediaQuery.of(context).padding.bottom +
              100, // Extra space for bottom nav bar
        ),
        itemCount: personalWishlists.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final wishlist = personalWishlists[index];
          if (guestStyle) {
            return GuestWishlistCardWidget(
              wishlist: wishlist,
              onTap: () => onWishlistTap(wishlist),
              onEdit: () => onMenuAction('edit', wishlist),
              onDelete: () => onMenuAction('delete', wishlist),
            );
          }

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
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: constraints.maxHeight,
          child: Stack(
            children: [
              // Decorative background blobs
              _buildDecorativeBlobs(),
              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                child: Column(
                  children: [
                    const Spacer(flex: 2), // Top space (2 parts)
                    Container(
                      width: 80,
                      height: 80,
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
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
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
                        text: localization.translate(
                          'wishlists.createWishlist',
                        ),
                        onPressed: onCreateWishlist,
                        customColor: AppColors.primary,
                        icon: Icons.add_rounded,
                      ),
                    const Spacer(flex: 3), // Bottom space (3 parts)
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build decorative blob shapes in bottom corners
  Widget _buildDecorativeBlobs() {
    return Positioned.fill(
      child: Stack(
        children: [
          // Bottom-left blob
          Positioned(
            left: -60,
            bottom: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.06),
              ),
            ),
          ),
          // Bottom-left smaller blob
          Positioned(
            left: 20,
            bottom: 40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(60),
                color: AppColors.accent.withOpacity(0.05),
              ),
            ),
          ),
          // Bottom-right blob
          Positioned(
            right: -50,
            bottom: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.06),
              ),
            ),
          ),
          // Bottom-right smaller blob
          Positioned(
            right: 30,
            bottom: 50,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: AppColors.accent.withOpacity(0.05),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
