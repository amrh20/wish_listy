import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/features/wishlists/data/models/wishlist_model.dart';
import 'package:wish_listy/features/wishlists/data/repository/wishlist_repository.dart';
import 'package:wish_listy/core/widgets/decorative_background.dart';
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

class _WishlistItemsScreenState extends State<WishlistItemsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    _initializeAnimations();
    _startAnimations();
    _loadWishlistDetails();
  }

  /// Load wishlist details and items from API
  Future<void> _loadWishlistDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _wishlistName = widget.wishlistName;
      _totalItems = widget.totalItems;
      _purchasedItems = widget.purchasedItems;
    });

    try {
      debugPrint('📡 WishlistItemsScreen: Loading wishlist: ${widget.wishlistId}');
      
      // Call API to get wishlist details
      final wishlistData = await _wishlistRepository.getWishlistById(widget.wishlistId);
      
      debugPrint('📡 WishlistItemsScreen: Received wishlist data: $wishlistData');

      // Handle both direct fields and nested wishlist object
      final data = wishlistData['wishlist'] as Map<String, dynamic>? ?? wishlistData;
      
      // Parse items from response
      final itemsList = data['items'] as List<dynamic>? ?? [];
      final items = itemsList
          .map((item) => _convertToWishlistItem(item as Map<String, dynamic>))
          .toList();

      // Get stats if available
      int totalItems = widget.totalItems;
      int purchasedItems = widget.purchasedItems;

      if (data['stats'] != null && data['stats'] is Map) {
        final stats = data['stats'] as Map<String, dynamic>;
        totalItems = stats['totalItems'] as int? ?? items.length;
        purchasedItems = stats['purchasedItems'] as int? ?? 0;
      } else {
        totalItems = items.length;
        purchasedItems = items.where((item) => item.status == ItemStatus.purchased).length;
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

      setState(() {
        _items = items;
        _totalItems = totalItems;
        _purchasedItems = purchasedItems;
        _wishlistName = data['name']?.toString() ?? widget.wishlistName;
        _category = category;
        _privacy = privacy;
        _createdAt = createdAt;
        _isLoading = false;
      });

      debugPrint('✅ WishlistItemsScreen: Loaded ${items.length} items');
      debugPrint('   Category: $_category');
      debugPrint('   Privacy: $_privacy');
      debugPrint('   CreatedAt: $_createdAt');
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
            margin: const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load wishlist. Please try again.';
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
            margin: const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      debugPrint('Load wishlist error: $e');
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
      purchasedBy: data['purchasedBy']?.toString() ?? data['purchased_by']?.toString(),
      purchasedAt: purchasedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
          ),
        );
  }

  void _startAnimations() {
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
    return Scaffold(
      body: DecorativeBackground(
        showGifts: true,
        child: Stack(
          children: [
            // Content
            SafeArea(
              child: Column(
                children: [
                  // Header
                  _buildHeader(),

                  // Content
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
                                  'Loading wishlist...',
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
                                        onPressed: _loadWishlistDetails,
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
                            : AnimatedBuilder(
                                animation: _animationController,
                                builder: (context, child) {
                                  return FadeTransition(
                                    opacity: _fadeAnimation,
                                    child: SlideTransition(
                                      position: _slideAnimation,
                                      child: Column(
                                        children: [
                                          // Stats Card
                                          _buildStatsCard(),

                                          const SizedBox(height: 20),

                                          // Search and Filters
                                          _buildSearchAndFilters(),

                                          const SizedBox(height: 20),

                                          // Items List
                                          Expanded(child: _buildItemsList()),
                                        ],
                                      ),
                                    ),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.9),
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
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceVariant,
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _wishlistName.isNotEmpty ? _wishlistName : widget.wishlistName,
                  style: AppStyles.headingSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                // Additional info row
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    if (widget.isFriendWishlist && widget.friendName != null)
                      _buildInfoChip(
                        icon: Icons.person_outline,
                        label: '${widget.friendName}\'s wishlist',
                        color: AppColors.secondary,
                      )
                    else
                      _buildInfoChip(
                        icon: Icons.inventory_2_outlined,
                        label: '${_items.length} items',
                        color: AppColors.textSecondary,
                      ),
                    if (_category.isNotEmpty)
                      _buildInfoChip(
                        icon: Icons.category_outlined,
                        label: _category[0].toUpperCase() + _category.substring(1),
                        color: AppColors.primary,
                      ),
                    if (_privacy.isNotEmpty)
                      _buildInfoChip(
                        icon: _privacy == 'public' 
                            ? Icons.public_outlined 
                            : Icons.lock_outline,
                        label: _privacy[0].toUpperCase() + _privacy.substring(1),
                        color: _privacy == 'public' 
                            ? AppColors.success 
                            : AppColors.warning,
                      ),
                    if (_createdAt != null)
                      _buildInfoChip(
                        icon: Icons.calendar_today_outlined,
                        label: _formatDate(_createdAt!),
                        color: AppColors.textTertiary,
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Add Item Button - Only show for own wishlists
          if (!widget.isFriendWishlist)
            IconButton(
              onPressed: () {
                // Navigate to add item screen
                Navigator.pushNamed(context, '/add-item');
              },
              icon: const Icon(Icons.add_rounded),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.secondary,
                padding: const EdgeInsets.all(12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.secondary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.secondary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.inventory_2_outlined,
              value: '$_totalItems',
              label: 'Total Items',
              color: AppColors.primary,
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.borderLight),
          Expanded(
            child: _buildStatItem(
              icon: Icons.check_circle_outline,
              value: '$_purchasedItems',
              label: 'Purchased',
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppStyles.headingSmall.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return years == 1 ? '1 year ago' : '$years years ago';
    }
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.borderLight,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight.withOpacity(0.1),
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
                hintText: 'Search items...',
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

          const SizedBox(height: 16),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
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
                  'Purchased',
                  Icons.check_circle_outline,
                ),
              ],
            ),
          ),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.secondary : AppColors.borderLight,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppColors.textTertiary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppStyles.caption.copyWith(
                color: isSelected ? Colors.white : AppColors.textTertiary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    // Check if there are no items at all (not just filtered)
    if (_items.isEmpty) {
      return _buildNoItemsState();
    }

    // Check if filtered items are empty (due to search/filter)
    if (_filteredItems.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        return _buildItemCard(item);
      },
    );
  }

  Widget _buildItemCard(WishlistItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.status == ItemStatus.purchased
              ? AppColors.success.withOpacity(0.3)
              : AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openItemDetails(item),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Item Image/Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _getPriorityColor(item.priority).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getPriorityColor(item.priority).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    _getCategoryIcon('General'),
                    color: _getPriorityColor(item.priority),
                    size: 24,
                  ),
                ),

                const SizedBox(width: 16),

                // Item Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: AppStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                decoration: item.status == ItemStatus.purchased
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          if (item.status == ItemStatus.purchased)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Purchased',
                                style: AppStyles.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      if (item.description != null &&
                          item.description!.isNotEmpty)
                        Text(
                          item.description!,
                          style: AppStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          // Priority Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(
                                item.priority,
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getPriorityText(item.priority),
                              style: AppStyles.caption.copyWith(
                                color: _getPriorityColor(item.priority),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          const Spacer(),

                          // Added by
                          Text(
                            'by Me',
                            style: AppStyles.caption.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action Buttons
                if (!widget.isFriendWishlist) ...[
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Edit Button
                      IconButton(
                        onPressed: () => _editItem(item),
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Colors.black,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surfaceVariant,
                          padding: const EdgeInsets.all(8),
                          minimumSize: const Size(36, 36),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Delete Button
                      IconButton(
                        onPressed: () => _deleteItem(item),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.1),
                          padding: const EdgeInsets.all(8),
                          minimumSize: const Size(36, 36),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
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
      setState(() {});
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
            style: AppStyles.headingSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
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
              'No Items Yet',
              style: AppStyles.headingMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This wishlist is empty. Start adding items you wish for!',
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
                label: const Text('Add First Item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
              'No items found',
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
