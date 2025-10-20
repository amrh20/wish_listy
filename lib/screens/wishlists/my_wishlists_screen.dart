import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../utils/app_routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/decorative_background.dart';
import '../../services/localization_service.dart';
import '../../services/auth_service.dart';

class MyWishlistsScreen extends StatefulWidget {
  const MyWishlistsScreen({super.key});

  @override
  _MyWishlistsScreenState createState() => _MyWishlistsScreenState();
}

class _MyWishlistsScreenState extends State<MyWishlistsScreen>
    with TickerProviderStateMixin {
  late TabController _mainTabController;
  late AnimationController _animationController;
  final TextEditingController _searchController = TextEditingController();
  List<UserProfile> _searchResults = [];
  bool _isSearching = false;

  // Mock data - Personal Wishlists (not linked to events)
  final List<WishlistSummary> _personalWishlists = [
    WishlistSummary(
      id: '1',
      name: 'My General Wishlist',
      itemCount: 12,
      purchasedCount: 3,
      totalValue: 450.0,
      lastUpdated: DateTime.now().subtract(Duration(days: 2)),
      privacy: WishlistPrivacy.public,
      imageUrl: null,
    ),
    WishlistSummary(
      id: '4',
      name: 'Dream Gadgets',
      itemCount: 6,
      purchasedCount: 1,
      totalValue: 890.0,
      lastUpdated: DateTime.now().subtract(Duration(days: 7)),
      privacy: WishlistPrivacy.private,
      imageUrl: null,
    ),
  ];

  // Mock data - Event Wishlists
  final List<WishlistSummary> _eventWishlists = [
    WishlistSummary(
      id: '2',
      name: 'Birthday Wishlist 2024',
      itemCount: 8,
      purchasedCount: 2,
      totalValue: 320.0,
      lastUpdated: DateTime.now().subtract(Duration(days: 1)),
      privacy: WishlistPrivacy.onlyInvited,
      imageUrl: null,
      eventName: 'My 28th Birthday',
      eventDate: DateTime.now().add(Duration(days: 15)),
    ),
    WishlistSummary(
      id: '3',
      name: 'Christmas Wishlist',
      itemCount: 15,
      purchasedCount: 0,
      totalValue: 680.0,
      lastUpdated: DateTime.now().subtract(Duration(days: 5)),
      privacy: WishlistPrivacy.public,
      imageUrl: null,
      eventName: 'Christmas Celebration',
      eventDate: DateTime(2024, 12, 25),
    ),
  ];

  // Mock public users for guest search
  final List<UserProfile> _publicUsers = [
    UserProfile(
      id: 'user1',
      name: 'أحمد محمد',
      profilePicture: null,
      publicWishlistsCount: 3,
      totalWishlistItems: 25,
    ),
    UserProfile(
      id: 'user2',
      name: 'سارة أحمد',
      profilePicture: null,
      publicWishlistsCount: 2,
      totalWishlistItems: 18,
    ),
    UserProfile(
      id: 'user3',
      name: 'محمد علي',
      profilePicture: null,
      publicWishlistsCount: 1,
      totalWishlistItems: 12,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _mainTabController.addListener(() {
      setState(() {});
    });
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  void _startAnimations() {
    _animationController.forward();
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LocalizationService, AuthService>(
      builder: (context, localization, authService, child) {
        // For guest users - show different interface
        if (authService.isGuest) {
          return _buildGuestView(localization);
        }

        // For authenticated users - show full interface
        return Scaffold(
          floatingActionButton: _buildSimpleFAB(localization),
          body: DecorativeBackground(
            showGifts: true,
            child: Column(
              children: [
                // Top App Bar
                _buildTopAppBar(localization),

                // Main Tab Bar
                _buildMainTabBar(localization),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _mainTabController,
                    children: [
                      _buildMyWishlistsTab(localization),
                      _buildFriendsWishlistsTab(localization),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopAppBar(LocalizationService localization) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                localization.translate('wishlists.myWishlists'),
                style: AppStyles.headingLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // Search Button
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: _showSearchBottomSheet,
                icon: Icon(Icons.search_rounded, color: AppColors.textPrimary),
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
            ),
            const SizedBox(width: 8),
            // Menu Button
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: PopupMenuButton<String>(
                onSelected: _handleMenuAction,
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.textPrimary,
                ),
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.download_outlined, size: 20),
                        SizedBox(width: 12),
                        Text(localization.translate('common.export')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings_outlined, size: 20),
                        SizedBox(width: 12),
                        Text(localization.translate('profile.settings')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainTabBar(LocalizationService localization) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.textTertiary.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          // My Wishlists Tab
          Expanded(
            child: GestureDetector(
              onTap: () {
                _mainTabController.animateTo(0);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: _mainTabController.index == 0
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_rounded,
                      size: 16,
                      color: _mainTabController.index == 0
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        localization.translate('wishlists.myWishlists'),
                        overflow: TextOverflow.ellipsis,
                        style: AppStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _mainTabController.index == 0
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Friends Wishlists Tab
          Expanded(
            child: GestureDetector(
              onTap: () {
                _mainTabController.animateTo(1);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: _mainTabController.index == 1
                      ? AppColors.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_rounded,
                      size: 16,
                      color: _mainTabController.index == 1
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        localization.translate('wishlists.friendsWishlists'),
                        overflow: TextOverflow.ellipsis,
                        style: AppStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: _mainTabController.index == 1
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyWishlistsTab(LocalizationService localization) {
    return RefreshIndicator(
      onRefresh: _refreshWishlists,
      color: AppColors.secondary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Personal Wishlists Section
            _buildSectionHeader(
              localization.translate('wishlists.personalWishlists'),
              Icons.favorite_border_rounded,
              AppColors.primary,
            ),
            const SizedBox(height: 12),
            ..._personalWishlists
                .map(
                  (wishlist) =>
                      _buildEnhancedWishlistCard(wishlist, localization),
                )
                .toList(),

            const SizedBox(height: 24),

            // Event Wishlists Section
            _buildSectionHeader(
              localization.translate('wishlists.eventWishlists'),
              Icons.celebration_rounded,
              AppColors.accent,
            ),
            const SizedBox(height: 12),

            if (_eventWishlists.isEmpty)
              _buildEmptyEventWishlists(localization)
            else
              ..._eventWishlists
                  .map(
                    (wishlist) => _buildEnhancedWishlistCard(
                      wishlist,
                      localization,
                      isEvent: true,
                    ),
                  )
                  .toList(),

            const SizedBox(height: 100), // Bottom padding for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: AppStyles.headingSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedWishlistCard(
    WishlistSummary wishlist,
    LocalizationService localization, {
    bool isEvent = false,
  }) {
    final progress = wishlist.itemCount > 0
        ? wishlist.purchasedCount / wishlist.itemCount
        : 0.0;

    final daysAgo = DateTime.now().difference(wishlist.lastUpdated).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textTertiary.withOpacity(0.08),
            offset: const Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and privacy badge
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isEvent
                        ? AppColors.accent.withOpacity(0.1)
                        : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isEvent
                        ? Icons.celebration_rounded
                        : Icons.favorite_rounded,
                    color: isEvent ? AppColors.accent : AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Title and event info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wishlist.name,
                        style: AppStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isEvent && wishlist.eventName != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.event_rounded,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                wishlist.eventName!,
                                style: AppStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Privacy badge
                _buildPrivacyBadge(wishlist.privacy),

                const SizedBox(width: 8),

                // More options menu
                PopupMenuButton<String>(
                  onSelected: (value) => _handleWishlistAction(value, wishlist),
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 12),
                          Text(localization.translate('common.edit')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share_outlined, size: 18),
                          SizedBox(width: 12),
                          Text(localization.translate('common.share')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: AppColors.error,
                          ),
                          SizedBox(width: 12),
                          Text(
                            localization.translate('common.delete'),
                            style: TextStyle(color: AppColors.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Last updated
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              daysAgo == 0
                  ? localization.translate('common.today')
                  : localization
                        .translate('common.updatedDaysAgo')
                        .replaceAll('{days}', daysAgo.toString()),
              style: AppStyles.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${wishlist.purchasedCount}/${wishlist.itemCount} ${localization.translate("wishlists.itemsPurchased")}',
                      style: AppStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: AppStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppColors.textTertiary.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress == 1.0 ? AppColors.success : AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildStatChip(
                  Icons.card_giftcard_rounded,
                  '${wishlist.itemCount} ${localization.translate("wishlists.items")}',
                  AppColors.primary,
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  Icons.check_circle_rounded,
                  '${wishlist.purchasedCount} ${localization.translate("wishlists.purchased")}',
                  AppColors.success,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Divider
          Divider(height: 1, color: AppColors.textTertiary.withOpacity(0.1)),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    label: localization.translate('wishlists.viewItems'),
                    icon: Icons.visibility_rounded,
                    onPressed: () => _navigateToWishlistItems(wishlist),
                    isPrimary: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    label: localization.translate('wishlists.addItem'),
                    icon: Icons.add_rounded,
                    onPressed: () => _navigateToAddItem(wishlist),
                    isPrimary: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyBadge(WishlistPrivacy privacy) {
    IconData icon;
    Color color;
    String label;

    switch (privacy) {
      case WishlistPrivacy.public:
        icon = Icons.public_rounded;
        color = AppColors.success;
        label = 'Public';
        break;
      case WishlistPrivacy.private:
        icon = Icons.lock_rounded;
        color = AppColors.error;
        label = 'Private';
        break;
      case WishlistPrivacy.onlyInvited:
        icon = Icons.group_rounded;
        color = AppColors.warning;
        label = 'Invited';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return Material(
      color: isPrimary ? AppColors.primary : AppColors.primary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isPrimary ? Colors.white : AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppStyles.bodyMedium.copyWith(
                  color: isPrimary ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyEventWishlists(LocalizationService localization) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.textTertiary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.celebration_outlined,
              size: 40,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            localization.translate('wishlists.noEventWishlists'),
            style: AppStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            localization.translate('wishlists.createEventWishlistDescription'),
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: localization.translate('wishlists.createEventWishlist'),
            onPressed: () => _showCreateWishlistDialog(isEvent: true),
            customColor: AppColors.accent,
            icon: Icons.add_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsWishlistsTab(LocalizationService localization) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline_rounded,
                size: 50,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              localization.translate('wishlists.friendsWishlistsComingSoon'),
              style: AppStyles.headingMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              localization.translate('wishlists.friendsWishlistsDescription'),
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleFAB(LocalizationService localization) {
    return FloatingActionButton(
      onPressed: () => _showFABOptions(localization),
      backgroundColor: AppColors.accent,
      child: Icon(Icons.add, color: Colors.white, size: 28),
    );
  }

  void _showFABOptions(LocalizationService localization) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              localization.translate('common.whatWouldYouLikeToDo'),
              style: AppStyles.headingSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),

            _buildFABOption(
              icon: Icons.playlist_add_rounded,
              title: localization.translate('wishlists.createNewWishlist'),
              subtitle: localization.translate(
                'wishlists.createNewWishlistDescription',
              ),
              color: AppColors.primary,
              onTap: () {
                Navigator.pop(context);
                _showCreateWishlistDialog();
              },
            ),
            const SizedBox(height: 12),

            _buildFABOption(
              icon: Icons.add_shopping_cart_rounded,
              title: localization.translate('wishlists.addItemToWishlist'),
              subtitle: localization.translate(
                'wishlists.addItemToWishlistDescription',
              ),
              color: AppColors.secondary,
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.addItem);
              },
            ),
            const SizedBox(height: 12),

            _buildFABOption(
              icon: Icons.celebration_rounded,
              title: localization.translate('events.createNewEvent'),
              subtitle: localization.translate(
                'events.createNewEventDescription',
              ),
              color: AppColors.accent,
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.createEvent);
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFABOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Guest view
  Widget _buildGuestView(LocalizationService localization) {
    return Scaffold(
      body: DecorativeBackground(
        showGifts: true,
        child: SafeArea(
          child: Column(
            children: [
              _buildGuestAppBar(localization),
              Expanded(child: _buildGuestWishlistsView(localization)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuestAppBar(LocalizationService localization) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.favorite_rounded, color: AppColors.primary, size: 28),
          const SizedBox(width: 12),
          Text(
            localization.translate('wishlists.exploreWishlists'),
            style: AppStyles.headingLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestWishlistsView(LocalizationService localization) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    localization.translate('auth.signInToCreateWishlists'),
                    style: AppStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Search section
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: localization.translate(
                'wishlists.searchPublicWishlists',
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.textSecondary,
              ),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Search results or public users
          if (_isSearching && _searchResults.isNotEmpty) ...[
            Text(
              localization.translate('wishlists.searchResults'),
              style: AppStyles.headingSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._searchResults
                .map((user) => _buildUserCard(user, localization))
                .toList(),
          ] else if (!_isSearching) ...[
            Text(
              localization.translate('wishlists.popularUsers'),
              style: AppStyles.headingSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._publicUsers
                .map((user) => _buildUserCard(user, localization))
                .toList(),
          ] else ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 64,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      localization.translate('wishlists.noResultsFound'),
                      style: AppStyles.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserCard(UserProfile user, LocalizationService localization) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.textTertiary.withOpacity(0.08),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(
            user.name[0],
            style: AppStyles.headingSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user.name,
          style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${user.publicWishlistsCount} ${localization.translate("wishlists.publicWishlists")} • ${user.totalWishlistItems} ${localization.translate("wishlists.items")}',
          style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: AppColors.textTertiary,
        ),
        onTap: () {
          _showGuestRestrictionDialog(localization);
        },
      ),
    );
  }

  void _showGuestRestrictionDialog(LocalizationService localization) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localization.translate('guest.restrictions.title')),
        content: Text(localization.translate('guest.restrictions.message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localization.translate('common.close')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.login);
            },
            child: Text(localization.translate('auth.signIn')),
          ),
        ],
      ),
    );
  }

  // Navigation methods
  void _navigateToWishlistItems(WishlistSummary wishlist) {
    Navigator.pushNamed(
      context,
      AppRoutes.wishlistItems,
      arguments: {
        'wishlistId': wishlist.id,
        'wishlistName': wishlist.name,
        'totalItems': wishlist.itemCount,
        'purchasedItems': wishlist.purchasedCount,
        'totalValue': wishlist.totalValue,
        'isFriendWishlist': false,
      },
    );
  }

  void _navigateToAddItem(WishlistSummary wishlist) {
    Navigator.pushNamed(context, AppRoutes.addItem, arguments: wishlist.id);
  }

  // Action handlers
  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _showExportDialog();
        break;
      case 'settings':
        // TODO: Navigate to settings when route is available
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Settings coming soon'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
    }
  }

  void _handleWishlistAction(String action, WishlistSummary wishlist) {
    switch (action) {
      case 'edit':
        _showEditWishlistDialog(wishlist);
        break;
      case 'share':
        _shareWishlist(wishlist);
        break;
      case 'delete':
        _showDeleteConfirmation(wishlist);
        break;
    }
  }

  void _showCreateWishlistDialog({bool isEvent = false}) {
    // TODO: Implement create wishlist dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Create ${isEvent ? "event" : ""} wishlist dialog'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showEditWishlistDialog(WishlistSummary wishlist) {
    // TODO: Implement edit wishlist dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit wishlist: ${wishlist.name}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareWishlist(WishlistSummary wishlist) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share wishlist: ${wishlist.name}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showDeleteConfirmation(WishlistSummary wishlist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Wishlist?'),
        content: Text('Are you sure you want to delete "${wishlist.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteWishlist(wishlist);
            },
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _deleteWishlist(WishlistSummary wishlist) {
    setState(() {
      _personalWishlists.remove(wishlist);
      _eventWishlists.remove(wishlist);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Wishlist deleted: ${wishlist.name}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showExportDialog() {
    // TODO: Implement export dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Export functionality'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSearchBottomSheet() {
    // TODO: Implement search bottom sheet
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Search functionality'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onSearchChanged(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      if (_isSearching) {
        _searchResults = _publicUsers
            .where(
              (user) => user.name.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      } else {
        _searchResults = [];
      }
    });
  }

  Future<void> _refreshWishlists() async {
    // TODO: Implement refresh logic
    await Future.delayed(Duration(seconds: 1));
  }
}

// Models
class WishlistSummary {
  final String id;
  final String name;
  final int itemCount;
  final int purchasedCount;
  final double totalValue;
  final DateTime lastUpdated;
  final WishlistPrivacy privacy;
  final String? imageUrl;
  final String? eventName;
  final DateTime? eventDate;

  WishlistSummary({
    required this.id,
    required this.name,
    required this.itemCount,
    required this.purchasedCount,
    required this.totalValue,
    required this.lastUpdated,
    this.privacy = WishlistPrivacy.public,
    this.imageUrl,
    this.eventName,
    this.eventDate,
  });
}

enum WishlistPrivacy { public, private, onlyInvited }

class UserProfile {
  final String id;
  final String name;
  final String? profilePicture;
  final int publicWishlistsCount;
  final int totalWishlistItems;

  UserProfile({
    required this.id,
    required this.name,
    this.profilePicture,
    required this.publicWishlistsCount,
    required this.totalWishlistItems,
  });
}
