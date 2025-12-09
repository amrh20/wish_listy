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
import 'package:wish_listy/features/events/data/repository/event_repository.dart';
import 'package:wish_listy/features/events/data/models/event_model.dart';
import 'package:wish_listy/core/services/api_service.dart';
import '../widgets/event_card.dart';
import '../widgets/guest_events_view.dart';
import '../widgets/empty_states.dart';
import '../widgets/event_modals.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  EventsScreenState createState() => EventsScreenState();
}

class EventsScreenState extends State<EventsScreen>
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

  // Events data (loaded from API)
  List<EventSummary> _myEvents = [];
  List<EventSummary> _invitedEvents = [];
  List<EventSummary> _publicEvents = [];

  // Loading and error states
  bool _isLoading = false; // Start as false, will be set to true when loading
  String? _errorMessage;

  // Repository
  final EventRepository _eventRepository = EventRepository();

  // Mock events data for authenticated users (fallback)
  final List<EventSummary> _mockMyEvents = [
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

  // Mock public events for guest users (fallback)
  final List<EventSummary> _mockPublicEvents = [
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

  // Mock invited events (fallback)
  final List<EventSummary> _mockInvitedEvents = [
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

  bool _hasLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeAnimations();
    _startAnimations();
    _searchController.addListener(_onSearchChanged);
    // Don't load events automatically - wait for tab tap
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when screen becomes visible after returning from another screen
    final isCurrent = ModalRoute.of(context)?.isCurrent ?? false;

    if (isCurrent && _hasLoadedOnce) {
      // Screen is now visible and we've loaded before, reload data
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadEvents();
        }
      });
    }
  }

  /// Public method to refresh events (called from MainNavigation)
  void refreshEvents() {
    if (mounted) {
      _hasLoadedOnce = true;
      _loadEvents();
    }
  }

  /// Load events from API
  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('📥 Loading events from API...');
      final events = await _eventRepository.getEvents();

      if (!mounted) return;

      // Get current user ID from AuthRepository
      final authService = Provider.of<AuthRepository>(context, listen: false);
      final currentUserId = authService.userId;

      // Convert Event objects to EventSummary
      final myEventsList = <EventSummary>[];
      final invitedEventsList = <EventSummary>[];

      for (final event in events) {
        // Use fromEvent factory with currentUserId to determine isCreatedByMe
        final summary = EventSummary.fromEvent(
          event,
          currentUserId: currentUserId,
        );

        if (summary.isCreatedByMe) {
          myEventsList.add(summary);
        } else {
          invitedEventsList.add(summary);
        }
      }

      setState(() {
        _myEvents = myEventsList;
        _invitedEvents = invitedEventsList;
        _publicEvents =
            []; // Public events would come from a different endpoint
        _isLoading = false;
        _hasLoadedOnce = true; // Mark as loaded
      });

      _applyFilters();
      debugPrint(
        '✅ Loaded ${events.length} events (${myEventsList.length} my events, ${invitedEventsList.length} invited)',
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
        // Use mock data as fallback
        _myEvents = _mockMyEvents;
        _invitedEvents = _mockInvitedEvents;
        _publicEvents = _mockPublicEvents;
      });
      _applyFilters();
      debugPrint('❌ API Error loading events: ${e.message}');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load events. Please try again.';
        _isLoading = false;
        // Use mock data as fallback
        _myEvents = _mockMyEvents;
        _invitedEvents = _mockInvitedEvents;
        _publicEvents = _mockPublicEvents;
      });
      _applyFilters();
      debugPrint('❌ Error loading events: $e');
    }
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
            backgroundColor: AppColors.background,
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
                    showSearch: true,
                    searchHint: localization.translate('events.searchEvents'),
                    searchController: _searchController,
                    onSearchChanged: (query) {
                      // Search is handled by listener
                    },
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
      child: _isLoading
          ? _buildEventSkeletonList()
          : myFilteredEvents.isEmpty
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
                  onEdit: () => _editEvent(myFilteredEvents[index]),
                  onShare: () => _shareEvent(myFilteredEvents[index]),
                  onDelete: () => _deleteEvent(myFilteredEvents[index]),
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
      child: _isLoading
          ? _buildEventSkeletonList()
          : invitedFilteredEvents.isEmpty
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
  void _viewEventDetails(EventSummary event) async {
    await Navigator.pushNamed(
      context,
      AppRoutes.eventDetails,
      arguments: {'eventId': event.id},
    );
    
    // Always refresh events list when returning from event details
    // This ensures data is updated after create/edit/delete operations
    if (mounted) {
      _loadEvents();
    }
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

  Future<void> _editEvent(EventSummary eventSummary) async {
    try {
      // Fetch full event data for editing
      final event = await _eventRepository.getEventById(eventSummary.id);
      
      // Navigate to create event screen with edit mode
      Navigator.pushNamed(
        context,
        AppRoutes.createEvent,
        arguments: {
          'eventId': event.id,
          'event': event,
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load event: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _shareEvent(EventSummary event) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share functionality coming soon'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  Future<void> _deleteEvent(EventSummary event) async {
    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: AppColors.surface,
          title: Text(
            'Delete Event',
            style: AppStyles.headingSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${event.name}"? This action cannot be undone.',
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: AppStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Delete',
                style: AppStyles.bodyMedium.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    // Show loading indicator with event name
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Deleting Event',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '"${event.name}"',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.warning,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    try {
      // Delete event via API
      await _eventRepository.deleteEvent(event.id);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Event deleted successfully'),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );

        // Reload events list to update the screen
        await _loadEvents();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete event: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      debugPrint('❌ Error deleting event: $e');
    }
  }

  Future<void> _refreshEvents() async {
    // Refresh events data from API
    await _loadEvents();
  }

  /// Build skeleton loading list for event cards
  Widget _buildEventSkeletonList() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // Create pulsing effect using sine wave - lighter and smoother
        final pulseValue =
            (0.15 +
            (0.2 *
                (0.5 +
                    0.5 * (1 + (2 * _animationController.value - 1).abs()))));

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: 3, // Show 3 skeleton cards
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            return _buildEventCardSkeleton(pulseValue);
          },
        );
      },
    );
  }

  /// Build a single event card skeleton
  Widget _buildEventCardSkeleton(double pulseValue) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.border.withOpacity(0.8),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header Section (Teal Background)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.06),
              ),
              child: Row(
                children: [
                  // Icon Skeleton
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.secondary.withOpacity(
                            0.08 + pulseValue * 0.05,
                          ),
                          AppColors.secondary.withOpacity(
                            0.12 + pulseValue * 0.05,
                          ),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Title and Location Skeleton
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 180,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(
                              0.1 + pulseValue * 0.05,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 120,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(
                              0.08 + pulseValue * 0.03,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Date Badge Skeleton
                  Container(
                    width: 50,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(
                        0.1 + pulseValue * 0.05,
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  // MoreVert Button Skeleton
                  const SizedBox(width: 8),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(
                        0.08 + pulseValue * 0.03,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
            // Body Section (White Background)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: AppColors.surface),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description Skeleton
                  Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(
                        0.06 + pulseValue * 0.03,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 200,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(
                        0.06 + pulseValue * 0.03,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Stats Row Skeleton
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildEventStatSkeleton(pulseValue),
                      _buildEventStatSkeleton(pulseValue),
                      _buildEventStatSkeleton(pulseValue),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Action Button Skeleton
                  Container(
                    height: 44,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(
                        0.06 + pulseValue * 0.03,
                      ),
                      borderRadius: BorderRadius.circular(16),
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

  /// Build a stat column skeleton for events
  Widget _buildEventStatSkeleton(double pulseValue) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.06 + pulseValue * 0.03),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 30,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.1 + pulseValue * 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 50,
          height: 12,
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.08 + pulseValue * 0.03),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ],
    );
  }
}
