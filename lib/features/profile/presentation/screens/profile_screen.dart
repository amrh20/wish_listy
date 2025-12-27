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
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/features/profile/presentation/screens/main_navigation.dart';

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

  // User profile data
  UserProfile? _userProfile;
  bool _isLoading = false;
  bool _hasLoaded = false; // Flag to track if we've loaded data
  String? _errorMessage;
  String _currentLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    _loadCurrentLanguage();
    // Don't load profile here - wait until screen is visible
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load profile only when screen becomes visible and hasn't loaded yet
    if (!_hasLoaded && !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadUserProfile();
        }
      });
    }
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
          backgroundColor: Colors.transparent,
          body: Stack(
              children: [
              // Full-height colorful pattern background (bottom layer)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 350, // Fixed height to cover header area
                child: Container(
                  margin: const EdgeInsets.only(left: 8, right: 8, top: 12),
                  decoration: BoxDecoration(
                    color: AppColors.cardPurple,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(36),
                      topRight: Radius.circular(36),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(36),
                      topRight: Radius.circular(36),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _buildDecorativeElements(),
                      ],
                    ),
                  ),
                ),
              ),
              // Main content column
              Column(
                children: [
                  // Profile Header with Avatar and Name
                  _buildProfileHeader(localization),

                // Profile Content in rounded container
                Expanded(
                    child: Transform(
                      transform: Matrix4.translationValues(0.0, -20.0, 0.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(32),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 18,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                    child: RefreshIndicator(
                      onRefresh: _refreshProfile,
                      color: AppColors.primary,
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _errorMessage != null
                              ? _buildErrorState()
                              : SingleChildScrollView(
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
                                                    const SizedBox(height: 16),
                                                    // Logout (last item)
                                                    _buildLogoutSection(),
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
                ),
              ],
            ),
            ],
          ),
        );
      },
    );
  }

  /// Build profile header with avatar circle and name
  Widget _buildProfileHeader(LocalizationService localization) {
    final userName = _userProfile?.name ?? '';
    final userInitial = userName.isNotEmpty
        ? userName[0].toUpperCase()
        : '?';
    final profileImage = _userProfile?.profilePicture;

    return Container(
      margin: const EdgeInsets.only(left: 8, right: 8, top: 12, bottom: 0),
      decoration: BoxDecoration(
        color: Colors.transparent, // Transparent to show background pattern
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(36),
          topRight: Radius.circular(36),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // White Circle with Initial
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  backgroundImage: profileImage != null && profileImage.isNotEmpty
                      ? NetworkImage(profileImage)
                      : null,
                  child: profileImage == null || profileImage.isEmpty
                      ? Text(
                          userInitial,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              // Name below circle
              Text(
                userName.isNotEmpty ? userName : 'User',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build decorative background elements (same as unified header)
  Widget _buildDecorativeElements() {
    return Positioned.fill(
      child: Stack(
        clipBehavior: Clip.none,
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

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load profile',
              style: AppStyles.headingMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadUserProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    if (_userProfile == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.textTertiary.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: IntrinsicHeight(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Friends Stat
          Expanded(
            child: GestureDetector(
              onTap: () {
                // Navigate to Friends tab while keeping the main navigation bar
                MainNavigation.switchToTab(context, 3);
              },
              child: _buildStatItem(
                icon: Icons.people_outline,
                value: '${_userProfile!.friendsCount}',
                label: 'Friends',
                iconColor: AppColors.secondary,
                iconBackgroundColor: AppColors.secondary.withOpacity(0.1),
              ),
            ),
          ),
          // Divider
            Container(height: 60, width: 1, color: Colors.grey.withOpacity(0.2)),
          // Wishlists Stat
          Expanded(
            child: GestureDetector(
                onTap: () {
                  // Navigate to Wishlists tab while keeping the main navigation bar
                  MainNavigation.switchToTab(context, 1);
                },
              child: _buildStatItem(
                icon: Icons.favorite_outline,
                value: '${_userProfile!.wishlistsCount}',
                label: 'Wishlists',
                iconColor: AppColors.primary,
                iconBackgroundColor: AppColors.primary.withOpacity(0.1),
              ),
            ),
          ),
          // Divider
            Container(height: 60, width: 1, color: Colors.grey.withOpacity(0.2)),
          // Events Stat
          Expanded(
            child: GestureDetector(
                onTap: () {
                  // Navigate to Events tab while keeping the main navigation bar
                  MainNavigation.switchToTab(context, 2);
                },
              child: _buildStatItem(
                icon: Icons.event_outlined,
                value: '${_userProfile!.eventsCreated}',
                label: 'Events',
                iconColor: AppColors.accent,
                iconBackgroundColor: AppColors.accent.withOpacity(0.1),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color iconColor,
    required Color iconBackgroundColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Icon with CircleAvatar
        CircleAvatar(
          radius: 18,
          backgroundColor: iconBackgroundColor,
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(height: 10),
        // Number (Large, Bold)
        Text(
          value,
          style: AppStyles.headingLarge.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 26,
            color: AppColors.textPrimary,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 3),
        // Label (Small, Grey)
        Text(
          label,
          style: AppStyles.bodySmall.copyWith(
            color: Colors.grey[600],
            fontSize: 11,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildAccountSettings() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.textTertiary.withOpacity(0.1),
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
                    colors: [AppColors.info, AppColors.info.withOpacity(0.8)],
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
        ],
      ),
    );
  }

  Widget _buildAppSettings() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.textTertiary.withOpacity(0.1),
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
                    colors: [
                      AppColors.warning,
                      AppColors.warning.withOpacity(0.8),
                    ],
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
            icon: Icons.language_outlined,
            title: 'Language',
            subtitle: _currentLanguage == 'en' ? 'English' : 'العربية',
            onTap: _languageSettings,
            showDivider: false,
            color: AppColors.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.textTertiary.withOpacity(0.1),
            offset: const Offset(0, 4),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: _buildLogoutItem(),
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

  void _editPersonalInfo() {
    if (_userProfile == null) return;
    
    Navigator.pushNamed(
      context,
      AppRoutes.personalInformation,
      arguments: {
        'name': _userProfile!.name,
        'email': _userProfile!.email,
        'bio': _userProfile!.bio,
      },
    );
  }

  void _privacySettings() {
    if (_userProfile == null) return;
    
    Navigator.pushNamed(
      context,
      AppRoutes.privacySecurity,
      arguments: {
        'showOnlineStatus': _userProfile!.privacy.showOnlineStatus,
        'allowFriendRequests': _userProfile!.privacy.allowFriendRequests,
        'showWishlistActivity': _userProfile!.privacy.showWishlistActivity,
        'showProfileToPublic':
            _userProfile!.privacy.profileVisibility == ProfileVisibility.public,
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

  Future<void> _loadUserProfile({bool forceRefresh = false}) async {
    // Don't reload if already loaded unless force refresh
    if (_hasLoaded && !forceRefresh) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepository = Provider.of<AuthRepository>(
        context,
        listen: false,
      );

      final response = await authRepository.getCurrentUserProfile();

      if (response['success'] == true) {
        final data = response['data'] ?? response;
        
        // Parse the response data
        if (mounted) {
          setState(() {
            _userProfile = UserProfile(
              id: data['_id'] ?? data['id'] ?? '',
              name: data['fullName'] ?? data['name'] ?? '',
              email: data['email'] ?? '',
              bio: data['bio'],
              profilePicture: data['profileImage'] ?? data['profilePicture'],
              joinDate: data['createdAt'] != null
                  ? DateTime.parse(data['createdAt'])
                  : DateTime.now(),
              friendsCount: data['friendsCount'] ?? 0,
              wishlistsCount: data['wishlistCount'] ?? data['wishlistsCount'] ?? 0,
              eventsCreated: data['eventsCount'] ?? data['eventsCreated'] ?? 0,
              giftsReceived: data['giftsReceived'] ?? 0,
              giftsGiven: data['giftsGiven'] ?? 0,
              privacy: PrivacySettings(
                profileVisibility: _parseProfileVisibility(
                  data['privacySettings']?['profileVisibility'] ??
                      data['privacySettings']?['publicWishlistVisibility'],
                ),
                showOnlineStatus:
                    data['privacySettings']?['showOnlineStatus'] ?? true,
                allowFriendRequests:
                    data['privacySettings']?['allowFriendRequests'] ?? true,
                showWishlistActivity:
                    data['privacySettings']?['showWishlistActivity'] ?? true,
              ),
            );
            _isLoading = false;
            _hasLoaded = true;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = response['message'] ?? 'Failed to load profile';
            _isLoading = false;
            _hasLoaded = true; // Mark as loaded even on error to prevent retry loops
          });
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
          _hasLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load profile. Please try again.';
          _isLoading = false;
          _hasLoaded = true;
        });
      }

    }
  }

  ProfileVisibility _parseProfileVisibility(dynamic value) {
    if (value == null) return ProfileVisibility.friends;
    
    final str = value.toString().toLowerCase();
    if (str == 'public') return ProfileVisibility.public;
    if (str == 'private') return ProfileVisibility.private;
    return ProfileVisibility.friends;
  }

  Future<void> _refreshProfile() async {
    await _loadUserProfile(forceRefresh: true);
  }

  // Public method to refresh profile from outside (e.g., from MainNavigation)
  void refreshProfile() {
    _loadUserProfile(forceRefresh: true);
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
