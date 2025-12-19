import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'package:wish_listy/core/widgets/decorative_background.dart';
import 'package:wish_listy/core/widgets/unified_page_header.dart';
import 'package:wish_listy/core/widgets/unified_page_container.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';
import 'package:wish_listy/features/wishlists/data/repository/wishlist_repository.dart';
import 'package:wish_listy/features/wishlists/data/repository/guest_data_repository.dart';
import 'package:wish_listy/features/wishlists/data/models/wishlist_model.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:wish_listy/features/notifications/data/models/notification_model.dart';
import 'package:wish_listy/core/services/socket_service.dart';
import 'package:wish_listy/features/friends/data/repository/friends_repository.dart';
import 'package:wish_listy/features/profile/presentation/screens/main_navigation.dart';

class HomeScreen extends StatefulWidget {
  final GlobalKey<HomeScreenState>? key;

  const HomeScreen({this.key}) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final ScrollController _scrollController = ScrollController();
  bool _showWelcomeCard = true;
  bool _hasWishlists = false;
  bool _isCheckingWishlists = false;
  int _wishlistCount = 0;
  final WishlistRepository _wishlistRepository = WishlistRepository();
  
  // Guest user data
  List<Wishlist> _guestWishlists = [];
  bool _isLoadingGuestData = false;
  bool _hasLoadedOnce = false;
  
  // Notification dropdown key
  final GlobalKey _notificationIconKey = GlobalKey();
  
  // Track last shown notification ID to avoid duplicate snackbars
  String? _lastShownNotificationId;
  
  // Track friend request action states (loading, success, error) per notification
  final Map<String, String> _notificationActionStates = {}; // 'loading', 'accepted', 'rejected', 'error'

  // Mock data - replace with real data from your backend
  final List<UpcomingEvent> _upcomingEvents = [
    UpcomingEvent(
      id: '1',
      name: 'Sarah\'s Birthday',
      date: DateTime.now().add(Duration(days: 3)),
      type: 'Birthday',
      hostName: 'Sarah Johnson',
      imageUrl: null,
    ),
    UpcomingEvent(
      id: '2',
      name: 'Wedding Anniversary',
      date: DateTime.now().add(Duration(days: 7)),
      type: 'Anniversary',
      hostName: 'Mike & Lisa',
      imageUrl: null,
    ),
    UpcomingEvent(
      id: '3',
      name: 'Graduation Party',
      date: DateTime.now().add(Duration(days: 12)),
      type: 'Graduation',
      hostName: 'Ahmed Ali',
      imageUrl: null,
    ),
  ];

  final List<FriendActivity> _friendActivities = [
    FriendActivity(
      id: '1',
      friendName: 'Emma Watson',
      action: 'added 3 new items to her wishlist',
      timeAgo: '2 hours ago',
      imageUrl: null,
    ),
    FriendActivity(
      id: '2',
      friendName: 'John Smith',
      action: 'created a new event: "Housewarming Party"',
      timeAgo: '5 hours ago',
      imageUrl: null,
    ),
    FriendActivity(
      id: '3',
      friendName: 'Fatima Al-Zahra',
      action: 'marked an item as received',
      timeAgo: '1 day ago',
      imageUrl: null,
    ),
  ];

