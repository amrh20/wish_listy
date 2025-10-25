import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/core/widgets/decorative_background.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';
import '../widgets/index.dart';

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
    return Consumer2<LocalizationService, AuthRepository>(
      builder: (context, localization, authService, child) {
        // For guest users - show different interface
        if (authService?.isGuest == true) {
          return Scaffold(
            body: DecorativeBackground(
              showGifts: true,
              child: SafeArea(
                child: Column(
                  children: [
                    // Guest App Bar
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.favorite_rounded,
                            color: AppColors.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            localization.translate(
                              'wishlists.exploreWishlists',
                            ),
                            style: AppStyles.headingLarge.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Guest Wishlists View
                    Expanded(
                      child: GuestWishlistsViewWidget(
                        publicUsers: _publicUsers,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // For authenticated users - show full interface
        return Scaffold(
          floatingActionButton: WishlistFabWidget(
            onCreatePersonalWishlist: () =>
                _showCreateWishlistDialog(isEvent: false),
            onCreateEventWishlist: () =>
                _showCreateWishlistDialog(isEvent: true),
          ),
          body: DecorativeBackground(
            showGifts: true,
            child: Column(
              children: [
                // Top App Bar
                MyWishlistsHeaderWidget(
                  onSearchPressed: _showSearchBottomSheet,
                  onMenuActionExport: _showExportDialog,
                  onMenuActionSettings: () => _handleMenuAction('settings'),
                ),

                // Main Tab Bar
                MyWishlistsTabBarWidget(tabController: _mainTabController),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _mainTabController,
                    children: [
                      PersonalWishlistsTabWidget(
                        personalWishlists: _personalWishlists,
                        eventWishlists: _eventWishlists,
                        onWishlistTap: _navigateToWishlistItems,
                        onAddItem: _navigateToAddItem,
                        onMenuAction: _handleWishlistAction,
                        onCreateEventWishlist: () =>
                            _showCreateWishlistDialog(isEvent: true),
                        onRefresh: _refreshWishlists,
                      ),
                      FriendsWishlistsTabWidget(),
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

  Future<void> _refreshWishlists() async {
    // TODO: Implement refresh logic
    await Future.delayed(Duration(seconds: 1));
  }
}
