import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/features/wishlists/presentation/widgets/index.dart';

/// Minimalist wishlist card for Home Screen
/// Extremely clean design with zero actions - purely informational
class MinimalWishlistCard extends StatelessWidget {
  final WishlistSummary wishlist;
  final VoidCallback? onTap;

  const MinimalWishlistCard({
    super.key,
    required this.wishlist,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final categoryVisual = _getCategoryVisual(wishlist.category);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () {
          Navigator.pushNamed(
            context,
            AppRoutes.wishlistItems,
            arguments: {
              'wishlistId': wishlist.id,
              'wishlistName': wishlist.name,
              'totalItems': wishlist.itemCount,
              'purchasedItems': wishlist.purchasedCount,
              'isFriendWishlist': false,
            },
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16), // Increased vertical padding for taller card
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16), // Match occasion card style
            border: Border.all(
              color: Colors.grey.shade200, // Subtle border for definition
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4), // Match occasion card shadow
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon with soft colored background (matching occasion card style)
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: categoryVisual.foregroundColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12), // Rounded corners
                ),
                child: Icon(
                  categoryVisual.icon,
                  size: 20,
                  color: categoryVisual.foregroundColor,
                ),
              ),
              const SizedBox(width: 10),
              // Wishlist name - bolder title
              Expanded(
                child: Text(
                  wishlist.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Item count - more subtle (greyish)
              Text(
                '${wishlist.itemCount} items',
                style: TextStyle(
                  color: Colors.grey.shade500, // More subtle grey
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              // Clean trailing arrow - aligned properly
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get category visual styling (same logic as ModernWishlistCard)
  _CategoryVisual _getCategoryVisual(String? categoryRaw) {
    final category = (categoryRaw ?? 'Other').trim();
    final normalized = category.toLowerCase();

    // Normalize a few common values
    final effective = (normalized == 'general' || normalized == 'other')
        ? 'other'
        : normalized;

    switch (effective) {
      case 'birthday':
        return _CategoryVisual(
          icon: Icons.cake_rounded,
          foregroundColor: Colors.orange.shade700,
        );
      case 'wedding':
        return _CategoryVisual(
          icon: Icons.favorite_rounded,
          foregroundColor: Colors.teal.shade700,
        );
      case 'graduation':
        return _CategoryVisual(
          icon: Icons.school_rounded,
          foregroundColor: Colors.lightBlue.shade700,
        );
      default:
        return _CategoryVisual(
          icon: Icons.star_rounded,
          foregroundColor: Colors.grey.shade700,
        );
    }
  }
}

/// Helper class for category visual styling
class _CategoryVisual {
  final IconData icon;
  final Color foregroundColor;

  const _CategoryVisual({
    required this.icon,
    required this.foregroundColor,
  });
}

