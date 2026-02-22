import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:wish_listy/features/notifications/data/models/notification_model.dart';
import 'package:wish_listy/features/notifications/presentation/widgets/friend_request_tile.dart';
import 'package:wish_listy/features/notifications/presentation/widgets/friend_request_accepted_tile.dart';
import 'package:wish_listy/features/notifications/presentation/widgets/friend_request_rejected_tile.dart';
import 'package:wish_listy/features/notifications/presentation/widgets/event_response_tile.dart';
import 'package:wish_listy/features/friends/data/repository/friends_repository.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:provider/provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    // Load notifications when screen appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsCubit>().loadNotifications();
    });
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
          ),
        );
  }

  void _startAnimations() {
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, state) {
        if (state is NotificationsLoading) {
          return Scaffold(
            backgroundColor: Colors.grey.shade50,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state is NotificationsError) {
          return Scaffold(
            backgroundColor: Colors.grey.shade50,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<NotificationsCubit>().loadNotifications(),
                    child: Text(Provider.of<LocalizationService>(context, listen: false).translate('dialogs.retry')),
                  ),
                ],
              ),
            ),
          );
        }

        final notifications = state is NotificationsLoaded
            ? state.notifications
            : <AppNotification>[];
        final unreadCount = state is NotificationsLoaded
            ? state.unreadCount
            : 0;

        final todayNotifications = _getNotificationsForToday(notifications);
        final earlierNotifications = _getEarlierNotifications(notifications);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Stack(
        children: [
          // Content
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(unreadCount),

                // Notifications List
                Expanded(
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                              child: notifications.isEmpty
                              ? _buildEmptyState()
                              : RefreshIndicator(
                                  onRefresh: _refreshNotifications,
                                  color: AppColors.primary,
                                  child: SingleChildScrollView(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Today Section
                                        if (todayNotifications.isNotEmpty) ...[
                                          _buildSectionHeader(Provider.of<LocalizationService>(context, listen: false).translate('notifications.today')),
                                          const SizedBox(height: 12),
                                          ...todayNotifications.map(
                                            (notification) =>
                                                _buildNotificationCard(
                                                  notification,
                                                ),
                                          ),
                                          const SizedBox(height: 24),
                                        ],

                                        // Earlier Section
                                        if (earlierNotifications
                                            .isNotEmpty) ...[
                                          _buildSectionHeader(Provider.of<LocalizationService>(context, listen: false).translate('notifications.earlier')),
                                          const SizedBox(height: 12),
                                          ...earlierNotifications.map(
                                            (notification) =>
                                                _buildNotificationCard(
                                                  notification,
                                                ),
                                          ),
                                        ],

                                        const SizedBox(
                                          height: 100,
                                        ), // Bottom padding
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                      );
                    },
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

  Widget _buildHeader(int unreadCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: AppColors.textTertiary.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceVariant,
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Provider.of<LocalizationService>(context, listen: false).translate('app.notifications'),
                  style: AppStyles.headingSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (unreadCount > 0)
                  Text(
                    Provider.of<LocalizationService>(context, listen: false).translate('notifications.unreadNotifications').replaceAll('{count}', unreadCount.toString()),
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.info,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),

          // Mark All Read Button
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                Provider.of<LocalizationService>(context, listen: false).translate('notifications.markAllAsRead'),
                style: AppStyles.bodySmall.copyWith(
                  color: AppColors.info,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: AppStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notification) {
    // Special design for friend request notifications
    if (notification.type == NotificationType.friendRequest) {
      return _buildFriendRequestCard(notification);
    }

    // Special design for friend request accepted notifications
    if (notification.type == NotificationType.friendRequestAccepted) {
      return _buildFriendRequestAcceptedCard(notification);
    }

    // Special design for friend request rejected notifications
    if (notification.type == NotificationType.friendRequestRejected) {
      return _buildFriendRequestRejectedCard(notification);
    }

    // Special design for event invitation response notifications
    if (notification.type == NotificationType.eventInvitation) {
      // Check if this is a response notification (accepted, declined, maybe)
      final notificationTypeString = notification.data?['type']?.toString() ?? 
                                    notification.data?['notificationType']?.toString() ??
                                    notification.title.toLowerCase();
      
      if (notificationTypeString.contains('accepted') || 
          notificationTypeString.contains('declined') || 
          notificationTypeString.contains('maybe')) {
        return _buildEventResponseCard(notification);
      }
    }

    // Default design for other notification types
    return Builder(
      builder: (context) {
        final localization = Provider.of<LocalizationService>(context, listen: false);
        final displayTitle = notification.getLocalizedTitle(localization);
        final displayMessage = notification.message;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: notification.isRead
                  ? Colors.transparent
                  : AppColors.info.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.textTertiary.withOpacity(0.1),
                offset: const Offset(0, 2),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                context.read<NotificationsCubit>().handleNotificationTap(notification, context);
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLeadingIcon(notification.type, data: notification.data),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  displayTitle,
                                  style: AppStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: _getTitleColor(notification.type, data: notification.data),
                                  ),
                                ),
                              ),
                              if (!notification.isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppColors.info,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            displayMessage,
                            style: AppStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            notification.timeAgo,
                            style: AppStyles.caption.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                          if (notification.type == NotificationType.eventInvitation) ...[
                            const SizedBox(height: 8),
                            Builder(
                              builder: (context) {
                                final eventId = notification.relatedId ??
                                    notification.data?['eventId']?.toString() ??
                                    notification.data?['event_id']?.toString() ??
                                    notification.data?['event']?['_id']?.toString() ??
                                    notification.data?['event']?['id']?.toString();
                                if (eventId != null && eventId.isNotEmpty) {
                                  final notificationWithId = notification.copyWith(relatedId: eventId);
                                  return _buildRSVPButtons(notificationWithId, context.read<NotificationsCubit>());
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ],
                          const SizedBox(height: 8),
                          if (_hasActions(notification.type) &&
                              notification.type != NotificationType.eventInvitation)
                            _buildActionButtons(notification),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build specialized friend request notification card
  Widget _buildFriendRequestCard(AppNotification notification) {
    // Extract sender information from notification data
    // Priority: relatedUser object (new API structure)
    String? senderId;
    String? senderName;
    String? senderImage;

    // Check for relatedUser object (new API structure)
    if (notification.data?['relatedUser'] != null && 
        notification.data!['relatedUser'] is Map<String, dynamic>) {
      final relatedUser = notification.data!['relatedUser'] as Map<String, dynamic>;
      senderId = relatedUser['_id']?.toString() ?? 
                relatedUser['id']?.toString();
      senderName = relatedUser['fullName']?.toString();
      senderImage = relatedUser['profileImage']?.toString();
    }

    // Fallback to old structure if relatedUser not found
    if (senderId == null || senderId.isEmpty) {
      senderId = notification.data?['senderId'] ?? 
                  notification.data?['sender_id'] ?? 
                  notification.data?['fromUserId'] ?? 
                  notification.data?['from_user_id'] ?? 
                  notification.userId;
    }

    if (senderName == null || senderName.isEmpty) {
      senderName = notification.data?['senderName'] ?? 
                   notification.data?['sender_name'] ?? 
                   notification.data?['fromUserName'] ?? 
                   notification.data?['from_user_name'] ?? 
                   notification.title.split(' ').first; // Fallback: first word of title
    }

    if (senderImage == null || senderImage.isEmpty) {
      senderImage = notification.data?['senderImage'] ?? 
                   notification.data?['sender_image'] ?? 
                   notification.data?['fromUserImage'] ?? 
                   notification.data?['from_user_image'];
    }

    // Use the custom FriendRequestTile widget
    return FriendRequestTile(
      senderName: senderName ?? 'Unknown',
      senderImage: senderImage,
      timeAgo: notification.timeAgo,
      onAccept: () => _handleFriendRequestAction(notification, true),
      onDecline: () => _handleFriendRequestAction(notification, false),
      onProfileTap: () => _navigateToProfile(senderId, popToHomeOnBack: true),
    );
  }

  /// Build specialized friend request accepted notification card
  Widget _buildFriendRequestAcceptedCard(AppNotification notification) {
    // Extract friend information from notification data
    // Priority: relatedUser object (new API structure)
    String? friendId;
    String? friendName;
    String? friendImage;

    // Check for relatedUser object (new API structure)
    if (notification.data?['relatedUser'] != null && 
        notification.data!['relatedUser'] is Map<String, dynamic>) {
      final relatedUser = notification.data!['relatedUser'] as Map<String, dynamic>;
      friendId = relatedUser['_id']?.toString() ?? 
                relatedUser['id']?.toString();
      friendName = relatedUser['fullName']?.toString();
      friendImage = relatedUser['profileImage']?.toString();
    }

    // Fallback to old structure if relatedUser not found
    if (friendId == null || friendId.isEmpty) {
      friendId = notification.data?['friendId'] ?? 
                  notification.data?['friend_id'] ?? 
                  notification.data?['userId'] ?? 
                  notification.userId;
    }

    if (friendName == null || friendName.isEmpty) {
      // Try to extract from message (e.g., "amrr accepted your friend request")
      final message = notification.message;
      if (message.isNotEmpty) {
        final parts = message.split(' ');
        if (parts.isNotEmpty) {
          friendName = parts[0]; // First word is usually the name
        }
      }
      
      // Final fallback
      if (friendName == null || friendName.isEmpty) {
        friendName = notification.data?['friendName'] ?? 
                     notification.data?['friend_name'] ?? 
                     notification.title.split(' ').first;
      }
    }

    if (friendImage == null || friendImage.isEmpty) {
      friendImage = notification.data?['friendImage'] ?? 
                   notification.data?['friend_image'] ?? 
                   notification.data?['profileImage'] ?? 
                   notification.data?['profile_image'];
    }

    // Use the custom FriendRequestAcceptedTile widget
    return FriendRequestAcceptedTile(
      friendName: friendName ?? 'Unknown',
      friendImage: friendImage,
      timeAgo: notification.timeAgo,
      onProfileTap: () => _navigateToProfile(friendId, popToHomeOnBack: true),
    );
  }

  /// Build specialized friend request rejected notification card
  Widget _buildFriendRequestRejectedCard(AppNotification notification) {
    // Extract friend information from notification data
    // Priority: relatedUser object (new API structure)
    String? friendId;
    String? friendName;
    String? friendImage;

    // Check for relatedUser object (new API structure)
    if (notification.data?['relatedUser'] != null && 
        notification.data!['relatedUser'] is Map<String, dynamic>) {
      final relatedUser = notification.data!['relatedUser'] as Map<String, dynamic>;
      friendId = relatedUser['_id']?.toString() ?? 
                relatedUser['id']?.toString();
      friendName = relatedUser['fullName']?.toString();
      friendImage = relatedUser['profileImage']?.toString();
    }

    // Fallback to old structure if relatedUser not found
    if (friendId == null || friendId.isEmpty) {
      friendId = notification.data?['friendId'] ?? 
                  notification.data?['friend_id'] ?? 
                  notification.data?['userId'] ?? 
                  notification.userId;
    }

    if (friendName == null || friendName.isEmpty) {
      // Try to extract from message (e.g., "amrr declined your friend request")
      final message = notification.message;
      if (message.isNotEmpty) {
        final parts = message.split(' ');
        if (parts.isNotEmpty) {
          friendName = parts[0]; // First word is usually the name
        }
      }
      
      // Final fallback
      if (friendName == null || friendName.isEmpty) {
        friendName = notification.data?['friendName'] ?? 
                     notification.data?['friend_name'] ?? 
                     notification.title.split(' ').first;
      }
    }

    if (friendImage == null || friendImage.isEmpty) {
      friendImage = notification.data?['friendImage'] ?? 
                   notification.data?['friend_image'] ?? 
                   notification.data?['profileImage'] ?? 
                   notification.data?['profile_image'];
    }

    // Use the custom FriendRequestRejectedTile widget
    return FriendRequestRejectedTile(
      friendName: friendName ?? 'Unknown',
      friendImage: friendImage,
      timeAgo: notification.timeAgo,
      onProfileTap: () => _navigateToProfile(friendId),
    );
  }

  /// Build specialized event response notification card
  Widget _buildEventResponseCard(AppNotification notification) {
    // Extract responder information from notification data
    String? responderId;
    String? responderName;
    String? responderImage;
    String? eventName;
    String? eventId;
    String? notificationTypeString;

    // Check for relatedUser object (new API structure)
    if (notification.data?['relatedUser'] != null && 
        notification.data!['relatedUser'] is Map<String, dynamic>) {
      final relatedUser = notification.data!['relatedUser'] as Map<String, dynamic>;
      responderId = relatedUser['_id']?.toString() ?? 
                   relatedUser['id']?.toString();
      responderName = relatedUser['fullName']?.toString();
      responderImage = relatedUser['profileImage']?.toString();
    }

    // Fallback to old structure if relatedUser not found
    if (responderId == null || responderId.isEmpty) {
      responderId = notification.data?['responderId'] ?? 
                     notification.data?['responder_id'] ?? 
                     notification.data?['userId'] ?? 
                     notification.userId;
    }

    if (responderName == null || responderName.isEmpty) {
      // Try to extract from message (e.g., "amrr is going to Event Name")
      final message = notification.message;
      if (message.isNotEmpty) {
        final parts = message.split(' ');
        if (parts.isNotEmpty) {
          responderName = parts[0]; // First word is usually the name
        }
      }
      
      // Final fallback
      if (responderName == null || responderName.isEmpty) {
        responderName = notification.data?['responderName'] ?? 
                        notification.data?['responder_name'] ?? 
                        notification.title.split(' ').first;
      }
    }

    if (responderImage == null || responderImage.isEmpty) {
      responderImage = notification.data?['responderImage'] ?? 
                      notification.data?['responder_image'] ?? 
                      notification.data?['profileImage'] ?? 
                      notification.data?['profile_image'];
    }

    // Extract event name and ID
    eventName = notification.data?['eventName'] ?? 
               notification.data?['event_name'] ?? 
               notification.data?['event']?['name']?.toString() ??
               notification.title.split(' ').last; // Fallback: last word of title
    
    // Try to extract from message if not found
    if (eventName == null || eventName.isEmpty || eventName == responderName) {
      final message = notification.message;
      // Try to find event name in message (usually after "to" or "in")
      if (message.contains(' to ')) {
        final parts = message.split(' to ');
        if (parts.length > 1) {
          eventName = parts[1].replaceAll('.', '').trim();
        }
      } else if (message.contains(' in ')) {
        final parts = message.split(' in ');
        if (parts.length > 1) {
          eventName = parts[1].replaceAll('.', '').trim();
        }
      }
    }

    eventId = notification.data?['eventId'] ?? 
             notification.data?['event_id'] ?? 
             notification.data?['event']?['_id']?.toString() ??
             notification.data?['event']?['id']?.toString();

    // Determine notification type from data or message
    notificationTypeString = notification.data?['type']?.toString() ?? 
                            notification.data?['notificationType']?.toString() ??
                            notification.data?['responseType']?.toString();
    
    // Fallback: parse from message
    if (notificationTypeString == null || notificationTypeString.isEmpty) {
      final message = notification.message.toLowerCase();
      if (message.contains('accepted') || message.contains('going')) {
        notificationTypeString = 'event_invitation_accepted';
      } else if (message.contains('declined') || message.contains('rejected')) {
        notificationTypeString = 'event_invitation_declined';
      } else if (message.contains('maybe') || message.contains('interested')) {
        notificationTypeString = 'event_invitation_maybe';
      } else {
        notificationTypeString = 'event_invitation_accepted'; // Default
      }
    }

    // Use the custom EventResponseTile widget
    return EventResponseTile(
      notificationType: notificationTypeString,
      responderName: responderName ?? 'Someone',
      responderImage: responderImage,
      eventName: eventName ?? 'Event',
      timeAgo: notification.timeAgo,
      onProfileTap: () => _navigateToProfile(responderId),
      onEventTap: eventId != null && eventId.isNotEmpty
          ? () {
              Navigator.pushNamed(
                context,
                AppRoutes.eventDetails,
                arguments: {'eventId': eventId},
              );
            }
          : null,
    );
  }

  /// Navigate to friend profile.
  /// [popToHomeOnBack] when true, back button on profile returns to Home (used when opened from friend-request notification).
  void _navigateToProfile(String? friendId, {bool popToHomeOnBack = false}) {
    if (friendId == null || friendId.isEmpty) return;
    
    Navigator.pushNamed(
      context,
      AppRoutes.friendProfile,
      arguments: {'friendId': friendId, 'popToHomeOnBack': popToHomeOnBack},
    );
  }

  Widget _buildActionButtons(AppNotification notification) {
    switch (notification.type) {
      case NotificationType.friendRequest:
        final localization = Provider.of<LocalizationService>(context, listen: false);
        return Row(
          children: [
            Expanded(
              child: _buildActionButton(
                localization.translate('dialogs.decline'),
                () => _handleFriendRequestAction(notification, false),
                isOutlined: true,
                color: AppColors.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                localization.translate('dialogs.accept'),
                () => _handleFriendRequestAction(notification, true),
                color: AppColors.success,
              ),
            ),
          ],
        );

      default:
        return const SizedBox();
    }
  }

  Widget _buildActionButton(
    String text,
    VoidCallback onPressed, {
    Color? color,
    bool isOutlined = false,
  }) {
    return SizedBox(
      height: 40,
      child: isOutlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: color ?? AppColors.error,
                side: BorderSide(
                  color: (color ?? AppColors.error).withOpacity(0.5),
                  width: 1.5,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                text,
                style: AppStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color ?? AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                text,
                style: AppStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
    );
  }

  /// Build RSVP buttons for event invitation notifications
  Widget _buildRSVPButtons(AppNotification notification, NotificationsCubit cubit) {
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
            const SizedBox(height: 8),
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
                              try {
                                final eventId = notification.relatedId ?? 
                                               notification.data?['eventId']?.toString() ??
                                               notification.data?['event_id']?.toString() ??
                                               notification.data?['event']?['_id']?.toString() ??
                                               notification.data?['event']?['id']?.toString();
                                if (eventId == null || eventId.isEmpty) {
                                  throw Exception('Event ID not found');
                                }
                                await cubit.respondToEvent(eventId, 'declined');
                                if (mounted) {
                                  context
                                      .read<NotificationsCubit>()
                                      .deleteNotification(notification.id);
                                }
                                if (mounted) {
                                  setState(() {
                                    isLoading = false;
                                    selectedStatus = 'declined';
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(Provider.of<LocalizationService>(context, listen: false).translate('notifications.youDeclinedInvitation')),
                                      backgroundColor: AppColors.textSecondary,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  setState(() {
                                    isLoading = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to respond: ${e.toString()}'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
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
                              try {
                                final eventId = notification.relatedId ?? 
                                               notification.data?['eventId']?.toString() ??
                                               notification.data?['event_id']?.toString() ??
                                               notification.data?['event']?['_id']?.toString() ??
                                               notification.data?['event']?['id']?.toString();
                                if (eventId == null || eventId.isEmpty) {
                                  throw Exception('Event ID not found');
                                }
                                await cubit.respondToEvent(eventId, 'maybe');
                                if (mounted) {
                                  context
                                      .read<NotificationsCubit>()
                                      .deleteNotification(notification.id);
                                }
                                if (mounted) {
                                  setState(() {
                                    isLoading = false;
                                    selectedStatus = 'maybe';
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(Provider.of<LocalizationService>(context, listen: false).translate('notifications.youMarkedMaybe')),
                                      backgroundColor: AppColors.warning,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  setState(() {
                                    isLoading = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to respond: ${e.toString()}'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
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
                              try {
                                final eventId = notification.relatedId ?? 
                                               notification.data?['eventId']?.toString() ??
                                               notification.data?['event_id']?.toString() ??
                                               notification.data?['event']?['_id']?.toString() ??
                                               notification.data?['event']?['id']?.toString();
                                if (eventId == null || eventId.isEmpty) {
                                  throw Exception('Event ID not found');
                                }
                                await cubit.respondToEvent(eventId, 'accepted');
                                if (mounted) {
                                  context
                                      .read<NotificationsCubit>()
                                      .deleteNotification(notification.id);
                                }
                                if (mounted) {
                                  setState(() {
                                    isLoading = false;
                                    selectedStatus = 'accepted';
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(Provider.of<LocalizationService>(context, listen: false).translate('notifications.youAcceptedInvitation')),
                                      backgroundColor: AppColors.success,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  setState(() {
                                    isLoading = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to respond: ${e.toString()}'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
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

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.notifications_outlined,
              size: 60,
              color: AppColors.info,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            Provider.of<LocalizationService>(context, listen: false).translate('notifications.noNotifications'),
            style: AppStyles.headingMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'When you have notifications, they\'ll appear here to keep you updated on your wishlists and friends\' activities.',
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper Methods
  List<AppNotification> _getNotificationsForToday(List<AppNotification> notifications) {
    final today = DateTime.now();
    return notifications.where((notification) {
      return notification.createdAt.year == today.year &&
          notification.createdAt.month == today.month &&
          notification.createdAt.day == today.day;
    }).toList();
  }

  List<AppNotification> _getEarlierNotifications(List<AppNotification> notifications) {
    final today = DateTime.now();
    return notifications.where((notification) {
      return !(notification.createdAt.year == today.year &&
          notification.createdAt.month == today.month &&
          notification.createdAt.day == today.day);
    }).toList();
  }

  /// Build leading icon with color based on notification type
  Widget _buildLeadingIcon(NotificationType type, {Map<String, dynamic>? data}) {
    final iconData = _getNotificationIcon(type, data: data);
    final iconColor = _getNotificationColor(type, data: data);
    
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  Color _getNotificationColor(NotificationType type, {Map<String, dynamic>? data}) {
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
      case NotificationType.reservationExpired:
      case NotificationType.reservationCancelled:
        return Colors.grey;
      case NotificationType.reservationReminder:
        return Colors.amber;
      case NotificationType.general:
        return AppColors.info;
    }
  }

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
      case NotificationType.reservationExpired:
      case NotificationType.reservationCancelled:
        return Icons.event_busy;
      case NotificationType.reservationReminder:
        return Icons.schedule;
      case NotificationType.general:
        return Icons.notifications_outlined;
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

  bool _hasActions(NotificationType type) {
    // Event invitations now use RSVP buttons, not action buttons
    return type == NotificationType.friendRequest;
  }

  String _formatNotificationTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  // Action Handlers
  void _handleNotificationTap(AppNotification notification) {
    // Use the cubit's handleNotificationTap method for smart navigation
    context.read<NotificationsCubit>().handleNotificationTap(notification, context);
  }

  Future<void> _handleFriendRequestAction(AppNotification notification, bool accept) async {
    // Extract requestId from notification data
    // Try multiple possible field names: relatedId, requestId, request_id, id, _id
    final requestId = notification.data?['relatedId'] ??
                      notification.data?['related_id'] ??
                      notification.data?['requestId'] ?? 
                      notification.data?['request_id'] ??
                      notification.data?['id'] ??
                      notification.data?['_id'] ??
                      notification.id;
    
    if (requestId == null || requestId.toString().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text(Provider.of<LocalizationService>(context, listen: false).translate('dialogs.unableToProcessFriendRequest')),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
      return;
    }
    
    try {
      final friendsRepository = FriendsRepository();
      
      if (accept) {
        await friendsRepository.acceptFriendRequest(requestId: requestId);
      } else {
        await friendsRepository.rejectFriendRequest(requestId: requestId);
      }
      
      if (!mounted) return;

      // Delete notification after action (Accept/Decline)
      final notificationsCubit = context.read<NotificationsCubit>();
      notificationsCubit.deleteNotification(notification.id);
      notificationsCubit.loadNotifications();
      notificationsCubit.getUnreadCount();

      final localization = Provider.of<LocalizationService>(context, listen: false);
      final message = accept
          ? localization.translate('notifications.friendRequestAccepted')
          : localization.translate('notifications.friendRequestDeclined');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                accept ? Icons.check_circle : Icons.cancel,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(message),
            ],
          ),
          backgroundColor: accept ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(e.message),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    accept
                        ? Provider.of<LocalizationService>(context, listen: false).translate('notifications.failedToAcceptRequest')
                        : Provider.of<LocalizationService>(context, listen: false).translate('notifications.failedToDeclineRequest'),
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

  // Removed _handleEventInvitationAction - now using cubit.respondToEvent directly in RSVP buttons

  void _markAllAsRead() {
    context.read<NotificationsCubit>().markAllAsRead();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.done_all, color: Colors.white),
            const SizedBox(width: 8),
            Text(Provider.of<LocalizationService>(context, listen: false).translate('dialogs.allNotificationsMarkedAsRead')),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _refreshNotifications() async {
    await context.read<NotificationsCubit>().loadNotifications();
  }
}
