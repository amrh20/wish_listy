import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/core/utils/app_constants.dart';
import 'package:wish_listy/core/services/deep_link_service.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/core/services/biometric_service.dart';
import 'package:wish_listy/core/services/fcm_service.dart';
import 'package:wish_listy/core/services/notification_preference_service.dart';
import 'package:wish_listy/core/widgets/unified_snackbar.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:wish_listy/features/profile/presentation/screens/main_navigation.dart';
import 'package:wish_listy/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:wish_listy/features/profile/presentation/cubit/profile_state.dart';
import 'package:wish_listy/features/profile/presentation/widgets/profile/profile_decorative_background_widget.dart';
import 'package:wish_listy/features/profile/presentation/widgets/profile/profile_error_state_widget.dart';
import 'package:wish_listy/features/profile/presentation/widgets/profile/profile_header_widget.dart';
import 'package:wish_listy/features/profile/presentation/widgets/profile/profile_stats_widget.dart';
import 'package:wish_listy/features/profile/presentation/widgets/profile/profile_setting_section_widget.dart';
import 'package:wish_listy/core/utils/interest_translation_extension.dart';
import 'package:wish_listy/features/profile/presentation/widgets/profile/profile_interests_section_widget.dart';

String? _parseShippingAddressFromProfile(Map<String, dynamic> data) {
  final obj = data['shippingAddress'];
  if (obj == null || obj is! Map) return null;
  final s = obj['fullAddress']?.toString().trim();
  return (s != null && s.isNotEmpty) ? s : null;
}

