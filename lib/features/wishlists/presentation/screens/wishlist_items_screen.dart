import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/features/wishlists/data/models/wishlist_model.dart';
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

  // Mock data for wishlist items
  final List<WishlistItem> _items = [
    WishlistItem(
      id: '1',
      wishlistId: '1',
      name: 'iPhone 15 Pro',
      description: 'Latest iPhone with amazing camera and performance',
      priority: ItemPriority.high,
      imageUrl: null,
      status: ItemStatus.desired,
      createdAt: DateTime.now().subtract(Duration(days: 5)),
      updatedAt: DateTime.now().subtract(Duration(days: 5)),
    ),
    WishlistItem(
      id: '2',
      wishlistId: '1',
      name: 'Nike Air Max 270',
      description: 'Comfortable running shoes for daily workouts',
      priority: ItemPriority.medium,
      imageUrl: null,
      status: ItemStatus.purchased,
      createdAt: DateTime.now().subtract(Duration(days: 10)),
      updatedAt: DateTime.now().subtract(Duration(days: 10)),
    ),
    WishlistItem(
      id: '3',
      wishlistId: '1',
      name: 'Kindle Paperwhite',
      description: 'E-reader with waterproof design and long battery life',
      priority: ItemPriority.low,
      imageUrl: null,
      status: ItemStatus.desired,
      createdAt: DateTime.now().subtract(Duration(days: 15)),
      updatedAt: DateTime.now().subtract(Duration(days: 15)),
    ),
    WishlistItem(
      id: '4',
      wishlistId: '1',
      name: 'KitchenAid Mixer',
      description: 'Professional stand mixer for baking enthusiasts',
      priority: ItemPriority.high,
      imageUrl: null,
      status: ItemStatus.desired,
      createdAt: DateTime.now().subtract(Duration(days: 20)),
      updatedAt: DateTime.now().subtract(Duration(days: 20)),
    ),
    WishlistItem(
      id: '5',
      wishlistId: '1',
      name: 'Sony WH-1000XM4',
      description: 'Wireless noise-canceling headphones',
      priority: ItemPriority.medium,
      imageUrl: null,
      status: ItemStatus.desired,
      createdAt: DateTime.now().subtract(Duration(days: 25)),
      updatedAt: DateTime.now().subtract(Duration(days: 25)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
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
        case 'high_priority':
          return matchesSearch && item.priority == ItemPriority.high;
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
                    child: AnimatedBuilder(
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
                  widget.wishlistName,
                  style: AppStyles.headingSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.isFriendWishlist && widget.friendName != null)
                  Text(
                    '${widget.friendName}\'s wishlist',
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  Text(
                    '${_filteredItems.length} items',
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
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
              value: '${widget.totalItems}',
              label: 'Total Items',
              color: AppColors.primary,
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.borderLight),
          Expanded(
            child: _buildStatItem(
              icon: Icons.check_circle_outline,
              value: '${widget.purchasedItems}',
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

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search items...',
              prefixIcon: Icon(
                Icons.search_outlined,
                color: AppColors.textTertiary,
              ),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
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
                const SizedBox(width: 8),
                _buildFilterChip(
                  'high_priority',
                  'High Priority',
                  Icons.priority_high,
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
          title: const Text('Delete Item'),
          content: Text('Are you sure you want to delete "${item.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _items.removeWhere((element) => element.id == item.id);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${item.name} deleted successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
            style: AppStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
          ),
        ],
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
