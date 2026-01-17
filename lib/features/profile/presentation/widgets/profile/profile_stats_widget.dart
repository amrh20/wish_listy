import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';

class ProfileStatsWidget extends StatelessWidget {
  final int friendsCount;
  final int wishlistsCount;
  final int eventsCount;
  final String friendsLabel;
  final String wishlistsLabel;
  final String eventsLabel;
  final VoidCallback onFriendsTap;
  final VoidCallback onWishlistsTap;
  final VoidCallback onEventsTap;

  const ProfileStatsWidget({
    super.key,
    required this.friendsCount,
    required this.wishlistsCount,
    required this.eventsCount,
    required this.friendsLabel,
    required this.wishlistsLabel,
    required this.eventsLabel,
    required this.onFriendsTap,
    required this.onWishlistsTap,
    required this.onEventsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.textTertiary.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Friends Stat
            Expanded(
              child: GestureDetector(
                onTap: onFriendsTap,
                child: _buildStatItem(
                  icon: Icons.people_outline,
                  value: '$friendsCount',
                  label: friendsLabel,
                  iconColor: AppColors.secondary,
                  iconBackgroundColor: AppColors.secondary.withOpacity(0.1),
                ),
              ),
            ),
            // Divider
            Container(height: 60, width: 1, color: Colors.grey.withOpacity(0.2)),
            // Wishlists Stat
            Expanded(
              child: GestureDetector(
                onTap: onWishlistsTap,
                child: _buildStatItem(
                  icon: Icons.favorite_outline,
                  value: '$wishlistsCount',
                  label: wishlistsLabel,
                  iconColor: AppColors.primary,
                  iconBackgroundColor: AppColors.primary.withOpacity(0.1),
                ),
              ),
            ),
            // Divider
            Container(height: 60, width: 1, color: Colors.grey.withOpacity(0.2)),
            // Events Stat
            Expanded(
              child: GestureDetector(
                onTap: onEventsTap,
                child: _buildStatItem(
                  icon: Icons.event_outlined,
                  value: '$eventsCount',
                  label: eventsLabel,
                  iconColor: AppColors.accent,
                  iconBackgroundColor: AppColors.accent.withOpacity(0.1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color iconColor,
    required Color iconBackgroundColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: iconBackgroundColor,
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: AppStyles.headingLarge.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 26,
            color: AppColors.textPrimary,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: AppStyles.bodySmall.copyWith(
            color: Colors.grey[600],
            fontSize: 11,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

