import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/features/wishlists/data/models/wishlist_model.dart';
import 'package:wish_listy/features/wishlists/data/repository/wishlist_repository.dart';
import 'package:wish_listy/core/utils/app_routes.dart';

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

  /// Load wishlist details and items from API
  Future<void> _loadWishlistDetails() async {
    debugPrint('⭐ WishlistItemsScreen: _loadWishlistDetails STARTED');
    debugPrint('   Current thread: ${DateTime.now()}');

    // Validate wishlistId before making API call
    if (widget.wishlistId.isEmpty) {
      debugPrint('❌ WishlistItemsScreen: Empty wishlistId provided');
      setState(() {
        _errorMessage = 'Invalid wishlist ID. Please try again.';
        _isLoading = false;
      });
      return;
    }

    debugPrint('✅ WishlistItemsScreen: wishlistId validation passed');
    debugPrint('   wishlistId: ${widget.wishlistId}');
    debugPrint('   wishlistId length: ${widget.wishlistId.length}');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _wishlistName = widget.wishlistName;
      _totalItems = widget.totalItems;
      _purchasedItems = widget.purchasedItems;
    });

    debugPrint('✅ WishlistItemsScreen: setState completed, _isLoading = true');

    try {
      debugPrint('📡 WishlistItemsScreen: About to call getWishlistById API');
      debugPrint('   Wishlist ID: ${widget.wishlistId}');
      debugPrint('   Wishlist Name: ${widget.wishlistName}');
      debugPrint('   Total Items: ${widget.totalItems}');
      debugPrint('   Purchased Items: ${widget.purchasedItems}');

      // Call API to get wishlist details
      final wishlistData = await _wishlistRepository.getWishlistById(
        widget.wishlistId,
      );

      debugPrint(
        '📡 WishlistItemsScreen: Received wishlist data: $wishlistData',
      );
      debugPrint('   WishlistData type: ${wishlistData.runtimeType}');
      debugPrint('   WishlistData keys: ${wishlistData.keys.toList()}');

      // Validate response
      if (wishlistData.isEmpty) {
        debugPrint('❌ WishlistItemsScreen: Empty wishlistData');
        throw Exception('Empty response from API');
      }

      // Handle both direct fields and nested wishlist object
      // The repository already extracts the wishlist object, so we use it directly
      // But also check if it's wrapped in 'wishlist' or 'data' keys
      Map<String, dynamic> data;
      if (wishlistData.containsKey('wishlist')) {
        // Response is wrapped: {success: true, wishlist: {...}}
        data = wishlistData['wishlist'] as Map<String, dynamic>;
        debugPrint(
          '📦 WishlistItemsScreen: Found wrapped wishlist in response',
        );
      } else if (wishlistData.containsKey('data')) {
        // Response is wrapped: {success: true, data: {...}}
        data = wishlistData['data'] as Map<String, dynamic>;
        debugPrint('📦 WishlistItemsScreen: Found wrapped data in response');
      } else {
        // Response is the wishlist object directly
        data = wishlistData;
        debugPrint('📦 WishlistItemsScreen: Using wishlistData directly');
      }

      if (data.isEmpty) {
        debugPrint('❌ WishlistItemsScreen: Empty data after parsing');
        throw Exception('Invalid response format from API');
      }

      debugPrint('📊 WishlistItemsScreen: Parsed data structure');
      debugPrint('   Data keys: ${data.keys.toList()}');

      // Parse items from response
      final itemsList = data['items'] as List<dynamic>? ?? [];
      debugPrint(
        '📦 WishlistItemsScreen: Found ${itemsList.length} items in response',
      );

      final items = <WishlistItem>[];
      for (var i = 0; i < itemsList.length; i++) {
        try {
          final itemData = itemsList[i];
          if (itemData is Map<String, dynamic>) {
            final item = _convertToWishlistItem(itemData);
            items.add(item);
          }
        } catch (e) {
          debugPrint('⚠️ WishlistItemsScreen: Failed to parse item $i: $e');
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
          debugPrint('⚠️ Failed to parse createdAt: $e');
        }
      }

      debugPrint('📊 WishlistItemsScreen: Parsed additional info');
      debugPrint('   Category: $category');
      debugPrint('   Privacy: $privacy');
      debugPrint('   CreatedAt: $createdAt');

      debugPrint('✅ WishlistItemsScreen: About to update state');
      debugPrint('   Items count: ${items.length}');
      debugPrint('   Total items: $totalItems');
      debugPrint('   Purchased items: $purchasedItems');
      debugPrint(
        '   Wishlist name: ${data['name']?.toString() ?? widget.wishlistName}',
      );

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

        debugPrint('✅ WishlistItemsScreen: State updated successfully');
        debugPrint('   Category: $_category');
        debugPrint('   Privacy: $_privacy');
        debugPrint('   CreatedAt: $_createdAt');
        debugPrint('   _isLoading: $_isLoading');
      } else {
        debugPrint(
          '⚠️ WishlistItemsScreen: Widget not mounted, skipping setState',
        );
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
      debugPrint('❌ WishlistItemsScreen: Error loading wishlist details');
      debugPrint('   Error: $e');
      debugPrint('   Error type: ${e.runtimeType}');
      debugPrint('   WishlistId: ${widget.wishlistId}');

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

  /// Convert API response item to WishlistItem
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
    ItemStatus status = ItemStatus.desired;
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
      imageUrl: data['imageUrl']?.toString() ?? data['image_url']?.toString(),
      priority: priority,
      status: status,
      purchasedBy:
          data['purchasedBy']?.toString() ?? data['purchased_by']?.toString(),
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
        backgroundColor: AppColors.surface,
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
        backgroundColor: AppColors.surface,
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
                                  ElevatedButton.icon(
                                    onPressed: _loadWishlistDetails,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Retry'),
                                    style: AppStyles.primaryButton,
                                  ),
                                ],
                              ),
                            ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Container(
        color: AppColors.surface,
        child: CustomScrollView(
          slivers: [
            // SliverAppBar with Minimalist header
            SliverAppBar(
              expandedHeight: 140,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
              ),
              actions: [
                if (!widget.isFriendWishlist)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
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
                  ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  padding: EdgeInsets.only(
                    top: kToolbarHeight + 20,
                    bottom: 20,
                    left: 56, // Padding to avoid back button
                    right: 80, // Padding to avoid action buttons
                  ),
            child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                      // Row 1: Title Only (Edit button is in actions)
                Text(
                  _wishlistName.isNotEmpty
                      ? _wishlistName
                      : widget.wishlistName,
                        style: AppStyles.headingLarge.copyWith(
                    fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontSize: 24,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      // Row 2: Info Chips
                      Row(
                  children: [
                          // Chip 1: Total Items
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.inventory_2,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$_totalItems Items',
                                  style: AppStyles.bodySmall.copyWith(
                                    color: AppColors.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                ),
              ],
            ),
          ),
                          const SizedBox(width: 12),
                          // Chip 2: Gifted
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
      decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
                              mainAxisSize: MainAxisSize.min,
        children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 16,
              color: AppColors.primary,
            ),
                                const SizedBox(width: 6),
                                Text(
                                  '$_purchasedItems Gifted',
                                  style: AppStyles.bodySmall.copyWith(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Search & Filters Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.surfaceVariant,
                          width: 1,
                        ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textTertiary.withOpacity(0.05),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
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
                fillColor: AppColors.surface,
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

                    const SizedBox(height: 12),

          // Filter Chips
                    Row(
              children: [
                _buildFilterChip('all', 'All', Icons.all_inclusive),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'available',
                  'Available',
                  Icons.shopping_bag_outlined,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'purchased',
                  'Gifted',
                  Icons.check_circle_outline,
                ),
              ],
                    ),
                  ],
                ),
              ),
            ),

            // Items List
            if (_items.isEmpty)
              SliverFillRemaining(child: _buildNoItemsState())
            else if (_filteredItems.isEmpty)
              SliverFillRemaining(child: _buildEmptyState())
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = _filteredItems[index];
                    return _buildModernListItem(item);
                  }, childCount: _filteredItems.length),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _selectedFilter == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.surfaceVariant.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : AppColors.textTertiary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppStyles.caption.copyWith(
                color: isSelected ? Colors.white : AppColors.textTertiary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernListItem(WishlistItem item) {
    final isPurchased = item.status == ItemStatus.purchased;
    final priorityColor = _getPriorityColor(item.priority);

    // Build the clean card content
    Widget cardContent = _ModernSwipeableWishlistItem(
      item: item,
      isPurchased: isPurchased,
      priorityColor: priorityColor,
      onTap: () => _openItemDetails(item),
      onToggleGifted: widget.isFriendWishlist
          ? null
          : () => _togglePurchaseStatus(item),
      onEdit: widget.isFriendWishlist ? null : () => _editItem(item),
      onDelete: widget.isFriendWishlist ? null : () => _deleteItem(item),
    );

    // Wrap with Slidable only for own wishlists
    if (!widget.isFriendWishlist) {
      return Slidable(
        key: Key(item.id),
        startActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.25,
          children: [
            CustomSlidableAction(
              onPressed: (_) => _togglePurchaseStatus(item),
              backgroundColor: const Color(0xFF2ECC71),
              foregroundColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check, size: 28, color: Colors.white),
                  SizedBox(height: 4),
                  Text(
                    'Gift',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
          ),
        ],
      ),
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.5,
              children: [
            CustomSlidableAction(
              onPressed: (_) => _editItem(item),
              backgroundColor: const Color(0xFF6366F1), // Indigo
              foregroundColor: Colors.white,
                    borderRadius: BorderRadius.circular(12),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_rounded, size: 28, color: Colors.white),
                  SizedBox(height: 4),
                  Text(
                    'Edit',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            CustomSlidableAction(
              onPressed: (_) => _deleteItem(item),
              backgroundColor: const Color(0xFFEF4444), // Red/Salmon
              foregroundColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_rounded, size: 28, color: Colors.white),
                  SizedBox(height: 4),
                  Text(
                    'Delete',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        child: cardContent,
      );
    }

    // For friend wishlists, return card without swipe actions
    return cardContent;
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
          title: Row(
                    children: [
              Icon(
                Icons.check_circle_outline,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Mark as Gifted?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to mark "${item.name}" as gifted?',
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
                              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: AppStyles.primaryButton,
              child: const Text('Confirm'),
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

      debugPrint(
        '🔄 WishlistItemsScreen: Toggling purchase status for item: ${item.id}',
      );
      debugPrint('   Current status: ${item.status}');
      debugPrint('   New status: $newStatus');

      // TODO: Implement API call to update item status
      // await _wishlistRepository.updateItemStatus(item.id, newStatus);

      // Update local state immediately for better UX
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

      if (mounted) {
        // Show success dialog instead of SnackBar
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Success Icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: newStatus == ItemStatus.purchased
                          ? AppColors.success.withOpacity(0.15)
                          : AppColors.info.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      newStatus == ItemStatus.purchased
                          ? Icons.check_circle
                          : Icons.shopping_bag_outlined,
                      color: newStatus == ItemStatus.purchased
                          ? AppColors.success
                          : AppColors.info,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Success Message
                        Text(
                    newStatus == ItemStatus.purchased
                        ? 'Marked as Gifted! 🎉'
                        : 'Marked as Available',
                    style: AppStyles.headingMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${item.name}',
                    style: AppStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                  const SizedBox(height: 24),
                  // OK Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: newStatus == ItemStatus.purchased
                            ? AppColors.success
                            : AppColors.info,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ),
                    ],
                  ),
                ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ WishlistItemsScreen: Error toggling status: $e');
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
          backgroundColor: Colors.white,
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
      debugPrint('🗑️ WishlistItemsScreen: Deleting item: ${item.id}');

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

      // Call API to delete item
      await _wishlistRepository.deleteItem(item.id);

      debugPrint('✅ WishlistItemsScreen: Item deleted successfully');

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
      debugPrint('❌ WishlistItemsScreen: Error deleting item: ${e.message}');

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
      debugPrint('❌ WishlistItemsScreen: Unexpected error deleting item: $e');

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

  /// Empty state when there are no items in the wishlist at all
  Widget _buildNoItemsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Wishes Yet',
              style: AppStyles.headingMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This wishlist is empty. Start adding wishes you dream of!',
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (!widget.isFriendWishlist)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.addItem,
                    arguments: {
                      'wishlistId': widget.wishlistId,
                      'wishlistName': widget.wishlistName,
                    },
                  ).then((_) {
                    // Refresh the list when returning from add item screen
                    setState(() {});
                  });
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add First Wish'),
                style: AppStyles.primaryButton,
              ),
          ],
        ),
      ),
    );
  }

  /// Empty state when filtered items are empty (due to search/filter)
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_outlined,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No wishes found',
              style: AppStyles.headingSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
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

