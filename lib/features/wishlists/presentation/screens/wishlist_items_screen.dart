import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/widgets/primary_gradient_button.dart';
import 'package:wish_listy/core/widgets/decorative_background.dart';
import 'package:wish_listy/core/widgets/animated_background.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/features/wishlists/data/models/wishlist_model.dart';
import 'package:wish_listy/features/wishlists/data/repository/wishlist_repository.dart';
import 'package:wish_listy/features/wishlists/data/repository/guest_data_repository.dart';
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import '../widgets/wishlist_item_card_widget.dart';
import '../widgets/empty_wishlist_state_widget.dart';
import '../widgets/empty_search_state_widget.dart';
import '../widgets/wishlist_filter_chip_widget.dart';

class WishlistItemsScreen extends StatefulWidget {
  final String wishlistName;
  final String wishlistId;
  final int totalItems;
  final int purchasedItems;
  final bool isFriendWishlist;
  final String? friendName;

  const WishlistItemsScreen({
    super.key,
    required this.wishlistName,
    required this.wishlistId,
    required this.totalItems,
    required this.purchasedItems,
    this.isFriendWishlist = false,
    this.friendName,
  });

  @override
  _WishlistItemsScreenState createState() => _WishlistItemsScreenState();
}

class _WishlistItemsScreenState extends State<WishlistItemsScreen> {
  String _selectedFilter = 'all';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  // Wishlist data from API
  List<WishlistItem> _items = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _totalItems = 0;
  int _purchasedItems = 0;
  String _wishlistName = '';
  String _category = '';
  String _privacy = '';
  DateTime? _createdAt;

  final WishlistRepository _wishlistRepository = WishlistRepository();

  @override
  void initState() {
    super.initState();
    _loadWishlistDetails();
  }

