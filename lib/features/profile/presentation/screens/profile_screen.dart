import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/core/utils/app_constants.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/features/profile/presentation/screens/main_navigation.dart';
import 'package:wish_listy/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:wish_listy/features/profile/presentation/cubit/profile_state.dart';
import 'package:wish_listy/features/profile/presentation/widgets/profile/profile_header_widget.dart';
import 'package:wish_listy/features/profile/presentation/widgets/profile/profile_stats_widget.dart';
import 'package:wish_listy/features/profile/presentation/widgets/profile/profile_setting_section_widget.dart';
import 'package:wish_listy/features/profile/presentation/widgets/profile/profile_logout_section_widget.dart';
import 'package:wish_listy/features/profile/presentation/widgets/profile/profile_decorative_background_widget.dart';
import 'package:wish_listy/features/profile/presentation/widgets/profile/profile_interests_section_widget.dart';
import 'package:wish_listy/features/profile/presentation/widgets/profile/profile_error_state_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  UserProfile? _userProfile;
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _errorMessage;
  String _currentLanguage = 'en';

  @override
  void initState() {
    super.initState();
    debugPrint('ProfileScreen: initState called (_hasLoaded: $_hasLoaded)');
    _initializeAnimations();
    _startAnimations();
    _loadCurrentLanguage();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasLoaded && !_isLoading) {
        debugPrint('ProfileScreen: Loading profile from initState');
        _loadUserProfile();
      } else {
        debugPrint('ProfileScreen: Skipping load from initState');
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    debugPrint('ProfileScreen: didChangeDependencies called - NO ACTION TAKEN');
  }

  void _loadCurrentLanguage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final localization = Provider.of<LocalizationService>(context, listen: false);
      setState(() {
        _currentLanguage = localization.currentLanguage;
      });
    });
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
        curve: const Interval(0.1, 0.9, curve: Curves.easeOutCubic),
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
    super.build(context); // Keep alive
    return BlocProvider(
      create: (context) => ProfileCubit(currentProfileImageUrl: _userProfile?.profilePicture),
      child: BlocListener<ProfileCubit, ProfileImageState>(
        listener: _handleProfileImageStateChanges,
        child: Consumer<LocalizationService>(
          builder: (context, localization, child) {
            return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
              children: [
                  // Background
                  _buildBackground(),
                  // Main content
                  _buildMainContent(localization),
                  // Popup Menu Button (Three Dots)
                  _buildPopupMenuButton(localization),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned(
                top: 0,
                left: 0,
                right: 0,
      height: 350,
                child: Container(
                  margin: const EdgeInsets.only(left: 8, right: 8, top: 12),
        decoration: const BoxDecoration(
                    color: AppColors.cardPurple,
          borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(36),
                      topRight: Radius.circular(36),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(36),
                      topRight: Radius.circular(36),
                    ),
          child: const Stack(
                      clipBehavior: Clip.none,
            children: [ProfileDecorativeBackgroundWidget()],
                    ),
                  ),
                ),
    );
  }

  Widget _buildMainContent(LocalizationService localization) {
    return Column(
      children: [
        // Profile Header
        ProfileHeaderWidget(
          userName: _userProfile?.name ?? '',
          profileImage: _userProfile?.profilePicture,
          userBio: _userProfile?.bio,
          userHandle: _userProfile?.getDisplayHandle(),
          onEditPersonalInfo: _editPersonalInfo,
          onShowFullScreenImage: _showFullScreenImageView,
        ),
        // Content
                Expanded(
                    child: Transform(
                      transform: Matrix4.translationValues(0.0, -20.0, 0.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
                child: _buildContentBody(localization),
                                ),
                    ),
                  ),
                ),
              ],
    );
  }

  Widget _buildContentBody(LocalizationService localization) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage != null) {
      return ProfileErrorStateWidget(
        errorMessage: _errorMessage!,
        retryButtonText: localization.translate('app.retry'),
        onRetry: () => _loadUserProfile(forceRefresh: true),
      );
    }
    
        return SingleChildScrollView(
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats
                    if (_userProfile != null)
                      ProfileStatsWidget(
                        friendsCount: _userProfile!.friendsCount,
                        wishlistsCount: _userProfile!.wishlistsCount,
                        eventsCount: _userProfile!.eventsCreated,
                        friendsLabel: localization.translate('ui.friends'),
                        wishlistsLabel: localization.translate('ui.wishlists'),
                        eventsLabel: localization.translate('ui.events'),
                        onFriendsTap: () => MainNavigation.switchToTab(context, 3),
                        onWishlistsTap: () => MainNavigation.switchToTab(context, 1),
                        onEventsTap: () => MainNavigation.switchToTab(context, 2),
                    ),
                    const SizedBox(height: 16),
                    // Interests
                    if (_userProfile != null)
                      ProfileInterestsSectionWidget(
                        interests: _userProfile!.interests,
                        emptyStateTitle: localization.translate('profile.helpFriendsChoose'),
                        emptyStateSubtitle: localization.translate('profile.tapToSelectCategories'),
                        interestsTitle: localization.translate('profile.interests'),
                        editButtonText: localization.translate('app.edit'),
                        onEditInterests: _showInterestsSelectionSheet,
                      ),
                    const SizedBox(height: 16),
                    // Account Settings
                    ProfileSettingSectionWidget(
                      title: localization.translate('profile.accountSettings'),
                      sectionIcon: Icons.settings,
                      gradientColors: [AppColors.info, AppColors.info.withOpacity(0.8)],
                      items: [
                        ProfileSettingItem(
            icon: Icons.person_outline,
                          title: localization.translate('profile.personalInformation'),
                          subtitle: localization.translate('profile.nameEmailBio'),
            onTap: _editPersonalInfo,
            color: AppColors.primary,
          ),
                        ProfileSettingItem(
            icon: Icons.lock_outline,
                          title: localization.translate('profile.changePassword'),
                          subtitle: localization.translate('profile.changePasswordSubtitle'),
            onTap: _changePassword,
            color: AppColors.secondary,
          ),
                        ProfileSettingItem(
            icon: Icons.notifications_outlined,
                          title: localization.translate('profile.notificationSettings'),
                          subtitle: localization.translate('profile.notificationSettingsSubtitle'),
            onTap: _notificationSettings,
            color: AppColors.accent,
          ),
        ],
      ),
                    const SizedBox(height: 16),
                    // App Settings
                    ProfileSettingSectionWidget(
                      title: localization.translate('profile.appSettings'),
                      sectionIcon: Icons.tune,
                      gradientColors: [AppColors.warning, AppColors.warning.withOpacity(0.8)],
                      items: [
                        ProfileSettingItem(
            icon: Icons.language_outlined,
                          title: localization.translate('profile.language'),
            subtitle: _currentLanguage == 'en' 
                              ? localization.translate('profile.english')
                              : localization.translate('profile.arabic'),
            onTap: _languageSettings,
            color: AppColors.secondary,
                          showDivider: false,
          ),
        ],
      ),
                    const SizedBox(height: 16),
                    // Support & Legal
                    ProfileSettingSectionWidget(
                      title: localization.translate('profile.supportLegal'),
                      sectionIcon: Icons.help_outline,
                      gradientColors: [AppColors.success, AppColors.success.withOpacity(0.8)],
                      items: [
                        ProfileSettingItem(
            icon: Icons.email_outlined,
                          title: localization.translate('profile.contactUs'),
                          subtitle: localization.translate('profile.contactUsSubtitle'),
            onTap: _contactUs,
            color: AppColors.primary,
          ),
                        ProfileSettingItem(
            icon: Icons.shield_outlined,
                          title: localization.translate('profile.privacyPolicy'),
                          subtitle: localization.translate('profile.privacyPolicySubtitle'),
            onTap: _openPrivacyPolicy,
            color: AppColors.secondary,
          ),
                        ProfileSettingItem(
            icon: Icons.description_outlined,
                          title: localization.translate('profile.termsConditions'),
                          subtitle: localization.translate('profile.termsConditionsSubtitle'),
            onTap: _openTermsConditions,
            color: AppColors.accent,
          ),
                        ProfileSettingItem(
            icon: Icons.help_outline,
                          title: localization.translate('profile.faq'),
                          subtitle: localization.translate('profile.faqSubtitle'),
            onTap: _openFAQ,
            color: AppColors.info,
                          showDivider: false,
          ),
        ],
      ),
                    const SizedBox(height: 16),
                    // Logout & Delete
                    ProfileLogoutSectionWidget(
                      logoutText: localization.translate('auth.logout'),
                      logoutSubtitle: localization.translate('profile.signOutOfAccount'),
                      deleteAccountText: localization.translate('profile.deleteAccount'),
                      deleteAccountSubtitle: localization.translate('profile.deleteAccountMessage'),
                      onLogout: () => _confirmLogout(localization),
                      onDeleteAccount: () => _confirmDeleteAccount(localization),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleProfileImageStateChanges(BuildContext context, ProfileImageState state) {
    if (state is ProfileImageUploadSuccess) {
      if (_userProfile != null) {
        setState(() {
          _userProfile = _userProfile!.copyWith(profilePicture: state.imageUrl);
        });
      }
      final authRepository = Provider.of<AuthRepository>(context, listen: false);
      authRepository.updateProfilePicture(state.imageUrl);
      context.read<ProfileCubit>().setCurrentProfileImage(state.imageUrl);
    } else if (state is ProfileImageDeleteSuccess) {
      if (_userProfile != null) {
        setState(() {
          _userProfile = _userProfile!.copyWith(profilePicture: null);
        });
      }
      final authRepository = Provider.of<AuthRepository>(context, listen: false);
      authRepository.updateProfilePicture(null);
      context.read<ProfileCubit>().setCurrentProfileImage(null);
    } else if (state is ProfileImageUploadError || state is ProfileImageDeleteError) {
      final errorMessage = state is ProfileImageUploadError
          ? state.message
          : (state as ProfileImageDeleteError).message;
      
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
          content: Text(errorMessage),
            backgroundColor: AppColors.error,
          ),
        );
    }
  }

  void _showFullScreenImageView(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withOpacity(0.9),
        pageBuilder: (context, animation, secondaryAnimation) {
          return _FullScreenImageView(imageUrl: imageUrl);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  // Build Popup Menu Button
  Widget _buildPopupMenuButton(LocalizationService localization) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      right: 16,
      child: PopupMenuButton<String>(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.more_vert,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: AppColors.surface,
        elevation: 8,
        onSelected: (value) {
          if (value == 'edit') {
            _editPersonalInfo();
          } else if (value == 'share') {
            _shareProfile(localization);
          } else if (value == 'logout') {
            _confirmLogout(localization);
          }
        },
        itemBuilder: (BuildContext context) => [
          PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Text(
                  localization.translate('profile.editProfile') ?? 'Edit Profile',
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontFamily: localization.currentLanguage == 'ar' ? 'Alexandria' : 'Ubuntu',
                  ),
                ),
              ],
            ),
          ),
          // Divider before logout
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            value: 'logout',
            child: Row(
              children: [
                Icon(Icons.logout, color: AppColors.error, size: 20),
                const SizedBox(width: 12),
                Text(
                  localization.translate('auth.logout') ?? 'Logout',
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                    fontFamily: localization.currentLanguage == 'ar' ? 'Alexandria' : 'Ubuntu',
                  ),
                ),
              ],
            ),
          ),
          // TODO: Re-enable share profile when HTTPS deep links are configured
          // PopupMenuItem<String>(
          //   value: 'share',
          //   child: Row(
          //     children: [
          //       Icon(Icons.share_outlined, color: AppColors.primary, size: 20),
          //       const SizedBox(width: 12),
          //       Text(
          //         localization.translate('profile.shareProfile') ?? 'Share Profile',
          //         style: AppStyles.bodyMedium.copyWith(
          //           color: AppColors.textPrimary,
          //           fontFamily: localization.currentLanguage == 'ar' ? 'Alexandria' : 'Ubuntu',
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  // Share Profile Functionality
  Future<void> _shareProfile(LocalizationService localization) async {
    try {
      final userName = _userProfile?.name ?? 'User';
      final profileLink = AppConstants.profileDeepLink;
      
      // Create share text with localization
      final shareText = localization.currentLanguage == 'ar'
          ? 'تحقق من قائمة الأمنيات الخاصة بي على Wish Listy! $profileLink'
          : 'Check out my wish list on Wish Listy! $profileLink';
      
      await Share.share(
        shareText,
        subject: localization.currentLanguage == 'ar'
            ? 'مشاركة الملف الشخصي - $userName'
            : 'Share Profile - $userName',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localization.translate('dialogs.errorSharing') ?? 'Error sharing profile. Please try again.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // Action methods for settings
  Future<void> _editPersonalInfo() async {
    await Navigator.pushNamed(context, AppRoutes.editProfile);
    _loadUserProfile(forceRefresh: true);
  }

  void _changePassword() {
    Navigator.pushNamed(context, AppRoutes.changePassword);
  }

  void _notificationSettings() {
    // Navigate to notifications screen instead (no separate notification settings screen)
    Navigator.pushNamed(context, AppRoutes.notifications);
  }

  void _languageSettings() {
    _showLanguageSelectionBottomSheet();
  }

  void _contactUs() {
    Navigator.pushNamed(context, AppRoutes.contactUs);
  }

  void _openPrivacyPolicy() {
    Navigator.pushNamed(
      context,
      AppRoutes.legalInfo,
      arguments: {'type': 'privacy'},
    );
  }

  void _openTermsConditions() {
    Navigator.pushNamed(
      context,
      AppRoutes.legalInfo,
      arguments: {'type': 'terms'},
    );
  }

  void _openFAQ() {
    Navigator.pushNamed(context, AppRoutes.faq);
  }

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

  void _confirmDeleteAccount(LocalizationService localization) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          localization.translate('profile.confirmDeleteAccount'),
          style: AppStyles.headingSmall.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          localization.translate('profile.deleteAccountMessage'),
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
              _deleteAccount(localization);
            },
            child: Text(
              localization.translate('profile.deleteAccount'),
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
            content: Text('${Provider.of<LocalizationService>(context, listen: false).translate('dialogs.errorLoggingOut')}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _deleteAccount(LocalizationService localization) async {
    try {
      final authRepository = Provider.of<AuthRepository>(
        context,
        listen: false,
      );
      await authRepository.deleteAccount();

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    localization.translate('profile.accountDeleted'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        // Navigate to Welcome screen and clear navigation stack
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.welcome,
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localization.translate('dialogs.errorDeletingAccount')}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showLanguageSelectionBottomSheet() {
    // Show language selection dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          Provider.of<LocalizationService>(context, listen: false).translate('profile.selectLanguage'),
          style: AppStyles.headingSmall.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              leading: Radio<String>(
                value: 'en',
                groupValue: Provider.of<LocalizationService>(context, listen: false).currentLanguage,
                onChanged: (value) {
                  Navigator.pop(context);
                  _changeLanguage('en');
                },
              ),
              onTap: () {
                Navigator.pop(context);
                _changeLanguage('en');
              },
            ),
            ListTile(
              title: const Text('العربية'),
              leading: Radio<String>(
                value: 'ar',
                groupValue: Provider.of<LocalizationService>(context, listen: false).currentLanguage,
                onChanged: (value) {
                  Navigator.pop(context);
                  _changeLanguage('ar');
                },
              ),
              onTap: () {
                Navigator.pop(context);
                _changeLanguage('ar');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _changeLanguage(String languageCode) async {
    // Implementation for changing language
    final localizationService = Provider.of<LocalizationService>(context, listen: false);
    await localizationService.changeLanguage(languageCode);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // All the business logic methods
  Future<void> _loadUserProfile({bool forceRefresh = false}) async {
    // Don't reload if already loaded unless force refresh
    if (_hasLoaded && !forceRefresh) {
      debugPrint('ProfileScreen: Skipping reload - already loaded (forceRefresh: $forceRefresh)');
      return;
    }

    debugPrint('ProfileScreen: Loading profile (forceRefresh: $forceRefresh, _hasLoaded: $_hasLoaded)');
    
    // Smart Loading: Only show loading skeleton if profile data doesn't exist yet
    // If data exists, refresh in background without showing loading skeleton
    final hasExistingData = _userProfile != null;
    if (!hasExistingData || forceRefresh) {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    } else {
      debugPrint('🔄 ProfileScreen: Background refresh (no loading skeleton)');
      // Still clear error message
      if (_errorMessage != null) {
        setState(() {
          _errorMessage = null;
        });
      }
    }

    try {
      final authRepository = Provider.of<AuthRepository>(
        context,
        listen: false,
      );

      final response = await authRepository.getCurrentUserProfile();

      if (response['success'] == true) {
        final data = response['data'] ?? response;
        
        // Parse the response data with error handling
        if (mounted) {
          try {
            // Parse interests from API response
            List<String> interests = [];
            if (data['interests'] != null) {
              if (data['interests'] is List) {
                interests = List<String>.from(data['interests']);
              } else if (data['interests'] is String) {
                // Handle case where interests might be a comma-separated string
                interests = (data['interests'] as String)
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
              }
            }
            
            final profilePictureUrl = data['profileImage'] ?? data['profilePicture'];
            
            // Parse privacy settings safely
            final privacySettingsData = data['privacySettings'];
            final profileVisibility = _parseProfileVisibility(
              privacySettingsData?['profileVisibility'] ??
                  privacySettingsData?['publicWishlistVisibility'],
            );
            
            // Parse join date safely
            DateTime joinDate;
            try {
              joinDate = data['createdAt'] != null
                  ? DateTime.parse(data['createdAt'])
                  : DateTime.now();
            } catch (e) {
              debugPrint('Error parsing createdAt: $e');
              joinDate = DateTime.now();
            }
            
            setState(() {
              _userProfile = UserProfile(
                id: data['_id']?.toString() ?? data['id']?.toString() ?? '',
                name: data['fullName']?.toString() ?? data['name']?.toString() ?? '',
                email: data['email']?.toString() ?? '',
                bio: data['bio']?.toString(),
                profilePicture: profilePictureUrl?.toString(),
                handle: data['handle']?.toString(),
                joinDate: joinDate,
                friendsCount: (data['friendsCount'] as num?)?.toInt() ?? 0,
                wishlistsCount: (data['wishlistCount'] as num?)?.toInt() ??
                    (data['wishlistsCount'] as num?)?.toInt() ?? 0,
                eventsCreated: (data['eventsCount'] as num?)?.toInt() ??
                    (data['eventsCreated'] as num?)?.toInt() ?? 0,
                giftsReceived: (data['giftsReceived'] as num?)?.toInt() ?? 0,
                giftsGiven: (data['giftsGiven'] as num?)?.toInt() ?? 0,
                privacy: PrivacySettings(
                  profileVisibility: profileVisibility,
                  showOnlineStatus:
                      privacySettingsData?['showOnlineStatus'] as bool? ?? true,
                  allowFriendRequests:
                      privacySettingsData?['allowFriendRequests'] as bool? ?? true,
                  showWishlistActivity:
                      privacySettingsData?['showWishlistActivity'] as bool? ?? true,
                ),
                interests: interests,
              );
              
              _isLoading = false;
              _hasLoaded = true;
              _errorMessage = null;
            });
            
            // Update global AuthRepository profile picture for sync across app
            authRepository.updateProfilePicture(profilePictureUrl?.toString());
            
            // Update ProfileCubit with current profile image (if available)
            // Use try-catch to handle cases where ProfileCubit is not available yet
            // Also check if context is still mounted before accessing BlocProvider
            if (mounted) {
              try {
                final cubit = context.read<ProfileCubit>();
                cubit.setCurrentProfileImage(profilePictureUrl?.toString());
              } catch (e) {
                // ProfileCubit not available yet - will be set when BlocProvider is created
                // This is normal if _loadUserProfile is called before build() completes
                debugPrint('ProfileCubit not available in _loadUserProfile (this is normal): $e');
              }
            }
          } catch (parseError) {
            // Handle parsing errors specifically
            debugPrint('Error parsing profile data: $parseError');
            if (mounted) {
              setState(() {
                _errorMessage = 'Failed to parse profile data: $parseError';
                _isLoading = false;
                _hasLoaded = true;
              });
            }
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = response['message']?.toString() ?? 'Failed to load profile';
            _isLoading = false;
            _hasLoaded = true; // Mark as loaded even on error to prevent retry loops
          });
        }
      }
    } on ApiException catch (e) {
      debugPrint('ApiException in _loadUserProfile: ${e.message}');
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
          _hasLoaded = true;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Unexpected error in _loadUserProfile: $e');
      debugPrint('Stack trace: $stackTrace');
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

  /// Update user interests
  Future<void> updateInterests(List<String> selectedInterests) async {
    try {
      final apiService = ApiService();
      
      // Call API: PUT /api/users/interests
      final response = await apiService.put(
        '/users/interests',
        data: {'interests': selectedInterests},
      );

      if (response['success'] == true || response['success'] == null) {
        // Update local user profile instantly
        if (mounted && _userProfile != null) {
          setState(() {
            _userProfile = _userProfile!.copyWith(interests: selectedInterests);
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(Provider.of<LocalizationService>(context, listen: false).translate('cards.interestsUpdatedSuccessfully')),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to update interests');
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(e.message),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(Provider.of<LocalizationService>(context, listen: false).translate('cards.failedToUpdateInterests')),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  // Public method to refresh profile from outside (e.g., from MainNavigation)
  void refreshProfile() {
    // Only refresh if not already loading and data exists
    // This prevents unnecessary reloads when returning from full-screen viewer
    if (!_isLoading && _hasLoaded) {
      debugPrint('ProfileScreen: refreshProfile called - background refresh...');
      _loadUserProfile(forceRefresh: false); // Background refresh without skeleton
    } else {
      debugPrint('ProfileScreen: refreshProfile called but skipping (_isLoading: $_isLoading, _hasLoaded: $_hasLoaded)');
    }
  }

  /// Build Interests Section Widget
  Widget _buildInterestsSection() {
    if (_userProfile == null) return const SizedBox.shrink();
    
    final interests = _userProfile!.interests;
    final isEmpty = interests.isEmpty;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isEmpty 
            ? Colors.purple.withOpacity(0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isEmpty
            ? Border.all(
                color: Colors.purple.withOpacity(0.2),
                width: 1.5,
                style: BorderStyle.solid,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.textTertiary.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: isEmpty ? _buildEmptyInterestsState() : _buildPopulatedInterestsState(),
    );
  }

  /// Build Empty Interests State (The "Hook")
  Widget _buildEmptyInterestsState() {
    return InkWell(
      onTap: () => _showInterestsSelectionSheet(),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              color: Colors.amber,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${Provider.of<LocalizationService>(context, listen: false).translate('profile.helpFriendsChoose')} 🎁',
                    style: AppStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Provider.of<LocalizationService>(context, listen: false).translate('profile.tapToSelectCategories'),
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  /// Build Populated Interests State (The "Tags")
  Widget _buildPopulatedInterestsState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with Title and Edit button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              Provider.of<LocalizationService>(context, listen: false).translate('profile.interests'),
              style: AppStyles.headingSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showInterestsSelectionSheet(),
              icon: Icon(
                Icons.edit_outlined,
                size: 16,
                color: AppColors.primary,
              ),
              label: Text(
                Provider.of<LocalizationService>(context, listen: false).translate('app.edit'),
                style: AppStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 32),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Wrap widget with Chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _userProfile!.interests.map((interest) {
            return Chip(
              label: Text(
                interest,
                style: AppStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor: Colors.purple.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Show Interests Selection Sheet
  void _showInterestsSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InterestsSelectionSheet(
        currentInterests: _userProfile?.interests ?? [],
        onSave: (selectedInterests) {
          updateInterests(selectedInterests);
        },
      ),
    );
  }
}

// Mock data models
class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? bio;
  final String? profilePicture;
  final String? handle; // Public handle (e.g., "@amr_hamdy_99")
  final DateTime joinDate;
  final int friendsCount;
  final int wishlistsCount;
  final int eventsCreated;
  final int giftsReceived;
  final int giftsGiven;
  final PrivacySettings privacy;
  final List<String> interests;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.bio,
    this.profilePicture,
    this.handle,
    required this.joinDate,
    required this.friendsCount,
    required this.wishlistsCount,
    required this.eventsCreated,
    required this.giftsReceived,
    required this.giftsGiven,
    required this.privacy,
    this.interests = const [],
  });
  
  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? bio,
    String? profilePicture,
    String? handle,
    DateTime? joinDate,
    int? friendsCount,
    int? wishlistsCount,
    int? eventsCreated,
    int? giftsReceived,
    int? giftsGiven,
    PrivacySettings? privacy,
    List<String>? interests,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      profilePicture: profilePicture ?? this.profilePicture,
      handle: handle ?? this.handle,
      joinDate: joinDate ?? this.joinDate,
      friendsCount: friendsCount ?? this.friendsCount,
      wishlistsCount: wishlistsCount ?? this.wishlistsCount,
      eventsCreated: eventsCreated ?? this.eventsCreated,
      giftsReceived: giftsReceived ?? this.giftsReceived,
      giftsGiven: giftsGiven ?? this.giftsGiven,
      privacy: privacy ?? this.privacy,
      interests: interests ?? this.interests,
    );
  }

  /// Get display handle for UI - returns @handle if available, otherwise "User #ID"
  String getDisplayHandle() {
    if (handle != null && handle!.isNotEmpty) {
      return handle!.startsWith('@') ? handle! : '@$handle';
    }
    return 'User #$id';
  }
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

/// Interests Selection Sheet Widget
class InterestsSelectionSheet extends StatefulWidget {
  final List<String> currentInterests;
  final Function(List<String>) onSave;

  const InterestsSelectionSheet({
    super.key,
    required this.currentInterests,
    required this.onSave,
  });

  @override
  State<InterestsSelectionSheet> createState() => _InterestsSelectionSheetState();
}

class _InterestsSelectionSheetState extends State<InterestsSelectionSheet> {
  late Set<String> _selectedInterests;
  bool _isLoading = false;

  // Hardcoded list of categories (matches Backend Enum)
  static const List<String> _allCategories = [
    'Watches',
    'Perfumes',
    'Sneakers',
    'Jewelry',
    'Handbags',
    'Makeup & Skincare',
    'Gadgets',
    'Gaming',
    'Photography',
    'Home Decor',
    'Plants',
    'Coffee & Tea',
    'Books',
    'Fitness Gear',
    'Car Accessories',
    'Music Instruments',
    'Art',
    'DIY & Crafts',
  ];

  @override
  void initState() {
    super.initState();
    _selectedInterests = Set<String>.from(widget.currentInterests);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    Provider.of<LocalizationService>(context, listen: false).translate('profile.selectYourInterests'),
                    style: AppStyles.headingMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            // Categories Grid
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _allCategories.map((category) {
                    final isSelected = _selectedInterests.contains(category);
                    return FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedInterests.add(category);
                          } else {
                            _selectedInterests.remove(category);
                          }
                        });
                      },
                      selectedColor: Colors.purple.withOpacity(0.2),
                      checkmarkColor: AppColors.primary,
                      labelStyle: AppStyles.bodySmall.copyWith(
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: BorderSide(
                        color: isSelected 
                            ? AppColors.primary 
                            : Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            // Save Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () async {
                    setState(() {
                      _isLoading = true;
                    });
                    
                    try {
                      await widget.onSave(_selectedInterests.toList());
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      // Error handling is done in updateInterests method
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          Provider.of<LocalizationService>(context, listen: false).translate('cards.saveChanges'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen image viewer widget with zoom and pan support
class _FullScreenImageView extends StatelessWidget {
  final String imageUrl;

  const _FullScreenImageView({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full-screen image with zoom and pan
          Center(
            child: Hero(
              tag: 'profile_image_$imageUrl',
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Close button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
