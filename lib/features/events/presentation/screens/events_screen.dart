import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/core/widgets/decorative_background.dart';
import 'package:wish_listy/core/widgets/unified_page_header.dart';
import 'package:wish_listy/core/widgets/unified_tab_bar.dart';
import 'package:wish_listy/core/widgets/unified_page_container.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';
import '../widgets/event_card.dart';
import '../widgets/guest_events_view.dart';
import '../widgets/empty_states.dart';
import '../widgets/event_modals.dart';

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
  String _searchQuery = '';

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
      wishlistId: 'wishlist_1', // Has wishlist
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
      wishlistItemCount: 0, // No wishlist yet
      wishlistId: null, // No wishlist linked
      isCreatedByMe: true,
      status: EventStatus.upcoming,
    ),
    EventSummary(
      id: '3',
      name: 'Team Building Event',
      date: DateTime.now().add(Duration(days: 7)),
      type: EventType.other,
      location: 'Office',
      description: 'Team building activities and games',
      invitedCount: 20,
      acceptedCount: 15,
      wishlistItemCount: 0, // No wishlist yet
      wishlistId: null, // No wishlist linked
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
      wishlistId: 'wishlist_pub1', // Has wishlist
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
      wishlistId: 'wishlist_pub2', // Has wishlist
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
      wishlistId: 'wishlist_wedding', // Has wishlist
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
      wishlistItemCount: 0, // No wishlist yet
      wishlistId: null, // No wishlist linked
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
      wishlistId: 'wishlist_baby', // Has wishlist
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
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
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

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      allEvents = allEvents.where((event) {
        return event.name.toLowerCase().contains(_searchQuery) ||
            (event.location?.toLowerCase().contains(_searchQuery) ?? false) ||
            (event.hostName?.toLowerCase().contains(_searchQuery) ?? false) ||
            (event.description?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }

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
    return Consumer2<LocalizationService, AuthRepository>(
      builder: (context, localization, authService, child) {
        // For guest users - show different interface
        if (authService.isGuest) {
          return Scaffold(
            body: UnifiedPageBackground(
              child: DecorativeBackground(
                showGifts: true,
                child: Column(
                  children: [
                    // Guest Page Header
                    UnifiedPageHeader(
                      title: localization.translate('navigation.events'),
                      subtitle: 'Explore public events',
                      showSearch: true,
                      searchHint: localization.translate('events.searchEvents'),
                      onSearchTap: () {
                        // Search functionality for guests
                      },
                    ),
                    // Content
                    Expanded(
                      child: UnifiedPageContainer(
                        child: AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return FadeTransition(
                              opacity: _fadeAnimation,
                              child: GuestEventsView(
                                publicEvents: _publicEvents,
                                localization: localization,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // For authenticated users - show full interface
        return Scaffold(
          body: UnifiedPageBackground(
            child: DecorativeBackground(
              showGifts: true,
              child: Column(
                children: [
                  // Unified Page Header with Integrated Tabs
                  UnifiedPageHeader(
                    title: localization.translate('events.title'),
                    titleIcon: Icons.celebration_rounded,
                    titleIconColor: AppColors.accent,
                    showSearch: true,
                    searchHint: localization.translate('events.searchEvents'),
                    searchController: _searchController,
                    onSearchChanged: (query) {
                      // Search is handled by listener
                    },
                    actions: [
                      HeaderAction(
                        icon: Icons.calendar_month_outlined,
                        onTap: _showCalendarView,
                      ),
                      HeaderAction(
                        icon: Icons.filter_list_outlined,
                        onTap: _showFilterOptions,
                      ),
                    ],
                    tabs: [
                      UnifiedTab(
                        label: localization.translate('events.myEvents'),
                        icon: Icons.event_rounded,
                        badgeCount: _myEvents.length,
                      ),
                      UnifiedTab(
                        label: localization.translate('events.invited'),
                        badgeCount: _invitedEvents
                            .where((e) => e.status == EventStatus.upcoming)
                            .length,
                      ),
                    ],
                    selectedTabIndex: _tabController.index,
                    onTabChanged: (index) {
                      _tabController.animateTo(index);
                      setState(() {});
                    },
                    selectedTabColor: AppColors.primary,
                  ),

                  // Tab Content in rounded container
                  Expanded(
                    child: UnifiedPageContainer(
                      child: AnimatedBuilder(
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
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.createEvent);
            },
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            heroTag: 'events_fab',
            child: Icon(Icons.add_rounded),
          ),
        );
      },
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
          ? EmptyMyEvents(localization: localization)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: myFilteredEvents.length + 1,
              itemBuilder: (context, index) {
                if (index == myFilteredEvents.length) {
                  return const SizedBox(height: 100);
                }
                return EventCard(
                  event: myFilteredEvents[index],
                  localization: localization,
                  onTap: () => _viewEventDetails(myFilteredEvents[index]),
                  onManageEvent: () => _manageEvent(myFilteredEvents[index]),
                  onViewWishlist: () =>
                      _viewEventWishlist(myFilteredEvents[index], localization),
                  onAddWishlist: () => _addWishlistToEvent(
                    myFilteredEvents[index],
                    localization,
                  ),
                );
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
          ? EmptyInvitedEvents(localization: localization)
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
                      (event) => EventCard(
                        event: event,
                        localization: localization,
                        onTap: () => _viewEventDetails(event),
                        onViewWishlist: () =>
                            _viewEventWishlist(event, localization),
                      ),
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
                      (event) => EventCard(
                        event: event,
                        localization: localization,
                        onTap: () => _viewEventDetails(event),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  const SizedBox(height: 100),
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

  // Action Handlers
  void _viewEventDetails(EventSummary event) {
    AppRoutes.pushNamed(
      context,
      AppRoutes.eventDetails,
      arguments: {'eventId': event.id},
    );
  }

  void _viewEventWishlist(
    EventSummary event,
    LocalizationService localization,
  ) {
    List<Map<String, dynamic>> associatedWishlists = _getAssociatedWishlists(
      event,
    );

    if (associatedWishlists.length == 1) {
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
      EventModals.showWishlistSelectionModal(
        context,
        event,
        associatedWishlists,
        localization,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localization.translate('events.noWishlistsAssociated')),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  void _addWishlistToEvent(
    EventSummary event,
    LocalizationService localization,
  ) {
    EventModals.showAddWishlistToEventModal(context, event, localization);
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

  void _manageEvent(EventSummary event) {
    // Navigate to event management screen
    Navigator.pushNamed(context, AppRoutes.eventManagement, arguments: event);
  }

  void _showCalendarView() {
    final localization = Provider.of<LocalizationService>(
      context,
      listen: false,
    );

    EventModals.showCalendarView(context, _filteredEvents, localization);
  }

  void _showFilterOptions() {
    EventModals.showFilterOptions(
      context,
      _selectedSortOption,
      _selectedEventType,
      (sortOption) {
        setState(() {
          _selectedSortOption = sortOption;
        });
      },
      (eventType) {
        setState(() {
          _selectedEventType = eventType;
        });
      },
      () {
        setState(() {
          _selectedSortOption = 'date_upcoming';
          _selectedEventType = null;
        });
        _applyFilters();
      },
      () {
        _applyFilters();
      },
    );
  }

  Future<void> _refreshEvents() async {
    // Refresh events data
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      // Update events data
    });
    _applyFilters();
  }
}
