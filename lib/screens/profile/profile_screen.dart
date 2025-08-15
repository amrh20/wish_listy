





import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../utils/app_routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/animated_background.dart';

class ProfileScreen extends StatefulWidget {
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
    bio: 'Love tech gadgets and outdoor adventures. Always looking for the next great read!',
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
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));
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
    return Scaffold(
      body: Stack(
        children: [
          // Animated Background
          AnimatedBackground(
            colors: [
              AppColors.background,
              AppColors.primary.withOpacity(0.02),
              AppColors.secondary.withOpacity(0.01),
            ],
          ),
          
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Stats Cards
                                _buildStatsSection(),
                                const SizedBox(height: 24),
                                
                                // Quick Actions
                                _buildQuickActions(),
                                const SizedBox(height: 24),
                                
                                // Achievements
                                _buildAchievements(),
                                const SizedBox(height: 24),
                                
                                // Account Settings
                                _buildAccountSettings(),
                                const SizedBox(height: 24),
                                
                                // App Settings
                                _buildAppSettings(),
                                const SizedBox(height: 24),
                                
                                // Support & About
                                _buildSupportSection(),
                                const SizedBox(height: 100), // Bottom padding
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
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary,
                AppColors.secondary,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  
                  // Profile Picture
                  Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              offset: const Offset(0, 4),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _userProfile.name[0].toUpperCase(),
                            style: AppStyles.headingLarge.copyWith(
                              color: AppColors.primary,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      
                      // Edit Button
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _editProfilePicture,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Name
                  Text(
                    _userProfile.name,
                    style: AppStyles.headingMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Email
                  Text(
                    _userProfile.email,
                    style: AppStyles.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Member Since
                  Text(
                    'Member since ${_formatJoinDate(_userProfile.joinDate)}',
                    style: AppStyles.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: _editProfile,
          icon: Icon(
            Icons.edit_outlined,
            color: Colors.white,
          ),
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          icon: Icon(
            Icons.more_vert,
            color: Colors.white,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'share_profile',
              child: Row(
                children: [
                  Icon(Icons.share_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('Share Profile'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'export_data',
              child: Row(
                children: [
                  Icon(Icons.download_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('Export Data'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout_outlined, size: 20, color: AppColors.error),
                  SizedBox(width: 12),
                  Text('Logout', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Row(
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
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Wishlists',
            value: '${_userProfile.wishlistsCount}',
            icon: Icons.favorite_outline,
            color: AppColors.primary,
            onTap: () => AppRoutes.pushNamed(context, AppRoutes.myWishlists),
          ),
        ),
        const SizedBox(width: 12),
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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: AppStyles.headingSmall.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: AppStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: AppStyles.headingSmall,
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.edit_outlined,
                  label: 'Edit Profile',
                  onTap: _editProfile,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.qr_code_rounded,
                  label: 'QR Code',
                  onTap: _showQRCode,
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
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.analytics_outlined,
                  label: 'View Stats',
                  onTap: _viewDetailedStats,
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
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Achievements',
                style: AppStyles.headingSmall,
              ),
              TextButton(
                onPressed: _viewAllAchievements,
                child: Text(
                  'View All',
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: achievement.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: achievement.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: achievement.color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              achievement.icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: AppStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  achievement.description,
                  style: AppStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: achievement.color,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Settings',
            style: AppStyles.headingSmall,
          ),
          const SizedBox(height: 16),
          
          _buildSettingItem(
            icon: Icons.person_outline,
            title: 'Personal Information',
            subtitle: 'Name, email, bio',
            onTap: _editPersonalInfo,
          ),
          
          _buildSettingItem(
            icon: Icons.security_outlined,
            title: 'Privacy & Security',
            subtitle: 'Password, privacy settings',
            onTap: _privacySettings,
          ),
          
          _buildSettingItem(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Push, email, in-app',
            onTap: _notificationSettings,
          ),
          
          _buildSettingItem(
            icon: Icons.block_outlined,
            title: 'Blocked Users',
            subtitle: 'Manage blocked friends',
            onTap: _blockedUsers,
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildAppSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'App Settings',
            style: AppStyles.headingSmall,
          ),
          const SizedBox(height: 16),
          
          _buildSettingItem(
            icon: Icons.palette_outlined,
            title: 'Theme',
            subtitle: 'Light, dark, system',
            onTap: _themeSettings,
          ),
          
          _buildSettingItem(
            icon: Icons.language_outlined,
            title: 'Language',
            subtitle: 'English',
            onTap: _languageSettings,
          ),
          
          _buildSettingItem(
            icon: Icons.storage_outlined,
            title: 'Storage',
            subtitle: 'Cache, offline data',
            onTap: _storageSettings,
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Support & About',
            style: AppStyles.headingSmall,
          ),
          const SizedBox(height: 16),
          
          _buildSettingItem(
            icon: Icons.help_outline,
            title: 'Help & FAQ',
            subtitle: 'Get answers to common questions',
            onTap: _helpAndFAQ,
          ),
          
          _buildSettingItem(
            icon: Icons.feedback_outlined,
            title: 'Send Feedback',
            subtitle: 'Report bugs or suggest features',
            onTap: _sendFeedback,
          ),
          
          _buildSettingItem(
            icon: Icons.star_outline,
            title: 'Rate WishLink',
            subtitle: 'Rate us on the app store',
            onTap: _rateApp,
          ),
          
          _buildSettingItem(
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'Version 1.0.0',
            onTap: _aboutApp,
            showDivider: false,
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
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          title: Text(
            title,
            style: AppStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: AppStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: AppColors.textTertiary,
          ),
          onTap: onTap,
        ),
        if (showDivider)
          Divider(
            color: AppColors.textTertiary.withOpacity(0.2),
            height: 1,
          ),
      ],
    );
  }

  // Helper Methods
  String _formatJoinDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
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
            Text(
              'Change Profile Picture',
              style: AppStyles.headingSmall,
            ),
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
    // Edit personal information
  }

  void _privacySettings() {
    // Privacy settings
  }

  void _notificationSettings() {
    // Notification settings
  }

  void _blockedUsers() {
    // Blocked users management
  }

  void _themeSettings() {
    // Theme settings
  }

  void _languageSettings() {
    // Language settings
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

  void _logout() {
    // Logout functionality
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

enum ProfileVisibility {
  public,
  friends,
  private,
}