  final List<GiftSuggestion> _giftSuggestions = [
    GiftSuggestion(
      id: '1',
      title: 'Smart Watch for Ahmed',
      subtitle: 'Based on his tech wishlist',
      price: '\$299',
      friendName: 'Ahmed',
      imageUrl: null,
    ),
    GiftSuggestion(
      id: '2',
      title: 'Art Supplies for Emma',
      subtitle: 'Perfect for her creative hobby',
      price: '\$45',
      friendName: 'Emma',
      imageUrl: null,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimations();
    _checkWishlists();
    _startAnimations();
    _loadGuestWishlists();
    // Load notifications when screen appears (only for authenticated users)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthRepository>(context, listen: false);
      if (authService.isAuthenticated && !authService.isGuest) {
        context.read<NotificationsCubit>().loadNotifications();
        
        // Debug: Check Socket.IO connection status
        final socketService = SocketService();
        socketService.printConnectionStatus();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Reload data when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _loadGuestWishlists();
      _checkWishlists();
      
      // Connect socket when app resumes (as per requirements)
      final authService = Provider.of<AuthRepository>(context, listen: false);
      if (authService.isAuthenticated && !authService.isGuest) {
        final socketService = SocketService();
        if (!socketService.isConnected) {
          debugPrint('🔄 [HomeScreen] App resumed - Connecting socket...');
          socketService.connect();
        } else {
          debugPrint('🔄 [HomeScreen] App resumed - Socket already connected');
        }
      }
    } else if (state == AppLifecycleState.paused) {
      // Optionally disconnect socket when app is paused to save resources
      // But we keep it connected for real-time notifications
      debugPrint('🔄 [HomeScreen] App paused - Keeping socket connected for notifications');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload guest wishlists when screen becomes visible
    // This ensures data is fresh when navigating back to home screen
    if (!_hasLoadedOnce) {
      _hasLoadedOnce = true;
      return; // Skip reload on first call (already loaded in initState)
    }
    
    // Reload data when screen becomes visible again (e.g., navigating back from another screen)
    final authService = Provider.of<AuthRepository>(context, listen: false);
    if (authService.isGuest) {
      // Reload guest wishlists to reflect any changes (e.g., deletions)
      _loadGuestWishlists();
    }
  }

  /// Check if user has any wishlists
  Future<void> _checkWishlists() async {
    final authService = Provider.of<AuthRepository>(context, listen: false);

    // Only check for authenticated users
    if (!authService.isAuthenticated || authService.isGuest) {
      return;
    }

    setState(() {
      _isCheckingWishlists = true;
    });

    try {
      final wishlists = await _wishlistRepository.getWishlists();

      setState(() {
        _hasWishlists = wishlists.isNotEmpty;
        _wishlistCount = wishlists.length;
        _showWelcomeCard =
            !_hasWishlists; // Hide welcome card if user has wishlists
        _isCheckingWishlists = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _isCheckingWishlists = false;
        // Keep welcome card visible if there's an error
      });
    } catch (e) {
      setState(() {
        _isCheckingWishlists = false;
      });
    }
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
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

    // Pulse animation for empty state button
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _pulseController.repeat(reverse: true);
  }

  void _startAnimations() {
    _animationController.forward();
  }


  @override
  bool get wantKeepAlive => true;

  /// Refresh guest wishlists data - called from MainNavigation
  void refreshGuestWishlists() {
    final authService = Provider.of<AuthRepository>(context, listen: false);
    if (authService.isGuest) {
      _loadGuestWishlists();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Consumer2<LocalizationService, AuthRepository>(
      builder: (context, localization, authService, child) {
        // For guest users, use UnifiedPageHeader like wishlist screen
        if (authService.isGuest) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: UnifiedPageBackground(
              child: DecorativeBackground(
                showGifts: true,
                child: Column(
                  children: [
                    // Unified Page Header with welcome message
                    UnifiedPageHeader(
                      title: 'WishListy',
                      titleIcon: Icons.favorite_rounded,
                      subtitle: 'Hello there! 👋\nWelcome to WishListy. Start by creating your first wishlist and organize your dreams.',
                      showSearch: false,
                      subtitleStyle: AppStyles.bodyMedium.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.normal,
                      ),
                      titleSubtitleSpacing: 32,
                      customSubtitleWidget: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello there! 👋',
                            style: AppStyles.headingMedium.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Welcome to WishListy. Start by creating your first wishlist and organize your dreams.',
                            style: AppStyles.bodyMedium.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.normal,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.visible,
                          ),
                        ],
                      ),
                      actions: [
                        HeaderAction(
                          icon: Icons.login_rounded,
                          iconColor: AppColors.primary,
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.login);
                          },
                        ),
                      ],
                    ),
                    // Content in rounded container with decorative blobs
                    Expanded(
                      child: Stack(
                        children: [
                          // Decorative background blobs (behind everything, extends to bottom)
                          _buildDecorativeBlobsForEmptyState(),
                          UnifiedPageContainer(
                            backgroundColor: _guestWishlists.isEmpty ? Colors.transparent : null,
                            showShadow: !_guestWishlists.isEmpty,
                            child: RefreshIndicator(
                              onRefresh: _refreshData,
                              color: AppColors.primary,
                              child: AnimatedBuilder(
                                animation: _animationController,
                                builder: (context, child) {
                                  return FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: SlideTransition(
                                      position: _slideAnimation,
                                      child: SingleChildScrollView(
                                        controller: _scrollController,
                                        physics: const AlwaysScrollableScrollPhysics(),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Guest Wishlist Section
                                              if (_isLoadingGuestData) ...[
                                                const Center(
                                                  child: Padding(
                                                    padding: EdgeInsets.all(32.0),
                                                    child: CircularProgressIndicator(),
                                                  ),
                                                ),
                                              ] else if (_guestWishlists.isEmpty) ...[
                                                _buildCreateFirstWishlistButton(),
                                              ] else ...[
                                                _buildGuestWishlistList(),
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
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // For authenticated users, use original layout
        return Scaffold(
          backgroundColor: AppColors.background,
          body: UnifiedPageBackground(
            child: DecorativeBackground(
              child: Column(
                children: [
                  // Unified Page Header
                  _buildUnifiedHeader(localization, authService),

                  // Content in rounded container (with negative margin to overlap header)
                  Expanded(
                    child: Transform.translate(
                      offset: const Offset(
                        0,
                        -8,
                      ), // Move up to overlap header and hide gray gap
                      child: UnifiedPageContainer(
                        showTopRadius: true,
                        child: RefreshIndicator(
                          onRefresh: _refreshData,
                          color: AppColors.primary,
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Regular Welcome Card for logged users (only if no wishlists)
                                          if (_showWelcomeCard &&
                                              !_hasWishlists &&
                                              !_isCheckingWishlists) ...[
                                            _buildWelcomeCard(localization),
                                            const SizedBox(height: 24),
                                          ],

                                          // Summary Card is now in the header (removed from body)

                                          // Quick Actions
                                          _buildQuickActions(localization),
                                          SizedBox(
                                            height: _hasWishlists ? 20 : 24,
                                          ),

                                          // Upcoming Events (only for authenticated users)
                                          if (authService.isAuthenticated) ...[
                                            _buildUpcomingEvents(localization),
                                            const SizedBox(height: 32),
                                          ],

                                          // Friend Activity (only for authenticated users)
                                          if (authService.isAuthenticated) ...[
                                            _buildFriendActivity(localization),
                                            const SizedBox(height: 32),
                                          ],

                                          // Gift Suggestions (limited for guests)
                                          if (authService.isAuthenticated) ...[
                                            _buildGiftSuggestions(localization),
                                            const SizedBox(height: 32),
                                          ],

                                          const SizedBox(
                                            height: 100,
                                          ), // Bottom padding for FAB
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
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


  Widget _buildUnifiedHeader(
    LocalizationService localization,
    AuthRepository authService,
  ) {
    return BlocListener<NotificationsCubit, NotificationsState>(
      listener: (context, state) {
        final timestamp = DateTime.now().toIso8601String();
        debugPrint('🖥️ [UI] ⏰ [$timestamp] BlocListener triggered - State changed');
        debugPrint('🖥️ [UI] ⏰ [$timestamp]    New state type: ${state.runtimeType}');
        
        if (state is NotificationsLoaded) {
          debugPrint('🖥️ [UI] ⏰ [$timestamp]    Notifications count: ${state.notifications.length}');
          debugPrint('🖥️ [UI] ⏰ [$timestamp]    Unread count: ${state.unreadCount}');
          debugPrint('🖥️ [UI] ⏰ [$timestamp]    Is new notification: ${state.isNewNotification}');
          
          // Show snackbar ONLY for new notifications from Socket (not from API load)
          // Skip snackbar for friend requests (they are shown in the banner instead)
          if (state.isNewNotification && state.unreadCount > 0 && state.notifications.isNotEmpty) {
            final latestNotification = state.notifications.first;
            
            // Skip snackbar for friend requests
            if (latestNotification.type == NotificationType.friendRequest) {
              debugPrint('🖥️ [UI] ⏰ [$timestamp]    ⚠️ Skipping snackbar for friend request (shown in banner instead)');
              return;
            }
            
            // Only show snackbar if this is a new notification (not already shown)
            if (_lastShownNotificationId != latestNotification.id) {
              debugPrint('🖥️ [UI] ⏰ [$timestamp]    New notification detected: ${latestNotification.id}');
              debugPrint('🖥️ [UI] ⏰ [$timestamp]    Last shown: $_lastShownNotificationId');
              debugPrint('🖥️ [UI] ⏰ [$timestamp]    Showing snackbar for notification: ${latestNotification.title}');
              
              _lastShownNotificationId = latestNotification.id;
              
              ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(
                      Icons.notifications_active,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            latestNotification.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            latestNotification.message,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppColors.accent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: EdgeInsets.all(16),
                duration: Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'View',
                  textColor: Colors.white,
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.notifications);
                  },
                ),
              ),
            );
            
              final snackbarTimestamp = DateTime.now().toIso8601String();
              debugPrint('🖥️ [UI] ⏰ [$snackbarTimestamp]    ✅ Snackbar displayed successfully');
            } else {
              debugPrint('🖥️ [UI] ⏰ [$timestamp]    ⚠️ Notification already shown, skipping snackbar');
              debugPrint('🖥️ [UI] ⏰ [$timestamp]       Notification ID: ${latestNotification.id}');
              debugPrint('🖥️ [UI] ⏰ [$timestamp]       Last shown ID: $_lastShownNotificationId');
            }
          } else {
            debugPrint('🖥️ [UI] ⏰ [$timestamp]    ⚠️ No unread notifications or empty list');
            debugPrint('🖥️ [UI] ⏰ [$timestamp]       Unread count: ${state.unreadCount}');
            debugPrint('🖥️ [UI] ⏰ [$timestamp]       Notifications count: ${state.notifications.length}');
          }
        } else {
          debugPrint('🖥️ [UI] ⏰ [$timestamp]    ⚠️ State is not NotificationsLoaded');
        }
      },
      child: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, notificationsState) {
          final rebuildTimestamp = DateTime.now().toIso8601String();
          debugPrint('🖥️ [UI] ⏰ [$rebuildTimestamp] BlocBuilder rebuild triggered');
          debugPrint('🖥️ [UI] ⏰ [$rebuildTimestamp]    State type: ${notificationsState.runtimeType}');
          
          // Get unread count from notifications state
          int unreadCount = 0;
          if (notificationsState is NotificationsLoaded) {
            unreadCount = notificationsState.unreadCount;
            debugPrint('🖥️ [UI] ⏰ [$rebuildTimestamp]    Unread count: $unreadCount');
          }

          // Get notifications list
          List<AppNotification> notifications = [];
          if (notificationsState is NotificationsLoaded) {
            notifications = notificationsState.notifications;
            debugPrint('🖥️ [UI] ⏰ [$rebuildTimestamp]    Notifications count: ${notifications.length}');
          }

          debugPrint('🖥️ [UI] ⏰ [$rebuildTimestamp]    Building UnifiedPageHeader with badge: ${unreadCount > 0}');

          return UnifiedPageHeader(
          title: '${localization.translate('home.greeting')} 👋',
          subtitle: authService.userName ?? 'User',
          showSearch: false,
          actions: [
            HeaderAction(
              icon: Icons.notifications_outlined,
              onTap: () {
                _showNotificationDropdown(context, notifications, localization);
              },
              showBadge: unreadCount > 0, // Show badge when there are unread notifications
              badgeCount: unreadCount > 0 ? unreadCount : null, // Show count when there are unread notifications
              badgeColor: AppColors.accent,
            ),
          ],
          // Add wishlist card as bottom content when user has wishlists
          // Show skeleton loading while checking, or card if has wishlists
          bottomContent: _isCheckingWishlists
              ? _buildWishlistCardSkeleton()
              : (_hasWishlists ? _buildSummaryCard(localization) : null),
          // Remove bottom margin to allow container to overlap
          bottomMargin: 0.0,
        );
        },
      ),
    );
  }

  Widget _buildWelcomeCard(LocalizationService localization) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary,
            AppColors.primaryLight,
            const Color(0xFF8B5CF6), // primaryAccent
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            offset: const Offset(0, 8),
            blurRadius: 24,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localization.translate('home.welcomeBanner.title'),
                      style: AppStyles.headingSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      localization.translate('home.welcomeBanner.description'),
                      style: AppStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _showWelcomeCard = false;
                  });
                },
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                style: IconButton.styleFrom(
                  minimumSize: const Size(40, 40),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: localization.translate(
              'home.welcomeBanner.createFirstWishlist',
            ),
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.createWishlist,
                arguments: {
                  'isEvent': false,
                  'previousRoute': AppRoutes.mainNavigation,
                },
              );
            },
            variant: ButtonVariant.secondary,
            customColor: Colors.white,
            customTextColor: AppColors.primary,
            size: ButtonSize.small,
            fullWidth: false,
          ),
        ],
      ),
    );
  }

  /// Summary card shown when user has wishlists (now inside header)
  Widget _buildSummaryCard(LocalizationService localization) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.85), // Semi-transparent white
        borderRadius: BorderRadius.circular(16), // Border radius from all sides
        border: Border.all(color: AppColors.primary.withOpacity(0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon Section
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.primary.withOpacity(0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.favorite_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          // Content Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Your Wishlists',
                      style: AppStyles.headingSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors
                            .textPrimary, // Dark text on white background
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$_wishlistCount',
                        style: AppStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Manage and organize your wishlists',
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary, // Secondary text color
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                // Quick Action Button
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.myWishlists);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white, // Solid white button for contrast
                      borderRadius: BorderRadius.circular(
                        16,
                      ), // Unified button radius
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          offset: const Offset(0, 2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View All',
                          style: AppStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColors.primary,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Skeleton loading widget for wishlist card
  Widget _buildWishlistCardSkeleton() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // Create pulsing effect using sine wave - lighter and smoother
        final pulseValue =
            (0.15 +
            (0.2 *
                (0.5 +
                    0.5 * (1 + (2 * _animationController.value - 1).abs()))));

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                offset: const Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon Skeleton - Light purple gradient
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withOpacity(0.08 + pulseValue * 0.05),
                      AppColors.primary.withOpacity(0.12 + pulseValue * 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(width: 16),
              // Content Skeleton
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Skeleton
                    Row(
                      children: [
                        Container(
                          width: 120,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(
                              0.1 + pulseValue * 0.05,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 30,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(
                              0.1 + pulseValue * 0.05,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Subtitle Skeleton
                    Container(
                      width: 200,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(
                          0.08 + pulseValue * 0.03,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Button Skeleton
                    Container(
                      width: 90,
                      height: 36,
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
        );
      },
    );
  }

  Widget _buildQuickActions(LocalizationService localization) {
    final authService = Provider.of<AuthRepository>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localization.translate('home.quickActions'),
          style: AppStyles.headingSmall,
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            textDirection: localization.isRTL
                ? TextDirection.rtl
                : TextDirection.ltr,
            children: [
              // For guests - Browse Public Wishlists
              if (authService.isGuest) ...[
                SizedBox(
                  width: 120,
                  child: _buildActionCard(
                    icon: Icons.explore_outlined,
                    title: localization.translate('guest.quickActions.explore'),
                    subtitle: localization.translate(
                      'guest.quickActions.exploreSubtitle',
                    ),
                    color: AppColors.primary,
                    onTap: () {
                      // Navigate to browse public wishlists
                      Navigator.pushNamed(context, AppRoutes.myWishlists);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: _buildActionCard(
                    icon: Icons.event_outlined,
                    title: localization.translate(
                      'guest.quickActions.publicEvents',
                    ),
                    subtitle: localization.translate(
                      'guest.quickActions.publicEventsSubtitle',
                    ),
                    color: AppColors.accent,
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.events);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: _buildActionCard(
                    icon: Icons.login_outlined,
                    title: localization.translate(
                      'guest.quickActions.loginForMore',
                    ),
                    subtitle: localization.translate(
                      'guest.quickActions.loginForMoreSubtitle',
                    ),
                    color: AppColors.success,
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.login);
                    },
                  ),
                ),
              ] else ...[
                // For authenticated users - Full features
                SizedBox(
                  width: 120,
                  child: _buildActionCard(
                    icon: Icons.add_circle_outline,
                    title: localization.translate(
                      'home.quickActionsCards.createWishlist',
                    ),
                    subtitle: localization.translate(
                      'home.quickActionsCards.createWishlistSubtext',
                    ),
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.createWishlist,
                        arguments: {
                          'previousRoute': AppRoutes.mainNavigation,
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: _buildActionCard(
                    icon: Icons.event_outlined,
                    title: localization.translate(
                      'home.quickActionsCards.createEvent',
                    ),
                    subtitle: localization.translate(
                      'home.quickActionsCards.createEventSubtext',
                    ),
                    color: AppColors.accent,
                    onTap: () {
                      AppRoutes.pushNamed(context, AppRoutes.createEvent);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: _buildActionCard(
                    icon: Icons.person_add_outlined,
                    title: localization.translate(
                      'home.quickActionsCards.addFriend',
                    ),
                    subtitle: localization.translate(
                      'home.quickActionsCards.addFriendSubtext',
                    ),
                    color: AppColors.success,
                    onTap: () {
                      // Switch to Friends tab in MainNavigation while keeping bottom nav
                      MainNavigation.switchToTab(context, 3);
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final localization = Provider.of<LocalizationService>(
      context,
      listen: false,
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              textAlign: localization.isRTL
                  ? TextAlign.right
                  : TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppStyles.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: localization.isRTL
                  ? TextAlign.right
                  : TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingEvents(LocalizationService localization) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              localization.translate('home.upcomingEvents'),
              style: AppStyles.headingSmall,
            ),
            TextButton(
              onPressed: () {
                AppRoutes.pushNamed(context, AppRoutes.events);
              },
              child: Text(
                localization.translate('home.viewAll'),
                style: AppStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_upcomingEvents.isEmpty)
          _buildEmptyState(
            icon: Icons.event_outlined,
            title: localization.translate('home.noEvents'),
            subtitle: localization.translate('home.noEventsSubtitle'),
          )
        else
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _upcomingEvents.length,
              itemBuilder: (context, index) {
                final event = _upcomingEvents[index];
                return _buildEventCard(event);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildEventCard(UpcomingEvent event) {
    final daysUntil = event.date.difference(DateTime.now()).inDays;

    return GestureDetector(
      onTap: () => _openEventDetails(event),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openEventDetails(event),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 200,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textTertiary.withOpacity(0.1),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.celebration_outlined,
                        color: AppColors.accent,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.name,
                            style: AppStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'by ${event.hostName}',
                            style: AppStyles.bodySmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: daysUntil <= 3
                        ? AppColors.warning.withOpacity(0.1)
                        : AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    daysUntil == 0
                        ? 'Today'
                        : daysUntil == 1
                        ? 'Tomorrow'
                        : 'In $daysUntil days',
                    style: AppStyles.caption.copyWith(
                      color: daysUntil <= 3
                          ? AppColors.warning
                          : AppColors.info,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openEventDetails(UpcomingEvent event) {
    AppRoutes.pushNamed(context, AppRoutes.eventDetails, arguments: event);
  }

  Widget _buildFriendActivity(LocalizationService localization) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              localization.translate('home.friendActivity'),
              style: AppStyles.headingSmall,
            ),
            TextButton(
              onPressed: () {
                AppRoutes.pushNamed(context, AppRoutes.friends);
              },
              child: Text(
                localization.translate('home.viewAll'),
                style: AppStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_friendActivities.isEmpty)
          _buildEmptyState(
            icon: Icons.people_outline,
            title: localization.translate('home.noFriendActivity'),
            subtitle: localization.translate('home.noFriendActivitySubtitle'),
          )
        else
          Column(
            children: _friendActivities.map((activity) {
              return _buildActivityItem(activity);
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildActivityItem(FriendActivity activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
              activity.friendName[0].toUpperCase(),
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: AppStyles.bodyMedium,
                    children: [
                      TextSpan(
                        text: activity.friendName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: ' ${activity.action}'),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.timeAgo,
                  style: AppStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftSuggestions(LocalizationService localization) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gift Suggestions', style: AppStyles.headingSmall),
        const SizedBox(height: 16),
        if (_giftSuggestions.isEmpty)
          _buildEmptyState(
            icon: Icons.card_giftcard_outlined,
            title: 'No suggestions yet',
            subtitle: 'We\'ll suggest gifts based on your friends\' wishlists',
          )
        else
          Column(
            children: _giftSuggestions.map((suggestion) {
              return _buildSuggestionCard(suggestion);
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildSuggestionCard(GiftSuggestion suggestion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.card_giftcard_rounded,
              color: AppColors.success,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.title,
                  style: AppStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  suggestion.subtitle,
                  style: AppStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            suggestion.price,
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _refreshData() async {
    // Refresh wishlists check
    await _checkWishlists();

    // Refresh your data here
    setState(() {
      // Update data
    });
  }


  // Guest wishlist methods
  Future<void> _loadGuestWishlists() async {
    final authService = Provider.of<AuthRepository>(context, listen: false);
    
    if (!authService.isGuest) return;
    
    setState(() {
      _isLoadingGuestData = true;
    });
    
    try {
      final guestDataRepo = Provider.of<GuestDataRepository>(context, listen: false);
      // getAllWishlists now uses Hive.box() instead of Hive.openBox() for better performance
      final wishlists = await guestDataRepo.getAllWishlists();
      
      // Load items for each wishlist to get accurate counts
      final updatedWishlists = <Wishlist>[];
      for (final wishlist in wishlists) {
        final items = await guestDataRepo.getWishlistItems(wishlist.id);
        // Update wishlist with loaded items for accurate count
        updatedWishlists.add(wishlist.copyWith(items: items));
      }
      
      if (!mounted) return;
      
      setState(() {
        _guestWishlists = updatedWishlists;
        _isLoadingGuestData = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingGuestData = false;
      });
    }
  }

  Widget _buildCreateFirstWishlistButton() {
    return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
            // Empty state icon (same as wishlist screen)
            Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 36,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Create Your First Wishlist',
              style: AppStyles.headingMediumWithContext(context).copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Start building your wishlist and organize your gift ideas',
              style: AppStyles.bodyMediumWithContext(context).copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            // Pulse animated button
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.createWishlist,
                            arguments: {
                              'previousRoute': AppRoutes.mainNavigation,
                            },
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Create Your First Wishlist',
                                style: AppStyles.headingSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Build decorative blob shapes anchored to bottom corners (behind bottom nav bar)
  Widget _buildDecorativeBlobsForEmptyState() {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomNavHeight = 80.0; // Approximate bottom nav bar height
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Positioned.fill(
      child: Stack(
        children: [
          // Bottom-left large blob - extends to absolute bottom
          Positioned(
            left: 0,
            bottom: -(screenHeight * 0.15), // Extend below viewport
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.06),
              ),
            ),
          ),
          // Bottom-left medium blob
          Positioned(
            left: 30,
            bottom: bottomNavHeight + bottomPadding + 40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withOpacity(0.05),
              ),
            ),
          ),
          // Bottom-right large blob - extends to absolute bottom
          Positioned(
            right: 0,
            bottom: -(screenHeight * 0.12), // Extend below viewport
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.06),
              ),
            ),
          ),
          // Bottom-right medium blob
          Positioned(
            right: 40,
            bottom: bottomNavHeight + bottomPadding + 50,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withOpacity(0.05),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildGuestWishlistList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Wishlists',
                    style: AppStyles.headingMediumWithContext(context).copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_guestWishlists.length} ${_guestWishlists.length == 1 ? 'wishlist' : 'wishlists'}',
                    style: AppStyles.bodySmallWithContext(context).copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              // Add Button
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.createWishlist,
                        arguments: {
                          'previousRoute': AppRoutes.mainNavigation,
                        },
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'New',
                            style: AppStyles.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Wishlist Cards with staggered animations
        AnimationLimiter(
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _guestWishlists.length,
            itemBuilder: (context, index) {
              final wishlist = _guestWishlists[index];
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 500),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: _buildGuestWishlistCard(wishlist),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Get color for category visual indicator
  Color _getCategoryColor(String? category) {
    if (category == null || category.isEmpty) {
      return AppColors.primary;
    }
    
    switch (category.toLowerCase()) {
      case 'birthday':
        return const Color(0xFFFF6B9D); // Pink
      case 'wedding':
        return const Color(0xFFFFB84D); // Orange
      case 'graduation':
        return const Color(0xFF4ECDC4); // Teal
      case 'anniversary':
        return const Color(0xFFA78BFA); // Purple
      case 'holiday':
        return const Color(0xFFF87171); // Red
      case 'babyshower':
        return const Color(0xFF60A5FA); // Blue
      case 'housewarming':
        return const Color(0xFF34D399); // Green
      case 'general':
      default:
        return AppColors.primary; // Default purple
    }
  }

  Widget _buildGuestWishlistCard(Wishlist wishlist) {
    // Get category color for visual indicator
    final categoryColor = _getCategoryColor(wishlist.category);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          // Softer, more spread-out shadows for floating effect
          BoxShadow(
            color: AppColors.textTertiary.withOpacity(0.06),
            blurRadius: 30,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: AppColors.textTertiary.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.wishlistItems,
              arguments: {
                'wishlistId': wishlist.id,
                'wishlistName': wishlist.name,
                'totalItems': wishlist.totalItems,
                'purchasedItems': wishlist.purchasedItems,
              },
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon Container with category indicator
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            categoryColor,
                            categoryColor.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: categoryColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    // Category color tag
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: categoryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surface,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: categoryColor.withOpacity(0.5),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wishlist.name,
                        style: AppStyles.headingSmallWithContext(context).copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.card_giftcard_rounded,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${wishlist.totalItems} ${wishlist.totalItems == 1 ? "wish" : "wishes"}',
                            style: AppStyles.bodyMediumWithContext(context).copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Arrow Icon
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Show notification dropdown menu
  void _showNotificationDropdown(
    BuildContext context,
    List<AppNotification> notifications,
    LocalizationService localization,
  ) {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('🔔 [UI] ⏰ [$timestamp] Opening notification dropdown');
    
    // Dismiss badge (update lastBadgeSeenAt on backend)
    // This will:
    // 1. Call PATCH /api/notifications/dismiss-badge
    // 2. Backend updates lastBadgeSeenAt to current timestamp
    // 3. Backend recalculates unreadCount (only notifications created after lastBadgeSeenAt)
    // 4. Badge count becomes 0 (because all visible notifications are now "seen")
    // Note: الإشعارات نفسها لن تتعلم كـ read إلا عند الضغط عليها
    debugPrint('🔔 [UI] ⏰ [$timestamp] Dismissing badge (updating lastBadgeSeenAt)');
    context.read<NotificationsCubit>().dismissBadge();
    
    // Get max 5 notifications
    final displayNotifications = notifications.take(5).toList();

    // Get screen size
    final screenSize = MediaQuery.of(context).size;
    const dropdownWidth = 320.0;
    const spacing = 8.0;
    
    // Calculate position: right-aligned, below header (approximately where icon is)
    // Header is usually around 100-120px from top
    final topPosition = 130.0; // Approximate header height + spacing
    final rightPosition = 16.0; // Padding from right edge

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Notifications',
      barrierColor: Colors.black.withOpacity(0.3),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.05), // Slide down from slightly above
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: Stack(
              children: [
                // Transparent background to close on tap
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(color: Colors.transparent),
                  ),
                ),
                // Dropdown content - positioned at top right
                Positioned(
                  top: topPosition,
                  right: rightPosition,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 400),
                      width: dropdownWidth,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.textTertiary.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                              border: Border(
                                bottom: BorderSide(
                                  color: AppColors.textTertiary.withOpacity(0.1),
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'Notifications',
                                  style: AppStyles.headingSmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                if (notifications.length > 5)
                                  Text(
                                    '${notifications.length - 5} more',
                                    style: AppStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Notifications list
                          if (displayNotifications.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.notifications_none,
                                    size: 48,
                                    color: AppColors.textTertiary,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No notifications',
                                    style: AppStyles.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Flexible(
                              child: ListView.separated(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount: displayNotifications.length,
                                separatorBuilder: (context, index) => Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: AppColors.textTertiary.withOpacity(0.1),
                                ),
                                itemBuilder: (context, index) {
                                  final notification = displayNotifications[index];
                                  return _buildNotificationItem(notification, context);
                                },
                              ),
                            ),
                          // View All button
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.pop(context); // Close dropdown
                                  AppRoutes.pushNamed(context, AppRoutes.notifications);
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'View All Notifications',
                                  style: AppStyles.bodyMedium.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build notification item for dropdown
  Widget _buildNotificationItem(AppNotification notification, BuildContext context) {
    final isFriendRequest = notification.type == NotificationType.friendRequest;
    
    return InkWell(
      onTap: () {
        // Mark notification as read when clicked
        if (!notification.isRead) {
          final timestamp = DateTime.now().toIso8601String();
          debugPrint('🔔 [UI] ⏰ [$timestamp] Notification clicked - Marking as read');
          debugPrint('🔔 [UI] ⏰ [$timestamp]    Notification ID: ${notification.id}');
          context.read<NotificationsCubit>().markAsRead(notification.id);
        }
        
        // Handle navigation based on notification type
        _handleNotificationTap(context, notification);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        color: notification.isRead
            ? Colors.transparent
            : AppColors.info.withOpacity(0.05),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getNotificationColor(notification.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getNotificationIcon(notification.type),
                  color: _getNotificationColor(notification.type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
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
                            style: AppStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: notification.isRead
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.info,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: AppStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.timeAgo,
                      style: AppStyles.caption.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Compact Accept/Reject buttons for friend requests (Row at bottom)
          if (isFriendRequest) ...[
            const SizedBox(height: 8),
            _buildFriendRequestActionButtons(context, notification),
          ],
        ],
      ),
      ),
    );
  }
  
  /// Build friend request action buttons based on state
  Widget _buildFriendRequestActionButtons(BuildContext context, AppNotification notification) {
    final actionState = _notificationActionStates[notification.id];
    
    // Check if notification type indicates it's already been processed
    final isAlreadyAccepted = notification.type == NotificationType.friendRequestAccepted;
    final isAlreadyRejected = notification.type == NotificationType.friendRequestRejected;
    
    // Loading state - show CircularProgressIndicator
    if (actionState == 'loading') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
            ),
          ),
        ],
      );
    }
    
    // Success states - show light text label (hide buttons)
    // Check both actionState and notification type to ensure buttons stay hidden
    if (actionState == 'accepted' || isAlreadyAccepted) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'تم الموافقة',
            style: AppStyles.caption.copyWith(
              fontSize: 11,
              color: AppColors.success.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
    
    if (actionState == 'rejected' || isAlreadyRejected) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'تم الرفض',
            style: AppStyles.caption.copyWith(
              fontSize: 11,
              color: AppColors.textSecondary.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
    
    // Default state - show Accept/Reject buttons
    // Check if any action is in progress for this notification
    final isProcessing = actionState == 'loading' || 
                        actionState == 'accepted' || 
                        actionState == 'rejected';
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Reject button - subtle grey/light red with border
        OutlinedButton(
          onPressed: isProcessing ? null : () {
            _handleFriendRequestAction(context, notification, false);
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: BorderSide(
              color: AppColors.textSecondary.withOpacity(0.3),
              width: 1,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: Text(
            'Reject',
            style: AppStyles.caption.copyWith(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Accept button - clean green with border
        OutlinedButton(
          onPressed: isProcessing ? null : () {
            _handleFriendRequestAction(context, notification, true);
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.success,
            side: BorderSide(
              color: AppColors.success.withOpacity(0.5),
              width: 1,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: Text(
            'Accept',
            style: AppStyles.caption.copyWith(
              fontSize: 12,
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Handle notification tap (navigation based on type)
  void _handleNotificationTap(BuildContext context, AppNotification notification) {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('🔔 [UI] ⏰ [$timestamp] Handling notification tap');
    debugPrint('🔔 [UI] ⏰ [$timestamp]    Type: ${notification.type}');
    
    // Close the dropdown first
    Navigator.pop(context);
    
    // Navigate based on notification type
    switch (notification.type) {
      case NotificationType.friendRequest:
        // Navigate to friend requests screen
        AppRoutes.pushNamed(context, AppRoutes.friends);
        break;
      case NotificationType.friendRequestAccepted:
      case NotificationType.friendRequestRejected:
        // Navigate to friends list
        AppRoutes.pushNamed(context, AppRoutes.friends);
        break;
      case NotificationType.eventInvitation:
        // Navigate to events screen
        // TODO: Navigate to specific event if ID is available in notification.data
        AppRoutes.pushNamed(context, AppRoutes.events);
        break;
      case NotificationType.itemPurchased:
      case NotificationType.wishlistShared:
        // Navigate to wishlists
        // TODO: Navigate to specific wishlist if ID is available in notification.data
        AppRoutes.pushNamed(context, AppRoutes.myWishlists);
        break;
      default:
        // For unknown types, just go to notifications page
        AppRoutes.pushNamed(context, AppRoutes.notifications);
    }
  }

  /// Handle friend request action (accept/reject)
  /// Implements state-based UI updates with loading, success, and error states
  Future<void> _handleFriendRequestAction(
    BuildContext context,
    AppNotification notification,
    bool accept,
  ) async {
    // Extract requestId from notification data
    // For friend requests, we need to use relatedId (the friend request ID)
    // The backend sends: relatedId (friend request ID), not the notification _id
    final requestId = notification.data?['relatedId'] ?? 
                      notification.data?['requestId'] ?? 
                      notification.data?['_id'] ?? 
                      notification.id;
    
    debugPrint('🔔 [FriendRequest] Extracting requestId...');
    debugPrint('🔔 [FriendRequest] relatedId: ${notification.data?['relatedId']}');
    debugPrint('🔔 [FriendRequest] requestId: ${notification.data?['requestId']}');
    debugPrint('🔔 [FriendRequest] _id: ${notification.data?['_id']}');
    debugPrint('🔔 [FriendRequest] notification.id: ${notification.id}');
    debugPrint('🔔 [FriendRequest] Final requestId: $requestId');
    
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
      return;
    }
    
    // Set loading state - UI will show CircularProgressIndicator
    setState(() {
      _notificationActionStates[notification.id] = 'loading';
    });
    
    try {
      final friendsRepository = FriendsRepository();
      
      debugPrint('🔔 [FriendRequest] Starting ${accept ? "accept" : "reject"} action');
      debugPrint('🔔 [FriendRequest] Request ID: $requestId');
      debugPrint('🔔 [FriendRequest] Notification ID: ${notification.id}');
      
      // Call API
      Map<String, dynamic> response;
      if (accept) {
        response = await friendsRepository.acceptFriendRequest(requestId: requestId);
      } else {
        response = await friendsRepository.rejectFriendRequest(requestId: requestId);
      }
      
      debugPrint('🔔 [FriendRequest] API call successful');
      debugPrint('🔔 [FriendRequest] Response: $response');
      
      if (!mounted) return;
      
      final notificationsCubit = context.read<NotificationsCubit>();
      
      // Step 1: Update notification type in cubit immediately to hide buttons
      // This ensures buttons stay hidden even if notification list is reloaded
      final updatedNotification = AppNotification(
        id: notification.id,
        userId: notification.userId,
        type: accept ? NotificationType.friendRequestAccepted : NotificationType.friendRequestRejected,
        title: accept ? 'تم الموافقة على الطلب' : 'تم رفض الطلب',
        message: notification.message,
        data: notification.data,
        isRead: true,
        createdAt: notification.createdAt,
      );
      
      notificationsCubit.updateNotification(updatedNotification);
      
      // Step 2: Update local state to hide buttons and show light text
      setState(() {
        _notificationActionStates[notification.id] = accept ? 'accepted' : 'rejected';
      });
      
      debugPrint('🔔 [FriendRequest] Notification type updated to: ${updatedNotification.type}');
      debugPrint('🔔 [FriendRequest] State updated to: ${accept ? "accepted" : "rejected"}');
      debugPrint('🔔 [FriendRequest] Buttons hidden, showing light text');
      
      // Step 3: Show light snackbar with success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  accept ? Icons.check_circle : Icons.cancel,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  accept ? 'تم الموافقة على الطلب' : 'تم رفض الطلب',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            backgroundColor: accept ? AppColors.success : AppColors.textSecondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 2),
            margin: const EdgeInsets.all(16),
            elevation: 2,
          ),
        );
      }
      
      // Step 3: After 2 seconds, delete notification from backend and remove from UI
      Future.delayed(const Duration(seconds: 2), () async {
        if (!mounted) return;
        
        debugPrint('🔔 [FriendRequest] Deleting notification after 2 seconds...');
        
        // Delete from backend
        try {
          await notificationsCubit.deleteNotification(notification.id);
          debugPrint('🔔 [FriendRequest] ✅ Notification deleted from backend');
        } catch (e) {
          debugPrint('🔔 [FriendRequest] ⚠️ Error deleting notification: $e');
          // If delete fails, still remove from UI optimistically
          notificationsCubit.removeNotificationOptimistically(notification.id);
        }
        
        // Remove from action states (cleanup)
        if (mounted) {
          setState(() {
            _notificationActionStates.remove(notification.id);
          });
        }
      });
      
    } on ApiException catch (e) {
      // Log error details
      debugPrint('🔔 [FriendRequest] ❌ ApiException caught');
      debugPrint('🔔 [FriendRequest] Error message: ${e.message}');
      debugPrint('🔔 [FriendRequest] Status code: ${e.statusCode}');
      debugPrint('🔔 [FriendRequest] Error data: ${e.data}');
      
      // Revert to original state on error
      if (mounted) {
        setState(() {
          _notificationActionStates[notification.id] = 'error';
        });
        
        // Show error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    e.message,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        
        // Reset to original state after showing error
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _notificationActionStates.remove(notification.id);
            });
          }
        });
      }
    } catch (e, stackTrace) {
      // Log unexpected error details
      debugPrint('🔔 [FriendRequest] ❌ Unexpected error caught');
      debugPrint('🔔 [FriendRequest] Error: $e');
      debugPrint('🔔 [FriendRequest] Stack trace: $stackTrace');
      
      // Revert to original state on error
      if (mounted) {
        setState(() {
          _notificationActionStates[notification.id] = 'error';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    accept
                        ? 'Failed to accept friend request. Please try again.'
                        : 'Failed to decline friend request. Please try again.',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        
        // Reset to original state after showing error
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _notificationActionStates.remove(notification.id);
            });
          }
        });
      }
    }
  }

  /// Get notification color based on type
  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.friendRequest:
        return AppColors.secondary;
      case NotificationType.friendRequestAccepted:
        return AppColors.success;
      case NotificationType.friendRequestRejected:
        return AppColors.error;
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

  /// Get notification icon based on type
  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.friendRequest:
        return Icons.person_add_outlined;
      case NotificationType.friendRequestAccepted:
        return Icons.person_add_alt_1_outlined;
      case NotificationType.friendRequestRejected:
        return Icons.person_remove_outlined;
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
}

// Mock data models
class UpcomingEvent {
  final String id;
  final String name;
  final DateTime date;
  final String type;
  final String hostName;
  final String? imageUrl;

  UpcomingEvent({
    required this.id,
    required this.name,
    required this.date,
    required this.type,
    required this.hostName,
    this.imageUrl,
  });
}

class FriendActivity {
  final String id;
  final String friendName;
  final String action;
  final String timeAgo;
  final String? imageUrl;

  FriendActivity({
    required this.id,
    required this.friendName,
    required this.action,
    required this.timeAgo,
    this.imageUrl,
  });
}

class GiftSuggestion {
  final String id;
  final String title;
  final String subtitle;
  final String price;
  final String friendName;
  final String? imageUrl;

  GiftSuggestion({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.friendName,
    this.imageUrl,
  });
}
