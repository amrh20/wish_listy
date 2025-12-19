import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/features/wishlists/data/models/wishlist_model.dart';
import 'package:wish_listy/features/wishlists/data/repository/wishlist_repository.dart';
import 'package:wish_listy/features/wishlists/data/repository/guest_data_repository.dart';
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';

class ItemDetailsScreen extends StatefulWidget {
  final WishlistItem item;

  const ItemDetailsScreen({super.key, required this.item});

  @override
  _ItemDetailsScreenState createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final WishlistRepository _wishlistRepository = WishlistRepository();

  WishlistItem? _currentItem;
  bool _isLoading = true;
  String? _errorMessage;
  String? _wishlistName; // Store wishlist name for navigation

  @override
  void initState() {
    super.initState();
    _currentItem = widget.item;
    _initializeAnimations();
    _fetchItemDetails();
  }

  Future<void> _fetchItemDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Check if user is guest
      final authService = Provider.of<AuthRepository>(context, listen: false);
      
      if (authService.isGuest) {
        // Load from local storage for guests

        final guestDataRepo = Provider.of<GuestDataRepository>(context, listen: false);
        final items = await guestDataRepo.getWishlistItems(widget.item.wishlistId);

        // Find the specific item by ID
        final item = items.firstWhere(
          (item) => item.id == widget.item.id,
          orElse: () {

            throw Exception('Item not found in local storage');
          },
        );

        // Load wishlist name for navigation
        final wishlist = await guestDataRepo.getWishlistById(widget.item.wishlistId);
        
        // Use the item directly (no need to convert from JSON)
        if (mounted) {
          setState(() {
            _currentItem = item;
            _wishlistName = wishlist?.name ?? 'Wishlist';
            _isLoading = false;
          });
          _startAnimations();
        }
      } else {
        // Load from API for authenticated users

        final itemData = await _wishlistRepository.getItemById(widget.item.id);

        // Parse the item data to WishlistItem model
        final updatedItem = WishlistItem.fromJson(itemData);
        
        // Try to get wishlist name from itemData or use default
        final wishlistName = itemData['wishlistName']?.toString() ?? 
                            itemData['wishlist']?['name']?.toString() ?? 
                            'Wishlist';

        if (mounted) {
          setState(() {
            _currentItem = updatedItem;
            _wishlistName = wishlistName;
            _isLoading = false;
          });
          _startAnimations();
        }
      }
    } on ApiException catch (e) {

      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {

      if (mounted) {
        setState(() {
          _errorMessage = e.toString().contains('Exception')
              ? e.toString().replaceFirst('Exception: ', '')
              : 'Failed to load item details. Please try again.';
          _isLoading = false;
        });
      }
    }
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
    if (mounted) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Minimal Header
            _buildHeader(),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? _buildErrorState()
                  : _currentItem == null
                  ? const Center(child: Text('Item not found'))
                  : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isPurchased =
        (_currentItem?.status ?? widget.item.status) == ItemStatus.purchased;
    
    // Check if user is guest
    final authService = Provider.of<AuthRepository>(context, listen: false);
    final isGuest = authService.isGuest;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            style: IconButton.styleFrom(padding: const EdgeInsets.all(8)),
          ),
          const Spacer(),
          // Mark as Purchased text button (small, compact)
          if (!isGuest) ...[
            TextButton(
              onPressed: _togglePurchaseStatus,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                isPurchased ? 'Mark as Available' : 'Mark as Gifted',
                style: AppStyles.caption.copyWith(
                  fontSize: 12,
                  color: isPurchased ? AppColors.textSecondary : AppColors.success,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Actions menu (Edit, Delete)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _editItem();
                  break;
                case 'delete':
                  _deleteItem();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18, color: AppColors.textPrimary),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: AppStyles.headingMedium.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: AppStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Retry',
              onPressed: _fetchItemDetails,
              variant: ButtonVariant.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        if (!mounted) return const SizedBox.shrink();

        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // Item Icon - Simplified
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _getPriorityColor(
                          _currentItem?.priority ?? widget.item.priority,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        _getCategoryIcon('General'),
                        color: _getPriorityColor(
                          _currentItem?.priority ?? widget.item.priority,
                        ),
                        size: 40,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Item Name - H1 Style
                  Text(
                    _currentItem?.name ?? widget.item.name,
                    style: AppStyles.headingLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      decoration:
                          (_currentItem?.status ?? widget.item.status) ==
                              ItemStatus.purchased
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Status Badges - Pill-shaped Chips
                  Row(
                    children: [
                      // Priority Badge
                      _buildPillBadge(
                        text: _getPriorityText(
                          _currentItem?.priority ?? widget.item.priority,
                        ),
                        color: _getPriorityColor(
                          _currentItem?.priority ?? widget.item.priority,
                        ),
                        icon: Icons.priority_high,
                      ),
                      const SizedBox(width: 8),
                      // Category Badge
                      _buildPillBadge(
                        text: 'General',
                        color: AppColors.info,
                        icon: _getCategoryIcon('General'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Item Information Section - Unified
                  _buildUnifiedInfoSection(),

                  const SizedBox(height: 32),

                  // Notes Section (if exists)
                  if (_currentItem?.description != null &&
                      _currentItem!.description!.isNotEmpty) ...[
                    _buildNotesSection(),
                    const SizedBox(height: 32),
                  ],

                  // Action Buttons
                  _buildActionButtons(),

                  const SizedBox(height: 100), // Bottom padding
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPillBadge({
    required String text,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnifiedInfoSection() {
    final isPurchased =
        (_currentItem?.status ?? widget.item.status) == ItemStatus.purchased;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Item Information',
          style: AppStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 20),

        // Status Label - Integrated
        _buildInfoRow(
          icon: isPurchased ? Icons.check_circle : Icons.shopping_bag_outlined,
          label: 'Status',
          value: isPurchased ? 'Gifted' : 'Available',
          iconColor: isPurchased ? AppColors.success : AppColors.warning,
          valueColor: isPurchased ? AppColors.success : AppColors.warning,
        ),

        const SizedBox(height: 16),

        // Category
        _buildInfoRow(
          icon: Icons.category_outlined,
          label: 'Category',
          value: 'General',
          iconColor: AppColors.info,
        ),

        const SizedBox(height: 16),

        // Added Date
        _buildInfoRow(
          icon: Icons.calendar_today_outlined,
          label: 'Added on',
          value: _formatDate(_currentItem?.createdAt ?? widget.item.createdAt),
          iconColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppStyles.caption.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.note_outlined, color: AppColors.info, size: 18),
            const SizedBox(width: 8),
            Text(
              'Notes',
              style: AppStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _currentItem!.description!,
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final isPurchased =
        (_currentItem?.status ?? widget.item.status) == ItemStatus.purchased;
    
    // Check if user is guest
    final authService = Provider.of<AuthRepository>(context, listen: false);
    final isGuest = authService.isGuest;

    // Standardized button height and border radius
    const double buttonHeight = 56.0;
    const double buttonBorderRadius = 16.0;
    const double buttonSpacing = 12.0;

    return Column(
      children: [
        // Button 1: Share Item (Secondary Action)
        SizedBox(
          width: double.infinity,
          height: buttonHeight,
          child: OutlinedButton(
            onPressed: _shareItem,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(buttonBorderRadius),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.share_outlined, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Share Item',
                  style: AppStyles.button.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: buttonSpacing),

        // Button 3: Delete Item (Destructive Action)
        SizedBox(
          width: double.infinity,
          height: buttonHeight,
          child: OutlinedButton(
            onPressed: _deleteItem,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(buttonBorderRadius),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                const SizedBox(width: 8),
                Text(
                  'Delete Item',
                  style: AppStyles.button.copyWith(color: AppColors.error),
                ),
              ],
            ),
          ),
        ),
      ],
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
  void _togglePurchaseStatus() {
    // TODO: Implement API call to update item status
    final newStatus =
        (_currentItem?.status ?? widget.item.status) == ItemStatus.purchased
        ? ItemStatus.desired
        : ItemStatus.purchased;

    setState(() {
      _currentItem =
          _currentItem?.copyWith(status: newStatus) ??
          widget.item.copyWith(status: newStatus);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newStatus == ItemStatus.purchased
              ? 'Wish marked as gifted! 🎉'
              : 'Wish marked as available! 📝',
        ),
        backgroundColor: newStatus == ItemStatus.purchased
            ? AppColors.success
            : AppColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _editItem() {
    // Navigate to edit item screen
    final item = _currentItem ?? widget.item;
    Navigator.pushNamed(
      context,
      AppRoutes.addItem,
      arguments: {
        'wishlistId': item.wishlistId,
        'wishlistName': _wishlistName ?? 'Wishlist',
        'itemId': item.id,
        'isEditing': true,
        'item': item,
      },
    ).then((_) {
      // Refresh item details when returning from edit screen
      if (mounted) {
        _fetchItemDetails();
      }
    });
  }

  void _shareItem() {
    // Share item functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share functionality coming soon!'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _deleteItem() {
    final item = _currentItem ?? widget.item;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: AppColors.error, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Delete Item',
                style: AppStyles.headingSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${item.name}"? This action cannot be undone.',
          style: AppStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
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
            onPressed: () => _performDeleteItem(item),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
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

  Future<void> _performDeleteItem(WishlistItem item) async {
    // Close dialog first
    Navigator.pop(context);
    
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
        final guestDataRepo = Provider.of<GuestDataRepository>(context, listen: false);
        await guestDataRepo.deleteWishlistItem(item.id);

      } else {
        // Call API to delete item for authenticated users
        await _wishlistRepository.deleteItem(item.id);

      }

      // Navigate back to previous screen
      if (mounted) {
        Navigator.pop(context);
        
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
    }
  }
}
