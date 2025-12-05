import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/widgets/top_navigation.dart';
import 'package:wish_listy/core/widgets/bottom_navigation.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';
import 'package:wish_listy/features/auth/presentation/widgets/guest_restriction_dialog.dart';
import 'home_screen.dart';
import 'package:wish_listy/features/wishlists/presentation/screens/my_wishlists_screen.dart';
import 'package:wish_listy/features/events/presentation/screens/events_screen.dart';
import 'package:wish_listy/features/friends/presentation/screens/friends_screen.dart';
import 'profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _fabAnimationController;
  final GlobalKey<MyWishlistsScreenState> _wishlistsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initializeFabAnimation();
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

  void _onTabTapped(int index) {
    final authService = Provider.of<AuthRepository>(context, listen: false);

    // Check if guest user is trying to access restricted features
    if (authService.isGuest) {
      if (index == 1) {
        // Wishlists - allow but show limited view
        // Allow access but the screen will handle guest limitations
      } else if (index == 2) {
        // Events - allow but show limited view
        // Allow access but the screen will handle guest limitations
      } else if (index == 3) {
        // Friends - restricted for guests
        GuestRestrictionDialog.show(context, 'Friends');
        return;
      } else if (index == 4) {
        // Profile - restricted for guests
        GuestRestrictionDialog.show(context, 'Profile');
        return;
      }
    }

    if (_currentIndex == index) {
      // Double tap to scroll to top or refresh
      _handleDoubleTap(index);
      return;
    }

    setState(() {
      _currentIndex = index;
    });

    // Refresh data when switching to wishlists tab
    if (index == 1 && _wishlistsKey.currentState != null) {
      _wishlistsKey.currentState!.refreshWishlists();
    }

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Animate FAB
    _fabAnimationController.reset();
    _fabAnimationController.forward();
  }

  List<Widget> get _screens => [
    const HomeScreen(),
    MyWishlistsScreen(key: _wishlistsKey),
    const EventsScreen(),
    const FriendsScreen(),
    const ProfileScreen(),
  ];

  void _handleDoubleTap(int index) {
    // Handle double tap actions for each tab
    switch (index) {
      case 0:
        // Scroll to top of home feed
        break;
      case 1:
        // Refresh wishlists
        break;
      case 2:
        // Refresh events
        break;
      case 3:
        // Refresh friends
        break;
      case 4:
        // Refresh profile
        break;
    }
    HapticFeedback.mediumImpact();
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
            body: IndexedStack(index: _currentIndex, children: _screens),
            floatingActionButton: _buildFloatingActionButton(),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          );
        } else {
          return Scaffold(
            body: IndexedStack(index: _currentIndex, children: _screens),
            bottomNavigationBar: CustomBottomNavigation(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
            ),
            floatingActionButton: _buildFloatingActionButton(),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          );
        }
      },
    );
  }

  Widget? _buildFloatingActionButton() {
    final authService = Provider.of<AuthRepository>(context, listen: false);

    switch (_currentIndex) {
      case 0: // Home
        return null; // No FAB for Home screen
      case 1: // Wishlists
        return authService.isGuest ? null : _buildWishlistFAB();
      case 2: // Events
        return authService.isGuest ? null : _buildEventFAB();
      case 3: // Friends
        return authService.isGuest ? null : _buildFriendFAB();
      case 4: // Profile
        return authService.isGuest ? null : _buildProfileFAB();
      default:
        return null;
    }
  }

  Widget _buildWishlistFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.pinkGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.pink.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          // Navigate to create wishlist
          Navigator.pushNamed(context, '/create-wishlist');
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        heroTag: 'wishlist_fab_nav',
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildEventFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.tealGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          // Navigate to create event
          Navigator.pushNamed(context, '/create-event');
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        heroTag: 'event_fab',
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildFriendFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.indigoGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.indigo.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          // Navigate to add friend
          Navigator.pushNamed(context, '/add-friend');
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        heroTag: 'friend_fab',
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildProfileFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.orangeGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          // Navigate to edit profile
          Navigator.pushNamed(context, '/edit-profile');
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        heroTag: 'profile_fab',
        child: const Icon(Icons.edit, color: Colors.white, size: 28),
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
