import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/widgets/primary_gradient_button.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/core/widgets/decorative_background.dart';
import 'package:wish_listy/core/widgets/unified_snackbar.dart';
import 'package:wish_listy/core/widgets/unified_page_header.dart';
import 'package:wish_listy/core/widgets/unified_tab_bar.dart';
import 'package:wish_listy/core/widgets/unified_page_container.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/services/deep_link_service.dart';
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
    with TickerProviderStateMixin, WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;
  
  late TabController _mainTabController;
  late AnimationController _animationController;
  final TextEditingController _searchController = TextEditingController();

  // Wishlist data from API
  List<WishlistSummary> _personalWishlists = [];
  List<WishlistSummary> _allPersonalWishlists =
      []; // Store all personal wishlists for filtering
  bool _isLoading = false;
  String? _errorMessage;
  
  // Reservations data
  List<WishlistItem> _myReservations = [];
  bool _isLoadingReservations = false;

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
      if (mounted) {
      setState(() {
        // Reset category filter when switching tabs
        if (_mainTabController.index != 0) {
          _selectedCategory = null;
        }
      });
      }
    });
    _initializeAnimations();
    _startAnimations();
    // Don't load data in initState - wait for screen to become visible
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

    // Only load data when screen becomes visible for the first time
    final isCurrent = ModalRoute.of(context)?.isCurrent ?? false;

    if (isCurrent && !_hasLoadedOnce) {
      _hasLoadedOnce = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadWishlists();
          _fetchMyReservations();
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
    super.build(context); // Keep alive
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
                            ),
                            UnifiedTab(
                              label: Provider.of<LocalizationService>(context, listen: false).translate('cards.reservations'),
                              icon: Icons.shopping_bag_outlined,
                            ),
                          ],
                    selectedTabIndex: authService.isGuest
                        ? null
                        : _mainTabController.index,
                    onTabChanged: authService.isGuest
                        ? null
                        : (index) {
                            _mainTabController.animateTo(index);
                            if (mounted) {
                            setState(() {
                              // Reset category filter when switching tabs
                              if (index != 0) {
                                _selectedCategory = null;
                              }
                            });
                            }
                          },
                  ),

                  // Tab Content in rounded container
                  Expanded(
                    child: UnifiedPageContainer(
                      backgroundColor: (authService.isGuest && _personalWishlists.isEmpty) || 
                                     (!authService.isGuest && _mainTabController.index == 0 && _personalWishlists.isEmpty)
                        ? Colors.transparent
                        : null,
                      showShadow: !((authService.isGuest && _personalWishlists.isEmpty) || 
                                   (!authService.isGuest && _mainTabController.index == 0 && _personalWishlists.isEmpty)),
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
                              child: Consumer<LocalizationService>(
                                builder: (context, localization, _) {
                                  return CategoryFilterTabsWidget(
                                    categories: _availableCategories,
                                    categoryCounts: _categoryCounts,
                                    selectedCategory: _selectedCategory,
                                    onCategorySelected: (c) {
                                      if (mounted) {
                                        setState(() {
                                          _selectedCategory = c;
                                          _applyCategoryFilter();
                                        });
                                      }
                                    },
                                    localization: localization,
                                  );
                                },
                              ),
                            ),
                          ],
                          // Main Content
                          Expanded(
                            child: _isLoading
                                ? WishlistSkeletonWidget(
                                    animationController: _animationController,
                                    onRefresh: _refreshWishlists,
                                  )
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
                                    guestStyle: true,
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
                                      ReservationsTabWidget(
                                        reservations: _myReservations,
                                        isLoading: _isLoadingReservations,
                                        onCancelReservation: _cancelReservation,
                                        onItemTap: (item) {
                                          // Navigate to ItemDetailsScreen (the main one with all logic)
                                          Navigator.pushNamed(
                                            context,
                                            AppRoutes.itemDetails,
                                            arguments: item,
                                          );
                                        },
                                        onRefresh: _fetchMyReservations,
                                      ),
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

  void _navigateToAddItem(WishlistSummary wishlist) async {
    await Navigator.pushNamed(context, AppRoutes.addItem, arguments: wishlist.id);
    
    // Reload wishlists after returning from AddItemScreen to show new items
    // Add a small delay to ensure Hive write is complete for guest users
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 200));
    await _loadWishlists();
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

  Future<void> _shareWishlist(WishlistSummary wishlist) async {
    // Check if user is guest
    final authService = Provider.of<AuthRepository>(context, listen: false);

    if (authService.isGuest) {
      // Show guest conversion dialog for sharing
      _showGuestShareDialog();
      return;
    }

    // Share wishlist using deep link
    await DeepLinkService.shareWishlist(
      wishlistId: wishlist.id,
      wishlistName: wishlist.name,
    );
  }

  void _showGuestShareDialog() {
    final localization = Provider.of<LocalizationService>(context, listen: false);
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
              localization.translate('wishlists.saveYourWishlistAndShare') ?? 'Save Your Wishlist & Share it!',
              style: AppStyles.headingMediumWithContext(
                context,
              ).copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              localization.translate('wishlists.getShareableLinkDescription') ?? 'To get a unique shareable link and ensure your wishlist is saved permanently, please create a quick, free account.',
              style: AppStyles.bodyMediumWithContext(
                context,
              ).copyWith(color: AppColors.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: localization.translate('wishlists.createAccountGetLink') ?? 'Create Account & Get Link',
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
                localization.translate('dialogs.notNow'),
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
    final localization = Provider.of<LocalizationService>(context, listen: false);
    final itemCount = wishlist.itemCount;
    final itemCountText = itemCount > 0
        ? 'All $itemCount ${itemCount == 1 ? 'item' : 'items'} inside this wishlist will also be deleted permanently.'
        : 'All items inside this wishlist will also be deleted permanently.';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          localization.translate('wishlists.deleteWishlist'),
          style: AppStyles.headingSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localization.translate(
                'wishlists.deleteWishlistConfirmation',
                args: {'name': wishlist.name},
              ),
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            if (itemCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                itemCountText,
                style: AppStyles.bodyMedium.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
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
              _deleteWishlist(wishlist);
            },
            child: Text(
              localization.translate('app.delete'),
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
    final localization = Provider.of<LocalizationService>(context, listen: false);
    
    // Show loading snackbar
    ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? loadingSnackbar;
    if (mounted) {
      loadingSnackbar = UnifiedSnackbar.showLoading(
        context: context,
        message: localization.translate('dialogs.deletingWishlist'),
      );
    }

    try {
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

      // Remove from local state immediately for instant UI update
      setState(() {
        _personalWishlists.removeWhere((w) => w.id == wishlist.id);
        _allPersonalWishlists.removeWhere((w) => w.id == wishlist.id);
      });

      // Reload wishlists to ensure data consistency
      await _loadWishlists();

      // Ensure we stay on the "My Wishlists" tab (index 0) after deletion
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _mainTabController.index != 0) {
            _mainTabController.animateTo(0);
          }
        });
      }

      // Show success snackbar
      if (mounted) {
        UnifiedSnackbar.hideCurrent(context);
        UnifiedSnackbar.showSuccess(
          context: context,
          message: localization.translate('wishlists.wishlistDeletedSuccessfully'),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        UnifiedSnackbar.hideCurrent(context);
        UnifiedSnackbar.showError(
          context: context,
          message: '${localization.translate('wishlists.failedToDeleteWishlist')}: ${e.message}',
        );
      }
    } catch (e) {
      if (mounted) {
        UnifiedSnackbar.hideCurrent(context);
        UnifiedSnackbar.showError(
          context: context,
          message: localization.translate('wishlists.failedToDeleteWishlistTryAgain'),
        );
      }
    }
  }

  /// Load wishlists from local storage for guest users
  Future<void> _loadGuestWishlists({bool forceShowSkeleton = false}) async {
    // Smart Loading: Only show skeleton if data doesn't exist yet
    final hasExistingData = _personalWishlists.isNotEmpty;
    if (!hasExistingData || forceShowSkeleton) {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }
    } else {
      debugPrint('🔄 MyWishlistsScreen (Guest): Background refresh (no skeleton)');
      if (_errorMessage != null && mounted) {
        setState(() {
          _errorMessage = null;
        });
      }
    }

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
            description: wishlist.description,
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
            previewItems: items.take(3).toList(),
          ),
        );
      }

      // Build category set from unique categories
      final categorySet = categoryMap.values.toSet();
      categoryCounts['all'] = totalCount; // Store total count for "All" filter

      if (mounted) {
      setState(() {
        _personalWishlists = personalWishlists;
        _allPersonalWishlists = List.from(personalWishlists);
        _wishlistIdToCategory = categoryMap;
        _availableCategories = categorySet.toList()..sort();
        _categoryCounts = categoryCounts; // Store category counts for filter tabs
        _isLoading = false;
        _hasLoadedOnce = true;
      });
      }

    } catch (e) {
      if (mounted) {
      setState(() {
        _errorMessage = 'Failed to load wishlists';
        _isLoading = false;
      });
      }
    }
  }

  Future<void> _loadWishlists({bool forceShowSkeleton = false}) async {
    // Check if user is guest
    final authService = Provider.of<AuthRepository>(context, listen: false);

    if (authService.isGuest) {
      await _loadGuestWishlists(forceShowSkeleton: forceShowSkeleton);
      return;
    }

    // Smart Loading: Only show skeleton if data doesn't exist yet
    // If data exists, refresh in background without showing skeleton
    final hasExistingData = _personalWishlists.isNotEmpty;
    if (!hasExistingData || forceShowSkeleton) {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }
    } else {
      debugPrint('🔄 MyWishlistsScreen: Background refresh (no skeleton)');
      // Still clear error message
      if (_errorMessage != null && mounted) {
        setState(() {
          _errorMessage = null;
        });
      }
    }

    try {
      // Call API to get wishlists

      final wishlistsData = await _wishlistRepository.getWishlists();

      // Convert API response to WishlistSummary objects
      final personalWishlists = <WishlistSummary>[];

      for (final wishlistData in wishlistsData) {

        final wishlist = _convertToWishlistSummary(wishlistData);

        // Only add personal wishlists (exclude event wishlists)
        if (wishlist.eventName == null && wishlistData['eventId'] == null) {
          personalWishlists.add(wishlist);

        }
      }

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

      if (mounted) {
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
      }
    } on ApiException catch (e) {
      if (mounted) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
      }

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
      if (mounted) {
      setState(() {
        _errorMessage = 'Failed to load wishlists. Please try again.';
        _isLoading = false;
      });
      }

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

  /// Fetch my reservations (items I reserved from other wishlists)
  Future<void> _fetchMyReservations() async {
    final authService = Provider.of<AuthRepository>(context, listen: false);
    if (authService.isGuest) {
      return; // Guests don't have reservations
    }

    if (mounted) {
      setState(() {
        _isLoadingReservations = true;
      });
    }

    try {
      final reservationsData = await _wishlistRepository.fetchMyReservations();
      
      final reservations = reservationsData
          .map((itemData) => WishlistItem.fromJson(itemData))
          .toList();

      if (mounted) {
        setState(() {
          _myReservations = reservations;
          _isLoadingReservations = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingReservations = false;
        });
      }
      // Silently fail - reservations are not critical
    }
  }

  /// Cancel a reservation (un-reserve an item)
  Future<void> _cancelReservation(WishlistItem item) async {
    // Optimistic update
    setState(() {
      _myReservations.removeWhere((i) => i.id == item.id);
    });

    try {
      // Item is reserved (we're in reservations list), so unreserve it
      await _wishlistRepository.toggleReservation(
        item.id,
        action: 'cancel', // Explicitly pass 'cancel' action
      );
      
      // Refresh reservations to ensure consistency
      await _fetchMyReservations();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Reservation cancelled',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Revert optimistic update on error
      if (mounted) {
        final localization = Provider.of<LocalizationService>(context, listen: false);
        setState(() {
          _myReservations.add(item);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localization.translate('dialogs.failedToCancelReservation')}: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
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
    List<WishlistItem> previewItems = const <WishlistItem>[];

    if (data['stats'] != null && data['stats'] is Map) {
      // Use stats from API if available
      final stats = data['stats'] as Map<String, dynamic>;
      itemCount = stats['totalItems'] as int? ?? 0;
      purchasedCount = stats['purchasedItems'] as int? ?? 0;
      // Still try to build preview items from items array if present.
      final rawItems = data['items'] as List<dynamic>? ?? const [];
      final parsed = <WishlistItem>[];
      for (final it in rawItems) {
        if (it is Map<String, dynamic>) {
          parsed.add(WishlistItem.fromJson(it));
        }
      }
      previewItems = parsed.take(3).toList();
    } else {
      // Fallback: calculate from items array
      final items = data['items'] as List<dynamic>? ?? [];
      itemCount = items.length;
      purchasedCount = items.where((item) {
        final status = item['status']?.toString().toLowerCase() ?? '';
        return status == 'purchased' || status == 'reserved';
      }).length;

      // Build preview items from the first 3 items (for wishlist cards bubbles).
      final parsed = <WishlistItem>[];
      for (final it in items) {
        if (it is Map<String, dynamic>) {
          parsed.add(WishlistItem.fromJson(it));
        }
      }
      previewItems = parsed.take(3).toList();
    }

    return WishlistSummary(
      id: data['id']?.toString() ?? data['_id']?.toString() ?? '',
      name: data['name']?.toString() ?? 'Unnamed Wishlist',
      description: data['description']?.toString(),
      itemCount: itemCount,
      purchasedCount: purchasedCount,
      lastUpdated: lastUpdated,
      privacy: privacy,
      imageUrl: data['imageUrl']?.toString() ?? data['image_url']?.toString(),
      eventName:
          data['eventName']?.toString() ?? data['event_name']?.toString(),
      eventDate: eventDate,
      category: data['category']?.toString(), // Added category field
      previewItems: previewItems,
    );
  }

  Future<void> _refreshWishlists() async {
    await _loadWishlists();
    await _fetchMyReservations();
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

    if (mounted) {
    setState(() {
      _personalWishlists = filtered;
    });
    }
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

}
