import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/widgets/animated_background.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:wish_listy/features/notifications/data/models/notification_model.dart';
import 'package:wish_listy/features/friends/data/repository/friends_repository.dart';

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
                    child: const Text('Retry'),
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
                                  color: AppColors.info,
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Today Section
                                        if (todayNotifications.isNotEmpty) ...[
                                          _buildSectionHeader('Today'),
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
                                          _buildSectionHeader('Earlier'),
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
                  'Notifications',
                  style: AppStyles.headingSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (unreadCount > 0)
                  Text(
                    '$unreadCount unread notifications',
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
                'Mark all read',
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
          onTap: () => _handleNotificationTap(notification),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getNotificationColor(
                      notification.type,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: _getNotificationColor(notification.type),
                    size: 24,
                  ),
                ),

                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: AppStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: notification.isRead
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
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
                        notification.message,
                        style: AppStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Time ago
                      Text(
                        notification.timeAgo,
                        style: AppStyles.caption.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Action Buttons for friend requests
                      if (_hasActions(notification.type))
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
  }

  Widget _buildActionButtons(AppNotification notification) {
    switch (notification.type) {
      case NotificationType.friendRequest:
        return Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Reject',
                () => _handleFriendRequestAction(notification, false),
                isOutlined: true,
                color: AppColors.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Accept',
                () => _handleFriendRequestAction(notification, true),
                color: AppColors.success,
              ),
            ),
          ],
        );

      case NotificationType.eventInvitation:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionButton(
              'Maybe',
              () => _handleEventInvitationAction(notification, 'maybe'),
              isOutlined: true,
            ),
            const SizedBox(width: 8),
            _buildActionButton(
              'Accept',
              () => _handleEventInvitationAction(notification, 'accept'),
              color: AppColors.accent,
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
            'No Notifications',
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

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.friendRequest:
        return AppColors.secondary;
      case NotificationType.friendRequestAccepted:
        return AppColors.success;
      case NotificationType.eventInvitation:
        return AppColors.accent;
      case NotificationType.eventReminder:
        return AppColors.warning;
      case NotificationType.itemPurchased:
        return AppColors.success;
      case NotificationType.itemReserved:
        return AppColors.info;
      case NotificationType.wishlistShared:
        return AppColors.primary;
      case NotificationType.general:
        return AppColors.info;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.friendRequest:
        return Icons.person_add_outlined;
      case NotificationType.friendRequestAccepted:
        return Icons.person_add_alt_1_outlined;
      case NotificationType.eventInvitation:
        return Icons.celebration_outlined;
      case NotificationType.eventReminder:
        return Icons.event_outlined;
      case NotificationType.itemPurchased:
        return Icons.shopping_bag_outlined;
      case NotificationType.itemReserved:
        return Icons.bookmark_outline;
      case NotificationType.wishlistShared:
        return Icons.share_outlined;
      case NotificationType.general:
        return Icons.notifications_outlined;
    }
  }

  bool _hasActions(NotificationType type) {
    return type == NotificationType.friendRequest ||
        type == NotificationType.eventInvitation;
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
    if (!notification.isRead) {
      context.read<NotificationsCubit>().markAsRead(notification.id);
    }

    // Navigate based on notification type
    switch (notification.type) {
      case NotificationType.friendRequest:
        // Navigate to friend profile or friends screen
        break;
      case NotificationType.eventInvitation:
        // Navigate to event details
        break;
      case NotificationType.itemPurchased:
      case NotificationType.itemReserved:
        // Navigate to wishlist
        break;
      case NotificationType.wishlistShared:
        // Navigate to shared wishlist
        break;
      default:
        break;
    }
  }

  Future<void> _handleFriendRequestAction(AppNotification notification, bool accept) async {
    // Extract requestId from notification data
    // The notification data can have requestId, _id, or the notification id itself
    final requestId = notification.data?['requestId'] ?? 
                      notification.data?['_id'] ?? 
                      notification.id;
    
    if (requestId == null || requestId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Unable to process friend request. Request ID not found.'),
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
      
      // Mark notification as read
      context.read<NotificationsCubit>().markAsRead(notification.id);
      
      // Reload notifications to update the list
      context.read<NotificationsCubit>().loadNotifications();
      
      final message = accept
          ? 'Friend request accepted!'
          : 'Friend request declined';

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
                        ? 'Failed to accept friend request. Please try again.'
                        : 'Failed to decline friend request. Please try again.',
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

  void _handleEventInvitationAction(
    AppNotification notification,
    String action,
  ) {
    context.read<NotificationsCubit>().markAsRead(notification.id);

    final message = action == 'accept'
        ? 'Event invitation accepted!'
        : 'Marked as maybe';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.event, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _markAllAsRead() {
    context.read<NotificationsCubit>().markAllAsRead();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.done_all, color: Colors.white),
            const SizedBox(width: 8),
            Text('All notifications marked as read'),
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
