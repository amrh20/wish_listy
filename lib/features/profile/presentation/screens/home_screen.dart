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
import 'package:wish_listy/features/profile/presentation/screens/guest_home_screen.dart';
import 'package:wish_listy/features/profile/presentation/screens/main_navigation.dart';
import 'package:wish_listy/features/profile/presentation/models/home_models.dart';
import 'package:wish_listy/features/wishlists/presentation/widgets/wishlist_card_widget.dart';
import 'package:wish_listy/features/wishlists/data/models/wishlist_model.dart';
import 'package:wish_listy/features/events/data/models/event_model.dart';
import 'package:wish_listy/features/notifications/presentation/widgets/notification_dropdown.dart';
import 'package:wish_listy/features/notifications/data/models/notification_model.dart';
import 'package:wish_listy/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:wish_listy/core/services/localization_service.dart';

class HomeScreen extends StatefulWidget {
  final GlobalKey<HomeScreenState>? key;

  const HomeScreen({this.key}) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  late HomeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HomeController();
    _controller.fetchDashboardData();
    // Load unread count from NotificationsCubit when app starts
    // This ensures we use the correct API that respects lastBadgeSeenAt
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<NotificationsCubit>();
      cubit.getUnreadCount();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Public method to refresh home dashboard from outside (e.g., MainNavigation tab switch)
  Future<void> refreshHome() async {
    await _controller.refresh();
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
    final profileImageUrl = dashboardData?.user.avatar;
    final unreadCount = dashboardData?.stats.unreadNotificationsCount ?? 0;

    return Container(
      margin: const EdgeInsets.only(
        left: 8,
        right: 8,
        top: 12,
        bottom: 16,
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
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: SafeArea(
                bottom: false,
                top: false, // Top SafeArea is handled by padding
                minimum: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Avatar + Greeting Column + Notification
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left: Profile Avatar (reduced radius, tappable)
                        GestureDetector(
                          onTap: () {
                            MainNavigation.switchToTab(context, 4); // Switch to Profile tab
                          },
                          child: CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.white,
                            backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
                                ? NetworkImage(profileImageUrl)
                                : null,
                            child: profileImageUrl == null || profileImageUrl.isEmpty
                                ? Icon(
                                    Icons.person_rounded,
                                    color: AppColors.primary,
                                    size: 30,
                                  )
                                : null,
                          ),
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
                                    fontSize: 20,
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
                    // Bottom: "Ready to make wishes" text (below Row, italic, darker grey, smaller)
                    const SizedBox(height: 12),
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
        bottom: 16,
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
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: SafeArea(
                bottom: false,
                top: false,
                minimum: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    // Bottom: Welcome message skeleton
                    const SizedBox(height: 12),
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
                          // Spacing between Header and My Wishlists section
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 20),
                          ),
                          // Content
                          if (controller.isLoading)
                            const SliverToBoxAdapter(child: HomeSkeletonView())
                          else if (isEmpty)
                            const SliverFillRemaining(
                              hasScrollBody: false,
                              child: EmptyHomeScreen(),
                            )
                          else
                            SliverToBoxAdapter(
                              child: ActiveDashboard(
                                occasions: _convertEventsToOccasions(
                                  controller.upcomingOccasions ?? [],
                                ),
                                wishlists: _convertWishlistsToSummaries(
                                  controller.myWishlists ?? [],
                                ),
                                activities: controller.latestActivityPreview ??
                                    [], // Use latestActivityPreview directly with null safety
                              ),
                            ),
                          // Bottom padding to clear Bottom Navigation Bar
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 120),
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
      return WishlistSummary(
        id: wishlist.id,
        name: wishlist.name,
        description: wishlist.description,
        itemCount: wishlist.totalItems,
        purchasedCount: wishlist.purchasedItems,
        lastUpdated: wishlist.updatedAt,
        privacy: _convertVisibilityToPrivacy(wishlist.visibility),
        category: wishlist.category,
        previewItems: wishlist.items.take(3).toList(),
      );
    }).toList();
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
    // Load notifications from API
    final cubit = context.read<NotificationsCubit>();
    await cubit.loadNotifications();
    
    // Dismiss badge (reset unread count)
    await cubit.dismissBadge();
    
    // Get updated state
    final state = cubit.state;
    final updatedNotifications = state is NotificationsLoaded
        ? state.notifications
        : notifications;
    final updatedUnreadCount = state is NotificationsLoaded
        ? state.unreadCount
        : 0;
    
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
      
      await showMenu(
        context: context,
        position: position,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: const BoxConstraints(
          maxWidth: 360,
          maxHeight: 400,
        ),
        items: [
          PopupMenuItem(
            enabled: false,
            padding: EdgeInsets.zero,
            child: NotificationDropdown(
              notifications: updatedNotifications,
              unreadCount: updatedUnreadCount,
            ),
          ),
        ],
      );
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
    // Calculate approximate height for new design:
    // - margin top: 12
    // - SafeArea top padding: ~44 (status bar)
    // - top padding: 20
    // - Avatar row (avatar + greeting): ~60px (avatar height)
    // - spacing: 16
    // - Welcome message: ~18
    // - bottom padding: 24
    // - margin bottom: 16
    // Total: ~210px, but we'll use a safe value
    return 210.0;
  }

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_FixedHeaderDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}
