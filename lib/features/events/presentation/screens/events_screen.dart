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
import 'package:wish_listy/core/services/deep_link_service.dart';
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';
import 'package:wish_listy/features/events/data/repository/event_repository.dart';
import 'package:wish_listy/features/events/data/models/event_model.dart';
import 'package:wish_listy/core/services/api_service.dart';
import '../widgets/event_card.dart';
import '../widgets/invited_event_card.dart';
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
    // Only load data when screen becomes visible for the first time
    final isCurrent = ModalRoute.of(context)?.isCurrent ?? false;

    if (isCurrent && !_hasLoadedOnce) {
      _hasLoadedOnce = true;
      // Use a small delay to ensure navigation is complete
      Future.delayed(const Duration(milliseconds: 100), () {
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

  /// Public method to switch to Invited tab (called from MainNavigation)
  void switchToInvitedTab() {
    if (mounted && _tabController.index != 1) {
      _tabController.animateTo(1);
      setState(() {});
    }
  }

  /// Load events from API
  Future<void> _loadEvents() async {
    // Don't make API calls for guest users
    final authService = Provider.of<AuthRepository>(context, listen: false);
    if (authService.isGuest) {
      debugPrint('⚠️ EventsScreen: Skipping API call for guest user');
      setState(() {
        _isLoading = false;
        _myEvents = [];
        _invitedEvents = [];
        _publicEvents = [];
        _hasLoadedOnce = true;
      });
      _applyFilters();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {

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
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
        _myEvents = [];
        _invitedEvents = [];
        _publicEvents = [];
      });
      _applyFilters();

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load events. Please try again.';
        _isLoading = false;
        _myEvents = [];
        _invitedEvents = [];
        _publicEvents = [];
      });
      _applyFilters();

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
                    actions: [
                      HeaderAction(
                        icon: Icons.add_rounded,
                        iconColor: AppColors.primary,
                        onTap: () async {
                          // Navigate to create event
                          await Navigator.pushNamed(
                            context,
                            AppRoutes.createEvent,
                          );
                          // Refresh events list when returning from create event
                          // This handles the case where user creates event and navigates to details,
                          // then comes back to events list
                          if (mounted) {
                            _loadEvents();
                          }
                        },
                      ),
                    ],
                    tabs: [
                      UnifiedTab(
                        label: localization.translate('events.myEvents'),
                        icon: Icons.event_rounded,
                      ),
                      UnifiedTab(
                        label: localization.translate('events.invited'),
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
      color: AppColors.primary,
      child: _isLoading
          ? _buildEventSkeletonList()
          : myFilteredEvents.isEmpty
          ? EmptyMyEvents(localization: localization)
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
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
      color: AppColors.primary,
      child: _isLoading
          ? _buildEventSkeletonList()
          : invitedFilteredEvents.isEmpty
          ? EmptyInvitedEvents(localization: localization)
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                      (event) => InvitedEventCard(
                        event: event,
                        localization: localization,
                        onTap: () => _viewEventDetails(event),
                        onRSVP: (status) => _handleRSVP(event, status),
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
                      (event) => InvitedEventCard(
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

  Future<void> _handleRSVP(EventSummary event, String status) async {
      if (!mounted) return;
      
    // Convert string to InvitationStatus enum
    final invitationStatus = status == 'accepted'
        ? InvitationStatus.accepted
        : status == 'declined'
            ? InvitationStatus.declined
            : InvitationStatus.maybe;

    // Optimistic update - update UI immediately
    _updateEventInvitationStatus(event.id, invitationStatus);

    try {
      // Call API to respond to invitation
      await _eventRepository.respondToEventInvitation(
        eventId: event.id,
        status: status,
      );

      // Show success message (optional, as UI already updated)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'accepted'
                  ? 'You accepted the invitation'
                  : status == 'declined'
                  ? 'You declined the invitation'
                  : 'You marked as maybe',
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      // No need to reload - already updated optimistically
    } catch (e) {
      if (!mounted) return;

      // On error, revert optimistic update and reload to sync with server
      _updateEventInvitationStatus(event.id, event.invitationStatus ?? InvitationStatus.pending);
      await _loadEvents(); // Full reload to ensure consistency
      
      // Show error message
      final localization = Provider.of<LocalizationService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${localization.translate('dialogs.failedToUpdateRsvp')}: ${e.toString()}'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _updateEventInvitationStatus(String eventId, InvitationStatus status) {
    setState(() {
      _invitedEvents = _invitedEvents.map((event) {
        if (event.id == eventId) {
          return event.copyWith(invitationStatus: status);
        }
        return event;
      }).toList();
    });
    _applyFilters(); // Re-apply filters to update _filteredEvents
  }

  void _viewEventWishlist(
    EventSummary event,
    LocalizationService localization,
  ) {
    // Use wishlistId and wishlistName directly from the event
    if (event.wishlistId != null && event.wishlistId!.isNotEmpty) {
      Navigator.pushNamed(
        context,
        AppRoutes.wishlistItems,
        arguments: {
          'wishlistId': event.wishlistId!,
          'wishlistName': event.wishlistName ?? 'Wishlist',
          'totalItems': event.wishlistItemCount,
          'purchasedItems': 0, // Will be loaded from API
          'isFriendWishlist': false,
        },
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
        arguments: {'eventId': event.id, 'event': event},
      );
    } catch (e) {
      if (mounted) {
        final localization = Provider.of<LocalizationService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localization.translate('dialogs.failedToLoadEvent')}: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _shareEvent(EventSummary event) async {
    // Share event using deep link
    await DeepLinkService.shareEvent(
      eventId: event.id,
      eventName: event.name,
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
        final localization = Provider.of<LocalizationService>(context, listen: false);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(localization.translate('dialogs.eventDeletedSuccessfully')),
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
        final localization = Provider.of<LocalizationService>(context, listen: false);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localization.translate('dialogs.failedToDeleteEvent')}: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }

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
