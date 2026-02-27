import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/core/widgets/decorative_background.dart';
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';
import 'package:wish_listy/features/profile/presentation/controllers/home_controller.dart';
import 'package:wish_listy/features/profile/presentation/widgets/home_skeleton.dart';
import 'package:wish_listy/features/profile/presentation/widgets/empty_home_screen.dart';
import 'package:wish_listy/features/profile/presentation/widgets/active_dashboard.dart';
import 'package:wish_listy/features/profile/presentation/widgets/compact_empty_wishlist.dart';
import 'package:wish_listy/features/profile/presentation/screens/guest_home_screen.dart';
import 'package:wish_listy/features/profile/presentation/screens/main_navigation.dart';
import 'package:wish_listy/features/profile/presentation/models/home_models.dart';
import 'package:wish_listy/features/wishlists/presentation/widgets/index.dart';
import 'package:wish_listy/features/wishlists/data/models/wishlist_model.dart';
import 'package:wish_listy/features/events/data/models/event_model.dart';
import 'package:wish_listy/features/notifications/presentation/widgets/notification_dropdown.dart';
import 'package:wish_listy/features/notifications/data/models/notification_model.dart';
import 'package:wish_listy/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/widgets/royal_avatar_wrapper.dart';
import 'package:wish_listy/core/widgets/generic_error_screen.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/core/services/fcm_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wish_listy/features/wishlists/presentation/cubit/pending_reservations_cubit.dart';
import 'package:wish_listy/features/friends/presentation/widgets/suggested_friends_section.dart';
import 'package:wish_listy/features/friends/data/repository/friends_repository.dart';
import 'package:wish_listy/features/friends/data/models/suggestion_user_model.dart';

class HomeScreen extends StatefulWidget {
  final GlobalKey<HomeScreenState>? key;

