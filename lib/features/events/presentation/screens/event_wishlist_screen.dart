import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'package:wish_listy/core/widgets/decorative_background.dart';
import 'package:wish_listy/features/wishlists/data/models/wishlist_model.dart';
import 'package:wish_listy/features/events/data/models/event_model.dart';
import 'package:wish_listy/core/services/localization_service.dart';

class EventWishlistScreen extends StatefulWidget {
  final EventSummary event;

  const EventWishlistScreen({super.key, required this.event});

  @override
  _EventWishlistScreenState createState() => _EventWishlistScreenState();
}

class _EventWishlistScreenState extends State<EventWishlistScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _selectedFilter = 'all';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  // Mock data for event wishlist items
  final List<EventWishlistItem> _items = [
    EventWishlistItem(
      id: '1',
      name: 'iPhone 15 Pro',
      description: 'Latest iPhone with amazing camera and performance',
      price: 999.99,
      priority: ItemPriority.high,
      category: 'Electronics',
      imageUrl: null,
      isReserved: false,
      isPurchased: false,
      addedBy: 'Host',
      addedDate: DateTime.now().subtract(Duration(days: 5)),
      notes: 'Preferably in Space Black color',
      reservedBy: null,
    ),
    EventWishlistItem(
      id: '2',
      name: 'Nike Air Max 270',
      description: 'Comfortable running shoes for daily workouts',
      price: 129.99,
      priority: ItemPriority.medium,
      category: 'Fashion',
      imageUrl: null,
      isReserved: true,
      isPurchased: false,
      addedBy: 'Host',
      addedDate: DateTime.now().subtract(Duration(days: 10)),
      notes: 'Size 42, any color is fine',
      reservedBy: 'Sarah Johnson',
    ),
    EventWishlistItem(
      id: '3',
      name: 'Kindle Paperwhite',
      description: 'E-reader with waterproof design and long battery life',
      price: 139.99,
      priority: ItemPriority.low,
      category: 'Books',
      imageUrl: null,
      isReserved: false,
      isPurchased: true,
      addedBy: 'Host',
      addedDate: DateTime.now().subtract(Duration(days: 15)),
      notes: '8GB version is sufficient',
      reservedBy: null,
    ),
    EventWishlistItem(
      id: '4',
      name: 'KitchenAid Mixer',
      description: 'Professional stand mixer for baking enthusiasts',
      price: 299.99,
      priority: ItemPriority.high,
      category: 'Home & Kitchen',
      imageUrl: null,
      isReserved: false,
      isPurchased: false,
      addedBy: 'Host',
      addedDate: DateTime.now().subtract(Duration(days: 20)),
      notes: 'Red color preferred',
      reservedBy: null,
    ),
    EventWishlistItem(
      id: '5',
      name: 'Sony WH-1000XM4',
      description: 'Wireless noise-canceling headphones',
      price: 349.99,
      priority: ItemPriority.medium,
      category: 'Electronics',
      imageUrl: null,
      isReserved: true,
      isPurchased: false,
      addedBy: 'Host',
      addedDate: DateTime.now().subtract(Duration(days: 25)),
      notes: 'Great for travel and work',
      reservedBy: 'Mike Thompson',
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

  List<EventWishlistItem> get _filteredItems {
    return _items.where((item) {
      final matchesSearch =
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.description.toLowerCase().contains(_searchQuery.toLowerCase());

      switch (_selectedFilter) {
        case 'all':
          return matchesSearch;
        case 'available':
          return matchesSearch && !item.isReserved && !item.isPurchased;
        case 'reserved':
          return matchesSearch && item.isReserved && !item.isPurchased;
        case 'purchased':
          return matchesSearch && item.isPurchased;
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
        child: SafeArea(
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
                            // Event Info Card
                            _buildEventInfoCard(),

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
            icon: const Icon(Icons.arrow_back_ios, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(8),
              shape: const CircleBorder(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.event.name} Wishlist',
                  style: AppStyles.headingSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_filteredItems.length} items available',
                  style: AppStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Help Button
          IconButton(
            onPressed: _showHelpDialog,
            icon: const Icon(Icons.help_outline),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceVariant,
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getEventTypeColor(widget.event.type).withOpacity(0.1),
            _getEventTypeColor(widget.event.type).withOpacity(0.05),
          ],
        ),
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getEventTypeColor(widget.event.type).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getEventTypeColor(widget.event.type),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getEventTypeIcon(widget.event.type),
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
                      widget.event.name,
                      style: AppStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(widget.event.date),
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (widget.event.hostName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'by ${widget.event.hostName}',
                        style: AppStyles.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Wishlist Stats
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.card_giftcard_outlined,
                  value: '${_items.length}',
                  label: 'Total Items',
                  color: AppColors.primary,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.person_add_outlined,
                  value: '${_items.where((item) => item.isReserved).length}',
                  label: 'Reserved',
                  color: AppColors.info,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.check_circle_outline,
                  value: '${_items.where((item) => item.isPurchased).length}',
                  label: 'Purchased',
                  color: AppColors.success,
                ),
              ),
            ],
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
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppStyles.bodyMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: AppStyles.caption.copyWith(color: AppColors.textTertiary),
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
              hintText: Provider.of<LocalizationService>(context, listen: false).translate('ui.searchWishlistItems'),
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
                  'reserved',
                  'Reserved',
                  Icons.person_add_outlined,
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
            color: isSelected ? AppColors.secondary : AppColors.surfaceVariant,
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

  Widget _buildItemCard(EventWishlistItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isPurchased
              ? AppColors.success.withOpacity(0.3)
              : item.isReserved
              ? AppColors.info.withOpacity(0.3)
              : AppColors.surfaceVariant,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textTertiary.withOpacity(0.05),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Item Image/Icon
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _getPriorityColor(
                          item.priority,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getPriorityColor(
                            item.priority,
                          ).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        _getCategoryIcon(item.category),
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
                                    decoration: item.isPurchased
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),
                              // Status Badge
                              if (item.isPurchased)
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
                                )
                              else if (item.isReserved)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.info,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Reserved',
                                    style: AppStyles.caption.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          Text(
                            item.description,
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

                              const SizedBox(width: 8),

                              // Price
                              Text(
                                '\$${item.price.toStringAsFixed(2)}',
                                style: AppStyles.bodyMedium.copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              const Spacer(),

                              // Reserved by
                              if (item.isReserved && item.reservedBy != null)
                                Text(
                                  'by ${item.reservedBy}',
                                  style: AppStyles.caption.copyWith(
                                    color: AppColors.info,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Action Button
                if (!item.isPurchased) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: item.isReserved
                          ? 'Already Reserved'
                          : 'Reserve This Item',
                      onPressed: item.isReserved
                          ? null
                          : () => _reserveItem(item),
                      variant: item.isReserved
                          ? ButtonVariant.outline
                          : ButtonVariant.primary,
                      customColor: item.isReserved
                          ? AppColors.textTertiary
                          : _getEventTypeColor(widget.event.type),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
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

  // Helper Methods
  Color _getPriorityColor(ItemPriority priority) {
    switch (priority) {
      case ItemPriority.high:
        return AppColors.error;
      case ItemPriority.medium:
        return AppColors.warning;
      case ItemPriority.low:
        return AppColors.success;
      case ItemPriority.urgent:
        return AppColors.error; // Same as high priority
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

  Color _getEventTypeColor(EventType type) {
    switch (type) {
      case EventType.birthday:
        return AppColors.accent;
      case EventType.wedding:
        return AppColors.primary;
      case EventType.graduation:
        return AppColors.accent;
      case EventType.babyShower:
        return AppColors.info;
      case EventType.houseWarming:
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  IconData _getEventTypeIcon(EventType type) {
    switch (type) {
      case EventType.birthday:
        return Icons.cake_outlined;
      case EventType.wedding:
        return Icons.favorite_outline;
      case EventType.graduation:
        return Icons.school_outlined;
      case EventType.babyShower:
        return Icons.child_friendly_outlined;
      case EventType.houseWarming:
        return Icons.home_outlined;
      default:
        return Icons.event_outlined;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // Action Handlers
  void _openItemDetails(EventWishlistItem item) {
    // Navigate to item details screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Item details coming soon!'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _reserveItem(EventWishlistItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reserve Item'),
        content: Text(
          'Are you sure you want to reserve "${item.name}"? This will mark it as reserved for you.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(Provider.of<LocalizationService>(context, listen: false).translate('app.cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                item.isReserved = true;
                item.reservedBy = 'You';
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Item reserved successfully! 🎉'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
            child: Text('Reserve'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('How to Use Event Wishlist'),
        content: Text(
          '• Available items can be reserved by tapping "Reserve This Item"\n'
          '• Reserved items show who has reserved them\n'
          '• Purchased items are marked as completed\n'
          '• Use filters to find specific items\n'
          '• Search for items by name or description',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it'),
          ),
        ],
      ),
    );
  }
}

// Data Models
// Using ItemPriority from wishlist_model.dart

class EventWishlistItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final ItemPriority priority;
  final String category;
  final String? imageUrl;
  bool isReserved;
  final bool isPurchased;
  final String addedBy;
  final DateTime addedDate;
  final String? notes;
  String? reservedBy;

  EventWishlistItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.priority,
    required this.category,
    this.imageUrl,
    required this.isReserved,
    required this.isPurchased,
    required this.addedBy,
    required this.addedDate,
    this.notes,
    this.reservedBy,
  });
}
