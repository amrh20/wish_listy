import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../utils/app_routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/decorative_background.dart';
import '../../widgets/guest_restriction_dialog.dart';
import '../../services/localization_service.dart';
import '../../services/auth_service.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  _EventsScreenState createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();
  List<EventSummary> _searchResults = [];
  bool _isSearching = false;

  // Filter and sort variables
  String _selectedSortOption = 'date_upcoming';
  String? _selectedEventType;
  List<EventSummary> _filteredEvents = [];

  // Mock events data for authenticated users
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

  // Mock public events for guest users
  final List<EventSummary> _publicEvents = [
    EventSummary(
      id: 'pub1',
      name: 'Community Birthday Celebration',
      date: DateTime.now().add(Duration(days: 5)),
      type: EventType.birthday,
      location: 'Community Center',
      description: 'Join us for a community birthday celebration!',
      invitedCount: 50,
      acceptedCount: 32,
      wishlistItemCount: 25,
      isCreatedByMe: false,
      status: EventStatus.upcoming,
      hostName: 'Sarah Ahmed',
    ),
    EventSummary(
      id: 'pub2',
      name: 'Wedding Anniversary',
      date: DateTime.now().add(Duration(days: 12)),
      type: EventType.anniversary,
      location: 'Grand Hotel',
      description: 'Celebrating 10 years of love and happiness',
      invitedCount: 100,
      acceptedCount: 75,
      wishlistItemCount: 40,
      isCreatedByMe: false,
      status: EventStatus.upcoming,
      hostName: 'Ahmed & Fatima',
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
    _applyFilters();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() {
    _animationController.forward();
  }

  void _applyFilters() {
    List<EventSummary> allEvents = [..._myEvents, ..._invitedEvents];

    // Apply event type filter
    if (_selectedEventType != null) {
      allEvents = allEvents
          .where(
            (event) =>
                event.type.toString().split('.').last == _selectedEventType,
          )
          .toList();
    }

    // Apply sorting
    switch (_selectedSortOption) {
      case 'date_upcoming':
        allEvents.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'date_latest':
        allEvents.sort((a, b) => b.date.compareTo(a.date));
        break;
      case 'name_az':
        allEvents.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    setState(() {
      _filteredEvents = allEvents;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LocalizationService, AuthService>(
      builder: (context, localization, authService, child) {
        // For guest users - show different interface
        if (authService.isGuest) {
          return Scaffold(
            body: DecorativeBackground(
              showGifts: true,
              child: Stack(
                children: [
                  // Content
                  NestedScrollView(
                    headerSliverBuilder: (context, innerBoxIsScrolled) {
                      return [_buildGuestSliverAppBar(localization)];
                    },
                    body: AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: _fadeAnimation,
                          child: _buildGuestEventsView(localization),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // For authenticated users - show full interface
        return Scaffold(
          body: DecorativeBackground(
            showGifts: true,
            child: Stack(
              children: [
                // Content
                NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      _buildSliverAppBar(localization),
                      _buildSliverTabBar(localization),
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
                            _buildMyEventsTab(localization),
                            _buildInvitedEventsTab(localization),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.createEvent);
            },
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            child: Icon(Icons.add_rounded),
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar(LocalizationService localization) {
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
              localization.translate('events.title'),
              style: AppStyles.headingMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_getUpcomingEventsCount()} ${localization.translate('events.upcomingEvents')}',
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
          icon: Icon(Icons.filter_list_outlined, color: AppColors.textPrimary),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surface,
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildSliverTabBar(LocalizationService localization) {
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
                  Text(localization.translate('events.myEvents')),
                  const SizedBox(width: 8),
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
                      '${_myEvents.length}',
                      style: AppStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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
                  Text(localization.translate('events.invited')),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
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

  Widget _buildMyEventsTab(LocalizationService localization) {
    final myFilteredEvents = _filteredEvents
        .where((e) => e.isCreatedByMe)
        .toList();

    return RefreshIndicator(
      onRefresh: _refreshEvents,
      color: AppColors.accent,
      child: myFilteredEvents.isEmpty
          ? _buildEmptyMyEvents(localization)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: myFilteredEvents.length + 1, // +1 for bottom padding
              itemBuilder: (context, index) {
                if (index == myFilteredEvents.length) {
                  return const SizedBox(height: 100); // Bottom padding for FAB
                }
                return _buildEventCard(myFilteredEvents[index], localization);
              },
            ),
    );
  }

  Widget _buildInvitedEventsTab(LocalizationService localization) {
    final invitedFilteredEvents = _filteredEvents
        .where((e) => !e.isCreatedByMe)
        .toList();
    final upcomingEvents = invitedFilteredEvents
        .where((e) => e.status == EventStatus.upcoming)
        .toList();
    final pastEvents = invitedFilteredEvents
        .where((e) => e.status == EventStatus.completed)
        .toList();

    return RefreshIndicator(
      onRefresh: _refreshEvents,
      color: AppColors.secondary,
      child: invitedFilteredEvents.isEmpty
          ? _buildEmptyInvitedEvents(localization)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Upcoming Events
                  if (upcomingEvents.isNotEmpty) ...[
                    _buildSectionHeader(
                      localization.translate('events.upcomingEvents'),
                    ),
                    const SizedBox(height: 12),
                    ...upcomingEvents.map(
                      (event) => _buildEventCard(event, localization),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Past Events
                  if (pastEvents.isNotEmpty) ...[
                    _buildSectionHeader(
                      localization.translate('events.pastEvents'),
                    ),
                    const SizedBox(height: 12),
                    ...pastEvents.map(
                      (event) => _buildEventCard(event, localization),
                    ),
                    const SizedBox(height: 24),
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

  Widget _buildEventCard(EventSummary event, LocalizationService localization) {
    final isPast = event.status == EventStatus.completed;
    final daysUntil = event.date.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: isPast
            ? Border.all(color: AppColors.textTertiary.withOpacity(0.3))
            : Border.all(
                color: _getEventTypeColor(event.type).withOpacity(0.3),
              ),
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
                              color: isPast
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
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
                                text: localization.translate('ui.manageEvent'),
                                onPressed: () => _manageEvent(event),
                                variant: ButtonVariant.outline,
                                customColor: _getEventTypeColor(event.type),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomButton(
                                text: localization.translate('ui.viewWishlist'),
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
                                text: localization.translate('ui.viewWishlist'),
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
        Icon(icon, size: 16, color: color),
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
          style: AppStyles.caption.copyWith(color: AppColors.textTertiary),
        ),
      ],
    );
  }

  Widget _buildEmptyMyEvents(LocalizationService localization) {
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
            localization.translate('events.noEvents'),
            style: AppStyles.headingMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            localization.translate('events.createEvent'),
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          CustomButton(
            text: localization.translate('events.createEvent'),
            onPressed: () {
              AppRoutes.pushNamed(context, AppRoutes.createEvent);
            },
            variant: ButtonVariant.primary,
            customColor: AppColors.accent,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyInvitedEvents(LocalizationService localization) {
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
            localization.translate('events.noInvitations'),
            style: AppStyles.headingMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            localization.translate('events.invited'),
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
    final myUpcoming = _myEvents
        .where((e) => e.status == EventStatus.upcoming)
        .length;
    final invitedUpcoming = _invitedEvents
        .where((e) => e.status == EventStatus.upcoming)
        .length;
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
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
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
    final localization = Provider.of<LocalizationService>(
      context,
      listen: false,
    );
    // Mock data for associated wishlists
    List<Map<String, dynamic>> associatedWishlists = _getAssociatedWishlists(
      event,
    );

    if (associatedWishlists.length == 1) {
      // Navigate directly to the single wishlist
      Navigator.pushNamed(
        context,
        AppRoutes.wishlistItems,
        arguments: {
          'wishlistId': associatedWishlists.first['id'],
          'wishlistName': associatedWishlists.first['name'],
          'totalItems': associatedWishlists.first['totalItems'],
          'purchasedItems': associatedWishlists.first['purchasedItems'],
          'totalValue': associatedWishlists.first['totalValue'],
          'isFriendWishlist': false,
        },
      );
    } else if (associatedWishlists.length > 1) {
      // Show modal to select wishlist
      _showWishlistSelectionModal(event, associatedWishlists, localization);
    } else {
      // No wishlists associated
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localization.translate('events.noWishlistsAssociated')),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  List<Map<String, dynamic>> _getAssociatedWishlists(EventSummary event) {
    // Mock data - in real app, this would come from API
    switch (event.id) {
      case '1': // My Birthday Party
        return [
          {
            'id': 'wishlist_1',
            'name': 'Birthday Wishlist',
            'privacy': 'public',
            'totalItems': 12,
            'purchasedItems': 3,
            'totalValue': 450.0,
          },
        ];
      case '2': // Housewarming Party
        return [
          {
            'id': 'wishlist_2a',
            'name': 'Home Essentials',
            'privacy': 'public',
            'totalItems': 8,
            'purchasedItems': 2,
            'totalValue': 320.0,
          },
          {
            'id': 'wishlist_2b',
            'name': 'Kitchen Items',
            'privacy': 'friends',
            'totalItems': 5,
            'purchasedItems': 1,
            'totalValue': 180.0,
          },
        ];
      case '3': // Sarah's Wedding
        return [
          {
            'id': 'wishlist_3',
            'name': 'Wedding Registry',
            'privacy': 'public',
            'totalItems': 25,
            'purchasedItems': 8,
            'totalValue': 1200.0,
          },
        ];
      default:
        return [];
    }
  }

  void _showWishlistSelectionModal(
    EventSummary event,
    List<Map<String, dynamic>> wishlists,
    LocalizationService localization,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              localization.translate('events.selectWishlist'),
              style: AppStyles.headingSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              localization
                  .translate('events.hasWishlists')
                  .replaceAll('{eventName}', event.name)
                  .replaceAll('{count}', wishlists.length.toString()),
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Wishlist List
            ...wishlists.map((wishlist) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                      context,
                      AppRoutes.wishlistItems,
                      arguments: {
                        'wishlistId': wishlist['id'],
                        'wishlistName': wishlist['name'],
                        'totalItems': wishlist['totalItems'],
                        'purchasedItems': wishlist['purchasedItems'],
                        'totalValue': wishlist['totalValue'],
                        'isFriendWishlist': false,
                      },
                    );
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: AppColors.surface,
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getEventTypeColor(event.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.favorite_rounded,
                      color: _getEventTypeColor(event.type),
                      size: 24,
                    ),
                  ),
                  title: Text(
                    wishlist['name'],
                    style: AppStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        '${wishlist['totalItems']} items • ${wishlist['purchasedItems']} purchased',
                        style: AppStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            _getPrivacyIcon(wishlist['privacy']),
                            size: 14,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getPrivacyLabel(wishlist['privacy']),
                            style: AppStyles.caption.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  IconData _getPrivacyIcon(String privacy) {
    switch (privacy) {
      case 'public':
        return Icons.public;
      case 'private':
        return Icons.lock;
      case 'friends':
        return Icons.people;
      default:
        return Icons.help;
    }
  }

  String _getPrivacyLabel(String privacy) {
    switch (privacy) {
      case 'public':
        return 'Public';
      case 'private':
        return 'Private';
      case 'friends':
        return 'Friends Only';
      default:
        return privacy;
    }
  }

  void _manageEvent(EventSummary event) {
    // Navigate to event management screen
    Navigator.pushNamed(context, AppRoutes.eventManagement, arguments: event);
  }

  void _showCalendarView() {
    // Show calendar view
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Calendar View'),
        content: SizedBox(
          height: 300,
          child: Center(child: Text('Calendar view coming soon!')),
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
    final localization = Provider.of<LocalizationService>(
      context,
      listen: false,
    );
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              localization.translate('events.filterAndSort'),
              style: AppStyles.headingSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Sort Options
            _buildSortSection(localization),
            const SizedBox(height: 24),

            // Filter Options
            _buildFilterSection(localization),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: localization.translate('events.clearAll'),
                    onPressed: () {
                      setState(() {
                        _selectedSortOption = 'date_upcoming';
                        _selectedEventType = null;
                      });
                      _applyFilters();
                      Navigator.pop(context);
                    },
                    variant: ButtonVariant.outline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: localization.translate('events.apply'),
                    onPressed: () {
                      _applyFilters();
                      Navigator.pop(context);
                    },
                    variant: ButtonVariant.gradient,
                    gradientColors: [AppColors.primary, AppColors.secondary],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSortSection(LocalizationService localization) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localization.translate('events.sortBy'),
          style: AppStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...['date_upcoming', 'date_latest', 'name_az'].map((option) {
          return RadioListTile<String>(
            title: Text(_getSortOptionLabel(option)),
            value: option,
            groupValue: _selectedSortOption,
            onChanged: (value) {
              setState(() {
                _selectedSortOption = value!;
              });
            },
            activeColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildFilterSection(LocalizationService localization) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localization.translate('events.filterByEventType'),
          style: AppStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        RadioListTile<String?>(
          title: Text(localization.translate('events.allTypes')),
          value: null,
          groupValue: _selectedEventType,
          onChanged: (value) {
            setState(() {
              _selectedEventType = value;
            });
          },
          activeColor: AppColors.primary,
          contentPadding: EdgeInsets.zero,
        ),
        ...[
          'birthday',
          'wedding',
          'anniversary',
          'graduation',
          'houseWarming',
        ].map((type) {
          return RadioListTile<String?>(
            title: Text(_getEventTypeLabel(type)),
            value: type,
            groupValue: _selectedEventType,
            onChanged: (value) {
              setState(() {
                _selectedEventType = value;
              });
            },
            activeColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
          );
        }).toList(),
      ],
    );
  }

  String _getSortOptionLabel(String option) {
    final localization = Provider.of<LocalizationService>(
      context,
      listen: false,
    );
    switch (option) {
      case 'date_upcoming':
        return localization.translate('events.dateUpcomingFirst');
      case 'date_latest':
        return localization.translate('events.dateLatestFirst');
      case 'name_az':
        return localization.translate('events.nameAZ');
      default:
        return option;
    }
  }

  String _getEventTypeLabel(String type) {
    switch (type) {
      case 'birthday':
        return 'Birthday';
      case 'wedding':
        return 'Wedding';
      case 'anniversary':
        return 'Anniversary';
      case 'graduation':
        return 'Graduation';
      case 'houseWarming':
        return 'Housewarming';
      default:
        return type;
    }
  }

  Future<void> _refreshEvents() async {
    // Refresh events data
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      // Update events data
    });
    _applyFilters();
  }

  // Guest-specific methods
  Widget _buildGuestSliverAppBar(LocalizationService localization) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: false,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          localization.translate('navigation.events'),
          style: AppStyles.headingMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.background,
                AppColors.background.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
      ),
      actions: [
        // Search Button
        IconButton(
          onPressed: () => _showGuestSearch(localization),
          icon: Icon(Icons.search, color: AppColors.textPrimary),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surface,
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildGuestEventsView(LocalizationService localization) {
    if (_isSearching &&
        _searchResults.isEmpty &&
        _searchController.text.isNotEmpty) {
      return _buildGuestEmptySearch();
    }

    if (_isSearching && _searchResults.isNotEmpty) {
      return _buildGuestSearchResults(localization);
    }

    return _buildGuestEmptyState(localization);
  }

  Widget _buildGuestEmptyState(LocalizationService localization) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 60),
          Icon(Icons.event_outlined, size: 80, color: AppColors.textTertiary),
          const SizedBox(height: 24),
          Text(
            localization.translate('guest.events.empty.title'),
            style: AppStyles.heading4.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            localization.translate('guest.events.empty.description'),
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          CustomButton(
            text: localization.translate(
              'guest.events.empty.searchPlaceholder',
            ),
            onPressed: () => _showGuestSearch(localization),
            variant: ButtonVariant.gradient,
            icon: Icons.search,
          ),
          const SizedBox(height: 20),
          CustomButton(
            text: localization.translate('guest.quickActions.loginForMore'),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.login);
            },
            variant: ButtonVariant.outline,
            icon: Icons.login,
          ),
        ],
      ),
    );
  }

  Widget _buildGuestEmptySearch() {
    final localization = Provider.of<LocalizationService>(
      context,
      listen: false,
    );
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            localization.translate('guest.events.search.noResults'),
            style: AppStyles.heading4.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            localization.translate('guest.events.search.noResultsDescription'),
            style: AppStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestSearchResults(LocalizationService localization) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return _buildGuestEventCard(_searchResults[index], localization);
      },
    );
  }

  Widget _buildGuestEventCard(
    EventSummary event,
    LocalizationService localization,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getEventTypeColor(event.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getEventTypeIcon(event.type),
                  color: _getEventTypeColor(event.type),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name,
                      style: AppStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (event.hostName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${localization.translate('common.by')} ${event.hostName}',
                        style: AppStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                children: [
                  Text(
                    '${event.date.day}',
                    style: AppStyles.heading4.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _getMonthName(event.date.month),
                    style: AppStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (event.description != null) ...[
            Text(
              event.description!,
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
          ],
          if (event.location != null) ...[
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  event.location!,
                  style: AppStyles.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              _buildGuestEventStat(
                icon: Icons.people_outline,
                value: '${event.acceptedCount}/${event.invitedCount}',
                label: localization.translate('guest.events.card.attendees'),
              ),
              const SizedBox(width: 16),
              _buildGuestEventStat(
                icon: Icons.card_giftcard,
                value: '${event.wishlistItemCount}',
                label: localization.translate('wishlists.items'),
              ),
              const Spacer(),
              CustomButton(
                text: localization.translate('guest.events.card.viewDetails'),
                onPressed: () => _showGuestEventDetails(event),
                variant: ButtonVariant.outline,
                size: ButtonSize.small,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuestEventStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              label,
              style: AppStyles.caption.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
      ],
    );
  }

  void _showGuestSearch(LocalizationService localization) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localization.translate('guest.events.search.title'),
                    style: AppStyles.heading4.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: localization.translate(
                        'guest.events.empty.searchPlaceholder',
                      ),
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: _performGuestSearch,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isSearching && _searchResults.isNotEmpty
                  ? ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        return _buildGuestEventCard(
                          _searchResults[index],
                          localization,
                        );
                      },
                    )
                  : _searchController.text.isEmpty
                  ? _buildGuestSearchSuggestions()
                  : _buildGuestEmptySearch(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestSearchSuggestions() {
    final localization = Provider.of<LocalizationService>(
      context,
      listen: false,
    );
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localization.translate('guest.events.search.popular'),
            style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSearchChip(localization.translate('events.birthday')),
              _buildSearchChip(localization.translate('events.wedding')),
              _buildSearchChip(localization.translate('events.graduation')),
              _buildSearchChip(localization.translate('events.other')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchChip(String text) {
    return GestureDetector(
      onTap: () {
        _searchController.text = text;
        _performGuestSearch(text);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Text(
          text,
          style: AppStyles.bodySmall.copyWith(color: AppColors.primary),
        ),
      ),
    );
  }

  void _performGuestSearch(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        _searchResults.clear();
      } else {
        // Simple search simulation
        _searchResults = _publicEvents
            .where(
              (event) =>
                  event.name.toLowerCase().contains(query.toLowerCase()) ||
                  (event.description?.toLowerCase().contains(
                        query.toLowerCase(),
                      ) ??
                      false),
            )
            .toList();
      }
    });
  }

  void _showGuestEventDetails(EventSummary event) {
    GuestRestrictionDialog.show(
      context,
      'تفاصيل الفعالية',
      customMessage: 'سجل دخولك لعرض تفاصيل الفعالية الكاملة والتفاعل معها.',
    );
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
    return Container(color: AppColors.background, child: _tabBar);
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
  vacation,
  babyShower,
  houseWarming,
  retirement,
  promotion,
  other,
}

enum EventStatus { upcoming, ongoing, completed, cancelled }
