


import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../utils/app_routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/animated_background.dart';
import 'events_screen.dart';

class EventDetailsScreen extends StatefulWidget {
  final String eventId;

  const EventDetailsScreen({Key? key, required this.eventId}) : super(key: key);

  @override
  _EventDetailsScreenState createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Mock event data
  late EventDetails _eventDetails;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadEventDetails();
    _startAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
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

  void _loadEventDetails() {
    // Mock event details - replace with actual API call
    _eventDetails = EventDetails(
      id: widget.eventId,
      name: 'Sarah\'s Birthday Party 🎂',
      description: 'Join us for an amazing birthday celebration with friends, music, delicious food, and lots of fun! We\'ll have games, dancing, and a surprise or two. Can\'t wait to celebrate with everyone!',
      hostName: 'Sarah Johnson',
      hostProfilePicture: null,
      date: DateTime.now().add(Duration(days: 15)),
      time: '6:00 PM',
      location: 'Sarah\'s House, 123 Main Street, Downtown',
      eventType: EventDetailsType.birthday,
      totalInvited: 24,
      totalAccepted: 18,
      totalDeclined: 2,
      totalPending: 4,
      wishlistItems: 12,
      isHost: false,
      attendanceStatus: AttendanceStatus.accepted,
      invitedFriends: [
        EventGuest(
          id: '1',
          name: 'Ahmed Ali',
          profilePicture: null,
          status: GuestStatus.accepted,
        ),
        EventGuest(
          id: '2',
          name: 'Emma Watson',
          profilePicture: null,
          status: GuestStatus.accepted,
        ),
        EventGuest(
          id: '3',
          name: 'Mike Thompson',
          profilePicture: null,
          status: GuestStatus.pending,
        ),
        EventGuest(
          id: '4',
          name: 'Lisa Chen',
          profilePicture: null,
          status: GuestStatus.declined,
        ),
      ],
      wishlistPreview: [
        WishlistItemPreview(
          id: '1',
          name: 'Wireless Bluetooth Headphones',
          price: '\$99',
          isPurchased: false,
        ),
        WishlistItemPreview(
          id: '2',
          name: 'Vintage Leather Journal',
          price: '\$45',
          isPurchased: true,
        ),
        WishlistItemPreview(
          id: '3',
          name: 'Essential Oils Diffuser',
          price: '\$65',
          isPurchased: false,
        ),
      ],
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
    return Scaffold(
      body: Stack(
        children: [
          // Animated Background
          AnimatedBackground(
            colors: [
              AppColors.background,
              _getEventTypeColor(_eventDetails.eventType).withOpacity(0.02),
              AppColors.secondary.withOpacity(0.01),
            ],
          ),
          
          // Content
          RefreshIndicator(
            onRefresh: _refreshEventDetails,
            color: _getEventTypeColor(_eventDetails.eventType),
            child: CustomScrollView(
              slivers: [
                // App Bar with Event Header
                _buildSliverAppBar(),
                
                // Event Content
                SliverToBoxAdapter(
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Event Info Card
                                _buildEventInfoCard(),
                                const SizedBox(height: 24),
                                
                                // Attendance Card
                                _buildAttendanceCard(),
                                const SizedBox(height: 24),
                                
                                // Guests Section
                                _buildGuestsSection(),
                                const SizedBox(height: 24),
                                
                                // Wishlist Preview
                                _buildWishlistPreview(),
                                const SizedBox(height: 24),
                                
                                // Action Buttons
                                _buildActionButtons(),
                                const SizedBox(height: 100), // Bottom padding
                              ],
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

  Widget _buildSliverAppBar() {
    final eventColor = _getEventTypeColor(_eventDetails.eventType);
    final daysUntil = _eventDetails.date.difference(DateTime.now()).inDays;
    
    return SliverAppBar(
      expandedHeight: 300,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                eventColor,
                eventColor.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  
                  // Event Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          offset: const Offset(0, 4),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Icon(
                      _getEventTypeIcon(_eventDetails.eventType),
                      color: eventColor,
                      size: 40,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Event Name
                  Text(
                    _eventDetails.name,
                    style: AppStyles.headingMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Host Info
                  Text(
                    'Hosted by ${_eventDetails.hostName}',
                    style: AppStyles.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Countdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      daysUntil > 0 
                          ? daysUntil == 1 
                              ? 'Tomorrow!' 
                              : 'In $daysUntil days'
                          : daysUntil == 0 
                              ? 'Today!'
                              : 'Event passed',
                      style: AppStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: _shareEvent,
          icon: Icon(
            Icons.share_outlined,
            color: Colors.white,
          ),
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          icon: Icon(
            Icons.more_vert,
            color: Colors.white,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          itemBuilder: (context) => [
            if (_eventDetails.isHost) ...[
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Edit Event'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'manage_guests',
                child: Row(
                  children: [
                    Icon(Icons.people_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Manage Guests'),
                  ],
                ),
              ),
            ],
            PopupMenuItem(
              value: 'add_to_calendar',
              child: Row(
                children: [
                  Icon(Icons.calendar_month_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('Add to Calendar'),
                ],
              ),
            ),
            if (!_eventDetails.isHost)
              PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.report_outlined, size: 20, color: AppColors.error),
                    SizedBox(width: 12),
                    Text('Report Event', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildEventInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textTertiary.withOpacity(0.1),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event Details',
            style: AppStyles.headingSmall,
          ),
          const SizedBox(height: 16),
          
          // Date & Time
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            title: 'Date & Time',
            value: '${_formatDate(_eventDetails.date)} at ${_eventDetails.time}',
            color: AppColors.info,
          ),
          
          const SizedBox(height: 16),
          
          // Location
          _buildInfoRow(
            icon: Icons.location_on_outlined,
            title: 'Location',
            value: _eventDetails.location,
            color: AppColors.accent,
            onTap: _openMap,
          ),
          
          if (_eventDetails.description != null) ...[
            const SizedBox(height: 20),
            
            // Description
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Description',
                      style: AppStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _eventDetails.description!,
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppStyles.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textTertiary,
            ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard() {
    if (_eventDetails.isHost) {
      return _buildHostAttendanceView();
    } else {
      return _buildGuestAttendanceView();
    }
  }

  Widget _buildHostAttendanceView() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Guest Responses',
            style: AppStyles.headingSmall,
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildAttendanceStatItem(
                  icon: Icons.check_circle_outline,
                  label: 'Accepted',
                  count: _eventDetails.totalAccepted,
                  total: _eventDetails.totalInvited,
                  color: AppColors.success,
                ),
              ),
              Expanded(
                child: _buildAttendanceStatItem(
                  icon: Icons.cancel_outlined,
                  label: 'Declined',
                  count: _eventDetails.totalDeclined,
                  total: _eventDetails.totalInvited,
                  color: AppColors.error,
                ),
              ),
              Expanded(
                child: _buildAttendanceStatItem(
                  icon: Icons.schedule_outlined,
                  label: 'Pending',
                  count: _eventDetails.totalPending,
                  total: _eventDetails.totalInvited,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuestAttendanceView() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getAttendanceStatusColor(_eventDetails.attendanceStatus).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Response',
            style: AppStyles.headingSmall,
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getAttendanceStatusColor(_eventDetails.attendanceStatus).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getAttendanceStatusIcon(_eventDetails.attendanceStatus),
                  color: _getAttendanceStatusColor(_eventDetails.attendanceStatus),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getAttendanceStatusText(_eventDetails.attendanceStatus),
                      style: AppStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _getAttendanceStatusColor(_eventDetails.attendanceStatus),
                      ),
                    ),
                    Text(
                      'You ${_getAttendanceStatusDescription(_eventDetails.attendanceStatus)} this event',
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_eventDetails.attendanceStatus != AttendanceStatus.accepted)
                TextButton(
                  onPressed: _changeAttendance,
                  child: Text('Change'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceStatItem({
    required IconData icon,
    required String label,
    required int count,
    required int total,
    required Color color,
  }) {
    final percentage = total > 0 ? (count / total * 100).round() : 0;
    
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          '$count',
          style: AppStyles.headingSmall.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppStyles.caption.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        Text(
          '$percentage%',
          style: AppStyles.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildGuestsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Guests (${_eventDetails.totalInvited})',
                style: AppStyles.headingSmall,
              ),
              TextButton(
                onPressed: _viewAllGuests,
                child: Text(
                  'View All',
                  style: AppStyles.bodyMedium.copyWith(
                    color: _getEventTypeColor(_eventDetails.eventType),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Column(
            children: _eventDetails.invitedFriends.take(4).map((guest) {
              return _buildGuestItem(guest);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestItem(EventGuest guest) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: _getGuestStatusColor(guest.status).withOpacity(0.1),
            child: Text(
              guest.name[0].toUpperCase(),
              style: AppStyles.bodyMedium.copyWith(
                color: _getGuestStatusColor(guest.status),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              guest.name,
              style: AppStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getGuestStatusColor(guest.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getGuestStatusText(guest.status),
              style: AppStyles.caption.copyWith(
                color: _getGuestStatusColor(guest.status),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWishlistPreview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.card_giftcard_outlined,
                color: AppColors.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Event Wishlist (${_eventDetails.wishlistItems} items)',
                  style: AppStyles.headingSmall,
                ),
              ),
              TextButton(
                onPressed: _viewFullWishlist,
                child: Text(
                  'View All',
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Column(
            children: _eventDetails.wishlistPreview.map((item) {
              return _buildWishlistItemPreview(item);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWishlistItemPreview(WishlistItemPreview item) {
    return GestureDetector(
      onTap: () => _viewWishlistItem(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: item.isPurchased 
              ? Border.all(color: AppColors.success.withOpacity(0.3))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.isPurchased 
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                item.isPurchased 
                    ? Icons.check_circle_outline
                    : Icons.card_giftcard_outlined,
                color: item.isPurchased ? AppColors.success : AppColors.secondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                      decoration: item.isPurchased ? TextDecoration.lineThrough : null,
                      color: item.isPurchased ? AppColors.textTertiary : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    item.price,
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (item.isPurchased)
              Text(
                'Purchased',
                style: AppStyles.caption.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_eventDetails.isHost) {
      return Column(
        children: [
          CustomButton(
            text: 'Manage Event',
            onPressed: _manageEvent,
            variant: ButtonVariant.primary,
            customColor: _getEventTypeColor(_eventDetails.eventType),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Edit Wishlist',
                  onPressed: _editWishlist,
                  variant: ButtonVariant.outline,
                  customColor: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  text: 'Invite More',
                  onPressed: _inviteMoreFriends,
                  variant: ButtonVariant.outline,
                  customColor: _getEventTypeColor(_eventDetails.eventType),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: CustomButton(
              text: 'View Wishlist',
              onPressed: _viewFullWishlist,
              variant: ButtonVariant.outline,
              customColor: AppColors.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CustomButton(
              text: _eventDetails.attendanceStatus == AttendanceStatus.accepted 
                  ? 'Going' 
                  : 'Respond',
              onPressed: _changeAttendance,
              variant: ButtonVariant.primary,
              customColor: _getEventTypeColor(_eventDetails.eventType),
            ),
          ),
        ],
      );
    }
  }

  // Helper Methods
  Color _getEventTypeColor(EventDetailsType type) {
    switch (type) {
      case EventDetailsType.birthday:
        return AppColors.secondary;
      case EventDetailsType.wedding:
        return AppColors.primary;
      case EventDetailsType.anniversary:
        return AppColors.error;
      case EventDetailsType.graduation:
        return AppColors.accent;
      default:
        return AppColors.primary;
    }
  }

  IconData _getEventTypeIcon(EventDetailsType type) {
    switch (type) {
      case EventDetailsType.birthday:
        return Icons.cake_outlined;
      case EventDetailsType.wedding:
        return Icons.favorite_outline;
      case EventDetailsType.anniversary:
        return Icons.favorite_border;
      case EventDetailsType.graduation:
        return Icons.school_outlined;
      default:
        return Icons.event_outlined;
    }
  }

  Color _getAttendanceStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.accepted:
        return AppColors.success;
      case AttendanceStatus.declined:
        return AppColors.error;
      case AttendanceStatus.pending:
        return AppColors.warning;
    }
  }

  IconData _getAttendanceStatusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.accepted:
        return Icons.check_circle_outline;
      case AttendanceStatus.declined:
        return Icons.cancel_outlined;
      case AttendanceStatus.pending:
        return Icons.schedule_outlined;
    }
  }

  String _getAttendanceStatusText(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.accepted:
        return 'Going';
      case AttendanceStatus.declined:
        return 'Not Going';
      case AttendanceStatus.pending:
        return 'Not Responded';
    }
  }

  String _getAttendanceStatusDescription(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.accepted:
        return 'accepted';
      case AttendanceStatus.declined:
        return 'declined';
      case AttendanceStatus.pending:
        return 'haven\'t responded to';
    }
  }

  Color _getGuestStatusColor(GuestStatus status) {
    switch (status) {
      case GuestStatus.accepted:
        return AppColors.success;
      case GuestStatus.declined:
        return AppColors.error;
      case GuestStatus.pending:
        return AppColors.warning;
    }
  }

  String _getGuestStatusText(GuestStatus status) {
    switch (status) {
      case GuestStatus.accepted:
        return 'Going';
      case GuestStatus.declined:
        return 'Declined';
      case GuestStatus.pending:
        return 'Pending';
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // Action Handlers
  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        _editEvent();
        break;
      case 'manage_guests':
        _manageGuests();
        break;
      case 'add_to_calendar':
        _addToCalendar();
        break;
      case 'report':
        _reportEvent();
        break;
    }
  }

  void _shareEvent() {
    // Share event functionality
  }

  void _openMap() {
    // Open location in maps
  }

  void _changeAttendance() {
    // Show attendance options
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
              'Your Response',
              style: AppStyles.headingSmall,
            ),
            const SizedBox(height: 24),
            
            _buildAttendanceOption(
              icon: Icons.check_circle_outline,
              title: 'Going',
              subtitle: 'I\'ll be there!',
              color: AppColors.success,
              onTap: () {
                Navigator.pop(context);
                // Update attendance
              },
            ),
            
            _buildAttendanceOption(
              icon: Icons.help_outline,
              title: 'Maybe',
              subtitle: 'I\'m not sure yet',
              color: AppColors.warning,
              onTap: () {
                Navigator.pop(context);
                // Update attendance
              },
            ),
            
            _buildAttendanceOption(
              icon: Icons.cancel_outlined,
              title: 'Can\'t Go',
              subtitle: 'I won\'t be able to attend',
              color: AppColors.error,
              onTap: () {
                Navigator.pop(context);
                // Update attendance
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }

  void _viewAllGuests() {
    // Navigate to all guests screen
  }

  void _viewFullWishlist() {
    // Navigate to full wishlist
    Navigator.pushNamed(
      context,
      AppRoutes.eventWishlist,
      arguments: EventSummary(
        id: _eventDetails.id,
        name: _eventDetails.name,
        date: _eventDetails.date,
        type: _convertEventType(_eventDetails.eventType),
        location: _eventDetails.location,
        description: _eventDetails.description,
        hostName: _eventDetails.hostName,
        status: _convertAttendanceStatus(_eventDetails.attendanceStatus),
        invitedCount: _eventDetails.totalInvited,
        acceptedCount: _eventDetails.totalAccepted,
        wishlistItemCount: _eventDetails.wishlistItems,
        isCreatedByMe: _eventDetails.isHost,
      ),
    );
  }

  void _viewWishlistItem(WishlistItemPreview item) {
    // Navigate to individual wishlist item details
    Navigator.pushNamed(
      context,
      AppRoutes.wishlistItemDetails,
      arguments: item,
    );
  }

  // Helper method to convert EventDetailsType to EventType
  EventType _convertEventType(EventDetailsType detailsType) {
    switch (detailsType) {
      case EventDetailsType.birthday:
        return EventType.birthday;
      case EventDetailsType.wedding:
        return EventType.wedding;
      case EventDetailsType.anniversary:
        return EventType.anniversary;
      case EventDetailsType.graduation:
        return EventType.graduation;
    }
  }

  // Helper method to convert AttendanceStatus to EventStatus
  EventStatus _convertAttendanceStatus(AttendanceStatus attendanceStatus) {
    switch (attendanceStatus) {
      case AttendanceStatus.pending:
        return EventStatus.upcoming;
      case AttendanceStatus.accepted:
        return EventStatus.ongoing;
      case AttendanceStatus.declined:
        return EventStatus.cancelled;
    }
  }

  void _manageEvent() {
    // Navigate to event management
  }

  void _editWishlist() {
    // Navigate to edit wishlist
  }

  void _inviteMoreFriends() {
    // Navigate to invite friends
  }

  void _editEvent() {
    // Navigate to edit event
  }

  void _manageGuests() {
    // Navigate to manage guests
  }

  void _addToCalendar() {
    // Add to device calendar
  }

  void _reportEvent() {
    // Report event
  }

  Future<void> _refreshEventDetails() async {
    // Refresh event details
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      // Update event data
    });
  }
}

// Mock data models
class EventDetails {
  final String id;
  final String name;
  final String? description;
  final String hostName;
  final String? hostProfilePicture;
  final DateTime date;
  final String time;
  final String location;
  final EventDetailsType eventType;
  final int totalInvited;
  final int totalAccepted;
  final int totalDeclined;
  final int totalPending;
  final int wishlistItems;
  final bool isHost;
  final AttendanceStatus attendanceStatus;
  final List<EventGuest> invitedFriends;
  final List<WishlistItemPreview> wishlistPreview;

  EventDetails({
    required this.id,
    required this.name,
    this.description,
    required this.hostName,
    this.hostProfilePicture,
    required this.date,
    required this.time,
    required this.location,
    required this.eventType,
    required this.totalInvited,
    required this.totalAccepted,
    required this.totalDeclined,
    required this.totalPending,
    required this.wishlistItems,
    required this.isHost,
    required this.attendanceStatus,
    required this.invitedFriends,
    required this.wishlistPreview,
  });
}

class EventGuest {
  final String id;
  final String name;
  final String? profilePicture;
  final GuestStatus status;

  EventGuest({
    required this.id,
    required this.name,
    this.profilePicture,
    required this.status,
  });
}

class WishlistItemPreview {
  final String id;
  final String name;
  final String price;
  final bool isPurchased;

  WishlistItemPreview({
    required this.id,
    required this.name,
    required this.price,
    required this.isPurchased,
  });
}

enum EventDetailsType {
  birthday,
  wedding,
  anniversary,
  graduation,
}

enum AttendanceStatus {
  pending,
  accepted,
  declined,
}

enum GuestStatus {
  pending,
  accepted,
  declined,
}