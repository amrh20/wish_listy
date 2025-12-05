import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/core/widgets/unified_page_container.dart';
import 'package:wish_listy/core/widgets/unified_page_header.dart';
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
          body: UnifiedPageBackground(
            child: DecorativeBackground(
              showGifts: false, // Less busy for profile
              child: Column(
                children: [
                  // Profile Header with UnifiedPageHeader
                  UnifiedPageHeader(
                    title: localization.translate('navigation.profile'),
                    subtitle: _userProfile.name,
                    showSearch: false,
                    actions: [],
                  ),

                  // Profile Content in rounded container
                  Expanded(
                    child: UnifiedPageContainer(
                      child: RefreshIndicator(
                        onRefresh: _refreshProfile,
                        color: AppColors.primary,
                        child: SingleChildScrollView(
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
                                        // Stats Cards
                                        _buildStatsSection(),
                                        const SizedBox(height: 16),

                                        // Account Settings
                                        _buildAccountSettings(),
                                        const SizedBox(height: 16),
                                        // App Settings
                                        _buildAppSettings(),
                                        const SizedBox(height: 80),
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
                ],
              ),
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

          // Logout button
          _buildLogoutItem(),
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
            showDivider: false,
            color: AppColors.teal,
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutItem() {
    final localization = Provider.of<LocalizationService>(
      context,
      listen: false,
    );

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
                    AppColors.error.withOpacity(0.1),
                    AppColors.error.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.error.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.logout_outlined,
                color: AppColors.error,
                size: 22,
              ),
            ),
            title: Text(
              localization.translate('auth.logout'),
              style: AppStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
            subtitle: Text(
              'Sign out of your account',
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
            onTap: () {
              _confirmLogout(localization);
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
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

  // Action Handlers

  void _confirmLogout(LocalizationService localization) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          localization.translate('auth.logout'),
          style: AppStyles.headingSmall.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          localization.translate('auth.logoutConfirmation'),
          style: AppStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              localization.translate('app.cancel'),
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: Text(
              localization.translate('auth.logout'),
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    try {
      final authRepository = Provider.of<AuthRepository>(
        context,
        listen: false,
      );
      await authRepository.logout();

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
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

enum ProfileVisibility { public, friends, private }