  /// Load wishlist details and items from API or local storage
  Future<void> _loadWishlistDetails() async {


    // Validate wishlistId
    if (widget.wishlistId.isEmpty) {

      setState(() {
        _errorMessage = 'Invalid wishlist ID. Please try again.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _wishlistName = widget.wishlistName;
      _totalItems = widget.totalItems;
      _purchasedItems = widget.purchasedItems;
    });

    try {
      // Check if user is guest
      final authService = Provider.of<AuthRepository>(context, listen: false);
      Map<String, dynamic> wishlistData;

      if (authService.isGuest) {
        // Load from local storage for guests

        final guestDataRepo = Provider.of<GuestDataRepository>(
          context,
          listen: false,
        );
        final wishlist = await guestDataRepo.getWishlistById(widget.wishlistId);

        if (wishlist == null) {
          throw Exception('Wishlist not found');
        }

        // Load items for this wishlist
        final items = await guestDataRepo.getWishlistItems(widget.wishlistId);

        // Convert Wishlist model to Map format for consistency
        wishlistData = {
          'id': wishlist.id,
          'name': wishlist.name,
          'description': wishlist.description,
          'privacy': wishlist.visibility.toString().split('.').last,
          'category': 'general', // Default category for guest wishlists
          'createdAt': wishlist.createdAt.toIso8601String(),
          'updatedAt': wishlist.updatedAt.toIso8601String(),
          'items': items
              .map(
                (item) => {
                  'id': item.id,
                  'name': item.name,
                  'description': item.description,
                  'link': item.link,
                  'image_url': item.imageUrl,
                  'priority': item.priority.toString().split('.').last,
                  'status': item.status.toString().split('.').last,
                  'createdAt': item.createdAt.toIso8601String(),
                  'updatedAt': item.updatedAt.toIso8601String(),
                },
              )
              .toList(),
          'stats': {
            'totalItems': items.length,
            'purchasedItems': items
                .where((item) => item.status == ItemStatus.purchased)
                .length,
          },
        };

      } else {
        // Load from API for authenticated users

        // Call API to get wishlist details
        wishlistData = await _wishlistRepository.getWishlistById(
          widget.wishlistId,
        );
      }


      // Validate response
      if (wishlistData.isEmpty) {

        final authService = Provider.of<AuthRepository>(context, listen: false);
        throw Exception(
          authService.isGuest
              ? 'Wishlist not found in local storage'
              : 'Empty response from API',
        );
      }

      // Handle both direct fields and nested wishlist object
      // The repository already extracts the wishlist object, so we use it directly
      // But also check if it's wrapped in 'wishlist' or 'data' keys
      Map<String, dynamic> data;
      if (wishlistData.containsKey('wishlist')) {
        // Response is wrapped: {success: true, wishlist: {...}}
        data = wishlistData['wishlist'] as Map<String, dynamic>;

      } else if (wishlistData.containsKey('data')) {
        // Response is wrapped: {success: true, data: {...}}
        data = wishlistData['data'] as Map<String, dynamic>;

      } else {
        // Response is the wishlist object directly
        data = wishlistData;

      }

      if (data.isEmpty) {

        final authService = Provider.of<AuthRepository>(context, listen: false);
        throw Exception(
          authService.isGuest
              ? 'Invalid wishlist data format'
              : 'Invalid response format from API',
        );
      }


      // Parse items from response
      final itemsList = data['items'] as List<dynamic>? ?? [];

      final items = <WishlistItem>[];
      for (var i = 0; i < itemsList.length; i++) {
        try {
          final itemData = itemsList[i];
          if (itemData is Map<String, dynamic>) {
            final item = _convertToWishlistItem(itemData);
            items.add(item);
          }
        } catch (e) {

        }
      }

      // Get stats if available
      int totalItems = widget.totalItems;
      int purchasedItems = widget.purchasedItems;

      if (data['stats'] != null && data['stats'] is Map) {
        final stats = data['stats'] as Map<String, dynamic>;
        totalItems = stats['totalItems'] as int? ?? items.length;
        purchasedItems = stats['purchasedItems'] as int? ?? 0;
      } else {
        totalItems = items.length;
        purchasedItems = items
            .where((item) => item.status == ItemStatus.purchased)
            .length;
      }

      // Parse additional wishlist info
      String category = data['category']?.toString().trim() ?? '';
      String privacy = data['privacy']?.toString().trim() ?? '';
      DateTime? createdAt;
      if (data['createdAt'] != null) {
        try {
          createdAt = DateTime.parse(data['createdAt'].toString());
        } catch (e) {

        }
      }

      if (mounted) {
        setState(() {
          _items = items;
          _totalItems = totalItems;
          _purchasedItems = purchasedItems;
          _wishlistName = data['name']?.toString() ?? widget.wishlistName;
          _category = category;
          _privacy = privacy;
          _createdAt = createdAt;
          _isLoading = false; // CRITICAL: Set loading to false
          _errorMessage = null; // Clear any previous errors
        });

      } else {

      }
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
        _errorMessage = e.toString().contains('Exception')
            ? e.toString().replaceFirst('Exception: ', '')
            : 'Failed to load wishlist. Please try again.';
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
                    _errorMessage ??
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
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                _loadWishlistDetails();
              },
            ),
          ),
        );
      }
    }
  }

  /// Convert item data (from API or Hive) to WishlistItem
  WishlistItem _convertToWishlistItem(Map<String, dynamic> data) {
    // Parse priority
    ItemPriority priority = ItemPriority.medium;
    final priorityStr = data['priority']?.toString().toLowerCase() ?? 'medium';
    switch (priorityStr) {
      case 'high':
        priority = ItemPriority.high;
        break;
      case 'low':
        priority = ItemPriority.low;
        break;
      case 'urgent':
        priority = ItemPriority.urgent;
        break;
      default:
        priority = ItemPriority.medium;
    }

    // Parse status
    // API can return isPurchased: true (boolean) OR status: "purchased"
    ItemStatus status = ItemStatus.desired;
    if (data['isPurchased'] == true) {
      status = ItemStatus.purchased;
    } else {
      final statusStr = data['status']?.toString().toLowerCase() ?? 'desired';
      switch (statusStr) {
        case 'purchased':
          status = ItemStatus.purchased;
          break;
        case 'reserved':
          status = ItemStatus.reserved;
          break;
        default:
          status = ItemStatus.desired;
      }
    }

    // Parse dates
    DateTime createdAt = DateTime.now();
    if (data['createdAt'] != null) {
      try {
        createdAt = DateTime.parse(data['createdAt'].toString());
      } catch (e) {
        createdAt = DateTime.now();
      }
    } else if (data['created_at'] != null) {
      try {
        createdAt = DateTime.parse(data['created_at'].toString());
      } catch (e) {
        createdAt = DateTime.now();
      }
    }

    DateTime updatedAt = DateTime.now();
    if (data['updatedAt'] != null) {
      try {
        updatedAt = DateTime.parse(data['updatedAt'].toString());
      } catch (e) {
        updatedAt = DateTime.now();
      }
    } else if (data['updated_at'] != null) {
      try {
        updatedAt = DateTime.parse(data['updated_at'].toString());
      } catch (e) {
        updatedAt = DateTime.now();
      }
    }

    DateTime? purchasedAt;
    if (data['purchasedAt'] != null) {
      try {
        purchasedAt = DateTime.parse(data['purchasedAt'].toString());
      } catch (e) {
        // Ignore
      }
    } else if (data['purchased_at'] != null) {
      try {
        purchasedAt = DateTime.parse(data['purchased_at'].toString());
      } catch (e) {
        // Ignore
      }
    }

    return WishlistItem(
      id: data['id']?.toString() ?? data['_id']?.toString() ?? '',
      wishlistId: widget.wishlistId,
      name: data['name']?.toString() ?? 'Unnamed Item',
      description: data['description']?.toString(),
      link: data['link']?.toString() ?? data['url']?.toString(),
      imageUrl: data['imageUrl']?.toString() ??
          data['image_url']?.toString() ??
          data['image']?.toString(),
      priority: priority,
      status: status,
      purchasedBy: () {
        final v = data['purchasedBy'] ?? data['purchased_by'];
        if (v is Map) {
          return v['_id']?.toString() ?? v['id']?.toString();
        }
        return v?.toString();
      }(),
      purchasedAt: purchasedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<WishlistItem> get _filteredItems {
    return _items.where((item) {
      final matchesSearch =
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (item.description?.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ??
              false);

      switch (_selectedFilter) {
        case 'all':
          return matchesSearch;
        case 'available':
          return matchesSearch && item.status != ItemStatus.purchased;
        case 'purchased':
          return matchesSearch && item.status == ItemStatus.purchased;
        default:
          return matchesSearch;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading wishlist...',
                style: AppStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColors.error),
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
                  onPressed: _loadWishlistDetails,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: DecorativeBackground(
        showGifts: true,
        child: Stack(
          children: [
            // Animated Background
            AnimatedBackground(
              colors: [
                AppColors.background,
                AppColors.accent.withOpacity(0.03),
                AppColors.primary.withOpacity(0.02),
              ],
            ),

            // Content
            SafeArea(
              child: Column(
                children: [
                  // Clean Header Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Row: Back Button & Actions
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.arrow_back_ios,
                                color: AppColors.textPrimary,
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const Spacer(),
                            if (!widget.isFriendWishlist)
                              IconButton(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.addItem,
                                    arguments: {
                                      'wishlistId': widget.wishlistId,
                                      'wishlistName': _wishlistName.isNotEmpty
                                          ? _wishlistName
                                          : widget.wishlistName,
                                    },
                                  ).then((_) {
                                    _loadWishlistDetails();
                                  });
                                },
                                icon: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Title
                        Text(
                          _wishlistName.isNotEmpty
                              ? _wishlistName
                              : widget.wishlistName,
                          style: AppStyles.headingLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            fontSize: 28,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 8),

                        // Stats Subtitle
                        Text(
                          '$_totalItems Wishes • $_purchasedItems Gifted',
                          style: AppStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Search and Filter Section (No Background Container)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // Search Bar
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.surfaceVariant,
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Search wishes...',
                              hintStyle: AppStyles.bodyMedium.copyWith(
                                color: AppColors.textTertiary,
                              ),
                              prefixIcon: Icon(
                                Icons.search_outlined,
                                color: AppColors.textTertiary,
                                size: 20,
                              ),
                              filled: true,
                              fillColor: Colors.transparent,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.secondary,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            style: AppStyles.bodyMedium,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Filter Chips
                        Row(
                          children: [
                            WishlistFilterChipWidget(
                              value: 'all',
                              label: 'All',
                              icon: Icons.all_inclusive,
                              isSelected: _selectedFilter == 'all',
                              onTap: () {
                                setState(() {
                                  _selectedFilter = 'all';
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            WishlistFilterChipWidget(
                              value: 'available',
                              label: 'Available',
                              icon: Icons.shopping_bag_outlined,
                              isSelected: _selectedFilter == 'available',
                              onTap: () {
                                setState(() {
                                  _selectedFilter = 'available';
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            WishlistFilterChipWidget(
                              value: 'purchased',
                              label: 'Gifted',
                              icon: Icons.check_circle_outline,
                              isSelected: _selectedFilter == 'purchased',
                              onTap: () {
                                setState(() {
                                  _selectedFilter = 'purchased';
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Scrollable Content
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return CustomScrollView(
                          slivers: [
                            // Items List
                            if (_items.isEmpty)
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    bottom: MediaQuery.of(
                                      context,
                                    ).padding.bottom,
                                  ),
                                  child: EmptyWishlistStateWidget(
                                    wishlistId: widget.wishlistId,
                                    wishlistName: _wishlistName.isNotEmpty
                                        ? _wishlistName
                                        : widget.wishlistName,
                                    isFriendWishlist: widget.isFriendWishlist,
                                  ),
                                ),
                              )
                            else if (_filteredItems.isEmpty)
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    bottom: MediaQuery.of(
                                      context,
                                    ).padding.bottom,
                                  ),
                                  child: const EmptySearchStateWidget(),
                                ),
                              )
                            else
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  8,
                                  16,
                                  16, // Extra bottom padding to prevent overflow
                                ),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate((
                                    context,
                                    index,
                                  ) {
                                    final item = _filteredItems[index];
                                    final isPurchased =
                                        item.status == ItemStatus.purchased;
                                    final priorityColor = _getPriorityColor(
                                      item.priority,
                                    );

                                    // Check if user is guest
                                    final authService =
                                        Provider.of<AuthRepository>(
                                          context,
                                          listen: false,
                                        );
                                    final isGuest = authService.isGuest;

                                    return WishlistItemCardWidget(
                                      item: item,
                                      isPurchased: isPurchased,
                                      priorityColor: priorityColor,
                                      onTap: () => _openItemDetails(item),
                                      // Hide "Mark as Gifted" for guest users and friend wishlists
                                      onToggleGifted:
                                          (widget.isFriendWishlist || isGuest)
                                          ? null
                                          : () => _togglePurchaseStatus(item),
                                      // Show edit/delete menu for guest users (not for friend wishlists)
                                      onEdit: widget.isFriendWishlist
                                          ? null
                                          : () => _editItem(item),
                                      onDelete: widget.isFriendWishlist
                                          ? null
                                          : () => _deleteItem(item),
                                      // Disable swipe for friend wishlists and guest users
                                      enableSwipe:
                                          !widget.isFriendWishlist && !isGuest,
                                    );
                                  }, childCount: _filteredItems.length),
                                ),
                              ),
                          ],
                        );
                      },
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

  void _togglePurchaseStatus(WishlistItem item) async {
    final currentStatus = item.status == ItemStatus.purchased;
    final newStatus = currentStatus ? ItemStatus.desired : ItemStatus.purchased;

    // Show confirmation dialog before marking as gifted
    if (newStatus == ItemStatus.purchased) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Mark as Gifted?',
                style: AppStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to mark "${item.name}" as gifted?',
                style: AppStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                'Cancel',
                style: AppStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                'Confirm',
                style: AppStyles.caption.copyWith(
                  color: AppColors.success,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        return; // User cancelled
      }
    }

    // Proceed with status update
    try {
      final newStatus = item.status == ItemStatus.purchased
          ? ItemStatus.desired
          : ItemStatus.purchased;

      // Check if user is guest
      final authService = Provider.of<AuthRepository>(context, listen: false);

      if (authService.isGuest) {
        // Update in local storage for guests
        try {
          final guestDataRepo = Provider.of<GuestDataRepository>(
            context,
            listen: false,
          );
          final updatedItem = item.copyWith(
            status: newStatus,
            updatedAt: DateTime.now(),
          );
          await guestDataRepo.updateWishlistItem(updatedItem);

        } catch (e) {

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Failed to update item: ${e.toString()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return; // Exit early on error
        }
      } else {
        // Call API to mark item as purchased for authenticated users
        WishlistItem? updatedItem;
        
        if (newStatus == ItemStatus.purchased) {
          try {
            final updatedItemData = await _wishlistRepository.markItemAsPurchased(
              itemId: item.id,
              // purchasedBy is optional, defaults to current user
            );

            // Parse the updated item from API response
            updatedItem = WishlistItem.fromJson(updatedItemData);
          } catch (e) {
            // Handle API error
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Failed to mark item as gifted: ${e.toString()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: AppColors.error,
                  duration: const Duration(seconds: 3),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            return; // Exit early on error
          }
        } else {
          // For unmarking as purchased, update local state
          // TODO: Add API endpoint to unmark as purchased if needed
          updatedItem = item.copyWith(
            status: newStatus,
            purchasedBy: null,
            purchasedAt: null,
            updatedAt: DateTime.now(),
          );
        }

        // Update local state with API response for authenticated users
        if (mounted && updatedItem != null) {
          setState(() {
            final index = _items.indexWhere((i) => i.id == item.id);
            if (index != -1) {
              _items[index] = updatedItem!;
              if (newStatus == ItemStatus.purchased) {
                _purchasedItems++;
              } else {
                _purchasedItems = _purchasedItems > 0 ? _purchasedItems - 1 : 0;
              }
            }
          });
        }
      }

      // Update local state for guest users
      if (authService.isGuest && mounted) {
        setState(() {
          final index = _items.indexWhere((i) => i.id == item.id);
          if (index != -1) {
            _items[index] = item.copyWith(status: newStatus);
            if (newStatus == ItemStatus.purchased) {
              _purchasedItems++;
            } else {
              _purchasedItems = _purchasedItems > 0 ? _purchasedItems - 1 : 0;
            }
          }
        });
      }

      if (mounted) {
        // Show light snackbar instead of dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  newStatus == ItemStatus.purchased
                      ? Icons.check_circle
                      : Icons.shopping_bag_outlined,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  newStatus == ItemStatus.purchased
                      ? 'Marked as Gifted! 🎉'
                      : 'Marked as Available',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            backgroundColor: newStatus == ItemStatus.purchased
                ? AppColors.success
                : AppColors.info,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 2),
            margin: const EdgeInsets.all(16),
            elevation: 2,
          ),
        );
      }
    } catch (e) {

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Failed to update status. Please try again.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
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
    }
  }

  void _editItem(WishlistItem item) {
    // Navigate to edit item screen
    Navigator.pushNamed(
      context,
      AppRoutes.addItem,
      arguments: {
        'wishlistId': widget.wishlistId,
        'wishlistName': widget.wishlistName,
        'itemId': item.id,
        'isEditing': true,
        'item': item,
      },
    ).then((_) {
      // Refresh the list when returning from edit screen
      _loadWishlistDetails();
    });
  }

  void _deleteItem(WishlistItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surface.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Delete Item',
            style: AppStyles.headingSmall.copyWith(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete "${item.name}"? This action cannot be undone.',
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: AppStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performDeleteItem(item);
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
        );
      },
    );
  }

  Future<void> _performDeleteItem(WishlistItem item) async {
    try {

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
                const Text('Deleting item...'),
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
        // Delete from local storage for guests
        final guestDataRepo = Provider.of<GuestDataRepository>(
          context,
          listen: false,
        );
        await guestDataRepo.deleteWishlistItem(item.id);
      } else {
        // Call API to delete item for authenticated users
        await _wishlistRepository.deleteItem(item.id);
      }

      // Reload wishlist details to update the screen
      await _loadWishlistDetails();

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
                    '${item.name} deleted successfully',
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Failed to delete item: ${e.message}',
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Failed to delete item: ${e.toString()}',
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

  Color _getPriorityColor(ItemPriority priority) {
    switch (priority) {
      case ItemPriority.high:
        return AppColors.error;
      case ItemPriority.medium:
        return AppColors.warning;
      case ItemPriority.low:
        return AppColors.success;
      case ItemPriority.urgent:
        return AppColors.accent;
    }
  }

  void _openItemDetails(WishlistItem item) {
    // Navigate to item details screen
    Navigator.pushNamed(
      context,
      AppRoutes.itemDetails,
      arguments: {
        'id': item.id,
        'wishlistId': item.wishlistId,
        'title': item.name,
        'name': item.name,
        'description': item.description,
        'imageUrl': item.imageUrl,
        'priority': item.priority.toString().split('.').last,
        'status': item.status.toString().split('.').last,
      },
    );
  }
}

// Data Models - Using models from wishlist_model.dart instead
