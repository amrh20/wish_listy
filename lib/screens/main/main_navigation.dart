import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../widgets/bottom_navigation.dart';
import '../../widgets/language_switcher.dart';
import '../../services/localization_service.dart';
import 'home_screen.dart';
import '../wishlists/my_wishlists_screen.dart';
import '../events/events_screen.dart';
import '../friends/friends_screen.dart';
import '../profile/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

  List<NavigationItem> _getNavigationItems(LocalizationService localization) {
    return [
      NavigationItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: localization.translate('navigation.home'),
        color: AppColors.primary,
      ),
      NavigationItem(
        icon: Icons.favorite_outline,
        activeIcon: Icons.favorite_rounded,
        label: localization.translate('navigation.wishlist'),
        color: AppColors.secondary,
      ),
      NavigationItem(
        icon: Icons.celebration_outlined,
        activeIcon: Icons.celebration_rounded,
        label: localization.translate('navigation.events'),
        color: AppColors.accent,
      ),
      NavigationItem(
        icon: Icons.people_outline,
        activeIcon: Icons.people_rounded,
        label: localization.translate('navigation.friends'),
        color: AppColors.warning,
      ),
      NavigationItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person_rounded,
        label: localization.translate('navigation.profile'),
        color: AppColors.info,
      ),
    ];
  }

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

    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.elasticOut,
      ),
    );

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
    return Consumer<LocalizationService>(
      builder: (context, localization, child) {
        if (!mounted) return const SizedBox.shrink();

        return Scaffold(
          body: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              if (mounted) {
                setState(() {
                  _currentIndex = index;
                });
              }
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
          bottomNavigationBar: CustomBottomNavigation(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
          ),

          // Floating Action Button (conditional)
          floatingActionButton: _buildFloatingActionButton(),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }

  Widget? _buildFloatingActionButton() {
    switch (_currentIndex) {
      case 0: // Home
        return _buildHomeFAB();
      case 1: // Wishlists
        return _buildWishlistFAB();
      case 2: // Events
        return _buildEventFAB();
      case 3: // Friends
        return _buildFriendFAB();
      case 4: // Profile
        return _buildProfileFAB();
      default:
        return null;
    }
  }

  Widget _buildHomeFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {
          // Show quick actions menu
          _showQuickActionsMenu(context);
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
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
        child: const Icon(Icons.edit, color: Colors.white, size: 28),
      ),
    );
  }

  void _showQuickActionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer<LocalizationService>(
        builder: (context, localization, child) {
          if (!context.mounted) return const SizedBox.shrink();

          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localization.translate('home.quickActions'),
                        style: AppStyles.heading4.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickActionCard(
                              icon: Icons.card_giftcard,
                              title: localization.translate(
                                'home.createWishlist',
                              ),
                              gradient: AppColors.pinkGradient,
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.pushNamed(
                                  context,
                                  '/create-wishlist',
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildQuickActionCard(
                              icon: Icons.event,
                              title: localization.translate('home.createEvent'),
                              gradient: AppColors.tealGradient,
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.pushNamed(context, '/create-event');
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickActionCard(
                              icon: Icons.person_add,
                              title: localization.translate('home.addFriend'),
                              gradient: AppColors.indigoGradient,
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.pushNamed(context, '/add-friend');
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildQuickActionCard(
                              icon: Icons.language,
                              title: localization.translate('app.language'),
                              gradient: AppColors.orangeGradient,
                              onTap: () {
                                Navigator.pop(context);
                                _showLanguageDialog(context);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppStyles.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const LanguageSelectionDialog(),
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
