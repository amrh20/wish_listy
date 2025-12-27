import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/features/notifications/data/models/notification_model.dart';
import 'package:wish_listy/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:wish_listy/features/friends/data/repository/friends_repository.dart';

/// Notification Dropdown Widget
/// Shows last 5 notifications with actions based on type
class NotificationDropdown extends StatelessWidget {
  final List<AppNotification> notifications;
  final int unreadCount;
  final VoidCallback? onDismiss;

  const NotificationDropdown({
    super.key,
    required this.notifications,
    required this.unreadCount,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    // Get last 5 notifications
    final recentNotifications = notifications.take(5).toList();

    return Container(
      width: 360,
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Notifications',
                  style: AppStyles.headingMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$unreadCount new',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Notifications List
          Flexible(
            child: recentNotifications.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: recentNotifications.length,
                    itemBuilder: (context, index) {
                      return _NotificationItem(
                        notification: recentNotifications[index],
                        onTap: () => _handleNotificationTap(
                          context,
                          recentNotifications[index],
                        ),
                        onAccept: recentNotifications[index].type == NotificationType.friendRequest
                            ? () => _handleFriendRequestAction(
                                  context,
                                  recentNotifications[index],
                                  accept: true,
                                )
                            : null,
                        onDecline: recentNotifications[index].type == NotificationType.friendRequest
                            ? () => _handleFriendRequestAction(
                                  context,
                                  recentNotifications[index],
                                  accept: false,
                                )
                            : null,
                      );
                    },
                  ),
          ),
          // View All Button
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context); // Close dropdown
                  }
                  Navigator.pushNamed(context, AppRoutes.notifications);
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'View All Notifications',
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications',
            style: AppStyles.bodyMedium.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(
    BuildContext context,
    AppNotification notification,
  ) {
    // Mark as read
    if (!notification.isRead) {
      context.read<NotificationsCubit>().markAsRead(notification.id);
    }

    // Handle action based on notification type
    switch (notification.type) {
      case NotificationType.friendRequest:
        // Navigate to friend request screen or show accept/decline dialog
        _handleFriendRequest(context, notification);
        break;
      case NotificationType.eventInvitation:
        // Navigate to event details
        if (notification.data?['eventId'] != null) {
          Navigator.pop(context); // Close dropdown
          Navigator.pushNamed(
            context,
            AppRoutes.eventDetails,
            arguments: {'eventId': notification.data!['eventId']},
          );
        }
        break;
      case NotificationType.itemReserved:
      case NotificationType.itemPurchased:
        // Navigate to wishlist or item details
        if (notification.data?['wishlistId'] != null) {
          Navigator.pop(context); // Close dropdown
          Navigator.pushNamed(
            context,
            AppRoutes.wishlistItems,
            arguments: {
              'wishlistId': notification.data!['wishlistId'],
              'wishlistName': notification.data?['wishlistName'] ?? 'Wishlist',
            },
          );
        }
        break;
      case NotificationType.wishlistShared:
        // Navigate to shared wishlist
        if (notification.data?['wishlistId'] != null) {
          Navigator.pop(context); // Close dropdown
          Navigator.pushNamed(
            context,
            AppRoutes.wishlistItems,
            arguments: {
              'wishlistId': notification.data!['wishlistId'],
              'wishlistName': notification.data?['wishlistName'] ?? 'Wishlist',
              'isFriendWishlist': true,
            },
          );
        }
        break;
      default:
        // For other types, just close dropdown
        Navigator.pop(context);
        break;
    }
  }

  void _handleFriendRequest(BuildContext context, AppNotification notification) {
    // Show accept/decline dialog or navigate to friends screen
    Navigator.pop(context); // Close dropdown
    Navigator.pushNamed(context, AppRoutes.friends);
  }

  /// Handle friend request action (Accept/Decline)
  Future<void> _handleFriendRequestAction(
    BuildContext context,
    AppNotification notification, {
    required bool accept,
  }) async {
    try {
      // Get requestId from notification data
      // Try multiple possible field names: relatedId, requestId, request_id, id
      final requestId = notification.data?['relatedId'] ??
                       notification.data?['related_id'] ??
                       notification.data?['requestId'] ?? 
                       notification.data?['request_id'] ??
                       notification.data?['id'] ??
                       notification.data?['_id'];
      
      if (requestId == null || requestId.toString().isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Unable to process friend request. Missing request ID.'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Call API to accept/decline friend request
      final friendsRepository = FriendsRepository();
      
      if (accept) {
        await friendsRepository.acceptFriendRequest(requestId: requestId.toString());
      } else {
        await friendsRepository.rejectFriendRequest(requestId: requestId.toString());
      }

      if (!context.mounted) return;

      // Delete notification after action
      context.read<NotificationsCubit>().deleteNotification(notification.id);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                accept ? Icons.check_circle : Icons.cancel,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(accept
                  ? 'Friend request accepted!'
                  : 'Friend request declined'),
            ],
          ),
          backgroundColor: accept ? AppColors.success : AppColors.accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  e.toString().contains('ApiException')
                      ? 'Failed to process request. Please try again.'
                      : 'An error occurred. Please try again.',
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}

/// Individual Notification Item
class _NotificationItem extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const _NotificationItem({
    required this.notification,
    required this.onTap,
    this.onAccept,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final isFriendRequest = notification.type == NotificationType.friendRequest;
    
    return InkWell(
      onTap: isFriendRequest ? null : onTap, // Disable tap for friend requests (use buttons instead)
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.white
              : AppColors.primary.withOpacity(0.05),
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade100,
              width: 1,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getIconColor(notification.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      notification.type.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: AppStyles.bodyMedium.copyWith(
                          fontWeight: notification.isRead
                              ? FontWeight.normal
                              : FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: AppStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.timeAgo,
                        style: AppStyles.caption.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Unread indicator
                if (!notification.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            // Accept/Decline buttons for friend requests
            if (isFriendRequest && (onAccept != null || onDecline != null)) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Decline button
                  if (onDecline != null)
                    SizedBox(
                      height: 32,
                      child: OutlinedButton(
                        onPressed: onDecline,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: const Size(0, 32),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Decline',
                          style: AppStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  if (onAccept != null && onDecline != null)
                    const SizedBox(width: 8),
                  // Accept button
                  if (onAccept != null)
                    SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        onPressed: onAccept,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: const Size(0, 32),
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Accept',
                          style: AppStyles.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getIconColor(NotificationType type) {
    switch (type) {
      case NotificationType.friendRequest:
      case NotificationType.friendRequestAccepted:
        return AppColors.info;
      case NotificationType.eventInvitation:
      case NotificationType.eventReminder:
        return AppColors.primary;
      case NotificationType.itemReserved:
      case NotificationType.itemPurchased:
        return AppColors.success;
      case NotificationType.wishlistShared:
        return AppColors.secondary;
      default:
        return AppColors.textSecondary;
    }
  }
}