  const HomeScreen({this.key}) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  late HomeController _controller;
  bool _isNotificationDropdownOpen = false;
  DateTime? _lastNotificationTapTime;
  List<SuggestionUser>? _homeSuggestions; // null = not loaded yet

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = HomeController();
    _controller.fetchDashboardData();
    _loadHomeSuggestions();
    // Load unread count from NotificationsCubit when app starts
    // This ensures we use the correct API that respects lastBadgeSeenAt
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<NotificationsCubit>();
      cubit.getUnreadCount();
    });
    
    // Request notification permission after first successful login or when app opens authenticated
    // This ensures the dialog appears at a high-value moment (Home Screen) rather than at launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authRepository = Provider.of<AuthRepository>(context, listen: false);
      
      // Only show permission dialog if user is fully authenticated (not guest)
      if (authRepository.isAuthenticated && context.mounted) {
        FcmService().ensurePermissionRequested(context).catchError((error) {
          // Silently handle errors - permission dialog is best-effort
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadHomeSuggestions() async {
    try {
      final suggestions = await FriendsRepository().getSuggestions();
      if (!mounted) return;
      setState(() {
        _homeSuggestions = suggestions;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _homeSuggestions = const [];
      });
    }
  }

  /// Public method to refresh home dashboard from outside (e.g., MainNavigation tab switch)
  Future<void> refreshHome() async {
    // Background refresh: keep existing UI (no skeleton) when data already exists.
    // HomeController.refresh() already implements "smart loading".
    try {
      context.read<NotificationsCubit>().getUnreadCount();
    } catch (_) {
      // NotificationsCubit may not be in tree yet – ignore
    }

    await Future.wait([
      _controller.refresh(),
      _loadHomeSuggestions(),
    ]);
    // Also refresh pending reservations section if it is mounted
    try {
      final pendingCubit = context.read<PendingReservationsCubit>();
      await pendingCubit.refresh();
    } catch (_) {
      // PendingReservationsCubit may not be in the tree yet (e.g. guest / skeleton) – ignore
    }
  }

  String _getTimeBasedGreeting(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return localization.translate('home.goodMorning');
    } else if (hour < 17) {
      return localization.translate('home.goodAfternoon');
    } else {
      return localization.translate('home.goodEvening');
    }
  }

  Widget _buildRichHeader(HomeController controller) {
    // Show skeleton if header is loading
    if (controller.isHeaderLoading) {
      return _buildHeaderSkeleton();
    }
    
    final dashboardData = controller.dashboardData.value;
    final firstName = dashboardData?.user.firstName ?? 'Friend';
    final fullName = firstName; // Using firstName as fullName is not available in DashboardUser
    
    // Get dashboard profile image (will be overridden by Consumer<AuthRepository> below for instant updates)
    final dashboardProfileImageUrl = dashboardData?.user.avatar;
    final unreadCount = dashboardData?.stats.unreadNotificationsCount ?? 0;

    return Container(
      margin: const EdgeInsets.only(
        left: 8,
        right: 8,
        top: 12,
        bottom: 12, // Reduced from 16
      ),
      decoration: BoxDecoration(
        color: AppColors.cardPurple, // Same as UnifiedPageHeader
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: AppColors.textTertiary.withOpacity(0.1),
            offset: const Offset(0, 4),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: Stack(
          children: [
            // Decorative background elements
            _buildDecorativeElements(),
            // Main content
            Container(
              // Reduced vertical padding to minimize header height
              padding: const EdgeInsets.fromLTRB(20, 44, 20, 8), // Reduced bottom from 12 to 8
              child: SafeArea(
                bottom: false,
                top: false, // Top SafeArea is handled by padding
                minimum: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // Ensure column takes minimum space
                  children: [
                    // Top Row: Avatar + Greeting Column + Notification
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left: Profile Avatar (reduced radius, tappable)
                        // Wrap with Consumer<AuthRepository> for instant updates
                        Consumer<AuthRepository>(
                          builder: (context, authRepository, child) {
                            // Get global profile image for instant sync
                            final globalProfileImage = authRepository.profilePicture;
                            final displayImageUrl = globalProfileImage ?? dashboardProfileImageUrl;
                            
                            return GestureDetector(
                              onTap: () {
                                MainNavigation.switchToTab(context, 4); // Switch to Profile tab
                              },
                              child: RoyalAvatarWrapper(
                                userName: fullName,
                                child: CircleAvatar(
                                  radius: 25,
                                  backgroundColor: Colors.white,
                                  child: displayImageUrl != null && displayImageUrl.isNotEmpty
                                      ? ClipOval(
                                          child: CachedNetworkImage(
                                            imageUrl: displayImageUrl,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => Container(
                                              width: 50,
                                              height: 50,
                                              color: Colors.white,
                                              child: Center(
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                            errorWidget: (context, url, error) => Icon(
                                              Icons.person_rounded,
                                              color: AppColors.primary,
                                              size: 30,
                                            ),
                                          ),
                                        )
                                      : Icon(
                                          Icons.person_rounded,
                                          color: AppColors.primary,
                                          size: 30,
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        // Middle: Greeting Column (left-aligned, tappable)
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              MainNavigation.switchToTab(context, 4); // Switch to Profile tab
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Time-based greeting (small, grey, regular)
                                Text(
                                  _getTimeBasedGreeting(context),
                                  style: AppStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // User name (larger, bold, black/dark purple, capitalized)
                                Text(
                                  fullName.isNotEmpty
                                      ? '${fullName[0].toUpperCase()}${fullName.substring(1)}'
                                      : fullName,
                                  style: AppStyles.headingLarge.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: MediaQuery.of(context).size.width < 360 ? 18 : 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Right: Notification Bell (pushed to end with Spacer)
                        BlocBuilder<NotificationsCubit, NotificationsState>(
                          builder: (context, state) {
                            final notifications = state is NotificationsLoaded
                                ? state.notifications
                                : <AppNotification>[];
                            final unreadCount = state is NotificationsLoaded
                                ? state.unreadCount
                                : 0;

                            return Builder(
                              builder: (buttonContext) {
                                return Material(
                                  color: Colors.transparent,
                                    child: InkWell(
                                    onTap: () {
                                      // Debounce: prevent rapid taps (within 300ms)
                                      final now = DateTime.now();
                                      if (_lastNotificationTapTime != null &&
                                          now.difference(_lastNotificationTapTime!) <
                                              const Duration(milliseconds: 300)) {
                                        return;
                                      }
                                      _lastNotificationTapTime = now;

                                      // Prevent opening if already open
                                      if (_isNotificationDropdownOpen) {
                                        return;
                                      }

                                      // Always open dropdown immediately with current data (cached or empty)
                                      // The dropdown uses BlocBuilder and will update automatically when data loads
                                      _showNotificationDropdown(
                                        buttonContext,
                                        notifications,
                                        unreadCount,
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            offset: const Offset(0, 2),
                                            blurRadius: 8,
                                            spreadRadius: 0,
                                          ),
                                        ],
                                      ),
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Center(
                                            child: Icon(
                                              Icons.notifications_outlined,
                                              color: AppColors.primary,
                                              size: 22,
                                            ),
                                          ),
                                          if (unreadCount > 0)
                                            Positioned(
                                              top: -2,
                                              right: -2,
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: unreadCount > 9 ? 4 : 5,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.accent,
                                                  shape: BoxShape.circle,
                                                ),
                                                constraints: const BoxConstraints(
                                                  minWidth: 18,
                                                  minHeight: 18,
                                                ),
                                                child: Text(
                                                  unreadCount > 9 ? '9+' : '$unreadCount',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
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
                          },
                        ),
                      ],
                    ),
                    // Bottom: "Ready to make wishes" text (minimal spacing)
                    const SizedBox(height: 4), // Further reduced from 6 to 4
                    Text(
                      Provider.of<LocalizationService>(context, listen: false)
                          .translate('profile.readyToMakeWishesComeTrue'),
                      style: AppStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary.withOpacity(0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Header Skeleton (with purple curved background)
  Widget _buildHeaderSkeleton() {
    return Container(
      margin: const EdgeInsets.only(
        left: 8,
        right: 8,
        top: 12,
        bottom: 12, // Reduced from 16 to match header
      ),
      decoration: BoxDecoration(
        color: AppColors.cardPurple, // Same as UnifiedPageHeader
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: AppColors.textTertiary.withOpacity(0.1),
            offset: const Offset(0, 4),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: Stack(
          children: [
            // Decorative background elements
            _buildDecorativeElements(),
            // Main content
            Container(
              // Match the tighter padding used in the real header
              padding: const EdgeInsets.fromLTRB(20, 44, 20, 8), // Reduced to match header
              child: SafeArea(
                bottom: false,
                top: false,
                minimum: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // Ensure column takes minimum space
                  children: [
                    // Top Row: Avatar + Greeting + Notification skeleton
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left: Avatar skeleton (reduced size to match radius 25)
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Middle: Greeting skeleton
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 100,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 140,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Right: Notification bell skeleton
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ],
                    ),
                    // Bottom: Welcome message skeleton (minimal spacing)
                    const SizedBox(height: 4), // Further reduced from 6 to 4 to match header
                    Container(
                      width: 180,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build decorative background elements (same as UnifiedPageHeader)
  Widget _buildDecorativeElements() {
    return Positioned.fill(
      child: Stack(
        children: [
          // Top right gift icon
          Positioned(
            top: -10,
            right: 30,
            child: Icon(
              Icons.card_giftcard_rounded,
              size: 70,
              color: Colors.white.withOpacity(0.15),
            ),
          ),

          // Bottom left heart
          Positioned(
            bottom: -15,
            left: 20,
            child: Icon(
              Icons.favorite_rounded,
              size: 60,
              color: AppColors.accent.withOpacity(0.12),
            ),
          ),

          // Top left circle
          Positioned(
            top: -20,
            left: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.08),
              ),
            ),
          ),

          // Bottom right star
          Positioned(
            bottom: 10,
            right: 50,
            child: Icon(
              Icons.star_rounded,
              size: 35,
              color: AppColors.accent.withOpacity(0.15),
            ),
          ),

          // Middle small circle
          Positioned(
            top: 40,
            right: -10,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withOpacity(0.1),
              ),
            ),
          ),

          // Small sparkle icon
          Positioned(
            top: 20,
            left: 80,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 25,
              color: Colors.white.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Keep alive
    final authService = Provider.of<AuthRepository>(context, listen: false);

    // For guest users, show GuestHomeScreen
    if (authService.isGuest) {
      return GuestHomeScreen(
        onCreateWishlist: () async {
          Navigator.pushNamed(
            context,
            AppRoutes.createWishlist,
            arguments: {
              'previousRoute': AppRoutes.mainNavigation,
            },
          );
        },
      );
    }

    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            DecorativeBackground(
              showGifts: true,
              showCircles: true,
              child: Consumer<HomeController>(
                  builder: (context, controller, child) {
                    final isEmpty = controller.isNewUser;

                    // Offline / failed-load state:
                    // If the API failed and we have no cached dashboard data, show a full-page error UI
                    // instead of falling back to "empty home" + snackbars.
                    final hasNoData = controller.dashboardData.value == null;
                    final hasError = controller.errorMessage != null &&
                        controller.errorMessage!.trim().isNotEmpty;
                    if (!controller.isLoading && hasNoData && hasError) {
                      if (controller.errorKind == ApiErrorKind.noInternet) {
                        return GenericErrorScreen.noInternet(
                          withScaffold: false,
                          onRetry: () async => controller.refresh(),
                        );
                      }
                      return GenericErrorScreen.serverError(
                        withScaffold: false,
                        onRetry: () async => controller.refresh(),
                      );
                    }

                    // Determine layout state
                    final hasWishlists = (controller.myWishlists ?? []).isNotEmpty;
                    final hasActivities = (controller.latestActivityPreview ?? []).isNotEmpty;
                    final hasOccasions = (controller.upcomingOccasions ?? []).isNotEmpty;
                    final hasSuggestions = (_homeSuggestions?.isNotEmpty ?? false);

                    // "Truly empty" = no lists, no occasions, no activity, and no suggestions.
                    // (Suggestions are not part of the dashboard response, so we load them separately.)
                    final isTrulyEmpty = !hasWishlists &&
                        !hasActivities &&
                        !hasOccasions &&
                        !hasSuggestions;

                    // Compact social-first empty layout:
                    // - User is new (no own wishlists yet)
                    // - But they already have some social signal (friends / activity / occasions)
                    // This layout shows:
                    //   - Compact "Create Wishlist" card
                    //   - People You May Know
                    //   - Upcoming Occasions (if any)
                    //   - Happening Now (if any)
                    final showCompactEmptyWithActivities =
                        isEmpty && !hasWishlists && !isTrulyEmpty;

                    return RefreshIndicator(
                      onRefresh: controller.refresh,
                      color: AppColors.primary,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          // Rich Header (Fixed/Pinned)
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _FixedHeaderDelegate(
                              child: _buildRichHeader(controller),
                            ),
                          ),
                          // Spacing between Header and content
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 20),
                          ),
                          // Content - Conditional Layout
                          if (controller.isLoading)
                            const SliverToBoxAdapter(child: HomeSkeletonView())
                          else if (showCompactEmptyWithActivities)
                            // Layout: Compact empty wishlist card + People You May Know +
                            // Upcoming Occasions (if any) + Happening Now (if any)
                            SliverToBoxAdapter(
                              child: _buildCompactEmptyWithActivities(
                                controller,
                                initialSuggestions: _homeSuggestions,
                              ),
                            )
                          else if (isEmpty && isTrulyEmpty)
                            // Full playful empty state (no wishlists, no occasions, no activity)
                            const SliverFillRemaining(
                              hasScrollBody: false,
                              child: EmptyHomeScreen(),
                            )
                          else
                            // Active dashboard with all data
                            SliverToBoxAdapter(
                              child: ActiveDashboard(
                                occasions: _convertEventsToOccasions(
                                  controller.upcomingOccasions ?? [],
                                ),
                                wishlists: _convertWishlistsToSummaries(
                                  controller.myWishlists ?? [],
                                ),
                                activities: controller.latestActivityPreview ?? [],
                              ),
                            ),
                          // Bottom padding to clear Bottom Navigation Bar (extra space so content is not stuck to nav)
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 140),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper methods to convert API models to UI models
  List<UpcomingOccasion> _convertEventsToOccasions(List<Event>? events) {
    // Add null safety check - return empty list if events is null or empty
    if (events == null || events.isEmpty) return [];
    
    return events.map((event) {
      return UpcomingOccasion(
        id: event.id,
        name: event.name,
        date: event.date,
        type: event.type.displayName,
        hostName: event.creatorName ?? 'Unknown',
        hostId: event.creatorId, // Pass creator ID for navigation
        avatarUrl: event.creatorImage,
        invitationStatus: event.myInvitationStatus, // Pass invitation status
      );
    }).toList();
  }

  List<WishlistSummary> _convertWishlistsToSummaries(List<Wishlist>? wishlists) {
    // Add null safety check - return empty list if wishlists is null or empty
    if (wishlists == null || wishlists.isEmpty) return [];
    
    return wishlists.map((wishlist) {
      // Use items.length for accurate count (even if items array is populated)
      // The wishlist.totalItems getter already does this, but we want to ensure accuracy
      final itemCount = wishlist.items.isNotEmpty 
          ? wishlist.items.length 
          : wishlist.totalItems;
      
      return WishlistSummary(
        id: wishlist.id,
        name: wishlist.name,
        description: wishlist.description,
        itemCount: itemCount,
        purchasedCount: wishlist.purchasedItems,
        lastUpdated: wishlist.updatedAt,
        privacy: _convertVisibilityToPrivacy(wishlist.visibility),
        category: wishlist.category,
        previewItems: wishlist.items.take(3).toList(),
      );
    }).toList();
  }

  /// Build compact empty wishlist state with "Happening Now" activities section
  /// Used when user has no wishlists but has friend activities to show
  Widget _buildCompactEmptyWithActivities(
    HomeController controller, {
    List<SuggestionUser>? initialSuggestions,
  }) {
    final activities = controller.latestActivityPreview ?? [];
    final occasions = controller.upcomingOccasions ?? [];
    final localization = Provider.of<LocalizationService>(context, listen: false);
    
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Compact Empty Wishlist Card (Because user has no wishlists)
          const CompactEmptyWishlistCard(),
          const SizedBox(height: 24),
          
          // 2. Pending Reservations (Gifts reserved for friends)
          // This widget handles its own empty state internally (returns SizedBox.shrink if empty).
          const PendingReservationsSection(),
          const SizedBox(height: 24),
          
          // 3. People You May Know
          SuggestedFriendsSection(
            localization: localization,
            initialSuggestions: initialSuggestions,
          ),
          const SizedBox(height: 24),
          
          // 4. Friends Events / Upcoming Occasions
          if (occasions.isNotEmpty) ...[
            UpcomingOccasionsSection(
              occasions: _convertEventsToOccasions(occasions),
            ),
            const SizedBox(height: 24),
          ],
          
          // 5. Happening Now (Friend Activities)
          if (activities.isNotEmpty)
            HappeningNowSection(activities: activities),
        ],
      ),
    );
  }

  String _calculateTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return years == 1 ? '1 year ago' : '$years years ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    } else if (difference.inDays > 0) {
      return difference.inDays == 1 ? '1 day ago' : '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return difference.inHours == 1 ? '1 hour ago' : '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return difference.inMinutes == 1 ? '1 minute ago' : '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  WishlistPrivacy _convertVisibilityToPrivacy(WishlistVisibility visibility) {
    switch (visibility) {
      case WishlistVisibility.public:
        return WishlistPrivacy.public;
      case WishlistVisibility.private:
        return WishlistPrivacy.private;
      case WishlistVisibility.friends:
        return WishlistPrivacy.onlyInvited;
    }
  }

  /// Show notification dropdown
  void _showNotificationDropdown(
    BuildContext context,
    List<AppNotification> notifications,
    int unreadCount,
  ) async {
    // Prevent opening if already open
    if (_isNotificationDropdownOpen) {
      return;
    }

    // Ensure we have fresh notifications data when opening for the first time.
    // If the cubit hasn't loaded notifications yet, trigger a load so the
    // dropdown BlocBuilder can update from real API data instead of staying empty.
    final notificationsCubit = context.read<NotificationsCubit>();
    if (notificationsCubit.state is! NotificationsLoaded) {
      notificationsCubit.loadNotifications();
    }

    // Mark as open immediately to prevent multiple opens
    _isNotificationDropdownOpen = true;

    // Show dropdown immediately with current data (no delay)
    // Load fresh data in the background after opening
    
    // Show dropdown menu positioned below the button
    final RenderBox? button = context.findRenderObject() as RenderBox?;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    
    if (button != null) {
      // Position dropdown below the button with small offset
      final buttonPosition = button.localToGlobal(Offset.zero, ancestor: overlay);
      final buttonSize = button.size;
      
      final RelativeRect position = RelativeRect.fromRect(
        Rect.fromLTWH(
          buttonPosition.dx,
          buttonPosition.dy + buttonSize.height + 8,
          buttonSize.width,
          0,
        ),
        Offset.zero & overlay.size,
      );
      
      final localization = Provider.of<LocalizationService>(context, listen: false);
      final isRTL = localization.isRTL;
      final screenWidth = MediaQuery.of(context).size.width;
      
      // Calculate dropdown position so it always opens inward and stays fully visible.
      // We anchor the dropdown's right edge to the button's right edge, then clamp.
      const dropdownWidth = 360.0;
      const horizontalMargin = 16.0;

      // Preferred: align dropdown RIGHT with button RIGHT (works well in both LTR/RTL)
      double dropdownLeft = buttonPosition.dx + buttonSize.width - dropdownWidth;

      // Clamp within screen bounds
      final minLeft = horizontalMargin;
      final maxLeft = screenWidth - dropdownWidth - horizontalMargin;
      if (dropdownLeft < minLeft) dropdownLeft = minLeft;
      if (dropdownLeft > maxLeft) dropdownLeft = maxLeft < minLeft ? minLeft : maxLeft;

      final dropdownTop = buttonPosition.dy + buttonSize.height + 8;
      
      // 1. Start loading notifications immediately (non-blocking)
      // This ensures API is called BEFORE dialog opens
      final cubit = context.read<NotificationsCubit>();
      cubit.loadNotifications().then((_) {
        // Dismiss badge only after successful fetch
        cubit.dismissBadge();
      });

      // 2. Open dialog immediately (no await - non-blocking)
      // The dropdown uses BlocBuilder and will update automatically when data arrives
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
        barrierColor: Colors.black.withOpacity(0.4), // Semi-transparent overlay
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          return Directionality(
            textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
            child: Material(
              color: Colors.transparent,
              child: Stack(
                children: [
                  // Backdrop overlay (tappable to close)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () => Navigator.of(dialogContext).pop(),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                  // Notification dropdown positioned below button
                  Positioned(
                    left: dropdownLeft,
                    top: dropdownTop,
                    child: GestureDetector(
                      onTap: () {}, // Prevent tap from closing when clicking on dropdown
                      child: NotificationDropdown(
                        notifications: notifications, // Use current data immediately
                        unreadCount: unreadCount, // Use current count immediately
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.05),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              )),
              child: child,
            ),
          );
        },
      ).then((_) {
        // Reset flag when dialog is closed
        _isNotificationDropdownOpen = false;
      });
    }
  }
}

/// Delegate for fixed header in SliverPersistentHeader
class _FixedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _FixedHeaderDelegate({required this.child});

  @override
  double get minExtent => _getHeaderHeight();

  @override
  double get maxExtent => _getHeaderHeight();

  double _getHeaderHeight() {
    // Keep this in sync with the visual header height.
    //
    // IMPORTANT:
    // If this extent is larger than the child's actual laid-out height, Flutter
    // can throw:
    // "SliverGeometry is not valid: The layoutExtent exceeds the paintExtent."
    //
    // We intentionally keep the header compact on mobile.
    return 160.0;
  }

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final h = _getHeaderHeight();
    // Force the child to match the sliver's extent so we never get invalid
    // sliver geometry when the header is compact.
    return SizedBox(height: h, child: child);
  }

  @override
  bool shouldRebuild(_FixedHeaderDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}
