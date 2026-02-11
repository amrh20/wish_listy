import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/features/profile/data/models/activity_model.dart';

/// Activity Card Widget - Displays a single activity
class ActivityCard extends StatelessWidget {
  final Activity activity;
  final VoidCallback? onTap;

  const ActivityCard({
    super.key,
    required this.activity,
    this.onTap,
  });

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '';
    final parts = name.split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  IconData _getActivityIcon(String type) {
    final typeLower = type.toLowerCase();
    switch (typeLower) {
      case 'wishlist_item_added':
        return Icons.card_giftcard; // 🎁
      case 'item_received':
        return Icons.celebration; // 🎉
      case 'purchased':
        return Icons.shopping_bag;
      case 'reserved':
        return Icons.bookmark;
      case 'added':
        return Icons.add_circle;
      case 'event_invi':
      case 'event_invitation':
      case 'event_invitation_accepted':
        return Icons.check_circle;
      case 'event_invitation_declined':
        return Icons.cancel;
      case 'event_invitation_maybe':
        return Icons.help_outline;
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
      case 'added':
        return AppColors.primary;
      case 'event_invi':
      case 'event_invitation':
      case 'event_invitation_accepted':
        return AppColors.success;
      case 'event_invitation_declined':
        return AppColors.error;
      case 'event_invitation_maybe':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  /// Localized time-ago string
  String _getTimeAgoLocalized(
    LocalizationService loc,
    DateTime dateTime,
  ) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      if (years == 1) {
        return loc.translate('activity.oneYearAgo');
      }
      return loc.translate('activity.yearsAgo', args: {'count': years});
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      if (months == 1) {
        return loc.translate('activity.oneMonthAgo');
      }
      return loc.translate('activity.monthsAgo', args: {'count': months});
    } else if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return loc.translate('activity.oneDayAgo');
      }
      return loc.translate('activity.daysAgo', args: {'count': difference.inDays});
    } else if (difference.inHours > 0) {
      if (difference.inHours == 1) {
        return loc.translate('activity.oneHourAgo');
      }
      return loc.translate('activity.hoursAgo', args: {'count': difference.inHours});
    } else if (difference.inMinutes > 0) {
      if (difference.inMinutes == 1) {
        return loc.translate('activity.oneMinuteAgo');
      }
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
    final typeLower = activity.type.toLowerCase();
    final itemName = activity.itemName ?? loc.translate('activity.anItem');
    final wishlistName = activity.wishlistName ?? '';
    
    // Build display text using localized templates
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
      displayText = loc.translate('activity.receivedTheir', args: {
        'actor': actorName,
        'item': itemName,
      });
      if (displayText == 'activity.receivedTheir') {
        displayText = '$actorName received their $itemName!';
      }
    } else {
      displayText = activity.getDisplayText();
    }

    final textSpans = [
      TextSpan(
        text: displayText,
        style: AppStyles.bodyMedium.copyWith(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
      ),
    ];

    // Navigate to friend profile when card is tapped
    final friendId = activity.actor.id;
    final canNavigateToProfile = friendId.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canNavigateToProfile
              ? () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.friendProfile,
                    arguments: {'friendId': friendId},
                  );
                }
              : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
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
                          fontSize: 16,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: AppStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        children: textSpans,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeAgo,
                      style: AppStyles.caption.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Activity Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: activityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  activityIcon,
                  color: activityColor,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

