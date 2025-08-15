


import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../utils/app_routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/animated_background.dart';

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Mock notifications data
  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: '1',
      type: NotificationType.friendRequest,
      title: 'New Friend Request',
      message: 'Sarah Johnson wants to be your friend',
      time: DateTime.now().subtract(Duration(minutes: 30)),
      isRead: false,
      actionData: {'userId': 'sarah123'},
    ),
    NotificationItem(
      id: '2',
      type: NotificationType.itemPurchased,
      title: 'Item Purchased',
      message: 'Someone bought the "Wireless Headphones" from your wishlist',
      time: DateTime.now().subtract(Duration(hours: 2)),
      isRead: false,
    ),
    NotificationItem(
      id: '3',
      type: NotificationType.eventInvitation,
      title: 'Event Invitation',
      message: 'Ahmed invited you to his Birthday Party on Dec 15',
      time: DateTime.now().subtract(Duration(hours: 5)),
      isRead: true,
      actionData: {'eventId': 'event123'},
    ),
    NotificationItem(
      id: '4',
      type: NotificationType.eventReminder,
      title: 'Event Reminder',
      message: 'Emma\'s Birthday is tomorrow! Don\'t forget to get a gift.',
      time: DateTime.now().subtract(Duration(days: 1)),
      isRead: true,
    ),
    NotificationItem(
      id: '5',
      type: NotificationType.friendRequestAccepted,
      title: 'Friend Request Accepted',
      message: 'Mike Thompson accepted your friend request',
      time: DateTime.now().subtract(Duration(days: 2)),
      isRead: true,
    ),
    NotificationItem(
      id: '6',
      type: NotificationType.wishlistShared,
      title: 'Wishlist Shared',
      message: 'Lisa shared her Christmas Wishlist with you',
      time: DateTime.now().subtract(Duration(days: 3)),
      isRead: true,
      actionData: {'wishlistId': 'wishlist456'},
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));
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
    final unreadCount = _notifications.where((n) => !n.isRead).length;
    final todayNotifications = _getNotificationsForToday();
    final earlierNotifications = _getEarlierNotifications();

    return Scaffold(
      body: Stack(
        children: [
          // Animated Background
          AnimatedBackground(
            colors: [
              AppColors.background,
              AppColors.info.withOpacity(0.02),
              AppColors.primary.withOpacity(0.01),
            ],
          ),
          
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
                          child: _notifications.isEmpty
                              ? _buildEmptyState()
                              : RefreshIndicator(
                                  onRefresh: _refreshNotifications,
                                  color: AppColors.info,
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Today Section
                                        if (todayNotifications.isNotEmpty) ...[
                                          _buildSectionHeader('Today'),
                                          const SizedBox(height: 12),
                                          ...todayNotifications.map(
                                            (notification) => _buildNotificationCard(notification),
                                          ),
                                          const SizedBox(height: 24),
                                        ],
                                        
                                        // Earlier Section
                                        if (earlierNotifications.isNotEmpty) ...[
                                          _buildSectionHeader('Earlier'),
                                          const SizedBox(height: 12),
                                          ...earlierNotifications.map(
                                            (notification) => _buildNotificationCard(notification),
                                          ),
                                        ],
                                        
                                        const SizedBox(height: 100), // Bottom padding
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
          
          // Settings Button
          IconButton(
            onPressed: _openNotificationSettings,
            icon: const Icon(Icons.settings_outlined),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceVariant,
              padding: const EdgeInsets.all(12),
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

  Widget _buildNotificationCard(NotificationItem notification) {
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
                    color: _getNotificationColor(notification.type).withOpacity(0.1),
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
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatNotificationTime(notification.time),
                            style: AppStyles.caption.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                          
                          // Action Buttons
                          if (_hasActions(notification.type))
                            _buildActionButtons(notification),
                        ],
                      ),
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

  Widget _buildActionButtons(NotificationItem notification) {
    switch (notification.type) {
      case NotificationType.friendRequest:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionButton(
              'Decline',
              () => _handleFriendRequestAction(notification, false),
              isOutlined: true,
            ),
            const SizedBox(width: 8),
            _buildActionButton(
              'Accept',
              () => _handleFriendRequestAction(notification, true),
              color: AppColors.success,
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
      height: 28,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: isOutlined 
              ? Colors.transparent 
              : (color ?? AppColors.primary).withOpacity(0.1),
          foregroundColor: color ?? AppColors.primary,
          side: isOutlined 
              ? BorderSide(color: AppColors.textTertiary.withOpacity(0.5))
              : null,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: Text(
          text,
          style: AppStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
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
  List<NotificationItem> _getNotificationsForToday() {
    final today = DateTime.now();
    return _notifications.where((notification) {
      return notification.time.year == today.year &&
             notification.time.month == today.month &&
             notification.time.day == today.day;
    }).toList();
  }

  List<NotificationItem> _getEarlierNotifications() {
    final today = DateTime.now();
    return _notifications.where((notification) {
      return !(notification.time.year == today.year &&
               notification.time.month == today.month &&
               notification.time.day == today.day);
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
  void _handleNotificationTap(NotificationItem notification) {
    if (!notification.isRead) {
      _markAsRead(notification);
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

  void _handleFriendRequestAction(NotificationItem notification, bool accept) {
    setState(() {
      notification.isRead = true;
    });
    
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _handleEventInvitationAction(NotificationItem notification, String action) {
    setState(() {
      notification.isRead = true;
    });
    
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _markAsRead(NotificationItem notification) {
    setState(() {
      notification.isRead = true;
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification.isRead = true;
      }
    });
    
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _openNotificationSettings() {
    // Navigate to notification settings
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Notification Settings',
              style: AppStyles.headingSmall,
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Icon(Icons.notifications_active),
              title: Text('Push Notifications'),
              trailing: Switch(
                value: true,
                onChanged: (value) {},
              ),
            ),
            ListTile(
              leading: Icon(Icons.email),
              title: Text('Email Notifications'),
              trailing: Switch(
                value: false,
                onChanged: (value) {},
              ),
            ),
            ListTile(
              leading: Icon(Icons.vibration),
              title: Text('Vibration'),
              trailing: Switch(
                value: true,
                onChanged: (value) {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshNotifications() async {
    // Simulate refresh
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      // Add new notification or update existing ones
    });
  }
}

// Mock data models
class NotificationItem {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime time;
  bool isRead;
  final Map<String, dynamic>? actionData;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.time,
    this.isRead = false,
    this.actionData,
  });
}

enum NotificationType {
  friendRequest,
  friendRequestAccepted,
  eventInvitation,
  eventReminder,
  itemPurchased,
  itemReserved,
  wishlistShared,
  general,
}