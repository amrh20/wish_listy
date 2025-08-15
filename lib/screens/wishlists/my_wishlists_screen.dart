import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../utils/app_routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/animated_background.dart';

class MyWishlistsScreen extends StatefulWidget {
  @override
  _MyWishlistsScreenState createState() => _MyWishlistsScreenState();
}

class _MyWishlistsScreenState extends State<MyWishlistsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Mock data - replace with real data from your backend
  final List<WishlistSummary> _publicWishlists = [
    WishlistSummary(
      id: '1',
      name: 'My General Wishlist',
      itemCount: 12,
      purchasedCount: 3,
      totalValue: 450.0,
      lastUpdated: DateTime.now().subtract(Duration(days: 2)),
      imageUrl: null,
    ),
  ];

  final List<WishlistSummary> _eventWishlists = [
    WishlistSummary(
      id: '2',
      name: 'Birthday Wishlist 2024',
      itemCount: 8,
      purchasedCount: 2,
      totalValue: 320.0,
      lastUpdated: DateTime.now().subtract(Duration(days: 1)),
      imageUrl: null,
      eventDate: DateTime.now().add(Duration(days: 15)),
    ),
    WishlistSummary(
      id: '3',
      name: 'Christmas Wishlist',
      itemCount: 15,
      purchasedCount: 0,
      totalValue: 680.0,
      lastUpdated: DateTime.now().subtract(Duration(days: 5)),
      imageUrl: null,
      eventDate: DateTime(2024, 12, 25),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() {
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Background
          AnimatedBackground(
            colors: [
              AppColors.background,
              AppColors.secondary.withOpacity(0.02),
              AppColors.primary.withOpacity(0.01),
            ],
          ),
          
          // Content
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                _buildSliverAppBar(),
                _buildSliverTabBar(),
              ];
            },
            body: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPublicWishlistTab(),
                      _buildEventWishlistsTab(),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
      floating: true,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'My Wishlists',
          style: AppStyles.headingMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
      ),
      actions: [
        // Search Button
        IconButton(
          onPressed: () {
            _showSearchBottomSheet();
          },
          icon: Icon(
            Icons.search_rounded,
            color: AppColors.textPrimary,
          ),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surface,
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(width: 8),
        // Menu Button
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          icon: Icon(
            Icons.more_vert_rounded,
            color: AppColors.textPrimary,
          ),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surface,
            padding: const EdgeInsets.all(12),
          ),
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
                  Text('Export Wishlists'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('Wishlist Settings'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildSliverTabBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverTabBarDelegate(
        TabBar(
          controller: _tabController,
          indicatorColor: AppColors.secondary,
          indicatorWeight: 3,
          labelColor: AppColors.secondary,
          unselectedLabelColor: AppColors.textTertiary,
          labelStyle: AppStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: AppStyles.bodyMedium,
          tabs: const [
            Tab(text: 'Public Wishlist'),
            Tab(text: 'Event Wishlists'),
          ],
        ),
      ),
    );
  }

  Widget _buildPublicWishlistTab() {
    return RefreshIndicator(
      onRefresh: _refreshWishlists,
      color: AppColors.secondary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Public Wishlist Card
            if (_publicWishlists.isNotEmpty) ...[
              _buildWishlistCard(_publicWishlists.first, isPublic: true),
              const SizedBox(height: 24),
            ],
            
            // Quick Stats
            _buildQuickStats(),
            const SizedBox(height: 24),
            
            // Recent Items
            _buildRecentItems(),
            const SizedBox(height: 100), // Bottom padding for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildEventWishlistsTab() {
    return RefreshIndicator(
      onRefresh: _refreshWishlists,
      color: AppColors.secondary,
      child: _eventWishlists.isEmpty
          ? _buildEmptyEventWishlists()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _eventWishlists.length + 1, // +1 for bottom padding
              itemBuilder: (context, index) {
                if (index == _eventWishlists.length) {
                  return const SizedBox(height: 100); // Bottom padding for FAB
                }
                return _buildWishlistCard(_eventWishlists[index]);
              },
            ),
    );
  }

  Widget _buildWishlistCard(WishlistSummary wishlist, {bool isPublic = false}) {
    final progress = wishlist.itemCount > 0 
        ? wishlist.purchasedCount / wishlist.itemCount 
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textTertiary.withOpacity(0.1),
            offset: const Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isPublic
                    ? [AppColors.secondary.withOpacity(0.1), AppColors.primary.withOpacity(0.1)]
                    : [AppColors.accent.withOpacity(0.1), AppColors.secondary.withOpacity(0.1)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isPublic ? AppColors.secondary : AppColors.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isPublic ? Icons.favorite_rounded : Icons.celebration_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wishlist.name,
                        style: AppStyles.headingSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (wishlist.eventDate != null)
                        Text(
                          _formatEventDate(wishlist.eventDate!),
                          style: AppStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        )
                      else
                        Text(
                          'Updated ${_formatLastUpdated(wishlist.lastUpdated)}',
                          style: AppStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleWishlistAction(value, wishlist),
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.textSecondary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Share'),
                        ],
                      ),
                    ),
                    if (!isPublic)
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          // Stats
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Progress Bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress',
                          style: AppStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${wishlist.purchasedCount}/${wishlist.itemCount} items',
                          style: AppStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isPublic ? AppColors.secondary : AppColors.accent,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Stats Row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.inventory_2_outlined,
                        label: 'Total Items',
                        value: '${wishlist.itemCount}',
                        color: AppColors.primary,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.check_circle_outline,
                        label: 'Purchased',
                        value: '${wishlist.purchasedCount}',
                        color: AppColors.success,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.attach_money_outlined,
                        label: 'Total Value',
                        value: '\$${wishlist.totalValue.toInt()}',
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'View Items',
                        onPressed: () => _viewWishlistItems(wishlist),
                        variant: ButtonVariant.outline,
                        customColor: isPublic ? AppColors.secondary : AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: 'Add Item',
                        onPressed: () => _addItemToWishlist(wishlist),
                        variant: ButtonVariant.primary,
                        customColor: isPublic ? AppColors.secondary : AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppStyles.caption.copyWith(
            color: AppColors.textTertiary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Stats',
            style: AppStyles.headingSmall,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickStatItem(
                  title: 'Total Wishlists',
                  value: '${_publicWishlists.length + _eventWishlists.length}',
                  color: AppColors.primary,
                ),
              ),
              Expanded(
                child: _buildQuickStatItem(
                  title: 'Total Items',
                  value: '${_getTotalItems()}',
                  color: AppColors.accent,
                ),
              ),
              Expanded(
                child: _buildQuickStatItem(
                  title: 'Friends',
                  value: '24',
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatItem({
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: AppStyles.headingMedium.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: AppStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecentItems() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Items',
                style: AppStyles.headingSmall,
              ),
              TextButton(
                onPressed: () {
                  // View all items
                },
                child: Text(
                  'View All',
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Recent items list
          _buildRecentItemsList(),
        ],
      ),
    );
  }

  Widget _buildRecentItemsList() {
    // Mock recent items
    final recentItems = [
      'iPhone 15 Pro',
      'Nike Air Jordan Sneakers',
      'MacBook Air M2',
    ];

    return Column(
      children: recentItems.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.card_giftcard_outlined,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item,
                  style: AppStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyEventWishlists() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.celebration_outlined,
              size: 60,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Event Wishlists Yet',
            style: AppStyles.headingMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Create wishlists for special events like birthdays, weddings, and holidays to make gift-giving easier for your friends.',
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          CustomButton(
            text: 'Create Event Wishlist',
            onPressed: () {
              AppRoutes.pushNamed(context, AppRoutes.createEvent);
            },
            variant: ButtonVariant.gradient,
            gradientColors: [AppColors.accent, AppColors.secondary],
          ),
        ],
      ),
    );
  }

  // Helper Methods
  String _formatEventDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference < 0) {
      return 'Event passed';
    } else if (difference == 0) {
      return 'Today!';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference < 7) {
      return 'In $difference days';
    } else {
      return 'In ${(difference / 7).ceil()} weeks';
    }
  }

  String _formatLastUpdated(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inMinutes} minutes ago';
    }
  }

  int _getTotalItems() {
    return _publicWishlists.fold(0, (sum, wishlist) => sum + wishlist.itemCount) +
           _eventWishlists.fold(0, (sum, wishlist) => sum + wishlist.itemCount);
  }

  // Action Handlers
  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _exportWishlists();
        break;
      case 'settings':
        _openWishlistSettings();
        break;
    }
  }

  void _handleWishlistAction(String action, WishlistSummary wishlist) {
    switch (action) {
      case 'edit':
        _editWishlist(wishlist);
        break;
      case 'share':
        _shareWishlist(wishlist);
        break;
      case 'delete':
        _deleteWishlist(wishlist);
        break;
    }
  }

  void _viewWishlistItems(WishlistSummary wishlist) {
    // Navigate to wishlist details
  }

  void _addItemToWishlist(WishlistSummary wishlist) {
    AppRoutes.pushNamed(context, AppRoutes.addItem, arguments: {
      'wishlistId': wishlist.id,
    });
  }

  void _exportWishlists() {
    // Export functionality
  }

  void _openWishlistSettings() {
    // Open settings
  }

  void _editWishlist(WishlistSummary wishlist) {
    // Edit wishlist
  }

  void _shareWishlist(WishlistSummary wishlist) {
    // Share wishlist
  }

  void _deleteWishlist(WishlistSummary wishlist) {
    // Delete wishlist with confirmation
  }

  void _showSearchBottomSheet() {
    // Show search bottom sheet
  }

  Future<void> _refreshWishlists() async {
    // Refresh wishlists data
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      // Update data
    });
  }
}

// Custom SliverTabBarDelegate
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.background,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}

// Mock data model
class WishlistSummary {
  final String id;
  final String name;
  final int itemCount;
  final int purchasedCount;
  final double totalValue;
  final DateTime lastUpdated;
  final String? imageUrl;
  final DateTime? eventDate;

  WishlistSummary({
    required this.id,
    required this.name,
    required this.itemCount,
    required this.purchasedCount,
    required this.totalValue,
    required this.lastUpdated,
    this.imageUrl,
    this.eventDate,
  });
}