import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';

import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/widgets/decorative_background.dart';
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Mock user data
  final UserProfile _userProfile = UserProfile(
    id: 'user123',
    name: 'Ahmed Ali',
    email: 'ahmed@example.com',
    bio:
        'Love tech gadgets and outdoor adventures. Always looking for the next great read!',
    profilePicture: null,
    joinDate: DateTime(2023, 6, 15),
    friendsCount: 24,
    wishlistsCount: 5,
    eventsCreated: 3,
    giftsReceived: 12,
    giftsGiven: 18,
    privacy: PrivacySettings(
      profileVisibility: ProfileVisibility.friends,
      showOnlineStatus: true,
      allowFriendRequests: true,
      showWishlistActivity: true,
    ),
  );

  String _currentLanguage = 'en';

  final List<Achievement> _achievements = [
    Achievement(
      id: '1',
      title: 'First Wishlist',
      description: 'Created your first wishlist',
      icon: Icons.favorite,
      color: AppColors.primary,
      unlockedAt: DateTime.now().subtract(Duration(days: 30)),
    ),
    Achievement(
      id: '2',
      title: 'Social Butterfly',
      description: 'Connected with 10 friends',
      icon: Icons.people,
      color: AppColors.secondary,
      unlockedAt: DateTime.now().subtract(Duration(days: 15)),
    ),
    Achievement(
      id: '3',
      title: 'Gift Giver',
      description: 'Gave 5 gifts to friends',
      icon: Icons.card_giftcard,
      color: AppColors.accent,
      unlockedAt: DateTime.now().subtract(Duration(days: 7)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    _loadCurrentLanguage();
  }

  void _loadCurrentLanguage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final localization = Provider.of<LocalizationService>(
        context,
        listen: false,
      );
      setState(() {
        _currentLanguage = localization.currentLanguage;
      });
    });
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(
        milliseconds: 800,
      ), // Reduced from 1000ms for better performance
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(
          0.0,
          0.7,
          curve: Curves.easeInOut,
        ), // Increased from 0.6
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
          // Reduced from 0.2
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(
              0.1,
              0.9,
              curve: Curves.easeOutCubic,
            ), // Adjusted intervals
          ),
        );
  }

  void _startAnimations() {
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localization, child) {
        return Scaffold(
          body: DecorativeBackground(
            showGifts: false, // Less busy for profile
            child: Stack(
              children: [
                // Content
                RefreshIndicator(
                  onRefresh: _refreshProfile,
                  color: AppColors.primary,
                  child: CustomScrollView(
                    slivers: [
                      // Profile Header
                      _buildSliverAppBar(),

                      // Profile Content
                      SliverToBoxAdapter(
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
                                      // Stats Cards
                                      _buildStatsSection(),
                                      const SizedBox(
                                        height: 16,
                                      ), // تقليل المسافة
                                      // Quick Actions
                                      _buildQuickActions(),
                                      const SizedBox(
                                        height: 16,
                                      ), // تقليل المسافة
                                      // Achievements
                                      _buildAchievements(),
                                      const SizedBox(
                                        height: 16,
                                      ), // تقليل المسافة
                                      // Account Settings
                                      _buildAccountSettings(),
                                      const SizedBox(
                                        height: 16,
                                      ), // تقليل المسافة
                                      // App Settings
                                      _buildAppSettings(),
                                      const SizedBox(
                                        height: 16,
                                      ), // تقليل المسافة
                                      // Support & About
                                      _buildSupportSection(),
                                      const SizedBox(
                                        height: 80,
                                      ), // تقليل المسافة السفلية
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.accent, AppColors.accentLight],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.3), // Reduced from 0.4
                  offset: const Offset(0, 6), // Reduced from 8
                  blurRadius: 15, // Reduced from 20
                  spreadRadius: 1, // Reduced from 2
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: _editProfile,
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Icon(Icons.edit_outlined, color: Colors.white, size: 24),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 280, // تقليل الارتفاع
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primaryAccent,
                AppColors.secondary,
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [Colors.white.withOpacity(0.1), Colors.transparent],
                center: Alignment.topRight,
                radius: 1.5,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16), // تقليل الـ padding
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20), // تقليل المسافة
                    // Profile Picture with enhanced design
                    Stack(
                      children: [
                        Container(
                          width: 90, // تقليل الحجم
                          height: 90, // تقليل الحجم
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white,
                                Colors.white.withOpacity(0.9),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                offset: const Offset(0, 6),
                                blurRadius: 15,
                                spreadRadius: 1,
                              ),
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                offset: const Offset(0, 3),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _userProfile.name[0].toUpperCase(),
                              style: AppStyles.headingLarge.copyWith(
                                color: AppColors.primary,
                                fontSize: 36, // تقليل حجم الخط
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        // Enhanced Edit Button
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _editProfilePicture,
                            child: Container(
                              width: 30, // تقليل الحجم
                              height: 30, // تقليل الحجم
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.accent,
                                    AppColors.accentLight,
                                  ],
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withOpacity(0.4),
                                    offset: const Offset(0, 3),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 16, // تقليل حجم الأيقونة
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12), // تقليل المسافة
                    // Enhanced Name with shadow
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ), // تقليل الـ padding
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _userProfile.name,
                        style: AppStyles.headingMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18, // تقليل حجم الخط
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              offset: const Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 6), // تقليل المسافة
                    // Enhanced Email
                    Text(
                      _userProfile.email,
                      style: AppStyles.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.95),
                        fontWeight: FontWeight.w500,
                        fontSize: 14, // تقليل حجم الخط
                      ),
                    ),

                    const SizedBox(height: 6), // تقليل المسافة
                    // Enhanced Member Since with icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: Colors.white.withOpacity(0.8),
                          size: 14, // تقليل حجم الأيقونة
                        ),
                        const SizedBox(width: 4), // تقليل المسافة
                        Text(
                          'Member since ${_formatJoinDate(_userProfile.joinDate)}',
                          style: AppStyles.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.85),
                            fontWeight: FontWeight.w500,
                            fontSize: 12, // تقليل حجم الخط
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      actions: [
        // Enhanced Edit Button
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          child: IconButton(
            onPressed: _editProfile,
            icon: Icon(Icons.edit_outlined, color: Colors.white, size: 22),
          ),
        ),
        // Enhanced Menu Button
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          child: PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            icon: Icon(Icons.more_vert, color: Colors.white, size: 22),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: AppColors.surface,
            elevation: 8,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'share_profile',
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.share_outlined,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Share Profile',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export_data',
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.download_outlined,
                        size: 18,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Export Data',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.logout_outlined,
                        size: 18,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('Logout', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(16), // تقليل الـ padding
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.surfaceVariant.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16), // تقليل الـ radius
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.08),
            offset: const Offset(0, 4),
            blurRadius: 20,
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
                padding: const EdgeInsets.all(6), // تقليل الـ padding
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryAccent],
                  ),
                  borderRadius: BorderRadius.circular(8), // تقليل الـ radius
                ),
                child: Icon(
                  Icons.analytics_outlined,
                  color: Colors.white,
                  size: 18, // تقليل الحجم
                ),
              ),
              const SizedBox(width: 10), // تقليل المسافة
              Text(
                'Your Stats',
                style: AppStyles.headingSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16, // تقليل حجم الخط
                ),
              ),
            ],
          ),
          const SizedBox(height: 16), // تقليل المسافة
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Friends',
                  value: '${_userProfile.friendsCount}',
                  icon: Icons.people_outline,
                  color: AppColors.secondary,
                  onTap: () => AppRoutes.pushNamed(context, AppRoutes.friends),
                ),
              ),
              const SizedBox(width: 8), // تقليل المسافة
              Expanded(
                child: _buildStatCard(
                  title: 'Wishlists',
                  value: '${_userProfile.wishlistsCount}',
                  icon: Icons.favorite_outline,
                  color: AppColors.primary,
                  onTap: () =>
                      AppRoutes.pushNamed(context, AppRoutes.myWishlists),
                ),
              ),
              const SizedBox(width: 8), // تقليل المسافة
              Expanded(
                child: _buildStatCard(
                  title: 'Events',
                  value: '${_userProfile.eventsCreated}',
                  icon: Icons.event_outlined,
                  color: AppColors.accent,
                  onTap: () => AppRoutes.pushNamed(context, AppRoutes.events),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.05), color.withOpacity(0.1)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              offset: const Offset(0, 4),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color.withOpacity(0.15), color.withOpacity(0.25)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.3), width: 1),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: AppStyles.headingSmall.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: AppStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.surfaceVariant.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.06),
            offset: const Offset(0, 4),
            blurRadius: 20,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.secondary, AppColors.secondaryLight],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.flash_on, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Quick Actions',
                style: AppStyles.headingSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.edit_outlined,
                  label: 'Edit Profile',
                  onTap: _editProfile,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.qr_code_rounded,
                  label: 'QR Code',
                  onTap: _showQRCode,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.backup_outlined,
                  label: 'Backup Data',
                  onTap: _backupData,
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.analytics_outlined,
                  label: 'View Stats',
                  onTap: _viewDetailedStats,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.05), color.withOpacity(0.1)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              offset: const Offset(0, 4),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color.withOpacity(0.15), color.withOpacity(0.25)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.3), width: 1),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: AppStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievements() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.surfaceVariant.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.06),
            offset: const Offset(0, 4),
            blurRadius: 20,
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.accent, AppColors.accentLight],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.emoji_events,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Achievements',
                    style: AppStyles.headingSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryAccent],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextButton(
                  onPressed: _viewAllAchievements,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: Text(
                    'View All',
                    style: AppStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Column(
            children: _achievements.take(3).map((achievement) {
              return _buildAchievementItem(achievement);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementItem(Achievement achievement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            achievement.color.withOpacity(0.08),
            achievement.color.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: achievement.color.withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: achievement.color.withOpacity(0.1),
            offset: const Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [achievement.color, achievement.color.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: achievement.color.withOpacity(0.3),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(achievement.icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: AppStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: AppStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 14,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatAchievementDate(achievement.unlockedAt),
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: achievement.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.check_circle, color: achievement.color, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSettings() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.surfaceVariant.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.06),
            offset: const Offset(0, 4),
            blurRadius: 20,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.info, AppColors.infoLight],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.settings, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Account Settings',
                style: AppStyles.headingSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildSettingItem(
            icon: Icons.person_outline,
            title: 'Personal Information',
            subtitle: 'Name, email, bio',
            onTap: _editPersonalInfo,
            color: AppColors.primary,
          ),

          _buildSettingItem(
            icon: Icons.security_outlined,
            title: 'Privacy & Security',
            subtitle: 'Password, privacy settings',
            onTap: _privacySettings,
            color: AppColors.secondary,
          ),

          _buildSettingItem(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Push, email, in-app',
            onTap: _notificationSettings,
            color: AppColors.accent,
          ),

          _buildSettingItem(
            icon: Icons.block_outlined,
            title: 'Blocked Users',
            subtitle: 'Manage blocked friends',
            onTap: _blockedUsers,
            showDivider: false,
            color: AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildAppSettings() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.surfaceVariant.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.06),
            offset: const Offset(0, 4),
            blurRadius: 20,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.warning, AppColors.warningLight],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.tune, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'App Settings',
                style: AppStyles.headingSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildSettingItem(
            icon: Icons.palette_outlined,
            title: 'Theme',
            subtitle: 'Light, dark, system',
            onTap: _themeSettings,
            color: AppColors.indigo,
          ),

          _buildSettingItem(
            icon: Icons.language_outlined,
            title: 'Language',
            subtitle: _currentLanguage == 'en' ? 'English' : 'العربية',
            onTap: _languageSettings,
            color: AppColors.teal,
          ),

          _buildSettingItem(
            icon: Icons.storage_outlined,
            title: 'Storage',
            subtitle: 'Cache, offline data',
            onTap: _storageSettings,
            showDivider: false,
            color: AppColors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.surfaceVariant.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.06),
            offset: const Offset(0, 4),
            blurRadius: 20,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.pink, AppColors.pinkLight],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.support_agent, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Support & About',
                style: AppStyles.headingSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildSettingItem(
            icon: Icons.help_outline,
            title: 'Help & FAQ',
            subtitle: 'Get answers to common questions',
            onTap: _helpAndFAQ,
            color: AppColors.info,
          ),

          _buildSettingItem(
            icon: Icons.feedback_outlined,
            title: 'Send Feedback',
            subtitle: 'Report bugs or suggest features',
            onTap: _sendFeedback,
            color: AppColors.success,
          ),

          _buildSettingItem(
            icon: Icons.star_outline,
            title: 'Rate WishListy',
            subtitle: 'Rate us on the app store',
            onTap: _rateApp,
            color: AppColors.warning,
          ),

          _buildSettingItem(
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'Version 1.0.0',
            onTap: _aboutApp,
            showDivider: false,
            color: AppColors.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showDivider = true,
    Color? color,
  }) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.transparent,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 8,
            ),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    (color ?? AppColors.primary).withOpacity(0.1),
                    (color ?? AppColors.primary).withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (color ?? AppColors.primary).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: color ?? AppColors.primary, size: 22),
            ),
            title: Text(
              title,
              style: AppStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: AppStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textTertiary,
              ),
            ),
            onTap: onTap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        if (showDivider)
          Container(
            margin: const EdgeInsets.only(left: 60),
            child: Divider(
              color: AppColors.textTertiary.withOpacity(0.15),
              height: 1,
              thickness: 0.5,
            ),
          ),
      ],
    );
  }

  // Helper Methods
  String _formatJoinDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatAchievementDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  // Action Handlers
  void _handleMenuAction(String action) {
    switch (action) {
      case 'share_profile':
        _shareProfile();
        break;
      case 'export_data':
        _exportData();
        break;
      case 'logout':
        _confirmLogout();
        break;
    }
  }

  void _editProfile() {
    // Navigate to edit profile screen
    Navigator.pushNamed(
      context,
      AppRoutes.profile,
      arguments: {'userProfile': _userProfile},
    );
  }

  void _editProfilePicture() {
    // Show profile picture options
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Change Profile Picture', style: AppStyles.headingSmall),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Camera',
                    onPressed: () {
                      Navigator.pop(context);
                      // Take photo with camera
                    },
                    variant: ButtonVariant.outline,
                    icon: Icons.camera_alt_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Gallery',
                    onPressed: () {
                      Navigator.pop(context);
                      // Pick from gallery
                    },
                    variant: ButtonVariant.outline,
                    icon: Icons.photo_library_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showQRCode() {
    // Show QR code for profile
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('My QR Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.qr_code,
                size: 100,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Share this QR code with friends to connect instantly!',
              style: AppStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          CustomButton(
            text: 'Share',
            onPressed: () {
              Navigator.pop(context);
              // Share QR code
            },
            variant: ButtonVariant.primary,
            size: ButtonSize.small,
            fullWidth: false,
          ),
        ],
      ),
    );
  }

  void _backupData() {
    // Backup data functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Data backup initiated...'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _viewDetailedStats() {
    // View detailed statistics
  }

  void _viewAllAchievements() {
    // View all achievements
  }

  void _editPersonalInfo() {
    Navigator.pushNamed(
      context,
      AppRoutes.personalInformation,
      arguments: {
        'name': _userProfile.name,
        'email': _userProfile.email,
        'bio': _userProfile.bio,
      },
    );
  }

  void _privacySettings() {
    Navigator.pushNamed(
      context,
      AppRoutes.privacySecurity,
      arguments: {
        'showOnlineStatus': _userProfile.privacy.showOnlineStatus,
        'allowFriendRequests': _userProfile.privacy.allowFriendRequests,
        'showWishlistActivity': _userProfile.privacy.showWishlistActivity,
        'showProfileToPublic':
            _userProfile.privacy.profileVisibility == ProfileVisibility.public,
      },
    );
  }

  void _notificationSettings() {
    Navigator.pushNamed(
      context,
      AppRoutes.notifications,
      arguments: {
        'pushNotifications': true,
        'emailNotifications': true,
        'inAppNotifications': true,
        'friendRequests': true,
        'wishlistUpdates': true,
        'eventInvitations': true,
        'giftNotifications': true,
      },
    );
  }

  void _blockedUsers() {
    Navigator.pushNamed(
      context,
      AppRoutes.blockedUsers,
      arguments: [
        // Mock blocked users data
        {
          'name': 'John Doe',
          'email': 'john@example.com',
          'blockedDate': DateTime.now().subtract(Duration(days: 7)),
        },
        {
          'name': 'Jane Smith',
          'email': 'jane@example.com',
          'blockedDate': DateTime.now().subtract(Duration(days: 3)),
        },
      ],
    );
  }

  void _themeSettings() {
    // Theme settings
  }

  void _languageSettings() {
    // Show language selection dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.language, color: AppColors.primary),
              title: Text('English'),
              subtitle: Text('English'),
              trailing: _currentLanguage == 'en'
                  ? Icon(Icons.check_circle, color: AppColors.success)
                  : null,
              onTap: () {
                Navigator.pop(context);
                _changeLanguage('en');
              },
            ),
            ListTile(
              leading: Icon(Icons.language, color: AppColors.secondary),
              title: Text('العربية'),
              subtitle: Text('Arabic'),
              trailing: _currentLanguage == 'ar'
                  ? Icon(Icons.check_circle, color: AppColors.success)
                  : null,
              onTap: () {
                Navigator.pop(context);
                _changeLanguage('ar');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _changeLanguage(String languageCode) async {
    final localization = Provider.of<LocalizationService>(
      context,
      listen: false,
    );
    await localization.changeLanguage(languageCode);
    setState(() {
      _currentLanguage = localization.currentLanguage;
    });
  }

  void _storageSettings() {
    // Storage settings
  }

  void _helpAndFAQ() {
    // Help and FAQ
  }

  void _sendFeedback() {
    // Send feedback
  }

  void _rateApp() {
    // Rate app
  }

  void _aboutApp() {
    // About app
  }

  void _shareProfile() {
    // Share profile
  }

  void _exportData() {
    // Export data
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: Text('Logout', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    // Clear token and local storage
    await AuthRepository().logout();
    // Navigate to welcome screen
    AppRoutes.pushNamedAndRemoveUntil(context, AppRoutes.welcome);
  }

  Future<void> _refreshProfile() async {
    // Refresh profile data
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      // Update profile data
    });
  }
}

// Mock data models
class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? bio;
  final String? profilePicture;
  final DateTime joinDate;
  final int friendsCount;
  final int wishlistsCount;
  final int eventsCreated;
  final int giftsReceived;
  final int giftsGiven;
  final PrivacySettings privacy;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.bio,
    this.profilePicture,
    required this.joinDate,
    required this.friendsCount,
    required this.wishlistsCount,
    required this.eventsCreated,
    required this.giftsReceived,
    required this.giftsGiven,
    required this.privacy,
  });
}

class PrivacySettings {
  final ProfileVisibility profileVisibility;
  final bool showOnlineStatus;
  final bool allowFriendRequests;
  final bool showWishlistActivity;

  PrivacySettings({
    required this.profileVisibility,
    required this.showOnlineStatus,
    required this.allowFriendRequests,
    required this.showWishlistActivity,
  });
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final DateTime unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.unlockedAt,
  });
}

enum ProfileVisibility { public, friends, private }
