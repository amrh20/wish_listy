import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/features/notifications/data/models/notification_model.dart';
import 'package:wish_listy/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:wish_listy/features/friends/data/repository/friends_repository.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/widgets/unified_snackbar.dart';

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
      // Only rebuild when notifications list or unreadCount actually changes
      buildWhen: (previous, current) {
        if (previous is NotificationsLoaded && current is NotificationsLoaded) {
          // Rebuild only if notifications list or unreadCount changed
          return previous.notifications != current.notifications ||
                 previous.unreadCount != current.unreadCount;
        }
        // Always rebuild on state type change (Loading -> Loaded, etc.)
        return previous.runtimeType != current.runtimeType;
      },
      builder: (context, state) {
        // Show loading state ONLY if we're loading AND have no cached data
        if (state is NotificationsLoading && notifications.isEmpty) {
          return _buildLoadingState(context);
        }

        // Use fresh data from state if loaded, otherwise use cached notifications
        final effectiveNotifications =
            state is NotificationsLoaded ? state.notifications : notifications;
        final effectiveUnreadCount =
            state is NotificationsLoaded ? state.unreadCount : unreadCount;

        // Get last 5 notifications
        final recentNotifications = effectiveNotifications.take(5).toList();

        final screenWidth = MediaQuery.of(context).size.width;
        const double maxWidth = 360;
        const double horizontalMargin = 16;
        final double effectiveWidth = screenWidth - (horizontalMargin * 2);
        final double dropdownWidth =
            effectiveWidth < maxWidth ? effectiveWidth : maxWidth;

        // Check if we're loading while having cached data (smart loading)
        final isLoadingWithData = state is NotificationsLoading && notifications.isNotEmpty;

        return Container(
          width: dropdownWidth,
          constraints: const BoxConstraints(
            minHeight: 200, // Stable minimum height to prevent jumps
            maxHeight: 400,
          ),
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
            child: Column(
              children: [
                Row(
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
                // Linear progress indicator when loading with existing data
                if (isLoadingWithData)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(
                      minHeight: 2,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
              ],
            ),
          ),
          // Notifications List
          Flexible(
            child: recentNotifications.isEmpty && !isLoadingWithData
                ? _buildEmptyState(context)
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(), // Prevent over-scroll glitches
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
    // Use shimmer state for better UX
    return _buildShimmerState(context);
  }

  /// Build shimmer loading state (skeleton screen)
  Widget _buildShimmerState(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context, listen: false);

    final screenWidth = MediaQuery.of(context).size.width;
    const double maxWidth = 360;
    const double horizontalMargin = 16;
    final double effectiveWidth = screenWidth - (horizontalMargin * 2);
    final double dropdownWidth =
        effectiveWidth < maxWidth ? effectiveWidth : maxWidth;

    return Container(
      width: dropdownWidth,
      constraints: const BoxConstraints(
        minHeight: 200, // Stable minimum height to prevent jumps
        maxHeight: 400,
      ),
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
          // Shimmer loading items
          Flexible(
            child: ListView(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(), // Prevent over-scroll glitches
              padding: const EdgeInsets.all(16),
              children: List.generate(3, (index) => _buildShimmerItem()),
            ),
          ),
          // View All Button (same as main state for stable layout)
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
                onPressed: null, // Disabled during loading
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  localization.translate('notifications.viewAllNotifications'),
                  style: AppStyles.bodyMedium.copyWith(
                    color: Colors.grey.shade400,
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

  /// Build individual shimmer item (skeleton for notification) with animation
  Widget _buildShimmerItem() {
    return _ShimmerItem();
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
  /// Uses a captured ScaffoldMessenger so the loading snackbar is always dismissed
  /// and replaced by success/error even if the dropdown is closed before the API returns.
  Future<void> _handleFriendRequestAction(
    BuildContext context,
    AppNotification notification, {
    required bool accept,
  }) async {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    final cubit = context.read<NotificationsCubit>();

    // Capture messenger before any async work so we can hide/show snackbars
    // even after the dropdown closes (context may be disposed).
    final messenger = ScaffoldMessenger.of(context);

    // Get requestId from notification - prefer relatedId field, fallback to data map
    final requestId = notification.relatedId ??
                     notification.data?['relatedId'] ??
                     notification.data?['related_id'] ??
                     notification.data?['requestId'] ??
                     notification.data?['request_id'] ??
                     notification.data?['id'] ??
                     notification.data?['_id'];

    if (requestId == null || requestId.toString().isEmpty) {
      messenger.hideCurrentSnackBar();
      UnifiedSnackbar.showError(
        context: context,
        message: localization.translate('dialogs.unableToProcessFriendRequest') ??
                 'Unable to process friend request. Missing request ID.',
      );
      return;
    }

    // Clear any stuck loading snackbar before showing a new one.
    messenger.hideCurrentSnackBar();

    final loadingMessage = accept
        ? (localization.translate('notifications.acceptingFriendRequest') ??
           'Accepting friend request...')
        : (localization.translate('notifications.decliningFriendRequest') ??
           'Declining friend request...');

    UnifiedSnackbar.showLoading(
      context: context,
      message: loadingMessage,
      duration: const Duration(minutes: 1), // Dismissed in finally
    );

    bool success = false;
    String? errorMessage;

    try {
      final friendsRepository = FriendsRepository();

      if (accept) {
        await friendsRepository.acceptFriendRequest(requestId: requestId.toString());
      } else {
        await friendsRepository.rejectFriendRequest(requestId: requestId.toString());
      }

      await cubit.deleteNotification(notification.id);
      success = true;
      // Refresh notification list and badge so bell count updates immediately
      cubit.loadNotifications();
      cubit.getUnreadCount();
    } catch (e) {
      errorMessage = e.toString().contains('ApiException')
          ? (localization.translate('dialogs.failedToProcessFriendRequest') ??
             'Failed to process friend request. Please try again.')
          : (localization.translate('dialogs.failedToProcessFriendRequest') ??
             'An error occurred. Please try again.');
    } finally {
      // Always dismiss the loading snackbar when the operation completes (no Cubit loading state for this flow).
      messenger.hideCurrentSnackBar();
    }

    // Show final success or error using captured messenger (works even if dropdown closed).
    if (success) {
      final message = accept
          ? (localization.translate('notifications.friendRequestAccepted') ??
             'Friend request accepted')
          : (localization.translate('notifications.friendRequestDeclined') ??
             'Friend request declined');
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: AppStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  errorMessage ?? 'An error occurred. Please try again.',
                  style: AppStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}

/// Individual Notification Item - Compact dropdown design matching full screen
/// Optimized with stable layout and image caching
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
    final localization = Provider.of<LocalizationService>(context, listen: false);
    final isFriendRequest = notification.type == NotificationType.friendRequest;
    final isFriendRequestAccepted = notification.type == NotificationType.friendRequestAccepted;
    final isEventResponse = notification.type == NotificationType.eventResponse;
    final isEventInvitation = notification.type == NotificationType.eventInvitation;
    
    // Check if this notification involves a user (show avatar)
    final hasUserAvatar = isFriendRequest || 
                          isFriendRequestAccepted || 
                          isEventResponse ||
                          isEventInvitation ||
                          notification.type == NotificationType.friendRequestRejected;
    
    // Extract user info from notification data
    final senderName = _extractSenderName();
    final senderImage = _extractSenderImage();
    
    return InkWell(
      onTap: () {
        Navigator.pop(context); // Close dropdown first
        cubit.handleNotificationTap(notification, context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.white
              : AppColors.primary.withOpacity(0.03),
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade100,
              width: 1,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar or Icon
            _buildLeadingWidget(hasUserAvatar, senderName, senderImage),
            const SizedBox(width: 10),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rich text message with bold name
                  _buildRichTextMessage(context, senderName, localization),
                  const SizedBox(height: 4),
                  // Timestamp
                  Text(
                    notification.timeAgo,
                    style: AppStyles.caption.copyWith(
                      color: AppColors.textTertiary,
                      fontFamily: 'Alexandria',
                      fontSize: 11,
                    ),
                  ),
                  // Compact Action Buttons for friend requests
                  if (isFriendRequest && (onAccept != null || onDecline != null)) ...[
                    const SizedBox(height: 8),
                    _buildCompactFriendRequestButtons(context, localization),
                  ],
                  // Compact RSVP Buttons for event invitations
                  if (isEventInvitation) ...[
                    const SizedBox(height: 8),
                    _buildCompactRSVPButtons(context, localization),
                  ],
                ],
              ),
            ),
            // Unread indicator (subtle pink dot)
            if (!notification.isRead)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(left: 6, top: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build leading widget - circular avatar for user notifications, icon for others
  Widget _buildLeadingWidget(bool hasUserAvatar, String? senderName, String? senderImage) {
    if (hasUserAvatar) {
      return _buildAvatarWithBadge(senderName, senderImage);
    }
    return _buildLeadingIcon(notification.type, data: notification.data);
  }

  /// Build circular avatar with status badge
  /// Uses CachedNetworkImageProvider for efficient image loading and caching
  Widget _buildAvatarWithBadge(String? senderName, String? senderImage) {
    final statusBadge = _getStatusBadge();
    
    return Stack(
      children: [
        // Circular Avatar with cached image
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          backgroundImage: senderImage != null && senderImage.isNotEmpty
              ? CachedNetworkImageProvider(senderImage)
              : null,
          child: senderImage == null || senderImage.isEmpty
              ? Text(
                  _getInitials(senderName ?? ''),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Alexandria',
                  ),
                )
              : null,
        ),
        // Status badge (bottom right)
        if (statusBadge != null)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: statusBadge['color'] as Color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Icon(
                statusBadge['icon'] as IconData,
                size: 9,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  /// Get status badge info based on notification type
  Map<String, dynamic>? _getStatusBadge() {
    switch (notification.type) {
      case NotificationType.friendRequestAccepted:
        return {'icon': Icons.check, 'color': Colors.green};
      case NotificationType.friendRequestRejected:
        return {'icon': Icons.close, 'color': Colors.red};
      case NotificationType.eventResponse:
        final response = notification.data?['response']?.toString().toLowerCase() ??
                        notification.data?['status']?.toString().toLowerCase() ?? '';
        if (response.contains('accepted')) {
          return {'icon': Icons.check, 'color': Colors.green};
        } else if (response.contains('maybe')) {
          return {'icon': Icons.help_outline, 'color': Colors.orange};
        } else if (response.contains('declined')) {
          return {'icon': Icons.close, 'color': Colors.red};
        }
        return {'icon': Icons.event_available, 'color': Colors.green};
      case NotificationType.friendRequest:
        return {'icon': Icons.person_add, 'color': Colors.blue};
      case NotificationType.eventInvitation:
        return {'icon': Icons.event, 'color': Colors.orange};
      default:
        return null;
    }
  }

  /// Build rich text message with bold sender name
  Widget _buildRichTextMessage(BuildContext context, String? senderName, LocalizationService localization) {
    // For notifications with sender, show "Name action" format
    if (senderName != null && senderName.isNotEmpty) {
      final actionText = _getActionText(localization);
      
      return RichText(
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: AppStyles.bodySmall.copyWith(
            fontFamily: 'Alexandria',
            fontSize: 13,
            height: 1.3,
          ),
          children: [
            TextSpan(
              text: senderName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  // Navigate to user profile if available
                  final userId = notification.data?['senderId'] ?? 
                                notification.data?['sender']?['_id'] ??
                                notification.data?['fromUser']?['_id'];
                  if (userId != null) {
                    Navigator.pop(context);
                    AppRoutes.pushNamed(context, AppRoutes.friendProfile,
                      arguments: {'friendId': userId, 'popToHomeOnBack': true});
                  }
                },
            ),
            TextSpan(
              text: ' $actionText',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      );
    }
    
    // Item reserved: use translated title and message
    if (notification.type == NotificationType.itemReserved) {
      final title = localization.translate('notifications.itemReservedTitle') ?? notification.title;
      final message = localization.translate('notifications.someoneReservedGiftForYou') ?? notification.message;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: _getTitleColor(notification.type, data: notification.data),
              fontFamily: 'Alexandria',
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            message,
            style: AppStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontFamily: 'Alexandria',
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }
    
    // Fallback: show title and message
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          notification.title,
          style: AppStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: _getTitleColor(notification.type, data: notification.data),
            fontFamily: 'Alexandria',
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (notification.message.isNotEmpty && notification.message != notification.title) ...[
          const SizedBox(height: 2),
          Text(
            notification.message,
            style: AppStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontFamily: 'Alexandria',
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  /// Get action text based on notification type
  String _getActionText(LocalizationService localization) {
    switch (notification.type) {
      case NotificationType.friendRequest:
        return localization.translate('notifications.sentYouFriendRequest');
      case NotificationType.friendRequestAccepted:
        return localization.translate('notifications.acceptedYourFriendRequest');
      case NotificationType.friendRequestRejected:
        return localization.translate('notifications.declinedYourFriendRequest');
      case NotificationType.eventInvitation:
        final eventName = notification.data?['eventName'] ?? 
                         notification.data?['event']?['name'] ?? '';
        if (eventName.isNotEmpty) {
          return '${localization.translate('notifications.invitedYouTo')} $eventName';
        }
        return localization.translate('notifications.invitedYouToEvent');
      case NotificationType.eventResponse:
        final response = notification.data?['response']?.toString().toLowerCase() ??
                        notification.data?['status']?.toString().toLowerCase() ?? '';
        if (response.contains('accepted')) {
          return localization.translate('notifications.acceptedYourInvitation');
        } else if (response.contains('maybe')) {
          return localization.translate('notifications.maybeYourInvitation');
        } else if (response.contains('declined')) {
          return localization.translate('notifications.declinedYourInvitation');
        }
        return localization.translate('notifications.respondedToYourInvitation');
      default:
        return notification.message;
    }
  }

  /// Build compact friend request buttons (smaller for dropdown)
  Widget _buildCompactFriendRequestButtons(BuildContext context, LocalizationService localization) {
    return Row(
      children: [
        // Decline button - compact
        Expanded(
          child: SizedBox(
            height: 28,
            child: OutlinedButton(
              onPressed: onDecline,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 28),
                side: BorderSide(color: Colors.grey.shade300),
                shape: const StadiumBorder(),
              ),
              child: Text(
                localization.translate('dialogs.decline'),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  fontFamily: 'Alexandria',
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Accept button - compact
        Expanded(
          child: SizedBox(
            height: 28,
            child: ElevatedButton(
              onPressed: onAccept,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 28),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              child: Text(
                localization.translate('dialogs.accept'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  fontFamily: 'Alexandria',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build compact RSVP buttons for event invitations
  Widget _buildCompactRSVPButtons(BuildContext context, LocalizationService localization) {
    final eventId = notification.relatedId ?? 
                   notification.data?['eventId']?.toString() ??
                   notification.data?['event_id']?.toString() ??
                   notification.data?['event']?['_id']?.toString() ??
                   notification.data?['event']?['id']?.toString();
    
    if (eventId == null || eventId.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        // Decline - compact
        SizedBox(
          height: 26,
          child: OutlinedButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              cubit.deleteNotification(notification.id);
              Navigator.pop(context);
              try {
                await cubit.respondToEvent(eventId, 'declined');
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(localization.translate('notifications.youDeclinedInvitation')),
                    backgroundColor: AppColors.textSecondary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                await cubit.loadNotifications();
              }
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              minimumSize: const Size(0, 26),
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: Text(
              localization.translate('dialogs.decline'),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 10,
                fontFamily: 'Alexandria',
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        // Maybe - compact
        SizedBox(
          height: 26,
          child: OutlinedButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              cubit.deleteNotification(notification.id);
              Navigator.pop(context);
              try {
                await cubit.respondToEvent(eventId, 'maybe');
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(localization.translate('notifications.youMarkedMaybe')),
                    backgroundColor: AppColors.warning,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                await cubit.loadNotifications();
              }
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              minimumSize: const Size(0, 26),
              side: BorderSide(color: Colors.orange.shade300),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: Text(
              localization.translate('dialogs.maybe'),
              style: TextStyle(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 10,
                fontFamily: 'Alexandria',
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        // Accept - compact
        Expanded(
          child: SizedBox(
            height: 26,
            child: ElevatedButton(
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                cubit.deleteNotification(notification.id);
                Navigator.pop(context);
                try {
                  await cubit.respondToEvent(eventId, 'accepted');
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(localization.translate('notifications.youAcceptedInvitation')),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (e) {
                  await cubit.loadNotifications();
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                minimumSize: const Size(0, 26),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                elevation: 0,
              ),
              child: Text(
                localization.translate('dialogs.accept'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                  fontFamily: 'Alexandria',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Extract sender name from notification data
  String? _extractSenderName() {
    final data = notification.data;
    if (data == null) return null;
    
    // Try direct name fields first
    if (data['senderName'] is String) return data['senderName'] as String;
    if (data['responderName'] is String) return data['responderName'] as String;
    
    // Try relatedUser (from API response)
    final relatedUser = data['relatedUser'];
    if (relatedUser is Map<String, dynamic>) {
      if (relatedUser['fullName'] is String) return relatedUser['fullName'] as String;
      if (relatedUser['name'] is String) return relatedUser['name'] as String;
    }
    
    // Try sender
    final sender = data['sender'];
    if (sender is Map<String, dynamic>) {
      if (sender['fullName'] is String) return sender['fullName'] as String;
      if (sender['name'] is String) return sender['name'] as String;
    }
    
    // Try fromUser
    final fromUser = data['fromUser'];
    if (fromUser is Map<String, dynamic>) {
      if (fromUser['fullName'] is String) return fromUser['fullName'] as String;
      if (fromUser['name'] is String) return fromUser['name'] as String;
    }
    
    // Try responder
    final responder = data['responder'];
    if (responder is Map<String, dynamic>) {
      if (responder['fullName'] is String) return responder['fullName'] as String;
      if (responder['name'] is String) return responder['name'] as String;
    }
    
    // Try user
    final user = data['user'];
    if (user is Map<String, dynamic>) {
      if (user['fullName'] is String) return user['fullName'] as String;
      if (user['name'] is String) return user['name'] as String;
    }
    
    return null;
  }

  /// Extract sender profile image from notification data
  String? _extractSenderImage() {
    final data = notification.data;
    if (data == null) return null;
    
    // Try direct image fields first
    if (data['senderImage'] is String) return data['senderImage'] as String;
    if (data['senderProfileImage'] is String) return data['senderProfileImage'] as String;
    if (data['responderImage'] is String) return data['responderImage'] as String;
    
    // Try relatedUser (from API response)
    final relatedUser = data['relatedUser'];
    if (relatedUser is Map<String, dynamic>) {
      if (relatedUser['profileImage'] is String) return relatedUser['profileImage'] as String;
      if (relatedUser['profile_image'] is String) return relatedUser['profile_image'] as String;
    }
    
    // Try sender
    final sender = data['sender'];
    if (sender is Map<String, dynamic>) {
      if (sender['profileImage'] is String) return sender['profileImage'] as String;
      if (sender['profile_image'] is String) return sender['profile_image'] as String;
    }
    
    // Try fromUser
    final fromUser = data['fromUser'];
    if (fromUser is Map<String, dynamic>) {
      if (fromUser['profileImage'] is String) return fromUser['profileImage'] as String;
      if (fromUser['profile_image'] is String) return fromUser['profile_image'] as String;
    }
    
    // Try responder
    final responder = data['responder'];
    if (responder is Map<String, dynamic>) {
      if (responder['profileImage'] is String) return responder['profileImage'] as String;
      if (responder['profile_image'] is String) return responder['profile_image'] as String;
    }
    
    // Try user
    final user = data['user'];
    if (user is Map<String, dynamic>) {
      if (user['profileImage'] is String) return user['profileImage'] as String;
      if (user['profile_image'] is String) return user['profile_image'] as String;
    }
    
    return null;
  }

  /// Get initials from name
  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
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
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 18,
      ),
    );
  }

  /// Get icon data based on notification type
  IconData _getNotificationIcon(NotificationType type, {Map<String, dynamic>? data}) {
    final isItemReceived = data?['type']?.toString().toLowerCase() == 'item_received' ||
                          data?['notificationType']?.toString().toLowerCase() == 'item_received';
    
    switch (type) {
      case NotificationType.eventInvitation:
        return Icons.event;
      case NotificationType.eventResponse:
        return Icons.event_available;
      case NotificationType.eventUpdate:
        return Icons.edit_calendar;
      case NotificationType.eventReminder:
        return Icons.calendar_today;
      case NotificationType.friendRequest:
        return Icons.person_add;
      case NotificationType.friendRequestAccepted:
        return Icons.how_to_reg;
      case NotificationType.friendRequestRejected:
        return Icons.person_remove;
      case NotificationType.itemReserved:
        return Icons.visibility_off;
      case NotificationType.itemPurchased:
        if (isItemReceived) {
          return Icons.check_circle_outline;
        }
        return Icons.card_giftcard;
      case NotificationType.itemUnreserved:
        return Icons.lock_open;
      case NotificationType.wishlistShared:
        return Icons.share_outlined;
      case NotificationType.reservationExpired:
        return Icons.event_busy;
      case NotificationType.reservationReminder:
        return Icons.schedule;
      default:
        return Icons.notifications_outlined;
    }
  }

  /// Get icon color based on notification type
  Color _getIconColor(NotificationType type, {Map<String, dynamic>? data}) {
    final isItemReceived = data?['type']?.toString().toLowerCase() == 'item_received' ||
                          data?['notificationType']?.toString().toLowerCase() == 'item_received';
    
    switch (type) {
      case NotificationType.eventInvitation:
        return Colors.orange;
      case NotificationType.eventResponse:
        return Colors.green;
      case NotificationType.eventUpdate:
        return Colors.amber;
      case NotificationType.eventReminder:
        return Colors.orange;
      case NotificationType.friendRequest:
        return Colors.blue;
      case NotificationType.friendRequestAccepted:
        return Colors.green;
      case NotificationType.friendRequestRejected:
        return Colors.red;
      case NotificationType.itemReserved:
        return Colors.deepPurple;
      case NotificationType.itemPurchased:
        if (isItemReceived) {
          return Colors.teal;
        }
        return Colors.purple;
      case NotificationType.itemUnreserved:
        return Colors.grey;
      case NotificationType.wishlistShared:
        return AppColors.primary;
      case NotificationType.reservationExpired:
        return Colors.grey;
      case NotificationType.reservationReminder:
        return Colors.amber;
      default:
        return AppColors.textSecondary;
    }
  }

  /// Get title color based on notification type
  Color _getTitleColor(NotificationType type, {Map<String, dynamic>? data}) {
    final isItemReceived = data?['type']?.toString().toLowerCase() == 'item_received' ||
                          data?['notificationType']?.toString().toLowerCase() == 'item_received';
    
    if (type == NotificationType.eventResponse) {
      return Colors.green.shade700;
    }
    
    if (type == NotificationType.itemPurchased && isItemReceived) {
      return Colors.teal.shade700;
    }
    
    return AppColors.textPrimary;
  }

}

/// Animated shimmer item for loading state
class _ShimmerItem extends StatefulWidget {
  const _ShimmerItem();

  @override
  State<_ShimmerItem> createState() => _ShimmerItemState();
}

class _ShimmerItemState extends State<_ShimmerItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar shimmer with animation
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200.withOpacity(_animation.value),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 12),
              // Text shimmer with animation
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title shimmer
                    Container(
                      height: 14,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200.withOpacity(_animation.value),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Message shimmer
                    Container(
                      height: 12,
                      width: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200.withOpacity(_animation.value),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Time shimmer
                    Container(
                      height: 10,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200.withOpacity(_animation.value),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

