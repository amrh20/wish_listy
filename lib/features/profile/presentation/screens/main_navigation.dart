import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:wish_listy/core/widgets/overflow_safe_speed_dial.dart';
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
import 'package:wish_listy/core/navigation/app_route_observer.dart';
import 'home_screen.dart' show HomeScreen, HomeScreenState;
import 'package:wish_listy/features/wishlists/presentation/screens/my_wishlists_screen.dart';
import 'package:wish_listy/features/events/presentation/screens/events_screen.dart';
import 'package:wish_listy/features/friends/presentation/screens/friends_screen.dart';
import 'profile_screen.dart' show ProfileScreen, ProfileScreenState;
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/core/services/update_service.dart';
import 'package:wish_listy/core/services/socket_service.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  /// Helper to switch tabs from child screens while keeping the bottom nav.
  /// [eventsTabIndex] allows switching to a specific Events sub-tab.
  /// [wishlistsTabIndex] allows switching to a specific Wishlists sub-tab (e.g. Reservations).
  /// [returnToTabOnBack] When set (e.g. when opening Friends from "Browse Friends" in Wishlists),
  /// the system back button will switch to this tab instead of exiting the app.
  static void switchToTab(
    BuildContext context,
    int index, {
    int? eventsTabIndex,
    int? wishlistsTabIndex,
    int? returnToTabOnBack,
  }) {
    final state = context.findAncestorStateOfType<_MainNavigationState>();
    state?._onTabTapped(
      index,
      eventsTabIndex: eventsTabIndex,
      wishlistsTabIndex: wishlistsTabIndex,
      returnToTabOnBack: returnToTabOnBack,
    );
  }

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with TickerProviderStateMixin, RouteAware, WidgetsBindingObserver {
  int _currentIndex = 0;
  /// When user opened Friends tab from another tab (e.g. "Browse Friends" from Wishlists),
  /// back button should return to this tab index instead of exiting the app.
  int? _returnToTabOnBack;
  /// Tracks empty state per tab (1=Wishlists, 2=Events, 3=Friends) to hide FAB and avoid conflict with empty-state add buttons.
  final Map<int, bool> _emptyStateByTab = {};
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
    WidgetsBinding.instance.addObserver(this);
    _initializeFabAnimation();
    
    // Fetch notifications unread count if user is authenticated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthRepository>(context, listen: false);
      if (!authService.isGuest) {
        // User is authenticated - fetch unread count
        try {
          final notificationsCubit = context.read<NotificationsCubit>();
          notificationsCubit.getUnreadCount();
        } catch (e) {
        }
      }
      
      // Show guest onboarding if needed
      if (authService.isGuest) {
        GuestOnboardingBottomSheet.showIfNeeded(context);
      }

      // Check for app updates via Firebase Remote Config (delayed to avoid
      // race with overlay/route changes that cause _elements.contains assertion)
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!context.mounted) return;
        UpdateService().checkForUpdates(context);
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
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
    WidgetsBinding.instance.removeObserver(this);
    appRouteObserver.unsubscribe(this);
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted) {
      _onAppResumed();
    }
  }

  /// Called when app returns from background. Reconnect socket if needed and refresh badge.
  void _onAppResumed() {
    final authService = Provider.of<AuthRepository>(context, listen: false);
    if (authService.isGuest) return;

    // Reconnect socket if it was disconnected (e.g. after network drop)
    final socketService = SocketService();
    if (!socketService.isConnected) {
      socketService.connect();
    }

    // Refresh notification badge to ensure it reflects backend state
    try {
      context.read<NotificationsCubit>().getUnreadCount();
    } catch (e) {
      // Cubit may not be available if context is invalid
    }
  }

  @override
  void didPopNext() {
    // We returned to MainNavigation from a pushed route (e.g., details/create).
    // Refresh the currently visible tab so it reflects the latest backend state.
    // EXCEPT for Profile tab - it should only refresh on explicit pull-to-refresh
    // to prevent redundant API calls when returning from full-screen image viewer
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Skip refresh for Profile tab (index 4) to prevent reload when closing full-screen viewer
      if (_currentIndex != 4) {
        _refreshTab(_currentIndex);
      }
    });
  }

  void _onTabTapped(
    int index, {
    int? eventsTabIndex,
    int? wishlistsTabIndex,
    int? returnToTabOnBack,
  }) {
    final authService = Provider.of<AuthRepository>(context, listen: false);

    // Remember which tab to return to when user presses back (e.g. from Friends back to Wishlists)
    if (returnToTabOnBack != null) {
      setState(() {
        _returnToTabOnBack = returnToTabOnBack;
      });
    }

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
      // If already on Wishlists tab and wishlistsTabIndex is provided, switch sub-tab
      if (index == 1 && wishlistsTabIndex != null) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (wishlistsTabIndex == 1) {
            _wishlistsKey.currentState?.switchToReservationsTab();
          }
        });
      }
      return;
    }

    setState(() {
      _currentIndex = index;
      // Clear return target when user explicitly taps another tab (so back doesn't use stale value)
      if (returnToTabOnBack == null) {
        _returnToTabOnBack = null;
      }
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

    // If switching to Wishlists tab and wishlistsTabIndex is provided, switch to that sub-tab
    if (index == 1 && wishlistsTabIndex != null) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (wishlistsTabIndex == 1) {
          _wishlistsKey.currentState?.switchToReservationsTab();
        }
      });
    }
  }

  void _onTabEmptyStateChanged(int tabIndex, bool isEmpty) {
    if (_emptyStateByTab[tabIndex] != isEmpty) {
      setState(() {
        _emptyStateByTab[tabIndex] = isEmpty;
      });
    }
  }

  List<Widget> get _screens => [
    KeyedSubtree(
      key: const PageStorageKey('tab_home'),
      child: HomeScreen(key: _homeKey, onEmptyStateChanged: (v) => _onTabEmptyStateChanged(0, v)),
    ),
    KeyedSubtree(
      key: const PageStorageKey('tab_wishlists'),
      child: MyWishlistsScreen(key: _wishlistsKey, onEmptyStateChanged: (v) => _onTabEmptyStateChanged(1, v)),
    ),
    KeyedSubtree(
      key: const PageStorageKey('tab_events'),
      child: EventsScreen(key: _eventsKey, onEmptyStateChanged: (v) => _onTabEmptyStateChanged(2, v)),
    ),
    KeyedSubtree(
      key: const PageStorageKey('tab_friends'),
      child: FriendsScreen(key: _friendsKey, onEmptyStateChanged: (v) => _onTabEmptyStateChanged(3, v)),
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

  Widget _buildSpeedDialChildRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color primaryColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: primaryColor, size: 22),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: AppStyles.bodyMedium.copyWith(
                color: Colors.grey[800],
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context) {
    // Home tab: Speed Dial with 3 actions (spread animation)
    if (_currentIndex == 0) {
      final localization = Provider.of<LocalizationService>(context, listen: false);
      final authService = Provider.of<AuthRepository>(context, listen: false);
      if (authService.isGuest) return null;
      // Hide Speed Dial in empty state to avoid conflict with "Create your first list" button
      if (_emptyStateByTab[0] != false) return null;

      final isRTL = localization.isRTL;
      final primaryColor = Theme.of(context).colorScheme.primary;

      return Padding(
        padding: const EdgeInsets.only(bottom: 1),
        child: OverflowSafeSpeedDial(
          icon: Icons.add,
          activeIcon: Icons.close,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          isRTL: isRTL,
          children: [
            OverflowSafeSpeedDialChild(
              child: _buildSpeedDialChildRow(
                context,
                icon: Icons.card_giftcard,
                label: localization.translate('home.createWishlist') ?? 'Create Wishlist',
                primaryColor: primaryColor,
              ),
              backgroundColor: Colors.white,
              foregroundColor: primaryColor,
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.createWishlist,
                arguments: {'previousRoute': AppRoutes.myWishlists},
              ),
            ),
            OverflowSafeSpeedDialChild(
              child: _buildSpeedDialChildRow(
                context,
                icon: Icons.event,
                label: localization.translate('home.createEvent') ?? 'Create Event',
                primaryColor: primaryColor,
              ),
              backgroundColor: Colors.white,
              foregroundColor: primaryColor,
              onTap: () async {
                await Navigator.pushNamed(context, AppRoutes.createEvent);
                if (mounted) _eventsKey.currentState?.refreshEvents();
              },
            ),
            OverflowSafeSpeedDialChild(
              child: _buildSpeedDialChildRow(
                context,
                icon: Icons.person_add,
                label: localization.translate('home.addFriend') ?? 'Add Friend',
                primaryColor: primaryColor,
              ),
              backgroundColor: Colors.white,
              foregroundColor: primaryColor,
              onTap: () => Navigator.pushNamed(context, AppRoutes.addFriend),
            ),
          ],
        ),
      );
    }

    // Wishlists / Events / Friends tabs: simple FAB
    if (_currentIndex != 1 && _currentIndex != 2 && _currentIndex != 3) {
      return null;
    }
    // Hide FAB until we know tab has data (avoid flicker: show then hide on empty)
    if (_emptyStateByTab[_currentIndex] != false) {
      return null;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: FloatingActionButton(
        elevation: 0,
        highlightElevation: 0,
        onPressed: () async {
          switch (_currentIndex) {
            case 1:
              Navigator.pushNamed(
                context,
                AppRoutes.createWishlist,
                arguments: {'previousRoute': AppRoutes.myWishlists},
              );
              break;
            case 2:
              await Navigator.pushNamed(context, AppRoutes.createEvent);
              if (mounted) _eventsKey.currentState?.refreshEvents();
              break;
            case 3:
              Navigator.pushNamed(context, AppRoutes.addFriend);
              break;
            default:
              break;
          }
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
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
          final canPop = !(_currentIndex == 3 && _returnToTabOnBack != null);
          return ValueListenableBuilder<bool>(
            valueListenable: ApiService.isOffline,
            builder: (context, isOffline, _) {
              return PopScope(
                canPop: canPop,
                onPopInvokedWithResult: (bool didPop, dynamic result) {
                  if (didPop) return;
                  if (_currentIndex == 3 && _returnToTabOnBack != null) {
                    final returnTo = _returnToTabOnBack!;
                    setState(() {
                      _currentIndex = returnTo;
                      _returnToTabOnBack = null;
                    });
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _refreshTab(returnTo);
                    });
                  }
                },
                child: Scaffold(
                  backgroundColor: Colors.white,
                  extendBody: !isOffline,
                  body: PageStorage(
                    bucket: _pageStorageBucket,
                    child: IndexedStack(index: _currentIndex, children: _screens),
                  ),
                  floatingActionButton: isOffline
                      ? null
                      : _buildFloatingActionButton(context),
                  floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
                  bottomNavigationBar: isOffline
                      ? null
                      : Container(
                          color: Colors.transparent,
                          child: CustomBottomNavigation(
                            currentIndex: _currentIndex,
                            onTap: _onTabTapped,
                          ),
                        ),
                ),
              );
            },
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
