import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/widgets/primary_gradient_button.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/core/widgets/decorative_background.dart';
import 'package:wish_listy/core/widgets/confirmation_dialog.dart';
import 'package:wish_listy/core/widgets/unified_page_header.dart';
import 'package:wish_listy/core/widgets/unified_tab_bar.dart';
import 'package:wish_listy/core/widgets/unified_page_container.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';
import 'package:wish_listy/features/wishlists/data/repository/wishlist_repository.dart';
import 'package:wish_listy/features/wishlists/data/repository/guest_data_repository.dart';
import 'package:wish_listy/features/wishlists/data/models/wishlist_model.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import '../widgets/index.dart';

class MyWishlistsScreen extends StatefulWidget {
  const MyWishlistsScreen({super.key});

  @override
  MyWishlistsScreenState createState() => MyWishlistsScreenState();
}

class MyWishlistsScreenState extends State<MyWishlistsScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _mainTabController;
  late AnimationController _animationController;
  final TextEditingController _searchController = TextEditingController();

  // Wishlist data from API
  List<WishlistSummary> _personalWishlists = [];
  List<WishlistSummary> _allPersonalWishlists =
      []; // Store all personal wishlists for filtering
  bool _isLoading = false;
  String? _errorMessage;

  // Category filtering
  List<String> _availableCategories = [];
  String? _selectedCategory; // null means "All"
  Map<String, String> _wishlistIdToCategory = {}; // Map wishlist ID to category
  Map<String, int> _categoryCounts = {}; // Map category to item count

  final WishlistRepository _wishlistRepository = WishlistRepository();
  bool _hasLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _mainTabController = TabController(length: 2, vsync: this);
    _mainTabController.addListener(() {
      setState(() {
        // Reset category filter when switching tabs
        if (_mainTabController.index != 0) {
          _selectedCategory = null;
        }
      });
    });
    _initializeAnimations();
    _startAnimations();
    _loadWishlists();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Reload data when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _loadWishlists();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    debugPrint('🔄 MyWishlistsScreen: didChangeDependencies called');
    debugPrint('   isCurrent: ${ModalRoute.of(context)?.isCurrent}');
    debugPrint('   _hasLoadedOnce: $_hasLoadedOnce');

    // Reload data when screen becomes visible
    // Check if this is the current route (screen is visible)
    final isCurrent = ModalRoute.of(context)?.isCurrent ?? false;

    if (isCurrent && _hasLoadedOnce) {
      // Screen is now visible and we've loaded before, reload data
      debugPrint('   ✅ Reloading wishlists (screen is current)');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadWishlists();
        }
      });
    }
  }

  /// Public method to refresh wishlists (can be called from outside)
  void refreshWishlists() {
    if (mounted) {
      _loadWishlists();
    }
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
    WidgetsBinding.instance.removeObserver(this);
    _mainTabController.dispose();
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LocalizationService, AuthRepository>(
      builder: (context, localization, authService, child) {
        // For guest users - show full interface with local data
        // For authenticated users - show full interface with API data
        return Scaffold(
          backgroundColor: AppColors.background,
          body: UnifiedPageBackground(
            child: DecorativeBackground(
              showGifts: true,
              child: Column(
                children: [
                  // Unified Page Header with Integrated Tabs
                  UnifiedPageHeader(
                    title: localization.translate('wishlists.myWishlists'),
                    showSearch: true,
                    searchHint: localization.translate(
                      'wishlists.searchWishlists',
                    ),
                    searchController: _searchController,
                    onSearchChanged: (query) {
                      _onSearchChanged(query);
                    },
                    actions: [
                      HeaderAction(
                        icon: Icons.add_rounded,
                        iconColor: AppColors.primary, // Purple background
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.createWishlist,
                            arguments: {
                              'previousRoute': AppRoutes.myWishlists,
                            },
                          );
                        },
                      ),
                    ],
                    // Hide tabs completely for guest users
                    tabs: authService.isGuest
                        ? null
                        : [
                            UnifiedTab(
                              label: localization.translate(
                                'wishlists.myWishlists',
                              ),
                              icon: Icons.favorite_rounded,
                              badgeCount: _personalWishlists.length,
                            ),
                            UnifiedTab(
                              label: localization.translate(
                                'wishlists.friendsWishlists',
                              ),
                              icon: Icons.people_rounded,
                            ),
                          ],
                    selectedTabIndex: authService.isGuest
                        ? null
                        : _mainTabController.index,
                    onTabChanged: authService.isGuest
                        ? null
                        : (index) {
                            _mainTabController.animateTo(index);
                            setState(() {
                              // Reset category filter when switching tabs
                              if (index != 0) {
                                _selectedCategory = null;
                              }
                            });
                          },
                  ),

                  // Tab Content in rounded container
                  Expanded(
                    child: UnifiedPageContainer(
                      child: Column(
                        children: [
                          // Category Filter Tabs (only show if there are more than 2 wishlists)
                          // For guests, always show (no tabs), for authenticated users only on first tab
                          if ((authService.isGuest ||
                                  _mainTabController.index == 0) &&
                              _allPersonalWishlists.length > 2 &&
                              _availableCategories.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 16,
                                bottom: 8,
                              ),
                              child: _buildCategoryFilterTabs(),
                            ),
                          ],
                          // Main Content
                          Expanded(
                            child: _isLoading
                                ? _buildWishlistSkeletonList()
                                : _errorMessage != null
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                                          PrimaryGradientButton(
                                            text: 'Retry',
                                            icon: Icons.refresh,
                                            onPressed: _loadWishlists,
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : authService.isGuest
                                // For guest users: show only personal wishlists (no tabs)
                                ? PersonalWishlistsTabWidget(
                                    personalWishlists: _personalWishlists,
                                    onWishlistTap: _navigateToWishlistItems,
                                    onAddItem: _navigateToAddItem,
                                    onMenuAction: _handleWishlistAction,
                                    onCreateWishlist: () =>
                                        _navigateToCreateWishlist(
                                          isEvent: false,
                                        ),
                                    onRefresh: _refreshWishlists,
                                  )
                                // For authenticated users: show TabBarView with both tabs
                                : TabBarView(
                                    controller: _mainTabController,
                                    children: [
                                      PersonalWishlistsTabWidget(
                                        personalWishlists: _personalWishlists,
                                        onWishlistTap: _navigateToWishlistItems,
                                        onAddItem: _navigateToAddItem,
                                        onMenuAction: _handleWishlistAction,
                                        onCreateWishlist: () =>
                                            _navigateToCreateWishlist(
                                              isEvent: false,
                                            ),
                                        onRefresh: _refreshWishlists,
                                      ),
                                      FriendsWishlistsTabWidget(),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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
      arguments: {'isEvent': isEvent, 'previousRoute': AppRoutes.myWishlists},
    );
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
    debugPrint('✏️ MyWishlistsScreen: Edit wishlist clicked');
    debugPrint('   Wishlist ID: ${wishlist.id}');
    debugPrint('   Wishlist Name: ${wishlist.name}');

    // Navigate to create-wishlist screen with wishlistId for editing
    Navigator.pushNamed(
      context,
      AppRoutes.createWishlist,
      arguments: {
        'wishlistId': wishlist.id,
        'previousRoute': AppRoutes.myWishlists,
      },
    ).then((result) {
      // Refresh wishlists if the edit was successful
      if (result == true) {
        _loadWishlists();
      }
    });
  }

  void _shareWishlist(WishlistSummary wishlist) {
    // Check if user is guest
    final authService = Provider.of<AuthRepository>(context, listen: false);

    if (authService.isGuest) {
      // Show guest conversion dialog for sharing
      _showGuestShareDialog();
      return;
    }

    // TODO: Implement share functionality for authenticated users
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share wishlist: ${wishlist.name}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showGuestShareDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.share, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              'Save Your Wishlist & Share it!',
              style: AppStyles.headingMediumWithContext(
                context,
              ).copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'To get a unique shareable link and ensure your wishlist is saved permanently, please create a quick, free account.',
              style: AppStyles.bodyMediumWithContext(
                context,
              ).copyWith(color: AppColors.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Create Account & Get Link',
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.signup);
              },
              variant: ButtonVariant.gradient,
              gradientColors: [AppColors.primary, AppColors.secondary],
              size: ButtonSize.large,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Not Now',
                style: AppStyles.bodyMediumWithContext(
                  context,
                ).copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(WishlistSummary wishlist) {
    final itemCount = wishlist.itemCount;
    final itemCountText = itemCount > 0
        ? 'All $itemCount ${itemCount == 1 ? 'item' : 'items'} inside this wishlist will also be deleted permanently.'
        : 'All items inside this wishlist will also be deleted permanently.';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Wishlist?',
          style: AppStyles.headingSmall.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "${wishlist.name}"?',
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              itemCountText,
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'This action cannot be undone.',
              style: AppStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
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

      // Check if user is guest
      final authService = Provider.of<AuthRepository>(context, listen: false);

      if (authService.isGuest) {
        // Delete from local storage
        final guestDataRepo = Provider.of<GuestDataRepository>(
          context,
          listen: false,
        );
        await guestDataRepo.deleteWishlist(wishlist.id);
      } else {
        // Call API to delete wishlist
        await _wishlistRepository.deleteWishlist(wishlist.id);
      }

      debugPrint('✅ MyWishlistsScreen: Wishlist deleted successfully');

      // Reload wishlists to update the screen
      await _loadWishlists();

      if (mounted) {
        final localization = Provider.of<LocalizationService>(
          context,
          listen: false,
        );

        // Show success dialog with Lottie animation
        ConfirmationDialog.show(
          context: context,
          isSuccess: true,
          title: localization.translate(
            'wishlists.wishlistDeletedSuccessfully',
          ),
          message: 'Wishlist "${wishlist.name}" has been deleted successfully.',
          primaryActionLabel: localization.translate('app.done'),
          onPrimaryAction: () {
            // Dialog will close automatically
          },
          barrierDismissible: true,
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

  /// Load wishlists from local storage for guest users
  Future<void> _loadGuestWishlists() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final guestDataRepo = Provider.of<GuestDataRepository>(
        context,
        listen: false,
      );
      final wishlists = await guestDataRepo.getAllWishlists();

      // Convert to WishlistSummary format
      // For guest users, we need to load items separately to get accurate counts
      final personalWishlists = <WishlistSummary>[];

      // Store category data for filtering
      final categoryMap = <String, String>{};
      final categoryCounts = <String, int>{};
      int totalCount = 0;

      for (final wishlist in wishlists) {
        // Load items for this wishlist to get accurate count
        final items = await guestDataRepo.getWishlistItems(wishlist.id);
        final purchasedCount = items
            .where((item) => item.status == ItemStatus.purchased)
            .length;

        // Extract category from wishlist model (default to 'general' if null)
        final category = wishlist.category ?? 'general';
        final itemCount = items.length;
        totalCount += itemCount;

        // Store category mapping
        categoryMap[wishlist.id] = category;
        categoryCounts[category] = (categoryCounts[category] ?? 0) + itemCount;

        personalWishlists.add(
          WishlistSummary(
            id: wishlist.id,
            name: wishlist.name,
            itemCount: itemCount, // Use actual items count from Hive
            purchasedCount:
                purchasedCount, // Use actual purchased count from Hive
            lastUpdated: wishlist.updatedAt,
            privacy: wishlist.visibility == WishlistVisibility.public
                ? WishlistPrivacy.public
                : wishlist.visibility == WishlistVisibility.private
                ? WishlistPrivacy.private
                : WishlistPrivacy.onlyInvited,
            category: category, // Use actual category from wishlist model
          ),
        );
      }

      // Build category set from unique categories
      final categorySet = categoryMap.values.toSet();
      categoryCounts['all'] = totalCount; // Store total count for "All" filter

      setState(() {
        _personalWishlists = personalWishlists;
        _allPersonalWishlists = List.from(personalWishlists);
        _wishlistIdToCategory = categoryMap;
        _availableCategories = categorySet.toList()..sort();
        _categoryCounts = categoryCounts; // Store category counts for filter tabs
        _isLoading = false;
        _hasLoadedOnce = true;
      });

      debugPrint(
        '📂 MyWishlistsScreen: Found ${categorySet.length} unique categories: ${categorySet.toList()..sort()}',
      );
      debugPrint(
        '📊 MyWishlistsScreen: Category counts: $categoryCounts',
      );

      debugPrint(
        '✅ MyWishlistsScreen: Loaded ${personalWishlists.length} guest wishlists',
      );
    } catch (e) {
      debugPrint('❌ MyWishlistsScreen: Error loading guest wishlists: $e');
      setState(() {
        _errorMessage = 'Failed to load wishlists';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadWishlists() async {
    // Check if user is guest
    final authService = Provider.of<AuthRepository>(context, listen: false);

    if (authService.isGuest) {
      await _loadGuestWishlists();
      return;
    }

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

      for (final wishlistData in wishlistsData) {
        debugPrint(
          '📦 MyWishlistsScreen: Processing wishlist: ${wishlistData['name']}',
        );
        final wishlist = _convertToWishlistSummary(wishlistData);

        // Only add personal wishlists (exclude event wishlists)
        if (wishlist.eventName == null && wishlistData['eventId'] == null) {
          personalWishlists.add(wishlist);
          debugPrint('   → Added to personal wishlists');
        }
      }

      debugPrint('✅ MyWishlistsScreen: Personal: ${personalWishlists.length}');

      // Store original wishlist data for category extraction and count items
      final Map<String, String> wishlistIdToCategory = {};
      final Map<String, int> categoryCounts = {};
      int totalCount = 0;

      for (final wishlistData in wishlistsData) {
        final id =
            wishlistData['id']?.toString() ??
            wishlistData['_id']?.toString() ??
            '';
        final category = wishlistData['category']?.toString();
        final items = wishlistData['items'] as List<dynamic>? ?? [];
        final itemCount = items.length;
        totalCount += itemCount;

        if (id.isNotEmpty && category != null && category.isNotEmpty) {
          wishlistIdToCategory[id] = category;
          categoryCounts[category] =
              (categoryCounts[category] ?? 0) + itemCount;
        }
      }

      // Extract unique categories
      final categoriesSet = wishlistIdToCategory.values.toSet();
      final categories = categoriesSet.toList()..sort();

      debugPrint(
        '📂 MyWishlistsScreen: Found ${categories.length} unique categories: $categories',
      );

      setState(() {
        _allPersonalWishlists = personalWishlists;
        _availableCategories = categories;
        _wishlistIdToCategory = wishlistIdToCategory;
        _categoryCounts = categoryCounts;
        _categoryCounts['all'] = totalCount; // Store total count
        _isLoading = false;
        _hasLoadedOnce = true;
        // Apply current filter if any
        _applyCategoryFilter();
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
      case 'friends':
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
      category: data['category']?.toString(), // Added category field
    );
  }

  Future<void> _refreshWishlists() async {
    await _loadWishlists();
  }

  /// Handle search query change (works for both guest and authenticated users)
  /// Performs local search on wishlists stored in memory
  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      // Reset to all wishlists (respecting category filter)
      _applyCategoryFilter();
      return;
    }

    // Filter wishlists based on search query (local search)
    final filtered = _allPersonalWishlists.where((wishlist) {
      final searchLower = query.toLowerCase();
      return wishlist.name.toLowerCase().contains(searchLower) ||
          (wishlist.category?.toLowerCase().contains(searchLower) ?? false);
    }).toList();

    setState(() {
      _personalWishlists = filtered;
    });
  }

  /// Apply category filter to personal wishlists
  void _applyCategoryFilter() {
    if (_selectedCategory == null) {
      // Show all wishlists
      _personalWishlists = List.from(_allPersonalWishlists);
    } else {
      // Filter by selected category
      _personalWishlists = _allPersonalWishlists.where((wishlist) {
        final category = _wishlistIdToCategory[wishlist.id];
        return category == _selectedCategory;
      }).toList();
    }
  }

  /// Build category filter tabs
  Widget _buildCategoryFilterTabs() {
    return Consumer<LocalizationService>(
      builder: (context, localization, _) {
        final isRTL = localization.isRTL;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Directionality(
            textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Filter Icon
                Icon(
                  Icons.filter_list_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                // "All" tab
                _buildCategoryChip(
                  label: 'All',
                  category: null,
                  isSelected: _selectedCategory == null,
                  icon: Icons.list_rounded,
                  count: _categoryCounts['all'] ?? 0,
                ),
                const SizedBox(width: 8),
                // Category tabs
                ..._availableCategories.map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildCategoryChip(
                      label: _getCategoryDisplayName(category),
                      category: category,
                      isSelected: _selectedCategory == category,
                      icon: _getCategoryIcon(category),
                      count: _categoryCounts[category] ?? 0,
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build a category filter chip
  Widget _buildCategoryChip({
    required String label,
    required String? category,
    required bool isSelected,
    IconData? icon,
    int count = 0,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
          _applyCategoryFilter();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.primary : AppColors.textTertiary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppStyles.bodySmall.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textTertiary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: AppStyles.caption.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Get display name for category
  String _getCategoryDisplayName(String category) {
    switch (category.toLowerCase()) {
      case 'general':
        return 'General';
      case 'birthday':
        return 'Birthday';
      case 'wedding':
        return 'Wedding';
      case 'graduation':
        return 'Graduation';
      case 'anniversary':
        return 'Anniversary';
      case 'holiday':
        return 'Holiday';
      case 'babyshower':
        return 'Baby Shower';
      case 'housewarming':
        return 'Housewarming';
      default:
        // Return category as is (no transformation)
        return category;
    }
  }

  /// Get icon for category
  IconData? _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'general':
        return Icons.category_outlined;
      case 'birthday':
        return Icons.cake_outlined;
      case 'wedding':
        return Icons.favorite_outline;
      case 'graduation':
        return Icons.school_outlined;
      case 'anniversary':
        return Icons.celebration_outlined;
      case 'holiday':
        return Icons.card_giftcard_outlined;
      case 'babyshower':
        return Icons.child_care_outlined;
      case 'housewarming':
        return Icons.home_outlined;
      case 'custom':
        return Icons.edit_outlined;
      default:
        return Icons.label_outline;
    }
  }

  /// Build skeleton loading list for wishlist cards
  Widget _buildWishlistSkeletonList() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // Create pulsing effect using sine wave - lighter and smoother
        final pulseValue =
            (0.15 +
            (0.2 *
                (0.5 +
                    0.5 * (1 + (2 * _animationController.value - 1).abs()))));

        return RefreshIndicator(
          onRefresh: _refreshWishlists,
          color: AppColors.primary,
          child: ListView.separated(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 16 + MediaQuery.of(context).padding.bottom + 100, // Extra space for bottom nav bar
            ),
            itemCount: 3, // Show 3 skeleton cards
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _buildWishlistCardSkeleton(pulseValue);
            },
          ),
        );
      },
    );
  }

  /// Build a single wishlist card skeleton
  Widget _buildWishlistCardSkeleton(double pulseValue) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.textTertiary.withOpacity(0.05),
              offset: const Offset(0, 5),
              blurRadius: 15,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header Section (Pastel Purple Background)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.04),
              ),
              child: Row(
                children: [
                  // Icon Skeleton - Light purple gradient
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary.withOpacity(
                            0.08 + pulseValue * 0.05,
                          ),
                          AppColors.primary.withOpacity(
                            0.12 + pulseValue * 0.05,
                          ),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Title and Subtitle Skeleton
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 180,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(
                              0.1 + pulseValue * 0.05,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 120,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(
                              0.08 + pulseValue * 0.03,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Badge Skeleton
                  Container(
                    width: 50,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(
                        0.1 + pulseValue * 0.05,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ),
            // Body Section (White Background)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: Colors.white),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Row Skeleton
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatSkeleton(pulseValue),
                      _buildStatSkeleton(pulseValue),
                      _buildStatSkeleton(pulseValue),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Progress Bar Skeleton
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(
                        0.06 + pulseValue * 0.03,
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Action Buttons Skeleton
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(
                              0.06 + pulseValue * 0.03,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(
                              0.06 + pulseValue * 0.03,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build a stat column skeleton
  Widget _buildStatSkeleton(double pulseValue) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.06 + pulseValue * 0.03),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 30,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1 + pulseValue * 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 50,
          height: 12,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08 + pulseValue * 0.03),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ],
    );
  }
}
