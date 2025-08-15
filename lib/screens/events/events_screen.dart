


import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../utils/app_routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/animated_background.dart';

class EventsScreen extends StatefulWidget {
  @override
  _EventsScreenState createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Mock events data
  final List<EventSummary> _myEvents = [
    EventSummary(
      id: '1',
      name: 'My Birthday Party 🎂',
      date: DateTime.now().add(Duration(days: 15)),
      type: EventType.birthday,
      location: 'My Home',
      description: 'Come celebrate my 25th birthday with friends and family!',
      invitedCount: 24,
      acceptedCount: 18,
      wishlistItemCount: 12,
      isCreatedByMe: true,
      status: EventStatus.upcoming,
    ),
    EventSummary(
      id: '2',
      name: 'Housewarming Party',
      date: DateTime.now().add(Duration(days: 45)),
      type: EventType.houseWarming,
      location: 'New Apartment',
      description: 'Help us celebrate our new home!',
      invitedCount: 15,
      acceptedCount: 8,
      wishlistItemCount: 8,
      isCreatedByMe: true,
      status: EventStatus.upcoming,
    ),
  ];

  final List<EventSummary> _invitedEvents = [
    EventSummary(
      id: '3',
      name: 'Sarah\'s Wedding',
      date: DateTime.now().add(Duration(days: 30)),
      type: EventType.wedding,
      location: 'Grand Hotel',
      description: 'Join us as we celebrate the union of Sarah and John!',
      hostName: 'Sarah Johnson',
      invitedCount: 120,
      acceptedCount: 95,
      wishlistItemCount: 25,
      isCreatedByMe: false,
      status: EventStatus.upcoming,
    ),
    EventSummary(
      id: '4',
      name: 'Ahmed\'s Graduation',
      date: DateTime.now().add(Duration(days: 8)),
      type: EventType.graduation,
      location: 'University Campus',
      description: 'Celebrating my PhD graduation!',
      hostName: 'Ahmed Ali',
      invitedCount: 50,
      acceptedCount: 42,
      wishlistItemCount: 10,
      isCreatedByMe: false,
      status: EventStatus.upcoming,
    ),
    EventSummary(
      id: '5',
      name: 'Emma\'s Baby Shower',
      date: DateTime.now().subtract(Duration(days: 5)),
      type: EventType.babyShower,
      location: 'Emma\'s House',
      description: 'Welcome baby Emma!',
      hostName: 'Emma Watson',
      invitedCount: 20,
      acceptedCount: 18,
      wishlistItemCount: 15,
      isCreatedByMe: false,
      status: EventStatus.completed,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() {
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
              AppColors.accent.withOpacity(0.02),
              AppColors.secondary.withOpacity(0.01),
            ],
          ),
          
          // Content
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                _buildSliverAppBar(),
                _buildSliverTabBar(),
              ];
            },
            body: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMyEventsTab(),
                      _buildInvitedEventsTab(),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Events',
              style: AppStyles.headingMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_getUpcomingEventsCount()} upcoming events',
              style: AppStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
      ),
      actions: [
        // Calendar View Button
        IconButton(
          onPressed: _showCalendarView,
          icon: Icon(
            Icons.calendar_month_outlined,
            color: AppColors.textPrimary,
          ),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surface,
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(width: 8),
        // Filter Button
        IconButton(
          onPressed: _showFilterOptions,
          icon: Icon(
            Icons.filter_list_outlined,
            color: AppColors.textPrimary,
          ),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surface,
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildSliverTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverTabBarDelegate(
        TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          indicatorWeight: 3,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textTertiary,
          labelStyle: AppStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('My Events'),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_myEvents.length}',
                      style: AppStyles.caption.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Invited'),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_invitedEvents.where((e) => e.status == EventStatus.upcoming).length}',
                      style: AppStyles.caption.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyEventsTab() {
    return RefreshIndicator(
      onRefresh: _refreshEvents,
      color: AppColors.accent,
      child: _myEvents.isEmpty
          ? _buildEmptyMyEvents()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _myEvents.length + 1, // +1 for bottom padding
              itemBuilder: (context, index) {
                if (index == _myEvents.length) {
                  return const SizedBox(height: 100); // Bottom padding for FAB
                }
                return _buildEventCard(_myEvents[index]);
              },
            ),
    );
  }

  Widget _buildInvitedEventsTab() {
    final upcomingEvents = _invitedEvents.where((e) => e.status == EventStatus.upcoming).toList();
    final pastEvents = _invitedEvents.where((e) => e.status == EventStatus.completed).toList();

    return RefreshIndicator(
      onRefresh: _refreshEvents,
      color: AppColors.secondary,
      child: _invitedEvents.isEmpty
          ? _buildEmptyInvitedEvents()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Upcoming Events
                  if (upcomingEvents.isNotEmpty) ...[
                    _buildSectionHeader('Upcoming Events'),
                    const SizedBox(height: 12),
                    ...upcomingEvents.map((event) => _buildEventCard(event)),
                    const SizedBox(height: 24),
                  ],
                  
                  // Past Events
                  if (pastEvents.isNotEmpty) ...[
                    _buildSectionHeader('Past Events'),
                    const SizedBox(height: 12),
                    ...pastEvents.map((event) => _buildEventCard(event)),
                  ],
                  
                  const SizedBox(height: 100), // Bottom padding
                ],
              ),
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

  Widget _buildEventCard(EventSummary event) {
    final isPast = event.status == EventStatus.completed;
    final daysUntil = event.date.difference(DateTime.now()).inDays;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: isPast 
            ? Border.all(color: AppColors.textTertiary.withOpacity(0.3))
            : Border.all(color: _getEventTypeColor(event.type).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.textTertiary.withOpacity(0.1),
            offset: const Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _viewEventDetails(event),
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isPast
                        ? [
                            AppColors.textTertiary.withOpacity(0.1),
                            AppColors.textTertiary.withOpacity(0.05),
                          ]
                        : [
                            _getEventTypeColor(event.type).withOpacity(0.1),
                            _getEventTypeColor(event.type).withOpacity(0.05),
                          ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    // Event Icon
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: isPast 
                            ? AppColors.textTertiary 
                            : _getEventTypeColor(event.type),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _getEventTypeIcon(event.type),
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Event Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.name,
                            style: AppStyles.headingSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isPast ? AppColors.textSecondary : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (event.hostName != null)
                            Text(
                              'by ${event.hostName}',
                              style: AppStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  event.location ?? 'Location TBD',
                                  style: AppStyles.bodySmall.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Date Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isPast
                            ? AppColors.textTertiary.withOpacity(0.1)
                            : daysUntil <= 7
                                ? AppColors.warning.withOpacity(0.1)
                                : AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${event.date.day}',
                            style: AppStyles.headingSmall.copyWith(
                              color: isPast
                                  ? AppColors.textTertiary
                                  : daysUntil <= 7
                                      ? AppColors.warning
                                      : AppColors.info,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _getMonthName(event.date.month),
                            style: AppStyles.caption.copyWith(
                              color: isPast
                                  ? AppColors.textTertiary
                                  : daysUntil <= 7
                                      ? AppColors.warning
                                      : AppColors.info,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
                    if (event.description != null)
                      Text(
                        event.description!,
                        style: AppStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Stats Row
                    Row(
                      children: [
                        _buildEventStat(
                          icon: Icons.people_outline,
                          label: 'Invited',
                          value: '${event.invitedCount}',
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 20),
                        _buildEventStat(
                          icon: Icons.check_circle_outline,
                          label: 'Accepted',
                          value: '${event.acceptedCount}',
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 20),
                        _buildEventStat(
                          icon: Icons.card_giftcard_outlined,
                          label: 'Wishlist',
                          value: '${event.wishlistItemCount}',
                          color: AppColors.secondary,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Action Buttons
                    if (!isPast) ...[
                      Row(
                        children: [
                          if (event.isCreatedByMe) ...[
                            Expanded(
                              child: CustomButton(
                                text: 'Manage Event',
                                onPressed: () => _manageEvent(event),
                                variant: ButtonVariant.outline,
                                customColor: _getEventTypeColor(event.type),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomButton(
                                text: 'View Wishlist',
                                onPressed: () => _viewEventWishlist(event),
                                variant: ButtonVariant.primary,
                                customColor: _getEventTypeColor(event.type),
                              ),
                            ),
                          ] else ...[
                            Expanded(
                              child: CustomButton(
                                text: 'View Details',
                                onPressed: () => _viewEventDetails(event),
                                variant: ButtonVariant.outline,
                                customColor: _getEventTypeColor(event.type),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomButton(
                                text: 'View Wishlist',
                                onPressed: () => _viewEventWishlist(event),
                                variant: ButtonVariant.primary,
                                customColor: _getEventTypeColor(event.type),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ] else ...[
                      // Past event actions
                      CustomButton(
                        text: 'View Event Details',
                        onPressed: () => _viewEventDetails(event),
                        variant: ButtonVariant.outline,
                        customColor: AppColors.textTertiary,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: AppStyles.bodySmall.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppStyles.caption.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyMyEvents() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.celebration_outlined,
              size: 60,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Events Created',
            style: AppStyles.headingMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Create your first event to start planning celebrations and sharing wishlists with friends.',
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          CustomButton(
            text: 'Create Event',
            onPressed: () {
              AppRoutes.pushNamed(context, AppRoutes.createEvent);
            },
            variant: ButtonVariant.gradient,
            gradientColors: [AppColors.accent, AppColors.secondary],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyInvitedEvents() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.mail_outline,
              size: 60,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Event Invitations',
            style: AppStyles.headingMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'When friends invite you to their events, you\'ll see them here.',
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
  int _getUpcomingEventsCount() {
    final myUpcoming = _myEvents.where((e) => e.status == EventStatus.upcoming).length;
    final invitedUpcoming = _invitedEvents.where((e) => e.status == EventStatus.upcoming).length;
    return myUpcoming + invitedUpcoming;
  }

  Color _getEventTypeColor(EventType type) {
    switch (type) {
      case EventType.birthday:
        return AppColors.secondary;
      case EventType.wedding:
        return AppColors.primary;
      case EventType.anniversary:
        return AppColors.error;
      case EventType.graduation:
        return AppColors.accent;
      case EventType.holiday:
        return AppColors.success;
      case EventType.babyShower:
        return AppColors.info;
      case EventType.houseWarming:
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  IconData _getEventTypeIcon(EventType type) {
    switch (type) {
      case EventType.birthday:
        return Icons.cake_outlined;
      case EventType.wedding:
        return Icons.favorite_outline;
      case EventType.anniversary:
        return Icons.favorite_border;
      case EventType.graduation:
        return Icons.school_outlined;
      case EventType.holiday:
        return Icons.celebration_outlined;
      case EventType.babyShower:
        return Icons.child_friendly_outlined;
      case EventType.houseWarming:
        return Icons.home_outlined;
      default:
        return Icons.event_outlined;
    }
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  // Action Handlers
  void _viewEventDetails(EventSummary event) {
    AppRoutes.pushNamed(
      context,
      AppRoutes.eventDetails,
      arguments: {'eventId': event.id},
    );
  }

  void _viewEventWishlist(EventSummary event) {
    // Navigate to event wishlist
  }

  void _manageEvent(EventSummary event) {
    // Navigate to event management
  }

  void _showCalendarView() {
    // Show calendar view
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Calendar View'),
        content: Container(
          height: 300,
          child: Center(
            child: Text('Calendar view coming soon!'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showFilterOptions() {
    // Show filter options
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
              'Filter Events',
              style: AppStyles.headingSmall,
            ),
            const SizedBox(height: 24),
            // Filter options would go here
            Text('Filter options coming soon!'),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshEvents() async {
    // Refresh events data
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      // Update events data
    });
  }
}

// Custom SliverTabBarDelegate
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.background,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

// Mock data model
class EventSummary {
  final String id;
  final String name;
  final DateTime date;
  final EventType type;
  final String? location;
  final String? description;
  final String? hostName;
  final int invitedCount;
  final int acceptedCount;
  final int wishlistItemCount;
  final bool isCreatedByMe;
  final EventStatus status;

  EventSummary({
    required this.id,
    required this.name,
    required this.date,
    required this.type,
    this.location,
    this.description,
    this.hostName,
    required this.invitedCount,
    required this.acceptedCount,
    required this.wishlistItemCount,
    required this.isCreatedByMe,
    required this.status,
  });
}

enum EventType {
  birthday,
  wedding,
  anniversary,
  graduation,
  holiday,
  babyShower,
  houseWarming,
  retirement,
  promotion,
  other,
}

enum EventStatus {
  upcoming,
  ongoing,
  completed,
  cancelled,
}