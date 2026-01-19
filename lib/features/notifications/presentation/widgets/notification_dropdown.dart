import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/features/notifications/data/models/notification_model.dart';
import 'package:wish_listy/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:wish_listy/features/friends/data/repository/friends_repository.dart';
import 'package:wish_listy/core/services/localization_service.dart';

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
    final localization = Provider.of<LocalizationService>(context, listen: false);
    // IMPORTANT:
    // The dropdown is shown via `showMenu` which takes a snapshot widget tree.
    // To reflect actions (accept/decline/delete) immediately without closing,
    // we must listen to `NotificationsCubit` changes here.
    return BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, state) {
        // Show loading state if notifications are being loaded
        if (state is NotificationsLoading) {
          return _buildLoadingState(context);
        }

        final effectiveNotifications =
            state is NotificationsLoaded ? state.notifications : notifications;
        final effectiveUnreadCount =
            state is NotificationsLoaded ? state.unreadCount : unreadCount;

        // Get last 5 notifications
        final recentNotifications = effectiveNotifications.take(5).toList();

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
                  localization.translate('app.notifications'),
                  style: AppStyles.headingMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (effectiveUnreadCount > 0)
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
                      localization
                          .translate('notifications.newNotifications')
                          .replaceAll('{count}', effectiveUnreadCount.toString()),
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
                ? _buildEmptyState(context)
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: recentNotifications.length,
                    itemBuilder: (context, index) {
                      final notification = recentNotifications[index];
                      final cubit = context.read<NotificationsCubit>();
                      return _NotificationItem(
                        notification: notification,
                        cubit: cubit,
                        onTap: () {
                          Navigator.pop(context); // Close dropdown
                          cubit.handleNotificationTap(notification, context);
                        },
                        onAccept: notification.type == NotificationType.friendRequest
                            ? () => _handleFriendRequestAction(
                                  context,
                                  notification,
                                  accept: true,
                                )
                            : null,
                        onDecline: notification.type == NotificationType.friendRequest
                            ? () => _handleFriendRequestAction(
                                  context,
                                  notification,
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
                  localization.translate('notifications.viewAllNotifications'),
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
      },
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    
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
                  localization.translate('app.notifications'),
                  style: AppStyles.headingMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Loading indicator
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  localization.translate('common.loading') ?? 'Loading...',
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontFamily: 'Alexandria',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
            Provider.of<LocalizationService>(context, listen: false).translate('notifications.noNotifications'),
            style: AppStyles.bodyMedium.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // Removed _handleNotificationTap - now using cubit.handleNotificationTap directly
  // Removed _handleFriendRequest - navigation handled by cubit.handleNotificationTap

  /// Handle friend request action (Accept/Decline)
  Future<void> _handleFriendRequestAction(
    BuildContext context,
    AppNotification notification, {
    required bool accept,
  }) async {
    // Get ScaffoldMessenger and localization before any async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final localization = Provider.of<LocalizationService>(context, listen: false);
    final cubit = context.read<NotificationsCubit>();
    
    try {
      // Get requestId from notification - prefer relatedId field, fallback to data map
      final requestId = notification.relatedId ??
                       notification.data?['relatedId'] ??
                       notification.data?['related_id'] ??
                       notification.data?['requestId'] ?? 
                       notification.data?['request_id'] ??
                       notification.data?['id'] ??
                       notification.data?['_id'];
      
      if (requestId == null || requestId.toString().isEmpty) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Text('Unable to process friend request. Missing request ID.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Delete notification first (optimistic update)
      cubit.deleteNotification(notification.id);

      // Call API to accept/decline friend request
      final friendsRepository = FriendsRepository();
      
      if (accept) {
        await friendsRepository.acceptFriendRequest(requestId: requestId.toString());
      } else {
        await friendsRepository.rejectFriendRequest(requestId: requestId.toString());
      }

      // Show success message
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                accept ? Icons.check_circle : Icons.cancel,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(accept
                  ? localization.translate('notifications.friendRequestAccepted')
                  : localization.translate('notifications.friendRequestDeclined')),
            ],
          ),
          backgroundColor: accept ? AppColors.success : AppColors.accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Restore notification on error
      await cubit.loadNotifications();
      
      scaffoldMessenger.showSnackBar(
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
  final NotificationsCubit cubit;
  final VoidCallback onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const _NotificationItem({
    required this.notification,
    required this.cubit,
    required this.onTap,
    this.onAccept,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final isFriendRequest = notification.type == NotificationType.friendRequest;
    
    return InkWell(
      onTap: () {
        // Handle tap using cubit's smart navigation
        cubit.handleNotificationTap(notification, context);
      },
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
                // Icon using helper method
                _buildLeadingIcon(notification.type, data: notification.data),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title - Always Bold
                      Text(
                        notification.title,
                        style: AppStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getTitleColor(notification.type, data: notification.data),
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
                          Provider.of<LocalizationService>(context, listen: false).translate('dialogs.decline'),
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
                          Provider.of<LocalizationService>(context, listen: false).translate('dialogs.accept'),
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
            // Action Buttons (RSVP) - Only for event_invite
            if (notification.type == NotificationType.eventInvitation) ...[
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  return _buildActionButtons(context, notification.type, notification, cubit);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build leading icon with color based on notification type
  Widget _buildLeadingIcon(NotificationType type, {Map<String, dynamic>? data}) {
    final iconData = _getNotificationIcon(type, data: data);
    final iconColor = _getIconColor(type, data: data);
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  /// Get icon data based on notification type
  IconData _getNotificationIcon(NotificationType type, {Map<String, dynamic>? data}) {
    // Check if this is item_received (even if mapped to itemPurchased)
    final isItemReceived = data?['type']?.toString().toLowerCase() == 'item_received' ||
                          data?['notificationType']?.toString().toLowerCase() == 'item_received';
    
    switch (type) {
      // Event types
      case NotificationType.eventInvitation:
        return Icons.event; // event_invite
      case NotificationType.eventResponse:
        return Icons.event_available; // event_invitation_accepted
      case NotificationType.eventUpdate:
        return Icons.edit_calendar; // event_update
      case NotificationType.eventReminder:
        return Icons.calendar_today;
      
      // Friend types
      case NotificationType.friendRequest:
        return Icons.person_add;
      case NotificationType.friendRequestAccepted:
        return Icons.how_to_reg;
      case NotificationType.friendRequestRejected:
        return Icons.person_remove;
      
      // Item types
      case NotificationType.itemReserved:
        return Icons.visibility_off; // Deep Purple - "Secret"
      case NotificationType.itemPurchased:
        // Check if this is actually item_received
        if (isItemReceived) {
          return Icons.check_circle_outline; // Success/happiness icon for item_received
        }
        return Icons.card_giftcard; // Purple
      case NotificationType.itemUnreserved:
        return Icons.lock_open; // Grey
      
      case NotificationType.wishlistShared:
        return Icons.share_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  /// Get icon color based on notification type
  Color _getIconColor(NotificationType type, {Map<String, dynamic>? data}) {
    // Check if this is item_received (even if mapped to itemPurchased)
    final isItemReceived = data?['type']?.toString().toLowerCase() == 'item_received' ||
                          data?['notificationType']?.toString().toLowerCase() == 'item_received';
    
    switch (type) {
      // Event types
      case NotificationType.eventInvitation:
        return Colors.orange; // event_invite
      case NotificationType.eventResponse:
        return Colors.green; // event_invitation_accepted (Green)
      case NotificationType.eventUpdate:
        return Colors.amber; // event_update (Amber)
      case NotificationType.eventReminder:
        return Colors.orange;
      
      // Friend types
      case NotificationType.friendRequest:
        return Colors.blue;
      case NotificationType.friendRequestAccepted:
        return Colors.green;
      case NotificationType.friendRequestRejected:
        return Colors.blue;
      
      // Item types
      case NotificationType.itemReserved:
        return Colors.deepPurple; // Deep Purple - "Secret"
      case NotificationType.itemPurchased:
        // Check if this is actually item_received
        if (isItemReceived) {
          return Colors.teal; // Teal for item_received (Mission Accomplished)
        }
        return Colors.purple;
      case NotificationType.itemUnreserved:
        return Colors.grey;
      
      case NotificationType.wishlistShared:
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  /// Get title color based on notification type (for highlighting)
  Color _getTitleColor(NotificationType type, {Map<String, dynamic>? data}) {
    // Check if this is item_received
    final isItemReceived = data?['type']?.toString().toLowerCase() == 'item_received' ||
                          data?['notificationType']?.toString().toLowerCase() == 'item_received';
    
    // Highlight event_invitation_accepted with green
    if (type == NotificationType.eventResponse) {
      return Colors.green.shade700;
    }
    
    // Highlight item_received with teal
    if (type == NotificationType.itemPurchased && isItemReceived) {
      return Colors.teal.shade700;
    }
    
    return AppColors.textPrimary;
  }

  /// Build action buttons (RSVP) - Only for event_invite
  Widget _buildActionButtons(BuildContext context, NotificationType type, AppNotification notification, NotificationsCubit cubit) {
    // Only show buttons for event_invite
    if (type != NotificationType.eventInvitation) {
      return const SizedBox.shrink();
    }
    
    // Get eventId from relatedId or data map
    final eventId = notification.relatedId ?? 
                   notification.data?['eventId']?.toString() ??
                   notification.data?['event_id']?.toString() ??
                   notification.data?['event']?['_id']?.toString() ??
                   notification.data?['event']?['id']?.toString();
    
    if (eventId == null || eventId.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildRSVPButtons(context, notification.copyWith(relatedId: eventId), cubit);
  }

  /// Build RSVP buttons for event invitation notifications
  Widget _buildRSVPButtons(BuildContext context, AppNotification notification, NotificationsCubit cubit) {
    if (notification.type != NotificationType.eventInvitation) {
      return const SizedBox.shrink();
    }
    
    // Get eventId from relatedId or data map
    final eventId = notification.relatedId ?? 
                   notification.data?['eventId']?.toString() ??
                   notification.data?['event_id']?.toString() ??
                   notification.data?['event']?['_id']?.toString() ??
                   notification.data?['event']?['id']?.toString();
    
    if (eventId == null || eventId.isEmpty) {
      return const SizedBox.shrink();
    }

    return StatefulBuilder(
      builder: (context, setState) {
        bool isLoading = false;
        String? selectedStatus; // 'accepted', 'maybe', 'declined'

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show success message if response was sent
            if (selectedStatus != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    Provider.of<LocalizationService>(context, listen: false).translate('notifications.responseSent'),
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Show action buttons - Same style as Friend Request buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Decline Button
                  SizedBox(
                    height: 32,
                    child: OutlinedButton(
                      onPressed: isLoading
                          ? null
                            : () async {
                              setState(() {
                                isLoading = true;
                              });
                              // Get ScaffoldMessenger before closing dropdown
                              final scaffoldMessenger = ScaffoldMessenger.of(context);
                              final localization = Provider.of<LocalizationService>(context, listen: false);
                              try {
                                final eventId = notification.relatedId ?? 
                                               notification.data?['eventId']?.toString() ??
                                               notification.data?['event_id']?.toString() ??
                                               notification.data?['event']?['_id']?.toString() ??
                                               notification.data?['event']?['id']?.toString();
                                if (eventId == null || eventId.isEmpty) {
                                  throw Exception('Event ID not found');
                                }
                                // Delete notification first (optimistic update)
                                cubit.deleteNotification(notification.id);
                                // Close dropdown
                                Navigator.pop(context);
                                // Call API
                                await cubit.respondToEvent(eventId, 'declined');
                                // Show success snackbar (using parent context)
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text(localization.translate('notifications.youDeclinedInvitation')),
                                    backgroundColor: AppColors.textSecondary,
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } catch (e) {
                                // Restore notification on error
                                await cubit.loadNotifications();
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to respond: ${e.toString()}'),
                                    backgroundColor: AppColors.error,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } finally {
                                if (context.mounted) {
                                  setState(() {
                                    isLoading = false;
                                    selectedStatus = 'declined';
                                  });
                                }
                              }
                            },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: const Size(0, 32),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isLoading
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                              ),
                            )
                          : Text(
                              Provider.of<LocalizationService>(context, listen: false).translate('dialogs.decline'),
                              style: AppStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Maybe Button
                  SizedBox(
                    height: 32,
                    child: OutlinedButton(
                      onPressed: isLoading
                          ? null
                            : () async {
                              setState(() {
                                isLoading = true;
                              });
                              // Get ScaffoldMessenger before closing dropdown
                              final scaffoldMessenger = ScaffoldMessenger.of(context);
                              final localization = Provider.of<LocalizationService>(context, listen: false);
                              try {
                                final eventId = notification.relatedId ?? 
                                               notification.data?['eventId']?.toString() ??
                                               notification.data?['event_id']?.toString() ??
                                               notification.data?['event']?['_id']?.toString() ??
                                               notification.data?['event']?['id']?.toString();
                                if (eventId == null || eventId.isEmpty) {
                                  throw Exception('Event ID not found');
                                }
                                // Delete notification first (optimistic update)
                                cubit.deleteNotification(notification.id);
                                // Close dropdown
                                Navigator.pop(context);
                                // Call API
                                await cubit.respondToEvent(eventId, 'maybe');
                                // Show success snackbar (using parent context)
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text(localization.translate('notifications.youMarkedMaybe')),
                                    backgroundColor: AppColors.warning,
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } catch (e) {
                                // Restore notification on error
                                await cubit.loadNotifications();
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to respond: ${e.toString()}'),
                                    backgroundColor: AppColors.error,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } finally {
                                if (context.mounted) {
                                  setState(() {
                                    isLoading = false;
                                    selectedStatus = 'maybe';
                                  });
                                }
                              }
                            },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: const Size(0, 32),
                        side: BorderSide(color: Colors.orange.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isLoading
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                              ),
                            )
                          : Text(
                              Provider.of<LocalizationService>(context, listen: false).translate('dialogs.maybe'),
                              style: AppStyles.bodySmall.copyWith(
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Accept Button
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                            : () async {
                              setState(() {
                                isLoading = true;
                              });
                              // Get ScaffoldMessenger before closing dropdown
                              final scaffoldMessenger = ScaffoldMessenger.of(context);
                              final localization = Provider.of<LocalizationService>(context, listen: false);
                              try {
                                final eventId = notification.relatedId ?? 
                                               notification.data?['eventId']?.toString() ??
                                               notification.data?['event_id']?.toString() ??
                                               notification.data?['event']?['_id']?.toString() ??
                                               notification.data?['event']?['id']?.toString();
                                if (eventId == null || eventId.isEmpty) {
                                  throw Exception('Event ID not found');
                                }
                                // Delete notification first (optimistic update)
                                cubit.deleteNotification(notification.id);
                                // Close dropdown
                                Navigator.pop(context);
                                // Call API
                                await cubit.respondToEvent(eventId, 'accepted');
                                // Show success snackbar (using parent context)
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text(localization.translate('notifications.youAcceptedInvitation')),
                                    backgroundColor: AppColors.success,
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } catch (e) {
                                // Restore notification on error
                                await cubit.loadNotifications();
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to respond: ${e.toString()}'),
                                    backgroundColor: AppColors.error,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } finally {
                                if (context.mounted) {
                                  setState(() {
                                    isLoading = false;
                                    selectedStatus = 'accepted';
                                  });
                                }
                              }
                            },
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
                      child: isLoading
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              Provider.of<LocalizationService>(context, listen: false).translate('dialogs.accept'),
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
        );
      },
    );
  }
}

