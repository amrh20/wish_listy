import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../services/localization_service.dart';

/// FAB widget for creating wishlists
class WishlistFabWidget extends StatelessWidget {
  final VoidCallback onCreatePersonalWishlist;
  final VoidCallback onCreateEventWishlist;

  const WishlistFabWidget({
    super.key,
    required this.onCreatePersonalWishlist,
    required this.onCreateEventWishlist,
  });

  void _showCreateOptions(BuildContext context) {
    final localization = Provider.of<LocalizationService>(
      context,
      listen: false,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              localization.translate('wishlists.createNewWishlist'),
              style: AppStyles.headingMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            // Options
            _buildFABOption(
              icon: Icons.favorite_rounded,
              title: localization.translate('wishlists.personalWishlist'),
              subtitle: localization.translate(
                'wishlists.createPersonalWishlistDescription',
              ),
              color: AppColors.primary,
              onTap: () {
                Navigator.pop(context);
                onCreatePersonalWishlist();
              },
            ),

            const SizedBox(height: 16),

            _buildFABOption(
              icon: Icons.celebration_rounded,
              title: localization.translate('wishlists.eventWishlist'),
              subtitle: localization.translate(
                'wishlists.createEventWishlistDescription',
              ),
              color: AppColors.accent,
              onTap: () {
                Navigator.pop(context);
                onCreateEventWishlist();
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFABOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _showCreateOptions(context),
      backgroundColor: AppColors.primary,
      elevation: 4,
      child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
    );
  }
}
