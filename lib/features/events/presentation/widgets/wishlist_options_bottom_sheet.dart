import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';

/// Bottom sheet widget for choosing wishlist option (Create New or Link Existing)
class WishlistOptionsBottomSheet extends StatelessWidget {
  final VoidCallback onCreateNew;
  final VoidCallback onLinkExisting;

  const WishlistOptionsBottomSheet({
    super.key,
    required this.onCreateNew,
    required this.onLinkExisting,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title
              Text(
                'Link Wishlist to Event',
                style: AppStyles.headingSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose how you want to link a wishlist to this event',
                style: AppStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Create New Wishlist Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onCreateNew();
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 24, color: Colors.white),
                  label: Text(
                    'Create New Wishlist',
                    style: AppStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Link Existing Wishlist Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onLinkExisting();
                  },
                  icon: Icon(
                    Icons.link_outlined,
                    size: 24,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    'Link Existing Wishlist',
                    style: AppStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

