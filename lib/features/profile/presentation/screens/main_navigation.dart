import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/widgets/top_navigation.dart';
import 'package:wish_listy/core/widgets/bottom_navigation.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';
import 'package:wish_listy/features/auth/presentation/widgets/guest_onboarding_bottom_sheet.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'home_screen.dart' show HomeScreen, HomeScreenState;
import 'package:wish_listy/features/wishlists/presentation/screens/my_wishlists_screen.dart';
import 'package:wish_listy/features/events/presentation/screens/events_screen.dart';
import 'package:wish_listy/features/friends/presentation/screens/friends_screen.dart';
import 'profile_screen.dart' show ProfileScreen, ProfileScreenState;

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  /// Helper to switch tabs from child screens while keeping the bottom nav.
  static void switchToTab(BuildContext context, int index, {int? eventsTabIndex}) {
    final state = context.findAncestorStateOfType<_MainNavigationState>();
    state?._onTabTapped(index, eventsTabIndex: eventsTabIndex);
  }

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _fabAnimationController;
  final PageStorageBucket _pageStorageBucket = PageStorageBucket();
  final GlobalKey<MyWishlistsScreenState> _wishlistsKey = GlobalKey();
  final GlobalKey<EventsScreenState> _eventsKey = GlobalKey();
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();
  final GlobalKey<FriendsScreenState> _friendsKey = GlobalKey<FriendsScreenState>();
  final GlobalKey<ProfileScreenState> _profileKey = GlobalKey<ProfileScreenState>();
  final GlobalKey homeKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initializeFabAnimation();
    
    // Fetch notifications unread count if user is authenticated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthRepository>(context, listen: false);
      if (!authService.isGuest) {
        // User is authenticated - fetch unread count
        try {
          final notificationsCubit = context.read<NotificationsCubit>();
          debugPrint('✅ MainNavigation: Fetching unread count on init...');
          notificationsCubit.getUnreadCount();
        } catch (e) {
          debugPrint('⚠️ MainNavigation: Could not access NotificationsCubit: $e');
        }
      }
      
      // Show guest onboarding if needed
      if (authService.isGuest) {
        GuestOnboardingBottomSheet.showIfNeeded(context);
      }
    });
  }

  void _initializeFabAnimation() {
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index, {int? eventsTabIndex}) {
    final authService = Provider.of<AuthRepository>(context, listen: false);

    // Check if guest user is trying to access restricted features
    if (authService.isGuest) {
      if (index == 1) {
        // Wishlists - fully allowed for guests (local storage)
        // Allow access with full local functionality
      } else if (index == 2) {
        // Events - locked for guests
        _showLockedFeatureBottomSheet(
          context,
          'Events',
          Icons.celebration_outlined,
          'Create events, invite friends, and link them to your wishlists by creating a free account.',
        );
        return;
      } else if (index == 3) {
        // Friends - locked for guests
        _showLockedFeatureBottomSheet(
          context,
          'Friends',
          Icons.people_outline,
          'Connect with friends, see their wishlists, and coordinate gift-giving by creating a free account.',
        );
        return;
      } else if (index == 4) {
        // Profile - locked for guests
        _showLockedFeatureBottomSheet(
          context,
          'Profile',
          Icons.person_outline,
          'Customize your profile, manage settings, and access all features by creating a free account.',
        );
        return;
      }
    }

    if (_currentIndex == index) {
      // Double tap to scroll to top or refresh
      _handleDoubleTap(index);
      // If already on Events tab and eventsTabIndex is provided, switch to that tab
      if (index == 2 && eventsTabIndex != null) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _eventsKey.currentState?.switchToInvitedTab();
        });
      }
      return;
    }

    setState(() {
      _currentIndex = index;
    });

    // Refresh newly selected tab content (important for IndexedStack tabs)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshTab(index);
    });

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Animate FAB
    _fabAnimationController.reset();
    _fabAnimationController.forward();

    // If switching to Events tab and eventsTabIndex is provided, switch to that tab
    if (index == 2 && eventsTabIndex != null) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _eventsKey.currentState?.switchToInvitedTab();
      });
    }
  }

  List<Widget> get _screens => [
    KeyedSubtree(
      key: const PageStorageKey('tab_home'),
      child: HomeScreen(key: _homeKey),
    ),
    KeyedSubtree(
      key: const PageStorageKey('tab_wishlists'),
      child: MyWishlistsScreen(key: _wishlistsKey),
    ),
    KeyedSubtree(
      key: const PageStorageKey('tab_events'),
      child: EventsScreen(key: _eventsKey),
    ),
    KeyedSubtree(
      key: const PageStorageKey('tab_friends'),
      child: FriendsScreen(key: _friendsKey),
    ),
    KeyedSubtree(
      key: const PageStorageKey('tab_profile'),
      child: ProfileScreen(key: _profileKey),
    ),
  ];

  void _handleDoubleTap(int index) {
    // Handle double tap actions for each tab
    switch (index) {
      case 0:
        _homeKey.currentState?.refreshHome();
        break;
      case 1:
        _wishlistsKey.currentState?.refreshWishlists();
        break;
      case 2:
        _eventsKey.currentState?.refreshEvents();
        break;
      case 3:
        _friendsKey.currentState?.refreshFriends();
        break;
      case 4:
        _profileKey.currentState?.refreshProfile();
        break;
    }
    HapticFeedback.mediumImpact();
  }

  void _refreshTab(int index) {
    switch (index) {
      case 0:
        _homeKey.currentState?.refreshHome();
        break;
      case 1:
        _wishlistsKey.currentState?.refreshWishlists();
        break;
      case 2:
        _eventsKey.currentState?.refreshEvents();
        break;
      case 3:
        _friendsKey.currentState?.refreshFriends();
        break;
      case 4:
        _profileKey.currentState?.refreshProfile();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localization, child) {
        if (!mounted) return const SizedBox.shrink();

        // Use top navigation for web, bottom navigation for mobile
        if (kIsWeb) {
          return Scaffold(
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: CustomTopNavigation(
                currentIndex: _currentIndex,
                onTap: _onTabTapped,
              ),
            ),
            body: PageStorage(
              bucket: _pageStorageBucket,
              child: IndexedStack(index: _currentIndex, children: _screens),
            ),
          );
        } else {
          return Scaffold(
            backgroundColor: Colors.white,
            extendBody: true,
            body: PageStorage(
              bucket: _pageStorageBucket,
              child: IndexedStack(index: _currentIndex, children: _screens),
            ),
            bottomNavigationBar: Container(
              color: Colors.transparent,
              child: CustomBottomNavigation(
                currentIndex: _currentIndex,
                onTap: _onTabTapped,
              ),
            ),
          );
        }
      },
    );
  }


  void _showLockedFeatureBottomSheet(
    BuildContext context,
    String featureName,
    IconData icon,
    String description,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(32),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Builder(
                builder: (context) {
                  final localization = Provider.of<LocalizationService>(context, listen: false);
                  String titleKey = '';
                  String descKey = '';
                  if (featureName == 'Events') {
                    titleKey = 'guest.unlock.events.title';
                    descKey = 'guest.unlock.events.description';
                  } else if (featureName == 'Friends') {
                    titleKey = 'guest.unlock.friends.title';
                    descKey = 'guest.unlock.friends.description';
                  } else if (featureName == 'Profile') {
                    titleKey = 'guest.unlock.profile.title';
                    descKey = 'guest.unlock.profile.description';
                  }
                  return Column(
                    children: [
                      Text(
                        titleKey.isNotEmpty ? localization.translate(titleKey) : 'Unlock $featureName',
                        style: AppStyles.headingLargeWithContext(context).copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        descKey.isNotEmpty ? localization.translate(descKey) : description,
                        style: AppStyles.bodyLargeWithContext(context).copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),

              // CTA Button
              Builder(
                builder: (context) {
                  final localization = Provider.of<LocalizationService>(context, listen: false);
                  return CustomButton(
                    text: localization.translate('guest.unlock.createFreeAccount'),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.signup);
                    },
                    variant: ButtonVariant.gradient,
                    gradientColors: [AppColors.primary, AppColors.secondary],
                    size: ButtonSize.large,
                  );
                },
              ),
              const SizedBox(height: 12),

              // Secondary button
              Builder(
                builder: (context) {
                  final localization = Provider.of<LocalizationService>(context, listen: false);
                  return TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      localization.translate('guest.unlock.notNow'),
                      style: AppStyles.bodyMediumWithContext(context).copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;

  NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
  });
}
