import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'package:wish_listy/core/theme/app_theme.dart' as theme;
import '../guest/guest_wishlist_card_widget.dart';
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
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: personalWishlists.isEmpty
          ? _buildEmptyState(localization)
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
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
        final h = constraints.maxHeight;
        final w = constraints.maxWidth;
        final height = h.isFinite && h > 0 ? h : MediaQuery.of(context).size.height * 0.85;
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: height,
            width: w.isFinite && w > 0 ? w : double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildDecorativeBlobs(),
                Align(
                  alignment: const Alignment(0, -0.35),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 24,
                      top: 0,
                      right: 24,
                      bottom: 8,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Stacked cards illustration
                        _buildStackedCards(context),
                        const SizedBox(height: 32),
                        // Title: Wishlists
                        Text(
                          localization.translate('wishlists.myWishlists'),
                          style: AppStyles.headingMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        // Subtitle: Your wishlist is empty
                        Text(
                          localization.translate('wishlists.emptySubtitle'),
                          style: AppStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        if (onCreateWishlist != null)
                          CustomButton(
                            text: localization.translate(
                              'wishlists.createWishlist',
                            ),
                            onPressed: onCreateWishlist,
                            customColor: AppColors.primary,
                            icon: Icons.add_rounded,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Stacked cards illustration - 140x140 each, purple theme
  Widget _buildStackedCards(BuildContext context) {
    const cardSize = 140.0;
    const radius = 28.0;
    final primaryColor = Theme.of(context).colorScheme.primary;

    const backColor = Color(0xFFE9D5FF); // light lavender
    const middleColor = Color(0xFFD8B4FE); // medium purple
    final frontColor = primaryColor.withOpacity(0.85);

    // Tighter overlapping positions (turns in radians)
    const poses = [
      _StackPose(top: 0.0, dx: -24.0, angle: -0.24),
      _StackPose(top: 20.0, dx: 20.0, angle: 0.17),
      _StackPose(top: 44.0, dx: 0.0, angle: 0.0),
    ];
    final colors = [backColor, middleColor, frontColor];
    const icons = [
      Icons.card_giftcard_rounded,
      Icons.favorite_rounded,
      Icons.inventory_2_rounded,
    ];

    final width = MediaQuery.of(context).size.width;
    const rightOffset = 20.0; // Extra space from right
    final centerLeft = (width - cardSize) / 2 - rightOffset;

    return SizedBox(
      height: 200,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < 3; i++)
            Positioned(
              top: poses[i].top,
              left: centerLeft + poses[i].dx,
              child: Transform.rotate(
                angle: poses[i].angle,
                child: Container(
                  width: cardSize,
                  height: cardSize,
                  decoration: BoxDecoration(
                    color: colors[i],
                    borderRadius: BorderRadius.circular(radius),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textPrimary.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    icons[i],
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
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

class _StackPose {
  final double top;
  final double dx;
  final double angle;

  const _StackPose({
    required this.top,
    required this.dx,
    required this.angle,
  });
}
