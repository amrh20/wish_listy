import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
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
      debugPrint('🏠 HomeScreen: Checking for wishlists...');
      final wishlists = await _wishlistRepository.getWishlists();

      setState(() {
        _hasWishlists = wishlists.isNotEmpty;
        _wishlistCount = wishlists.length;
        _showWelcomeCard =
            !_hasWishlists; // Hide welcome card if user has wishlists
        _isCheckingWishlists = false;
      });

      debugPrint(
        '🏠 HomeScreen: Has wishlists: $_hasWishlists, Count: $_wishlistCount',
      );
    } on ApiException catch (e) {
      debugPrint('⚠️ HomeScreen: Error checking wishlists: ${e.message}');
      setState(() {
        _isCheckingWishlists = false;
        // Keep welcome card visible if there's an error
      });
    } catch (e) {
      debugPrint('⚠️ HomeScreen: Unexpected error checking wishlists: $e');
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
  }

  void _startAnimations() {
    _animationController.forward();
  }


  @override
  Widget build(BuildContext context) {
    return Consumer2<LocalizationService, AuthRepository>(
      builder: (context, localization, authService, child) {
        // For guest users, use custom hero header layout
        if (authService.isGuest) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: UnifiedPageBackground(
              child: DecorativeBackground(
                child: Column(
                  children: [
                    // Custom Hero Header for Guests
                    _buildGuestHeroHeader(localization),

                    // Content in rounded container (with negative margin to overlap header)
                    Expanded(
                      child: Transform.translate(
                        offset: const Offset(0, -8), // Move up to overlap header
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

  /// Build custom hero header for guest users
  Widget _buildGuestHeroHeader(LocalizationService localization) {
    final screenHeight = MediaQuery.of(context).size.height;
    final headerHeight = screenHeight * 0.30; // 30% of screen height

    return Container(
      height: headerHeight,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            children: [
              // Top Row: Logo and Sign In button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // WishListy Logo/Text
                  Text(
                    'WishListy',
                    style: AppStyles.headingLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  // Sign In Icon Button
                  IconButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.login);
                    },
                    icon: const Icon(
                      Icons.login_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      padding: const EdgeInsets.all(10),
                      minimumSize: const Size(40, 40),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Center Content: Welcome Message
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello there! 👋',
                    style: AppStyles.headingLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Start by creating your first wishlist and organize your dreams.',
                    style: AppStyles.bodyLarge.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnifiedHeader(
    LocalizationService localization,
    AuthRepository authService,
  ) {
    return UnifiedPageHeader(
      title: '${localization.translate('home.greeting')} 👋',
      subtitle: authService.userName ?? 'User',
      showSearch: false,
      actions: [
        HeaderAction(
          icon: Icons.notifications_outlined,
          onTap: () {
            AppRoutes.pushNamed(context, AppRoutes.notifications);
          },
          showBadge: true,
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
                arguments: {'isEvent': false},
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
                      AppRoutes.pushNamed(context, AppRoutes.createWishlist);
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
                      AppRoutes.pushNamed(context, AppRoutes.friends);
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
      final wishlists = await guestDataRepo.getAllWishlists();
      
      setState(() {
        _guestWishlists = wishlists;
        _isLoadingGuestData = false;
      });
      
      debugPrint('✅ HomeScreen: Loaded ${wishlists.length} guest wishlists');
    } catch (e) {
      debugPrint('❌ HomeScreen: Error loading guest wishlists: $e');
      setState(() {
        _isLoadingGuestData = false;
      });
    }
  }

  Widget _buildCreateFirstWishlistButton() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_outline,
              size: 30,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 18),
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
          const SizedBox(height: 24),
          CustomButton(
            text: 'Create Your First Wishlist',
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.createWishlist);
            },
            variant: ButtonVariant.gradient,
            gradientColors: [AppColors.primary, AppColors.secondary],
            size: ButtonSize.medium,
            icon: Icons.add,
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
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.createWishlist);
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
        // Wishlist Cards
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _guestWishlists.length,
          itemBuilder: (context, index) {
            final wishlist = _guestWishlists[index];
            return _buildGuestWishlistCard(wishlist);
          },
        ),
      ],
    );
  }

  Widget _buildGuestWishlistCard(Wishlist wishlist) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textTertiary.withOpacity(0.08),
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
                // Icon Container
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
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
