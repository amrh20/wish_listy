import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/core/widgets/decorative_background.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';
import 'package:wish_listy/features/wishlists/data/repository/wishlist_repository.dart';
import '../widgets/index.dart';
import '../widgets/guest_wishlists_view_widget.dart';

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

  // Wishlist data from API
  List<WishlistSummary> _personalWishlists = [];
  List<WishlistSummary> _eventWishlists = [];
  bool _isLoading = false;
  String? _errorMessage;

  final WishlistRepository _wishlistRepository = WishlistRepository();

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _mainTabController.addListener(() {
      setState(() {});
    });
    _initializeAnimations();
    _startAnimations();
    _loadWishlists();
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
        if (authService.isGuest) {
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
                        publicWishlists:
                            const [], // Empty for now, can be populated later
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
                _navigateToCreateWishlist(isEvent: false),
            onCreateEventWishlist: () =>
                _navigateToCreateWishlist(isEvent: true),
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
                  child: _isLoading
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Loading...',
                                style: AppStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
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
                                  _errorMessage!,
                                  style: AppStyles.bodyLarge.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: _loadWishlists,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Retry'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : TabBarView(
                          controller: _mainTabController,
                          children: [
                            PersonalWishlistsTabWidget(
                              personalWishlists: _personalWishlists,
                              eventWishlists: _eventWishlists,
                              onWishlistTap: _navigateToWishlistItems,
                              onAddItem: _navigateToAddItem,
                              onMenuAction: _handleWishlistAction,
                              onCreateEventWishlist: () =>
                                  _navigateToCreateWishlist(isEvent: true),
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
        'isFriendWishlist': false,
      },
    );
  }

  void _navigateToAddItem(WishlistSummary wishlist) {
    Navigator.pushNamed(context, AppRoutes.addItem, arguments: wishlist.id);
  }

  void _navigateToCreateWishlist({bool isEvent = false}) {
    // TODO: Navigate to create wishlist screen when it's implemented
    Navigator.pushNamed(
      context,
      AppRoutes.createWishlist,
      arguments: {'isEvent': isEvent},
    );
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Wishlist?',
          style: AppStyles.headingSmall.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "${wishlist.name}"? This action cannot be undone.',
          style: AppStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteWishlist(wishlist);
            },
            child: Text(
              'Delete',
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

  Future<void> _deleteWishlist(WishlistSummary wishlist) async {
    try {
      debugPrint('🗑️ MyWishlistsScreen: Deleting wishlist: ${wishlist.id}');

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
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
                const SizedBox(width: 12),
                Text('Deleting wishlist...'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Call API to delete wishlist
      await _wishlistRepository.deleteWishlist(wishlist.id);

      debugPrint('✅ MyWishlistsScreen: Wishlist deleted successfully');

      // Reload wishlists to update the screen
      await _loadWishlists();

      if (mounted) {
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
                    'Wishlist "${wishlist.name}" deleted successfully',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(
              top: 60,
              left: 16,
              right: 16,
              bottom: 0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      debugPrint('❌ MyWishlistsScreen: Error deleting wishlist: ${e.message}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Failed to delete wishlist: ${e.message}',
                    style: const TextStyle(
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
            margin: const EdgeInsets.only(
              top: 60,
              left: 16,
              right: 16,
              bottom: 0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ MyWishlistsScreen: Unexpected error deleting wishlist: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'An unexpected error occurred. Please try again.',
                    style: const TextStyle(
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
            margin: const EdgeInsets.only(
              top: 60,
              left: 16,
              right: 16,
              bottom: 0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
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

  /// Load wishlists from API
  Future<void> _loadWishlists() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Call API to get wishlists
      debugPrint('📡 MyWishlistsScreen: Loading wishlists...');
      final wishlistsData = await _wishlistRepository.getWishlists();
      debugPrint(
        '📡 MyWishlistsScreen: Received ${wishlistsData.length} wishlists',
      );

      // Convert API response to WishlistSummary objects
      final personalWishlists = <WishlistSummary>[];
      final eventWishlists = <WishlistSummary>[];

      for (final wishlistData in wishlistsData) {
        debugPrint(
          '📦 MyWishlistsScreen: Processing wishlist: ${wishlistData['name']}',
        );
        final wishlist = _convertToWishlistSummary(wishlistData);

        // Separate personal and event wishlists
        // If wishlist has eventId or eventName, it's an event wishlist
        if (wishlist.eventName != null || wishlistData['eventId'] != null) {
          eventWishlists.add(wishlist);
          debugPrint('   → Added to event wishlists');
        } else {
          personalWishlists.add(wishlist);
          debugPrint('   → Added to personal wishlists');
        }
      }

      debugPrint(
        '✅ MyWishlistsScreen: Personal: ${personalWishlists.length}, Event: ${eventWishlists.length}',
      );

      setState(() {
        _personalWishlists = personalWishlists;
        _eventWishlists = eventWishlists;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    e.message,
                    style: const TextStyle(
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
            margin: const EdgeInsets.only(
              top: 60,
              left: 16,
              right: 16,
              bottom: 0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load wishlists. Please try again.';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'An unexpected error occurred. Please try again.',
                    style: const TextStyle(
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
            margin: const EdgeInsets.only(
              top: 60,
              left: 16,
              right: 16,
              bottom: 0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      debugPrint('Load wishlists error: $e');
    }
  }

  /// Convert API response data to WishlistSummary
  WishlistSummary _convertToWishlistSummary(Map<String, dynamic> data) {
    // Parse privacy
    WishlistPrivacy privacy = WishlistPrivacy.public;
    final privacyStr = data['privacy']?.toString().toLowerCase() ?? 'public';
    switch (privacyStr) {
      case 'private':
        privacy = WishlistPrivacy.private;
        break;
      case 'friendsonly':
      case 'friends_only':
      case 'onlyinvited':
      case 'only_invited':
        privacy = WishlistPrivacy.onlyInvited;
        break;
      default:
        privacy = WishlistPrivacy.public;
    }

    // Parse dates
    DateTime? lastUpdated;
    if (data['updatedAt'] != null) {
      try {
        lastUpdated = DateTime.parse(data['updatedAt'].toString());
      } catch (e) {
        lastUpdated = DateTime.now();
      }
    } else if (data['updated_at'] != null) {
      try {
        lastUpdated = DateTime.parse(data['updated_at'].toString());
      } catch (e) {
        lastUpdated = DateTime.now();
      }
    } else {
      lastUpdated = DateTime.now();
    }

    DateTime? eventDate;
    if (data['eventDate'] != null) {
      try {
        eventDate = DateTime.parse(data['eventDate'].toString());
      } catch (e) {
        // Ignore parsing error
      }
    } else if (data['event_date'] != null) {
      try {
        eventDate = DateTime.parse(data['event_date'].toString());
      } catch (e) {
        // Ignore parsing error
      }
    }

    // Get item counts from stats if available, otherwise calculate from items
    int itemCount = 0;
    int purchasedCount = 0;

    if (data['stats'] != null && data['stats'] is Map) {
      // Use stats from API if available
      final stats = data['stats'] as Map<String, dynamic>;
      itemCount = stats['totalItems'] as int? ?? 0;
      purchasedCount = stats['purchasedItems'] as int? ?? 0;
    } else {
      // Fallback: calculate from items array
      final items = data['items'] as List<dynamic>? ?? [];
      itemCount = items.length;
      purchasedCount = items.where((item) {
        final status = item['status']?.toString().toLowerCase() ?? '';
        return status == 'purchased' || status == 'reserved';
      }).length;
    }

    return WishlistSummary(
      id: data['id']?.toString() ?? data['_id']?.toString() ?? '',
      name: data['name']?.toString() ?? 'Unnamed Wishlist',
      itemCount: itemCount,
      purchasedCount: purchasedCount,
      lastUpdated: lastUpdated,
      privacy: privacy,
      imageUrl: data['imageUrl']?.toString() ?? data['image_url']?.toString(),
      eventName:
          data['eventName']?.toString() ?? data['event_name']?.toString(),
      eventDate: eventDate,
    );
  }

  Future<void> _refreshWishlists() async {
    await _loadWishlists();
  }
}