bool _parseShippingVisibleFromProfile(Map<String, dynamic> data) {
  final obj = data['shippingAddress'];
  if (obj == null || obj is! Map) return true;
  final v = obj['isVisibleToFriends'];
  if (v == null) return true;
  return v == true || v == 'true';
}

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
  bool _isBiometricEnabled = false;
  bool _isBiometricAvailable = false;
  bool _isPushNotificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    _loadCurrentLanguage();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasLoaded && !_isLoading) {
        _loadUserProfile();
      }
      _loadBiometricState();
      _loadNotificationState();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void _loadCurrentLanguage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final localization = Provider.of<LocalizationService>(context, listen: false);
      setState(() {
        _currentLanguage = localization.currentLanguage;
      });
    });
  }

  Future<void> _loadBiometricState() async {
    if (!mounted) return;
    final biometricService = BiometricService();
    final available = await biometricService.isBiometricAvailable();

    final prefs = await SharedPreferences.getInstance();
    final identifier = prefs.getString('user_email')?.trim();

    bool enabled = false;
    if (identifier != null && identifier.isNotEmpty) {
      enabled = await biometricService.isEnabledForIdentifier(identifier);
    }

    debugPrint('[Biometric] available=$available, enabled=$enabled, identifier=$identifier');

    if (mounted) {
      setState(() {
        _isBiometricAvailable = available;
        _isBiometricEnabled = enabled;
      });
    }
  }

  Future<void> _onBiometricToggleChanged(bool value) async {
    if (!mounted) return;
    final localization = Provider.of<LocalizationService>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    final identifier = prefs.getString('user_email')?.trim();
    if (identifier == null || identifier.isEmpty) {
      if (mounted) UnifiedSnackbar.showError(context: context, message: localization.translate('auth.biometricFailed') ?? 'Unable to update biometric setting.');
      return;
    }
    final biometricService = BiometricService();

    if (value) {
      final available = await biometricService.isBiometricAvailable();
      if (!available) {
        if (mounted) {
          UnifiedSnackbar.showError(context: context, message: localization.translate('auth.biometricNotAvailable') ?? 'Biometric not available on this device.');
        }
        return;
      }
      final didAuthenticate = await biometricService.authenticate(
        context: context,
        reason: localization.translate('auth.biometricReason') ?? 'Verify identity to enable biometric login',
      );
      if (!didAuthenticate || !mounted) {
        setState(() => _isBiometricEnabled = false);
        if (mounted) {
          UnifiedSnackbar.showError(context: context, message: localization.translate('auth.biometricFailed') ?? 'Biometric verification failed.');
        }
        return;
      }
      final token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) {
        if (mounted) {
          setState(() => _isBiometricEnabled = false);
          UnifiedSnackbar.showError(context: context, message: localization.translate('auth.biometricTokenMissing') ?? 'Please login again to enable biometric.');
        }
        return;
      }
      final success = await biometricService.saveTokenSecurely(
        token,
        identifier: identifier,
        refreshToken: prefs.getString('refresh_token'),
        userId: prefs.getString('user_id'),
        userName: prefs.getString('user_name'),
      );
      if (mounted) {
        setState(() => _isBiometricEnabled = success);
        if (success) {
          UnifiedSnackbar.showSuccess(context: context, message: localization.translate('auth.biometricEnabled') ?? 'Biometric login enabled.');
        } else {
          UnifiedSnackbar.showError(context: context, message: localization.translate('auth.biometricFailed') ?? 'Failed to enable biometric.');
        }
      }
    } else {
      await biometricService.clearBiometricDataForIdentifier(identifier);
      if (mounted) setState(() => _isBiometricEnabled = false);
    }
  }

  Future<void> _loadNotificationState() async {
    if (!mounted) return;
    final prefService = NotificationPreferenceService();
    final userChoice = await prefService.getPushNotificationsEnabled();
    if (userChoice != null) {
      if (mounted) setState(() => _isPushNotificationsEnabled = userChoice);
      return;
    }
    final status = await FcmService().getAuthorizationStatus();
    final enabled = status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
    if (mounted) setState(() => _isPushNotificationsEnabled = enabled);
  }

  Future<void> _onNotificationToggleChanged(bool value) async {
    if (!mounted) return;
    final localization = Provider.of<LocalizationService>(context, listen: false);
    final prefService = NotificationPreferenceService();
    final fcmService = FcmService();

    if (value) {
      final granted = await fcmService.requestPermissionDirectly();
      if (!mounted) return;
      if (granted) {
        await prefService.setPushNotificationsEnabled(true);
        setState(() => _isPushNotificationsEnabled = true);

        UnifiedSnackbar.hideCurrent(context);
        UnifiedSnackbar.showLoading(
          context: context,
          message: localization.translate('profile.reactivatingAlerts') ?? 'Reactivating alerts...',
          duration: const Duration(minutes: 1),
        );

        final authRepository = Provider.of<AuthRepository>(context, listen: false);
        final synced = await authRepository.syncFcmToken();

        UnifiedSnackbar.hideCurrent(context);

        if (!mounted) return;
        if (synced) {
          UnifiedSnackbar.showSuccess(
            context: context,
            message: localization.translate('profile.alertsReactivated') ?? 'Alerts reactivated!',
          );
        } else {
          await prefService.setPushNotificationsEnabled(false);
          setState(() => _isPushNotificationsEnabled = false);
          UnifiedSnackbar.showError(
            context: context,
            message: localization.translate('profile.alertsReactivationFailed') ?? 'Could not reactivate alerts. Please try again.',
          );
        }
      } else {
        setState(() => _isPushNotificationsEnabled = false);
        UnifiedSnackbar.showError(
          context: context,
          message: localization.translate('profile.pushNotificationsDenied') ?? 'Could not enable notifications.',
        );
      }
    } else {
      await prefService.setPushNotificationsEnabled(false);
      try {
        final authRepository = Provider.of<AuthRepository>(context, listen: false);
        await authRepository.deleteFcmToken();
      } catch (_) {}
      if (mounted) {
        setState(() => _isPushNotificationsEnabled = false);
        UnifiedSnackbar.showSuccess(
          context: context,
          message: localization.translate('profile.pushNotificationsDisabled') ?? "Alerts paused. To fully disable, visit your phone's App Settings.",
        );
      }
    }
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

  void _handleProfileImageStateChanges(
      BuildContext context, ProfileImageState state) {
    if (state is ProfileImageUploadSuccess) {
      if (_userProfile != null) {
        setState(() {
          _userProfile = _userProfile!.copyWith(profilePicture: state.imageUrl);
        });
      }
      final authRepository = Provider.of<AuthRepository>(context, listen: false);
      authRepository.updateProfilePicture(state.imageUrl);
      context.read<ProfileCubit>().setCurrentProfileImage(state.imageUrl);
      // Recall profile API in background to sync full profile data
      _loadUserProfile(forceRefresh: true, silent: true);
    } else if (state is ProfileImageDeleteSuccess) {
      if (_userProfile != null) {
        setState(() {
          _userProfile = _userProfile!.copyWith(profilePicture: null);
        });
      }
      final authRepository = Provider.of<AuthRepository>(context, listen: false);
      authRepository.updateProfilePicture(null);
      context.read<ProfileCubit>().setCurrentProfileImage(null);
      // Recall profile API in background to sync full profile data
      _loadUserProfile(forceRefresh: true, silent: true);
    } else if (state is ProfileImageUploadError ||
        state is ProfileImageDeleteError) {
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

  @override
  Widget build(BuildContext context) {
    super.build(context); // Keep alive
    return BlocProvider(
      create: (context) =>
          ProfileCubit(currentProfileImageUrl: _userProfile?.profilePicture),
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
        ProfileHeaderWidget(
          userName: _userProfile?.name ?? '',
          profileImage: _userProfile?.profilePicture,
          userBio: _userProfile?.bio,
          userHandle: _userProfile?.getDisplayHandle(),
          onEditPersonalInfo: _editPersonalInfo,
          onShowFullScreenImage: _showFullScreenImageView,
        ),
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
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    if (_userProfile != null)
                      _buildShippingAddressCard(localization),
                    if (_userProfile != null) const SizedBox(height: 16),
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
                    ProfileSettingSectionWidget(
                      title: localization.translate('profile.account'),
                      sectionIcon: Icons.person_outline,
                      gradientColors: [AppColors.info, AppColors.info.withValues(alpha: 0.8)],
                      items: [
                        ProfileSettingItem(
                          icon: Icons.person_outline,
                          title: localization.translate('profile.editProfile'),
                          subtitle: localization.translate('profile.nameEmailBio'),
                          onTap: _editPersonalInfo,
                          color: AppColors.primary,
                          showDivider: false,
                        ),
                        ProfileSettingItem(
                          icon: Icons.lock_outline,
                          title: localization.translate('profile.changePassword'),
                          subtitle: localization.translate('profile.changePasswordSubtitle'),
                          onTap: _changePassword,
                          color: AppColors.secondary,
                          showDivider: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ProfileSettingSectionWidget(
                      title: localization.translate('profile.settings'),
                      sectionIcon: Icons.tune,
                      gradientColors: [AppColors.warning, AppColors.warning.withValues(alpha: 0.8)],
                      items: [
                        ProfileSettingItem(
                          icon: Icons.fingerprint,
                          title: localization.translate('auth.enableBiometric') ?? 'Biometric Login',
                          subtitle: localization.translate('auth.enableBiometricMessage') ?? 'Use fingerprint or Face ID for quick sign-in',
                          color: AppColors.primary,
                          isSwitch: true,
                          switchValue: _isBiometricEnabled,
                          onSwitchChanged: _onBiometricToggleChanged,
                          showDivider: true,
                        ),
                        // App Alerts switch hidden for MVP to encourage user engagement
                        // ProfileSettingItem(
                        //   icon: Icons.notifications_active_outlined,
                        //   title: localization.translate('profile.pushNotifications') ?? 'App Alerts',
                        //   subtitle: localization.translate('profile.pushNotificationsSubtitle') ?? 'Receive updates about your wishes and friends',
                        //   color: AppColors.primary,
                        //   isSwitch: true,
                        //   switchValue: _isPushNotificationsEnabled,
                        //   onSwitchChanged: _onNotificationToggleChanged,
                        //   showDivider: true,
                        // ),
                        ProfileSettingItem(
                          icon: Icons.notifications_outlined,
                          title: localization.translate('profile.notificationSettings') ?? 'Notification Prefs',
                          subtitle: localization.translate('profile.notificationSettingsSubtitle') ?? 'Customize how you receive alerts',
                          onTap: _notificationSettings,
                          color: AppColors.accent,
                        ),
                        ProfileSettingItem(
                          icon: Icons.language_outlined,
                          title: localization.translate('profile.languageAndTheme'),
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
                    ProfileSettingSectionWidget(
                      title: localization.translate('profile.privacy'),
                      sectionIcon: Icons.shield_outlined,
                      gradientColors: [AppColors.secondary, AppColors.secondary.withValues(alpha: 0.8)],
                      items: [
                        ProfileSettingItem(
                          icon: Icons.block_outlined,
                          title: localization.translate('friends.blockedUser'),
                          subtitle: localization.translate('profile.blockedUsersSubtitle'),
                          onTap: () => Navigator.pushNamed(context, AppRoutes.blockedUsers),
                          color: AppColors.secondary,
                        ),
                        ProfileSettingItem(
                          icon: Icons.verified_user,
                          title: localization.translate('profile.privacyPolicy'),
                          subtitle: localization.translate('profile.privacyPolicySubtitle'),
                          onTap: _openPrivacyPolicy,
                          color: AppColors.secondary,
                          showDivider: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ProfileSettingSectionWidget(
                      title: localization.translate('profile.support'),
                      sectionIcon: Icons.help_outline,
                      gradientColors: [AppColors.success, AppColors.success.withValues(alpha: 0.8)],
                      items: [
                        ProfileSettingItem(
                          icon: Icons.person_add_alt_1_outlined,
                          title: localization.translate('invite.inviteFriendsTitle'),
                          subtitle: localization.translate('invite.inviteFriendsSubtitle'),
                          onTap: () => _shareAppInvite(localization),
                          color: AppColors.primary,
                        ),
                        ProfileSettingItem(
                          icon: Icons.headset_outlined,
                          title: localization.translate('profile.contactUs'),
                          subtitle: localization.translate('profile.contactUsSubtitle'),
                          onTap: _contactUs,
                          color: AppColors.primary,
                        ),
                        ProfileSettingItem(
                          icon: Icons.help_outline,
                          title: localization.translate('profile.faq'),
                          subtitle: localization.translate('profile.faqSubtitle'),
                          onTap: _openFAQ,
                          color: AppColors.info,
                        ),
                        ProfileSettingItem(
                          icon: Icons.description_outlined,
                          title: localization.translate('profile.termsConditions'),
                          subtitle: localization.translate('profile.termsConditionsSubtitle'),
                          onTap: _openTermsConditions,
                          color: AppColors.accent,
                          showDivider: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ProfileSettingSectionWidget(
                      title: localization.translate('profile.dangerZone'),
                      sectionIcon: Icons.warning_amber_rounded,
                      gradientColors: [AppColors.error, AppColors.error.withValues(alpha: 0.8)],
                      items: [
                        ProfileSettingItem(
                          icon: Icons.logout,
                          title: localization.translate('auth.logout'),
                          subtitle: localization.translate('profile.signOutOfAccount'),
                          onTap: () => _confirmLogout(localization),
                          color: AppColors.textSecondary,
                        ),
                        ProfileSettingItem(
                          icon: Icons.delete_outline,
                          title: localization.translate('profile.deleteAccount'),
                          subtitle: localization.translate('profile.deleteAccountMessage'),
                          onTap: () => _confirmDeleteAccount(localization),
                          color: AppColors.error,
                          showDivider: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildVersionWidget(),
                    const SizedBox(height: 12),
                    _buildSocialMediaLinksRow(),
                    SizedBox(
                      height: MediaQuery.of(context).padding.bottom +
                          kBottomNavigationBarHeight +
                          24,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
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
          ? 'تحقق من قائمة الأمنيات الخاصة بي على wishListy! $profileLink'
          : 'Check out my wish list on wishListy! $profileLink';
      
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

  void _navigateToShippingAddress() async {
    final result = await Navigator.pushNamed(context, AppRoutes.shippingAddress);
    if (result == true && mounted) {
      _loadUserProfile(forceRefresh: true);
    }
  }

  Widget _buildShippingAddressCard(LocalizationService localization) {
    final address = _userProfile?.shippingAddress?.trim();
    final hasAddress = address != null && address.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textTertiary.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _navigateToShippingAddress,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.location_on_outlined,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localization.translate('profile.shippingAddress') ?? 'Shipping Address',
                        style: AppStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        localization.translate('profile.shippingAddressSubtitle') ??
                            'Where friends can send you gifts privately',
                        style: AppStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      if (hasAddress) ...[
                        const SizedBox(height: 8),
                        Text(
                          address.length > 50 ? '${address.substring(0, 50)}...' : address,
                          style: AppStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        Text(
                          localization.translate('profile.shippingNotSet') ?? 'Not set',
                          style: AppStyles.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (hasAddress)
                  Icon(Icons.edit_outlined, size: 20, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textTertiary,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

  void _shareAppInvite(LocalizationService localization) {
    final message = localization.translate('invite.inviteFriendsShareMessage') +
        DeepLinkService.inviteLink;
    DeepLinkService.shareAppInvite(message);
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
    final localization = Provider.of<LocalizationService>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // Show loading snackbar
    final loadingSnackBar = _buildLoadingSnackBar(
      localization.translate('common.pleaseWait') ?? 'Processing...',
      localization,
    );
    scaffoldMessenger.showSnackBar(loadingSnackBar);
    
    try {
      final authRepository = Provider.of<AuthRepository>(
        context,
        listen: false,
      );
      await authRepository.logout();

      // Dismiss loading snackbar immediately when API succeeds (so it doesn't persist after navigation)
      if (mounted) {
        scaffoldMessenger.clearSnackBars();
      }

      if (mounted) {
        // Navigate to login screen
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
      }
    } on ApiException catch (e) {
      // Dismiss loading snackbar
      if (mounted) scaffoldMessenger.clearSnackBars();
      
      if (mounted) {
        // Show error snackbar with backend message
        scaffoldMessenger.showSnackBar(
          _buildErrorSnackBar(
            e.message.isNotEmpty 
                ? e.message 
                : (localization.translate('dialogs.errorLoggingOut') ?? 'Error logging out'),
            localization,
          ),
        );
      }
    } catch (e) {
      // Dismiss loading snackbar
      if (mounted) scaffoldMessenger.clearSnackBars();
      
      if (mounted) {
        // Show error snackbar
        scaffoldMessenger.showSnackBar(
          _buildErrorSnackBar(
            '${localization.translate('dialogs.errorLoggingOut') ?? 'Error logging out'}: $e',
            localization,
          ),
        );
      }
    }
  }

  void _deleteAccount(LocalizationService localization) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // Show loading snackbar
    final loadingSnackBar = _buildLoadingSnackBar(
      localization.translate('common.pleaseWait') ?? 'Processing...',
      localization,
    );
    scaffoldMessenger.showSnackBar(loadingSnackBar);
    
    try {
      final authRepository = Provider.of<AuthRepository>(
        context,
        listen: false,
      );
      await authRepository.deleteAccount();

      // Dismiss loading snackbar
      scaffoldMessenger.hideCurrentSnackBar();

      if (mounted) {
        // Show success message
        scaffoldMessenger.showSnackBar(
          _buildSuccessSnackBar(
            localization.translate('profile.accountDeleted') ?? 'Your account has been deleted.',
            localization,
          ),
        );

        // Wait a moment for user to see success message, then navigate
        await Future.delayed(const Duration(milliseconds: 1500));

        if (mounted) {
          // Navigate to Welcome screen and clear navigation stack
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.welcome,
            (route) => false,
          );
        }
      }
    } on ApiException catch (e) {
      // Dismiss loading snackbar
      scaffoldMessenger.hideCurrentSnackBar();
      
      if (mounted) {
        // Show error snackbar with backend message
        scaffoldMessenger.showSnackBar(
          _buildErrorSnackBar(
            e.message.isNotEmpty 
                ? e.message 
                : (localization.translate('dialogs.errorDeletingAccount') ?? 'Error deleting account'),
            localization,
          ),
        );
      }
    } catch (e) {
      // Dismiss loading snackbar
      scaffoldMessenger.hideCurrentSnackBar();
      
      if (mounted) {
        // Show error snackbar
        scaffoldMessenger.showSnackBar(
          _buildErrorSnackBar(
            '${localization.translate('dialogs.errorDeletingAccount') ?? 'Error deleting account'}: $e',
            localization,
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
  Future<void> _loadUserProfile({
    bool forceRefresh = false,
    bool silent = false,
  }) async {
    // Don't reload if already loaded unless force refresh
    if (_hasLoaded && !forceRefresh) {
      return;
    }

    // Smart Loading: Only show loading skeleton if profile data doesn't exist yet
    // If data exists, refresh in background without showing loading skeleton
    // silent=true: refresh in background without loading UI (e.g. after photo upload)
    final hasExistingData = _userProfile != null;
    if (!silent && (!hasExistingData || forceRefresh)) {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    } else if (!silent) {
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
                shippingAddress: _parseShippingAddressFromProfile(data),
                shippingVisibleToFriends: _parseShippingVisibleFromProfile(data),
              );
              
              _isLoading = false;
              _hasLoaded = true;
              _errorMessage = null;
            });
            
            // Update global AuthRepository profile picture for sync across app
            authRepository.updateProfilePicture(profilePictureUrl?.toString());
          } catch (parseError) {
            // Handle parsing errors specifically
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
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
          _hasLoaded = true;
        });
      }
    } catch (e, stackTrace) {
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
    if (!mounted) return;
    final localization = Provider.of<LocalizationService>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      _buildLoadingSnackBar(
        localization.translate('common.pleaseWait') ?? 'Saving...',
        localization,
      ),
    );
    try {
      final apiService = ApiService();
      final response = await apiService.put(
        '/users/interests',
        data: {'interests': selectedInterests},
      );

      if (!mounted) return;
      scaffoldMessenger.hideCurrentSnackBar();

      if (response['success'] == true || response['success'] == null) {
        if (_userProfile != null) {
          setState(() {
            _userProfile = _userProfile!.copyWith(interests: selectedInterests);
          });
        }
        scaffoldMessenger.showSnackBar(
          _buildSuccessSnackBar(localization.translate('cards.interestsUpdatedSuccessfully'), localization),
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to update interests');
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        _buildErrorSnackBar(
          e.message.isNotEmpty ? e.message : (localization.translate('dialogs.errorGeneric') ?? 'Something went wrong'),
          localization,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        _buildErrorSnackBar(
          localization.translate('cards.failedToUpdateInterests') ?? 'Failed to update interests',
          localization,
        ),
      );
    }
  }

  // Public method to refresh profile from outside (e.g., from MainNavigation)
  void refreshProfile() {
    // Only refresh if not already loading and data exists
    // This prevents unnecessary reloads when returning from full-screen viewer
    if (!_isLoading && _hasLoaded) {
      _loadUserProfile(forceRefresh: false); // Background refresh without skeleton
    } else {
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
                interest.translateInterest(context),
                style: AppStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor: Colors.purple.withOpacity(0.1),
              side: BorderSide.none,
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

  /// App version text at bottom - long press to copy FCM token to clipboard
  Widget _buildVersionWidget() {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.hasData ? snapshot.data!.version : '?.?.?';
        return Center(
          child: GestureDetector(
            onLongPress: () => _copyFcmTokenToClipboard(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'App Version $version',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSocialMediaLinksRow() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SocialCircleIconButton(
            icon: FontAwesomeIcons.facebookF,
            onTap: () => _launchExternalUrl(AppConstants.facebookUrl),
          ),
          const SizedBox(width: 16),
          _SocialCircleIconButton(
            icon: FontAwesomeIcons.instagram,
            onTap: () => _launchExternalUrl(AppConstants.instagramUrl),
          ),
        ],
      ),
    );
  }

  Future<void> _launchExternalUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      if (await canLaunchUrl(uri)) {
        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (ok) return;
      }
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Provider.of<LocalizationService>(context, listen: false)
                .translate('profile.couldNotLaunchUrl'),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _copyFcmTokenToClipboard() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty && mounted) {
        await Clipboard.setData(ClipboardData(text: token));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Token copied to clipboard!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to get FCM token'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Build loading snackbar with CircularProgressIndicator
  SnackBar _buildLoadingSnackBar(String message, LocalizationService localization) {
    final isArabic = localization.currentLanguage == 'ar';
    
    return SnackBar(
      content: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: isArabic
                  ? GoogleFonts.alexandria(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    )
                  : AppStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.primary,
      duration: const Duration(minutes: 5), // Long duration for persistent loading
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
    );
  }

  /// Build error snackbar with Alexandria font
  SnackBar _buildErrorSnackBar(String message, LocalizationService localization) {
    final isArabic = localization.currentLanguage == 'ar';
    
    return SnackBar(
      content: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: isArabic
                  ? GoogleFonts.alexandria(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    )
                  : AppStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.error,
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
    );
  }

  /// Build success snackbar with Alexandria font
  SnackBar _buildSuccessSnackBar(String message, LocalizationService localization) {
    final isArabic = localization.currentLanguage == 'ar';
    
    return SnackBar(
      content: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: isArabic
                  ? GoogleFonts.alexandria(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    )
                  : AppStyles.bodyMedium.copyWith(
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
      margin: const EdgeInsets.all(16),
    );
  }
}

class _SocialCircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SocialCircleIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: FaIcon(
              icon,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
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
  final String? shippingAddress;
  final bool shippingVisibleToFriends;

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
    this.shippingAddress,
    this.shippingVisibleToFriends = true,
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
    String? shippingAddress,
    bool? shippingVisibleToFriends,
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
      shippingAddress: shippingAddress ?? this.shippingAddress,
      shippingVisibleToFriends: shippingVisibleToFriends ?? this.shippingVisibleToFriends,
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
                      label: Text(category.translateInterest(context)),
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