// Modern Swipeable Wishlist Item Widget
class _ModernSwipeableWishlistItem extends StatefulWidget {
  final WishlistItem item;
  final bool isPurchased;
  final Color priorityColor;
  final VoidCallback onTap;
  final VoidCallback? onToggleGifted;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ModernSwipeableWishlistItem({
    required this.item,
    required this.isPurchased,
    required this.priorityColor,
    required this.onTap,
    this.onToggleGifted,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<_ModernSwipeableWishlistItem> createState() =>
      _ModernSwipeableWishlistItemState();
}

class _ModernSwipeableWishlistItemState
    extends State<_ModernSwipeableWishlistItem> {
  String _getPriorityText(ItemPriority priority) {
    switch (priority) {
      case ItemPriority.high:
        return 'High';
      case ItemPriority.medium:
        return 'Medium';
      case ItemPriority.low:
        return 'Low';
      case ItemPriority.urgent:
        return 'Urgent';
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'electronics':
        return Icons.devices;
      case 'fashion':
        return Icons.checkroom;
      case 'books':
        return Icons.book;
      case 'home & kitchen':
        return Icons.home;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: widget.isPurchased
                ? const Color(0xFF2ECC71).withOpacity(0.15)
                : widget.priorityColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getCategoryIcon('General'),
            color: widget.isPurchased
                ? const Color(0xFF2ECC71)
                : widget.priorityColor,
            size: 24,
          ),
        ),
        title: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: AppStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            decoration: widget.isPurchased
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            color: widget.isPurchased ? Colors.grey : AppColors.textPrimary,
          ),
          child: Text(widget.item.name),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                // Priority dot + text
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: widget.priorityColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _getPriorityText(widget.item.priority),
                  style: AppStyles.caption.copyWith(
                    color: widget.priorityColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                // Category
                Text(
                  'General',
                  style: AppStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: widget.onToggleGifted != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Purchase Toggle IconButton
                  IconButton(
                    onPressed: () {
                      // This callback is handled separately and won't trigger ListTile.onTap
                      widget.onToggleGifted?.call();
                    },
                    iconSize: 20.0,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    icon: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: widget.isPurchased
                            ? const Color(0xFF2ECC71)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: widget.isPurchased
                            ? null
                            : Border.all(
                                color: Colors.grey.withOpacity(0.3),
                                width: 2,
                              ),
                      ),
                      child: widget.isPurchased
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Context Menu PopupMenuButton
                  PopupMenuButton<String>(
                    color: Colors.white,
                    icon: Icon(
                      Icons.more_vert,
                      color: AppColors.textTertiary,
                      size: 20,
                    ),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onSelected: (value) {
                      if (value == 'edit') {
                        widget.onEdit?.call();
                      } else if (value == 'delete') {
                        widget.onDelete?.call();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit,
                              color: AppColors.textPrimary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Edit',
                              style: AppStyles.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              'Delete',
                              style: AppStyles.bodyMedium.copyWith(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : // For friend wishlists, only show purchase status indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: widget.isPurchased
                      ? const Color(0xFF2ECC71)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: widget.isPurchased
                      ? null
                      : Border.all(
                          color: Colors.grey.withOpacity(0.3),
                          width: 2,
                        ),
                ),
                child: widget.isPurchased
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
        onTap: widget.onTap,
      ),
    );
  }
}

// Data Models - Using models from wishlist_model.dart instead
