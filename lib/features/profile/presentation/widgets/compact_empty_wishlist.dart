import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/features/profile/data/models/activity_model.dart';
import 'package:wish_listy/features/profile/presentation/widgets/activity_card.dart';

/// Compact Empty Wishlist Card - Used when wishlists are empty but activities exist
/// Shows a smaller version of the empty state to make room for the activity feed
class CompactEmptyWishlistCard extends StatelessWidget {
  const CompactEmptyWishlistCard({super.key});

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            '${localization.translate('cards.myWishlists')} 🎁',
            style: AppStyles.headingMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Alexandria',
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Compact Empty State Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Small illustration/icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.card_giftcard_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        localization.translate('details.youDontHaveWishlistYet'),
                        style: AppStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontFamily: 'Alexandria',
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Compact CTA Button
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.createWishlist,
                      arguments: {
                        'previousRoute': AppRoutes.mainNavigation,
                      },
                    );
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    localization.translate('cards.createWishlist'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      fontFamily: 'Alexandria',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Happening Now Section - Shows friend activities when user has no wishlists
/// This is a standalone section that can be used in the empty-wishlists-but-has-activities state
class HappeningNowSection extends StatelessWidget {
  final List<Activity> activities;

  const HappeningNowSection({
    super.key,
    required this.activities,
  });

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    
    // Limit to 3 activities for preview
    final displayActivities = activities.take(3).toList();
    
    if (displayActivities.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: 1.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with "Happening Now" title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${localization.translate('cards.happeningNow')} ⚡',
                  style: AppStyles.headingMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontFamily: 'Alexandria',
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.friendActivityFeed,
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    localization.translate('home.viewAll'),
                    style: AppStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      fontFamily: 'Alexandria',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Activity List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: displayActivities
                  .map((activity) => ActivityCard(activity: activity))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact Activity Card - A smaller version for inline display
/// Shows activity in a more compact horizontal format
class CompactActivityCard extends StatelessWidget {
  final Activity activity;

  const CompactActivityCard({
    super.key,
    required this.activity,
  });

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  IconData _getActivityIcon(String type) {
    final typeLower = type.toLowerCase();
    switch (typeLower) {
      case 'wishlist_item_added':
        return Icons.card_giftcard;
      case 'item_received':
        return Icons.celebration;
      case 'purchased':
        return Icons.shopping_bag;
      case 'reserved':
        return Icons.bookmark;
      default:
        return Icons.card_giftcard;
    }
  }

  Color _getActivityColor(String type) {
    final typeLower = type.toLowerCase();
    switch (typeLower) {
      case 'wishlist_item_added':
        return AppColors.primary;
      case 'item_received':
        return AppColors.success;
      case 'purchased':
        return AppColors.success;
      case 'reserved':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  String _getTimeAgoLocalized(LocalizationService loc, DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      if (years == 1) return loc.translate('activity.oneYearAgo');
      return loc.translate('activity.yearsAgo', args: {'count': years});
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      if (months == 1) return loc.translate('activity.oneMonthAgo');
      return loc.translate('activity.monthsAgo', args: {'count': months});
    } else if (difference.inDays > 0) {
      if (difference.inDays == 1) return loc.translate('activity.oneDayAgo');
      return loc.translate('activity.daysAgo', args: {'count': difference.inDays});
    } else if (difference.inHours > 0) {
      if (difference.inHours == 1) return loc.translate('activity.oneHourAgo');
      return loc.translate('activity.hoursAgo', args: {'count': difference.inHours});
    } else if (difference.inMinutes > 0) {
      if (difference.inMinutes == 1) return loc.translate('activity.oneMinuteAgo');
      return loc.translate('activity.minutesAgo', args: {'count': difference.inMinutes});
    } else {
      return loc.translate('activity.justNow');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context);
    final actorName = activity.actor.displayName ?? loc.translate('activity.someone');
    final actorImage = activity.actor.imageUrl;
    final activityIcon = _getActivityIcon(activity.type);
    final activityColor = _getActivityColor(activity.type);
    final timeAgo = _getTimeAgoLocalized(loc, activity.createdAt);
    final friendId = activity.actor.id;

    final typeLower = activity.type.toLowerCase();
    final itemName = activity.itemName ?? loc.translate('activity.anItem');
    final wishlistName = activity.wishlistName ?? '';
    String displayText;
    if (typeLower == 'wishlist_item_added') {
      displayText = loc.translate('activity.addedToWishlist', args: {
        'actor': actorName,
        'item': itemName,
        'wishlist': wishlistName,
      });
      if (displayText == 'activity.addedToWishlist') {
        displayText = '$actorName added $itemName to their wishlist $wishlistName';
      }
    } else if (typeLower == 'item_received') {
      displayText = loc.translate('activity.receivedTheir', args: {'actor': actorName, 'item': itemName});
      if (displayText == 'activity.receivedTheir') {
        displayText = '$actorName received their $itemName!';
      }
    } else {
      displayText = activity.getDisplayText();
    }

    return GestureDetector(
      onTap: friendId.isNotEmpty
          ? () {
              Navigator.pushNamed(
                context,
                AppRoutes.friendProfile,
                arguments: {'friendId': friendId},
              );
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: actorImage != null
                  ? NetworkImage(actorImage)
                  : null,
              child: actorImage == null
                  ? Text(
                      _getInitials(actorName),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        fontFamily: 'Alexandria',
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayText,
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontFamily: 'Alexandria',
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeAgo,
                    style: AppStyles.caption.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 10,
                      fontFamily: 'Alexandria',
                    ),
                  ),
                ],
              ),
            ),
            // Activity Icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: activityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                activityIcon,
                color: activityColor,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
