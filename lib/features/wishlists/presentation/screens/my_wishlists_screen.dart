import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
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
import '../widgets/index.dart';
import '../widgets/guest_wishlists_view_widget.dart';

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
  List<WishlistSummary> _eventWishlists = [];
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
    // Reload data when screen becomes visible (useful for IndexedStack)
    // This ensures data is fresh when navigating back to this screen
    // Only reload if we've already loaded once (to avoid double loading in initState)
    if (_hasLoadedOnce) {
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
          body: UnifiedPageBackground(
            child: DecorativeBackground(
              showGifts: true,
              child: Column(
                children: [
                  // Unified Page Header
                  UnifiedPageHeader(
                    title: localization.translate('wishlists.myWishlists'),
                    titleIcon: Icons.favorite_rounded,
                    titleIconColor: AppColors.primary,
                    showSearch: true,
                    searchHint: localization.translate(
                      'wishlists.searchWishlists',
                    ),
                    searchController: _searchController,
                    onSearchChanged: (query) {
                      // Handle search query change
                      // You can add search filtering logic here
                    },
                  ),

                  // Unified Tab Bar
                  UnifiedTabBar(
                    tabs: [
                      UnifiedTab(
                        label: localization.translate('wishlists.myWishlists'),
                        icon: Icons.favorite_rounded,
                        badgeCount:
                            _personalWishlists.length + _eventWishlists.length,
                      ),
                      UnifiedTab(
                        label: localization.translate(
                          'wishlists.friendsWishlists',
                        ),
                        icon: Icons.people_rounded,
                      ),
                    ],
                    selectedIndex: _mainTabController.index,
                    onTabChanged: (index) {
                      _mainTabController.animateTo(index);
                      setState(() {
                        // Reset category filter when switching tabs
                        if (index != 0) {
                          _selectedCategory = null;
                        }
                      });
                    },
                  ),

                  // Category Filter Tabs (only show if there are categories and on Personal tab)
                  if (_mainTabController.index == 0 &&
                      _availableCategories.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildCategoryFilterTabs(),
                  ],

                  // Tab Content in rounded container
                  Expanded(
                    child: UnifiedPageContainer(
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
      arguments: {'isEvent': isEvent},
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
      arguments: {'wishlistId': wishlist.id},
    ).then((result) {
      // Refresh wishlists if the edit was successful
      if (result == true) {
        _loadWishlists();
      }
    });
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
        _eventWishlists = eventWishlists;
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
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
            color: isSelected ? AppColors.primary : AppColors.borderLight,
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
}
