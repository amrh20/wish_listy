


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../utils/app_theme.dart';
import 'home_screen.dart';
import '../wishlists/my_wishlists_screen.dart';
import '../events/events_screen.dart';
import '../friends/friends_screen.dart';
import '../profile/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
      color: AppColors.primary,
    ),
    NavigationItem(
      icon: Icons.favorite_outline,
      activeIcon: Icons.favorite_rounded,
      label: 'Wishlists',
      color: AppColors.secondary,
    ),
    NavigationItem(
      icon: Icons.celebration_outlined,
      activeIcon: Icons.celebration_rounded,
      label: 'Events',
      color: AppColors.accent,
    ),
    NavigationItem(
      icon: Icons.people_outline,
      activeIcon: Icons.people_rounded,
      label: 'Friends',
      color: AppColors.info,
    ),
    NavigationItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
      color: AppColors.warning,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initializeFabAnimation();
  }

  void _initializeFabAnimation() {
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fabScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    ));

    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) {
      // Double tap to scroll to top or refresh
      _handleDoubleTap(index);
      return;
    }

    setState(() {
      _currentIndex = index;
    });

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Animate FAB
    _fabAnimationController.reset();
    _fabAnimationController.forward();
  }

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
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          HomeScreen(),
          MyWishlistsScreen(),
          EventsScreen(),
          FriendsScreen(),
          ProfileScreen(),
        ],
      ),
      
      // Custom Bottom Navigation Bar
      bottomNavigationBar: _buildBottomNavigationBar(),
      
      // Floating Action Button (conditional)
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.textTertiary.withOpacity(0.1),
            offset: const Offset(0, -4),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _navigationItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isActive = _currentIndex == index;
              
              return _buildNavigationButton(item, index, isActive);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButton(NavigationItem item, int index, bool isActive) {
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? item.color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? item.activeIcon : item.icon,
                key: ValueKey(isActive),
                color: isActive ? item.color : AppColors.textTertiary,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: AppStyles.caption.copyWith(
                color: isActive ? item.color : AppColors.textTertiary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    // Show FAB only on specific tabs
    if (_currentIndex == 1) {
      // Wishlists tab
      return AnimatedBuilder(
        animation: _fabScaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _fabScaleAnimation.value,
            child: FloatingActionButton(
              onPressed: () {
                // Navigate to add item screen
                Navigator.pushNamed(context, '/add-item');
              },
              backgroundColor: AppColors.secondary,
              elevation: 8,
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          );
        },
      );
    } else if (_currentIndex == 2) {
      // Events tab
      return AnimatedBuilder(
        animation: _fabScaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _fabScaleAnimation.value,
            child: FloatingActionButton(
              onPressed: () {
                // Navigate to create event screen
                Navigator.pushNamed(context, '/create-event');
              },
              backgroundColor: AppColors.accent,
              elevation: 8,
              child: const Icon(
                Icons.celebration_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          );
        },
      );
    }
    return null;
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