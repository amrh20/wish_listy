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
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;
  
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Filter and sort variables
  String _selectedSortOption = 'date_upcoming';
  String? _selectedEventType;
  List<EventSummary> _filteredEvents = [];
  // Keep a copy of events filtered by search/type but BEFORE status filter,
  // so we can show accurate counts in the filter chips.
  List<EventSummary> _baseFilteredEvents = [];
  // Status filter (Wishlists-style chips)
  String _selectedStatusFilter = 'all'; // 'all' | 'upcoming' | 'past'

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
  Future<void> _loadEvents({bool forceShowSkeleton = false}) async {
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

    // Smart Loading: Only show skeleton if data doesn't exist yet
    // If data exists, refresh in background without showing skeleton
    final hasExistingData = _myEvents.isNotEmpty || _invitedEvents.isNotEmpty;
    if (!hasExistingData || forceShowSkeleton) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      debugPrint('🔄 EventsScreen: Background refresh (no skeleton)');
      // Still clear error message
      if (_errorMessage != null) {
        setState(() {
          _errorMessage = null;
        });
      }
    }

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

    // Save base filtered list (before status filter) for chip counts per tab
    _baseFilteredEvents = allEvents;

    // Apply status filter (All / Upcoming / Past)
    bool isPastStatus(EventStatus s) =>
        s == EventStatus.completed || s == EventStatus.cancelled;
    if (_selectedStatusFilter == 'upcoming') {
      allEvents = allEvents.where((e) => !isPastStatus(e.status)).toList();
    } else if (_selectedStatusFilter == 'past') {
      allEvents = allEvents.where((e) => isPastStatus(e.status)).toList();
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

  Widget _buildStatusFilterTabs(
    LocalizationService localization, {
    required int allCount,
    required int upcomingCount,
    required int pastCount,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(
            Icons.filter_list_rounded,
            size: 20,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          _buildStatusChip(
            label: localization.translate('ui.all'),
            value: 'all',
            isSelected: _selectedStatusFilter == 'all',
            icon: Icons.list_rounded,
            count: allCount,
          ),
          const SizedBox(width: 8),
          _buildStatusChip(
            label: localization.translate('events.upcoming'),
            value: 'upcoming',
            isSelected: _selectedStatusFilter == 'upcoming',
            icon: Icons.upcoming_rounded,
            count: upcomingCount,
          ),
          const SizedBox(width: 8),
          _buildStatusChip(
            label: localization.translate('events.past'),
            value: 'past',
            isSelected: _selectedStatusFilter == 'past',
            icon: Icons.history_rounded,
            count: pastCount,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip({
    required String label,
    required String value,
    required bool isSelected,
    required IconData icon,
    required int count,
  }) {
    return GestureDetector(
      onTap: () {
        if (_selectedStatusFilter == value) return;
        setState(() {
          _selectedStatusFilter = value;
        });
        _applyFilters();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primary : AppColors.textTertiary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppStyles.bodySmall.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textTertiary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: AppStyles.caption.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInlineFilteredEmpty(
    LocalizationService localization, {
    required String filter, // 'all' | 'upcoming' | 'past'
  }) {
    final String title = switch (filter) {
      'past' => localization.translate('events.noPastEvents'),
      'upcoming' => localization.translate('events.noUpcomingEvents'),
      _ => localization.translate('events.noEvents'),
    };

    final IconData icon = switch (filter) {
      'past' => Icons.history_rounded,
      'upcoming' => Icons.event_busy_rounded,
      _ => Icons.event_busy_rounded,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 30,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: AppStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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
    super.build(context); // Keep alive
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
    final myBaseEvents = _baseFilteredEvents.where((e) => e.isCreatedByMe).toList();
    final myFilteredEvents = _filteredEvents.where((e) => e.isCreatedByMe).toList();
    bool isPastStatus(EventStatus s) =>
        s == EventStatus.completed || s == EventStatus.cancelled;
    final allCount = myBaseEvents.length;
    final upcomingCount = myBaseEvents.where((e) => !isPastStatus(e.status)).length;
    final pastCount = myBaseEvents.where((e) => isPastStatus(e.status)).length;

    return RefreshIndicator(
      onRefresh: _refreshEvents,
      color: AppColors.primary,
      child: _isLoading
          ? _buildEventSkeletonList()
          : allCount == 0
              ? EmptyMyEvents(localization: localization)
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildStatusFilterTabs(
                        localization,
                        allCount: allCount,
                        upcomingCount: upcomingCount,
                        pastCount: pastCount,
                      ),
                    ),
                    if (myFilteredEvents.isEmpty)
                      _buildInlineFilteredEmpty(
                        localization,
                        filter: _selectedStatusFilter,
                      )
                    else ...[
                      ...myFilteredEvents.map(
                        (e) => EventCard(
                          event: e,
                          localization: localization,
                          onTap: () => _viewEventDetails(e),
                          onManageEvent: () => _manageEvent(e),
                          onViewWishlist: () => _viewEventWishlist(e, localization),
                          onAddWishlist: () => _addWishlistToEvent(e, localization),
                          onEdit: () => _editEvent(e),
                          onShare: () => _shareEvent(e),
                          onDelete: () => _deleteEvent(e),
                        ),
                      ),
                    ],
                    const SizedBox(height: 100),
                  ],
                ),
    );
  }

  Widget _buildInvitedEventsTab(LocalizationService localization) {
    final invitedBaseEvents =
        _baseFilteredEvents.where((e) => !e.isCreatedByMe).toList();
    final invitedFilteredEvents =
        _filteredEvents.where((e) => !e.isCreatedByMe).toList();
    bool isPastStatus(EventStatus s) =>
        s == EventStatus.completed || s == EventStatus.cancelled;
    final allCount = invitedBaseEvents.length;
    final upcomingCount =
        invitedBaseEvents.where((e) => !isPastStatus(e.status)).length;
    final pastCount = invitedBaseEvents.where((e) => isPastStatus(e.status)).length;

    final upcomingEvents =
        invitedFilteredEvents.where((e) => !isPastStatus(e.status)).toList();
    final pastEvents =
        invitedFilteredEvents.where((e) => isPastStatus(e.status)).toList();

    return RefreshIndicator(
      onRefresh: _refreshEvents,
      color: AppColors.primary,
      child: _isLoading
          ? _buildEventSkeletonList()
          : allCount == 0
              ? EmptyInvitedEvents(localization: localization)
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildStatusFilterTabs(
                          localization,
                          allCount: allCount,
                          upcomingCount: upcomingCount,
                          pastCount: pastCount,
                        ),
                      ),
                      if (invitedFilteredEvents.isEmpty)
                        _buildInlineFilteredEmpty(
                          localization,
                          filter: _selectedStatusFilter,
                        )
                      else ...[
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
