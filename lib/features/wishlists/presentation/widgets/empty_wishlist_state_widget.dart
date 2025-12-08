import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/widgets/primary_gradient_button.dart';
import 'package:wish_listy/core/utils/app_routes.dart';

/// Empty state widget when wishlist has no items
class EmptyWishlistStateWidget extends StatelessWidget {
  final String wishlistId;
  final String wishlistName;
  final bool isFriendWishlist;

  const EmptyWishlistStateWidget({
    super.key,
    required this.wishlistId,
    required this.wishlistName,
    this.isFriendWishlist = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Wishes Yet',
              style: AppStyles.headingMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This wishlist is empty. Start adding wishes you dream of!',
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (!isFriendWishlist)
              PrimaryGradientButton(
                text: 'Add First Wish',
                icon: Icons.add_rounded,
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.addItem,
                    arguments: {
                      'wishlistId': wishlistId,
                      'wishlistName': wishlistName,
                    },
                  ).then((_) {
                    // Refresh the list when returning from add item screen
                    // This will be handled by the parent screen
                  });
                },
              ),
          ],
        ),
      ),
    );
  }
}

