import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
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

  @override
  Widget build(BuildContext context) {
    final actorName = activity.actor.displayName ?? 'Someone';
    final actorImage = activity.actor.imageUrl;
    final activityIcon = _getActivityIcon(activity.type);
    final activityColor = _getActivityColor(activity.type);
    final timeAgo = activity.getTimeAgo();
    final typeLower = activity.type.toLowerCase();
    final itemName = activity.itemName;
    final wishlistName = activity.wishlistName;
    
    // Build RichText children based on activity type
    List<TextSpan> textSpans = [];
    
    if (typeLower == 'wishlist_item_added') {
      // [Actor Name] added [itemName] to their wishlist [wishlistName]
      textSpans = [
        TextSpan(
          text: actorName,
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const TextSpan(text: ' added '),
        TextSpan(
          text: itemName ?? 'an item',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        const TextSpan(text: ' to their wishlist '),
        TextSpan(
          text: wishlistName ?? '',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
      ];
    } else if (typeLower == 'item_received') {
      // [Actor Name] received their [itemName]!
      textSpans = [
        TextSpan(
          text: actorName,
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const TextSpan(text: ' received their '),
        TextSpan(
          text: itemName ?? 'item',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        const TextSpan(text: '!'),
      ];
    } else {
      // Fallback for other types
      final displayText = activity.getDisplayText();
      textSpans = [
        TextSpan(
          text: actorName,
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        TextSpan(
          text: ' ${displayText.replaceFirst(actorName, '').trim()}',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
      ];
    }

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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            GestureDetector(
              onTap: activity.actor.id.isNotEmpty
                  ? () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.friendProfile,
                        arguments: {'friendId': activity.actor.id},
                      );
                    }
                  : null,
              child: CircleAvatar(
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
    );
  }
}

