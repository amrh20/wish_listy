import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'package:wish_listy/core/widgets/decorative_background.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/features/wishlists/data/models/wishlist_model.dart';
import 'package:wish_listy/features/wishlists/data/repository/wishlist_repository.dart';
import 'package:wish_listy/features/wishlists/data/repository/guest_data_repository.dart';
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';

enum SourceType { online, physical, anywhere }

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
  Map<String, dynamic>? _rawItemData; // keep raw API data (price/url/purchasedBy object)
  String? _wishlistOwnerId; // Store wishlist owner ID for owner check

  @override
  void initState() {
    super.initState();
    _currentItem = widget.item;
    _initializeAnimations();
    _fetchItemDetails();
  }

  Future<void> _refreshItemDetails() async {
    await _fetchItemDetails();
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
        _rawItemData = itemData;

        // Parse the item data to WishlistItem model
        final updatedItem = WishlistItem.fromJson(itemData);
        
        // Try to get wishlist name and ownerId from itemData or use default
        // API may return `wishlist` as a String id OR an object {name: ..., owner: ...}
        String wishlistName = 'Wishlist';
        String? wishlistOwnerId;
        
        final directName = itemData['wishlistName']?.toString();
        if (directName != null && directName.isNotEmpty) {
          wishlistName = directName;
        }
        
        final wishlistField = itemData['wishlist'];
        if (wishlistField is Map<String, dynamic>) {
          final nestedName = wishlistField['name']?.toString();
          if (nestedName != null && nestedName.isNotEmpty) {
            wishlistName = nestedName;
          }
          
          // Extract ownerId from wishlist object
          final ownerField = wishlistField['owner'];
          if (ownerField is Map<String, dynamic>) {
            wishlistOwnerId = ownerField['_id']?.toString() ?? ownerField['id']?.toString();
          } else if (ownerField is String) {
            wishlistOwnerId = ownerField;
          }
          
          // Also check for userId in wishlist object
          if (wishlistOwnerId == null) {
            wishlistOwnerId = wishlistField['userId']?.toString() ?? 
                             wishlistField['user_id']?.toString();
          }
        }

        if (mounted) {
          setState(() {
            _currentItem = updatedItem;
            _wishlistName = wishlistName;
            _wishlistOwnerId = wishlistOwnerId;
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
    final item = _currentItem ?? widget.item;

    return Scaffold(
      body: DecorativeBackground(
        showGifts: true,
        showCircles: true, // Enable gradient blobs
        child: SafeArea(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : _errorMessage != null
                  ? _buildErrorState()
                  : _currentItem == null
                      ? Center(
                          child: Text(
                            'Item not found',
                            style: AppStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            _buildCleanTopBar(item),
                            Expanded(
                              child: RefreshIndicator(
                                onRefresh: _refreshItemDetails,
                                color: AppColors.primary,
                                child: SingleChildScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header Section (Title + Priority + Date)
                                    _buildHeaderSection(item),
                                    const SizedBox(height: 16),
                                    // Image
                                    if (item.imageUrl != null &&
                                        item.imageUrl!.trim().isNotEmpty) ...[
                                      _buildImageCard(item),
                                      const SizedBox(height: 16),
                                    ],
                                    // Received Banner (if applicable)
                                    if (_isReceived(item)) ...[
                                      _buildGiftedBanner(item),
                                      const SizedBox(height: 16),
                                    ],
                                    // Purchased Banner (if purchased but not received - Owner view)
                                    if (_isOwner() && item.isPurchasedValue && !item.isReceived) ...[
                                      _buildPurchasedBanner(item),
                                      const SizedBox(height: 16),
                                    ],
                                    // Source Section (Online/Physical/Anywhere)
                                    _buildSourceSection(item),
                                    const SizedBox(height: 20),
                                    // Description
                                    _buildDescriptionSection(item),
                                    // Add bottom padding for sticky bar
                                    if (!_isOwner() || (item.isPurchasedValue && !item.isReceived)) 
                                      const SizedBox(height: 80),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          ],
                        ),
        ),
      ),
      // Sticky Bottom Action Bar (Guest View or Owner when purchased but not received)
      bottomNavigationBar: (!_isOwner() || (item.isPurchasedValue && !item.isReceived)) 
          ? _buildStickyActionBar(item) 
          : null,
    );
  }

  bool _isOwner() {
    final authService = Provider.of<AuthRepository>(context, listen: false);
    if (authService.isGuest || authService.userId == null) {
      return false;
    }
    
    // Check if current user is the owner of the wishlist
    if (_wishlistOwnerId == null) {
      return false;
    }
    
    return authService.userId == _wishlistOwnerId;
  }

  Widget _buildCleanTopBar(WishlistItem item) {
    final isReceived = _isReceived(item);
    final isOwner = _isOwner();
    final isReserved = item.isReservedValue; // Check if item is reserved (Teaser Mode)
    final isReservedForOwner = isOwner && isReserved; // Teaser Mode: Owner sees reserved but can't edit/delete
    
    // Helper function to show snackbar when trying to edit/delete reserved item
    void _showReservedItemSnackbar() {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Provider.of<LocalizationService>(context, listen: false).translate('details.cannotEditDeleteReserved'),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            color: AppColors.textPrimary,
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const Spacer(),
          // Only show Share and Edit if user is owner
          if (isOwner) ...[
            IconButton(
              tooltip: 'Share',
              onPressed: () => _shareItem(item),
              icon: const Icon(Icons.share_outlined, size: 22),
              color: AppColors.textPrimary,
              style: IconButton.styleFrom(
                padding: const EdgeInsets.all(8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            if (!isReceived && !isReservedForOwner)
              IconButton(
                tooltip: 'Edit',
                onPressed: _editItem,
                icon: const Icon(Icons.edit_outlined, size: 22),
                color: AppColors.textPrimary,
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            // Show disabled Edit button if reserved (Teaser Mode)
            if (!isReceived && isReservedForOwner)
              IconButton(
                tooltip: 'Edit',
                onPressed: _showReservedItemSnackbar,
                icon: Icon(
                  Icons.edit_outlined, 
                  size: 22,
                ),
                color: AppColors.textTertiary.withOpacity(0.5), // Grey out
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderSection(WishlistItem item) {
    final priorityColor = _getPriorityColor(item.priority);
    final dateText = _formatDate(item.createdAt);
    final isOwner = _isOwner();
    final isReserved = item.isReservedValue; // Check if item is reserved (Teaser Mode)
    final isReceived = item.isReceived; // Check if item is received
    final isReservedForOwner = isOwner && isReserved && !isReceived; // Teaser Mode: Owner sees reserved only if NOT received
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          item.name,
          style: AppStyles.headingLarge.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 28,
            color: AppColors.textPrimary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        // Badge + Date Row
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Show Mystery Badge if reserved for owner (Teaser Mode) AND not received, otherwise show Priority Chip
                if (isReservedForOwner)
                  // Mystery Badge for Teaser Mode - Longer and clearer text
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6A1B9A).withOpacity(0.12), // Deep Purple
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF6A1B9A).withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.visibility_off,
                          size: 16,
                          color: const Color(0xFF6A1B9A), // Deep Purple
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Reserved by a friend 🤫',
                          style: TextStyle(
                            color: const Color(0xFF6A1B9A), // Deep Purple
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  )
            else
              // Priority Chip (default) - or Gifted badge if received
              isReceived
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.success.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Gifted',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: priorityColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getPriorityIcon(item.priority),
                            size: 14,
                            color: priorityColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getPriorityText(item.priority),
                            style: TextStyle(
                              color: priorityColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                const SizedBox(width: 12),
                // Date
                Text(
                  '${Provider.of<LocalizationService>(context, listen: false).translate('details.addedOn')} $dateText',
                  style: AppStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  IconData _getPriorityIcon(ItemPriority priority) {
    switch (priority) {
      case ItemPriority.high:
        return Icons.local_fire_department;
      case ItemPriority.urgent:
        return Icons.priority_high;
      case ItemPriority.medium:
        return Icons.bolt;
      case ItemPriority.low:
        return Icons.spa;
    }
  }

  Widget _buildSourceSection(WishlistItem item) {
    final sourceType = _getSourceType(item);
    
    switch (sourceType) {
      case SourceType.online:
        return _buildOnlineSource(item);
      case SourceType.physical:
        return _buildPhysicalSource(item);
      case SourceType.anywhere:
        return _buildAnywhereSource();
    }
  }

  Widget _buildOnlineSource(WishlistItem item) {
    if (!_shouldShowVisitStore(item)) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          'Where to buy:',
          style: AppStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        // Card
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openStoreUrl(item),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icon Box
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.language,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Middle Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Online Store',
                          style: AppStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tap to visit link',
                          style: AppStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Arrow Icon
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.textTertiary,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhysicalSource(WishlistItem item) {
    final storeName = _getStoreName();
    final storeLocation = _getStoreLocation();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          'Where to buy:',
          style: AppStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        // Card
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: storeLocation != null && storeLocation.isNotEmpty
                ? _openInMaps
                : null,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Icon Box
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.store,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Middle Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              storeName ?? 'Physical Store',
                              style: AppStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (storeLocation != null && storeLocation.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                storeLocation,
                                style: AppStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (storeLocation != null && storeLocation.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _openInMaps,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Row(
                          children: [
                            Icon(Icons.location_on_outlined, 
                                 color: AppColors.primary, 
                                 size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Open in Maps',
                                style: AppStyles.bodySmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, 
                                 color: AppColors.primary, 
                                 size: 14),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnywhereSource() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          'Where to buy:',
          style: AppStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        // Info Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.public,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No specific store listed. You can find this gift anywhere!',
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageCard(WishlistItem item) {
    final url = item.imageUrl!.trim();
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: AppColors.surfaceVariant.withOpacity(0.6),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.surfaceVariant.withOpacity(0.6),
                  child: const Icon(Icons.image_not_supported_outlined),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGiftedBanner(WishlistItem item) {
    // This banner is shown when item is received (isReceived: true)
    // It should display "Marked as gifted" not "Reserved by a friend"
    final isReceived = item.isReceived;
    
    // Only show if item is actually received
    if (!isReceived) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.success.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Marked as gifted',
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchasedBanner(WishlistItem item) {
    // Show banner for owner when item is purchased but not received yet
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.warning.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            color: AppColors.warning,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Purchased by another friend, awaiting confirmation from you that you have received it',
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitStoreButton(WishlistItem item) {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: 'Visit Store 🌐',
        onPressed: () => _openStoreUrl(item),
        variant: ButtonVariant.primary,
      ),
    );
  }

  Widget _buildSoftInfoGrid(WishlistItem item) {
    final w = (MediaQuery.of(context).size.width - 20 * 2 - 12) / 2;

    final priorityColor = _getPriorityColor(item.priority);
    final store = _rawItemData?['storeName']?.toString() ??
        _rawItemData?['store']?.toString() ??
        '—';

    return Wrap(
      runSpacing: 12,
      spacing: 12,
      children: [
        _InfoTile(
          width: w,
          title: 'Date Added',
          value: _formatDate(item.createdAt),
          icon: Icons.calendar_today_outlined,
          iconColor: AppColors.textSecondary,
          chipColor: AppColors.surfaceVariant.withOpacity(0.6),
        ),
        _InfoTile(
          width: w,
          title: 'Store',
          value: (store.trim().isEmpty || store.trim() == 'null') ? '—' : store,
          icon: Icons.storefront_outlined,
          iconColor: AppColors.primary,
          chipColor: AppColors.primary.withOpacity(0.10),
        ),
        _InfoTile(
          width: w,
          title: 'Priority',
          value: _getPriorityText(item.priority),
          icon: Icons.priority_high,
          iconColor: priorityColor,
          chipColor: priorityColor.withOpacity(0.12),
        ),
      ],
    );
  }

  bool _isReceived(WishlistItem item) {
    return item.isReceived;
  }

  // Helper functions to determine item status (matching wishlist_items_screen logic)
  String _getItemStatusText(WishlistItem item) {
    final isPurchased = item.isPurchasedValue;
    final isReserved = item.isReservedValue;
    final isReceived = item.isReceived;
    
    if (isReceived) {
      return 'Gifted';
    } else if (isPurchased && !isReceived) {
      return 'Purchased';
    } else if (isReserved) {
      return 'Reserved';
    } else {
      return 'Available';
    }
  }

  IconData _getItemStatusIcon(WishlistItem item) {
    final isPurchased = item.isPurchasedValue;
    final isReserved = item.isReservedValue;
    final isReceived = item.isReceived;
    
    if (isReceived) {
      return Icons.check_circle;
    } else if (isPurchased && !isReceived) {
      return Icons.shopping_bag_outlined;
    } else if (isReserved) {
      return Icons.lock_outline;
    } else {
      return Icons.shopping_bag_outlined;
    }
  }

  Color _getItemStatusColor(WishlistItem item) {
    final isPurchased = item.isPurchasedValue;
    final isReserved = item.isReservedValue;
    final isReceived = item.isReceived;
    
    if (isReceived) {
      return AppColors.success; // Green for Gifted
    } else if (isPurchased && !isReceived) {
      return AppColors.warning; // Orange/Yellow for Purchased
    } else if (isReserved) {
      return AppColors.warning; // Orange/Yellow for Reserved
    } else {
      return AppColors.info; // Blue for Available
    }
  }

  bool _shouldShowVisitStore(WishlistItem item) {
    // For owner: always show if URL exists
    if (_isOwner()) {
      return true;
    }
    
    // For guest: hide if reserved by someone else
    if (item.reservedBy != null && !_isReservedByMe(item)) {
      return false;
    }
    
    return true;
  }

  // Helper to determine source type
  SourceType _getSourceType(WishlistItem item) {
    final url = _getItemUrl(item);
    if (url != null && url.isNotEmpty) {
      return SourceType.online;
    }
    
    final storeName = _rawItemData?['storeName']?.toString()?.trim();
    final storeLocation = _rawItemData?['storeLocation']?.toString()?.trim();
    
    if ((storeName != null && storeName.isNotEmpty) ||
        (storeLocation != null && storeLocation.isNotEmpty)) {
      return SourceType.physical;
    }
    
    return SourceType.anywhere;
  }

  String? _getStoreName() {
    return _rawItemData?['storeName']?.toString()?.trim() ?? 
           _rawItemData?['store']?.toString()?.trim();
  }

  String? _getStoreLocation() {
    return _rawItemData?['storeLocation']?.toString()?.trim();
  }

  Future<void> _openInMaps() async {
    final storeLocation = _getStoreLocation();
    if (storeLocation == null || storeLocation.isEmpty) {
      return;
    }

    final query = Uri.encodeComponent(storeLocation);
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          final localization = Provider.of<LocalizationService>(context, listen: false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localization.translate('dialogs.couldNotOpenMaps')),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final localization = Provider.of<LocalizationService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localization.translate('dialogs.couldNotOpenMaps')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  bool _isReservedByMe(WishlistItem item) {
    final authService = Provider.of<AuthRepository>(context, listen: false);
    if (authService.isGuest || authService.userId == null) {
      return false;
    }
    // Use isReservedByMe from API if available, otherwise calculate from reservedBy
    // Convert both IDs to String for comparison to ensure type matching
    final reservedById = item.reservedBy?.id?.toString();
    final currentUserId = authService.userId?.toString();
    return item.isReservedByMe ?? (reservedById != null && reservedById == currentUserId);
  }

  Widget _buildStickyActionBar(WishlistItem item) {
    final authService = Provider.of<AuthRepository>(context, listen: false);
    final isOwner = _isOwner();
    final isPurchased = item.isPurchasedValue;
    
    // Case A: Item is Received
    if (item.isReceived) {
      return Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: 12 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              const Text(
                '🎁',
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  Provider.of<LocalizationService>(context, listen: false).translate('details.giftReceivedPurchased'),
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Case A.5: Purchased but not Received (Owner view)
    if (isOwner && isPurchased && !item.isReceived) {
      return Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: 12 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.warning.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    color: AppColors.warning,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      Provider.of<LocalizationService>(context, listen: false).translate('details.purchasedAwaitingConfirmation'),
                      style: AppStyles.bodyMedium.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _toggleReceivedStatus,
                  icon: const Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: Text(
                    Provider.of<LocalizationService>(context, listen: false).translate('details.markReceived'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Case B: Reserved by ME
    if (_isReservedByMe(item)) {
      return Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: 12 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.green.shade200,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade700, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Reserved by You',
                  style: AppStyles.bodyMedium.copyWith(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  // Always use _currentItem if available (it has the latest data from API)
                  // If _currentItem is null, use item parameter
                  final currentItem = _currentItem ?? item;
                  
                  // Force isCurrentlyReserved to true since we're in the "Reserved by ME" case
                  // This ensures we always send "cancel" action when clicking Cancel Reservation
                  _toggleReservationWithAction(currentItem, action: 'cancel');
                },
                child: Text(
                  Provider.of<LocalizationService>(context, listen: false).translate('details.undo'),
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Case C: Reserved by OTHERS (Guest view)
    // Check if item is reserved but NOT by me (using isReserved from API)
    final isReserved = item.isReservedValue;
    final isReservedByMe = _isReservedByMe(item);
    final isReservedByOther = isReserved && !isReservedByMe;
    
    if (isReservedByOther) {
      // For guest: show "Already reserved by another friend 🔒"
      return Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: 12 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.lock_outline, color: Colors.grey.shade600, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  Provider.of<LocalizationService>(context, listen: false).translate('details.alreadyReservedByFriend'),
                  style: AppStyles.bodyMedium.copyWith(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Case D: Available - Large Primary Button
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: 12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: CustomButton(
          text: Provider.of<LocalizationService>(context, listen: false).translate('details.reserveGift'),
          onPressed: () => _toggleReservation(item),
          variant: ButtonVariant.gradient,
          gradientColors: [AppColors.primary, AppColors.secondary],
          icon: Icons.bookmark_outline,
        ),
      ),
    );
  }

  Future<void> _toggleReservation(WishlistItem item) async {
    // Use _isReservedByMe to determine action
    final isCurrentlyReserved = _isReservedByMe(item);
    final action = isCurrentlyReserved ? 'cancel' : 'reserve';
    await _toggleReservationWithAction(item, action: action);
  }

  Future<void> _toggleReservationWithAction(
    WishlistItem item, {
    required String action, // 'reserve' or 'cancel'
  }) async {
    final authService = Provider.of<AuthRepository>(context, listen: false);
    if (authService.isGuest) {
      final localization = Provider.of<LocalizationService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localization.translate('dialogs.pleaseLoginToReserve')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      // Debug: Log the reservation state
      debugPrint('🔍 _toggleReservationWithAction Debug:');
      debugPrint('  - item.isReservedByMe (from API): ${item.isReservedByMe}');
      debugPrint('  - item.reservedBy?.id: ${item.reservedBy?.id}');
      debugPrint('  - authService.userId: ${authService.userId}');
      debugPrint('  - action (explicit): $action');
      
      // Optimistic update
      setState(() {
        if (action == 'cancel') {
          _currentItem = item.copyWith(reservedBy: null);
        } else {
          // Will be updated from API response
        }
      });

      // Call API with explicit action
      final updatedItemData = await _wishlistRepository.toggleReservation(
        item.id,
        action: action, // Explicitly pass 'reserve' or 'cancel'
      );
      final updatedItem = WishlistItem.fromJson(updatedItemData);

      if (mounted) {
        setState(() {
          _currentItem = updatedItem;
        });

        // Refresh item details to ensure UI is up to date
        await _fetchItemDetails();

          // Determine message based on the action we took
          // If action was 'reserve', now it's reserved
          // If action was 'cancel', now it's not reserved
          final isNowReserved = action == 'reserve';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isNowReserved
                  ? 'Item reserved! 🎁'
                  : 'Reservation cancelled',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      // Revert optimistic update
      if (mounted) {
        setState(() {
          _currentItem = item;
        });
        final localization = Provider.of<LocalizationService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localization.translate('dialogs.failedToUpdateReservation')}: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String? _getItemUrl(WishlistItem item) {
    final rawUrl = _rawItemData?['url']?.toString();
    final fromModel = item.link;
    final url = (rawUrl != null && rawUrl.trim().isNotEmpty) ? rawUrl : fromModel;
    if (url == null || url.trim().isEmpty) return null;
    return url.trim();
  }

  String? _getDisplayPrice(WishlistItem item) {
    final rawPrice = _rawItemData?['price']?.toString();
    if (rawPrice != null && rawPrice.trim().isNotEmpty) return rawPrice.trim();

    // Fallback to model's priceRange string if available
    final pr = item.priceRange?.toString();
    if (pr != null && pr.trim().isNotEmpty && pr != 'Price not specified') {
      return pr.trim();
    }
    return null;
  }

  String? _getReservedByName() {
    final rb = _rawItemData?['reservedBy'] ?? _rawItemData?['reserved_by'];
    if (rb is Map) {
      final fullName = rb['fullName']?.toString();
      if (fullName != null && fullName.trim().isNotEmpty) return fullName.trim();
      final username = rb['username']?.toString();
      if (username != null && username.trim().isNotEmpty) return username.trim();
    }
    return null;
  }

  Future<void> _openStoreUrl(WishlistItem item) async {
    final url = _getItemUrl(item);
    if (url == null) return;

    Uri uri;
    try {
      uri = Uri.parse(url);
      if (uri.scheme.isEmpty) {
        uri = Uri.parse('https://$url');
      }
    } catch (_) {
      if (mounted) {
        final localization = Provider.of<LocalizationService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localization.translate('dialogs.invalidUrl')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      final localization = Provider.of<LocalizationService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localization.translate('dialogs.couldNotOpenLink')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildGiftedStatusCard(WishlistItem item) {
    final reservedByName = _getReservedByName();
    final localization = Provider.of<LocalizationService>(context, listen: false);
    final byText = (reservedByName != null && reservedByName.isNotEmpty)
        ? localization.translate('details.byFriend').replaceAll('{name}', reservedByName)
        : localization.translate('details.bySecretFriend');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.14),
            Colors.white.withOpacity(0.85),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: AppColors.primary.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.10),
              ),
            ),
          ),
          Positioned(
            left: -18,
            bottom: -22,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withOpacity(0.08),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.card_giftcard, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎁 Gifted!',
                      style: AppStyles.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      byText,
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
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
    );
  }

  Widget _buildInfoGrid(WishlistItem item) {
    final priorityColor = _getPriorityColor(item.priority);
    final store = _rawItemData?['storeName']?.toString() ??
        _rawItemData?['store']?.toString() ??
        '—';
    final createdAt = item.createdAt;

    return Wrap(
      runSpacing: 12,
      spacing: 12,
      children: [
        _InfoTile(
          width: (MediaQuery.of(context).size.width - 16 * 2 - 12) / 2,
          title: Provider.of<LocalizationService>(context, listen: false).translate('details.priority'),
          value: _getPriorityText(item.priority),
          icon: Icons.priority_high,
          iconColor: priorityColor,
          chipColor: priorityColor.withOpacity(0.12),
        ),
        _InfoTile(
          width: (MediaQuery.of(context).size.width - 16 * 2 - 12) / 2,
          title: Provider.of<LocalizationService>(context, listen: false).translate('details.status'),
          value: _getItemStatusText(item),
          icon: _getItemStatusIcon(item),
          iconColor: _getItemStatusColor(item),
          chipColor: _getItemStatusColor(item).withOpacity(0.12),
        ),
        _InfoTile(
          width: (MediaQuery.of(context).size.width - 16 * 2 - 12) / 2,
          title: Provider.of<LocalizationService>(context, listen: false).translate('details.store'),
          value: (store.trim().isEmpty || store.trim() == 'null') ? '—' : store,
          icon: Icons.storefront_outlined,
          iconColor: AppColors.primary,
          chipColor: AppColors.primary.withOpacity(0.12),
        ),
        _InfoTile(
          width: (MediaQuery.of(context).size.width - 16 * 2 - 12) / 2,
          title: Provider.of<LocalizationService>(context, listen: false).translate('details.added'),
          value: _formatDate(createdAt),
          icon: Icons.calendar_today_outlined,
          iconColor: AppColors.textSecondary,
          chipColor: AppColors.surfaceVariant.withOpacity(0.6),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(WishlistItem item) {
    final desc = item.description?.trim();
    if (desc == null || desc.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Provider.of<LocalizationService>(context, listen: false).translate('details.description'),
          style: AppStyles.headingSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            desc,
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    // lightweight formatting without intl
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '${dt.year}-$m-$d';
  }

  Widget _buildHeader() {
    final isReceived =
        (_currentItem?.isReceived ?? widget.item.isReceived);
    
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
              onPressed: _toggleReceivedStatus,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                isReceived 
                    ? Provider.of<LocalizationService>(context, listen: false).translate('details.markAsNotReceived')
                    : Provider.of<LocalizationService>(context, listen: false).translate('details.markAsReceived'),
                style: AppStyles.caption.copyWith(
                  fontSize: 12,
                  color: isReceived ? AppColors.textSecondary : AppColors.success,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Actions menu (Edit, Delete)
          Builder(
            builder: (context) {
              // Check if item is reserved for owner (Teaser Mode)
              final item = _currentItem ?? widget.item;
              final isOwner = _isOwner();
              final isReserved = item.isReservedValue;
              final isReservedForOwner = isOwner && isReserved;
              
              return PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert, 
                  size: 20,
                  color: isReservedForOwner 
                      ? AppColors.textTertiary.withOpacity(0.5) // Grey out if reserved
                      : AppColors.textPrimary,
                ),
                onSelected: (value) {
                  // If item is reserved, show snackbar instead of executing action
                  if (isReservedForOwner) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'You cannot edit or delete this item because a friend has already reserved it for you! 🎁',
                        ),
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        duration: const Duration(seconds: 3),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                    return;
                  }
                  
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
                  PopupMenuItem<String>(
                    value: 'edit',
                    enabled: !isReservedForOwner, // Disable if reserved
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined, 
                          size: 18, 
                          color: isReservedForOwner 
                              ? AppColors.textTertiary.withOpacity(0.5)
                              : AppColors.textPrimary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Edit',
                          style: TextStyle(
                            color: isReservedForOwner 
                                ? AppColors.textTertiary.withOpacity(0.5)
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    enabled: !isReservedForOwner, // Disable if reserved
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline, 
                          size: 18, 
                          color: isReservedForOwner 
                              ? AppColors.error.withOpacity(0.5)
                              : AppColors.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Delete',
                          style: TextStyle(
                            color: isReservedForOwner 
                                ? AppColors.error.withOpacity(0.5)
                                : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
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
    final item = _currentItem ?? widget.item;
    final isReceived = item.isReceived;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Provider.of<LocalizationService>(context, listen: false).translate('details.itemInformation'),
          style: AppStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 20),

        // Status Label - Integrated
        _buildInfoRow(
          icon: _getItemStatusIcon(item),
          label: Provider.of<LocalizationService>(context, listen: false).translate('details.status'),
          value: _getItemStatusText(item),
          iconColor: _getItemStatusColor(item),
          valueColor: _getItemStatusColor(item),
        ),

        const SizedBox(height: 16),

        // Category
        _buildInfoRow(
          icon: Icons.category_outlined,
          label: Provider.of<LocalizationService>(context, listen: false).translate('details.category'),
          value: 'General',
          iconColor: AppColors.info,
        ),

        const SizedBox(height: 16),

        // Added Date
        _buildInfoRow(
          icon: Icons.calendar_today_outlined,
          label: Provider.of<LocalizationService>(context, listen: false).translate('details.addedOn'),
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
              Provider.of<LocalizationService>(context, listen: false).translate('details.notes'),
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
    final item = _currentItem ?? widget.item;
    final isReceived = item.isReceived;
    final isPurchased = item.isPurchasedValue;
    final isOwner = _isOwner();
    
    // Check if user is guest
    final authService = Provider.of<AuthRepository>(context, listen: false);
    final isGuest = authService.isGuest;

    // Standardized button height and border radius
    const double buttonHeight = 56.0;
    const double buttonBorderRadius = 16.0;
    const double buttonSpacing = 12.0;

    return Column(
      children: [
        // Button 0: Mark Received (if purchased but not received - Owner only)
        if (isOwner && isPurchased && !isReceived) ...[
          SizedBox(
            width: double.infinity,
            height: buttonHeight,
            child: ElevatedButton.icon(
              onPressed: _toggleReceivedStatus,
              icon: const Icon(Icons.check_circle_outline, size: 20, color: Colors.white),
              label: const Text(
                'Mark Received',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(buttonBorderRadius),
                ),
                elevation: 0,
              ),
            ),
          ),
          SizedBox(height: buttonSpacing),
        ],
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
        Builder(
          builder: (context) {
            // Check if item is reserved for owner (Teaser Mode)
            final item = _currentItem ?? widget.item;
            final isOwner = _isOwner();
            final isReserved = item.isReservedValue;
            final isReservedForOwner = isOwner && isReserved;
            
            return SizedBox(
              width: double.infinity,
              height: buttonHeight,
              child: OutlinedButton(
                onPressed: isReservedForOwner 
                    ? () {
                        // Show snackbar instead of deleting
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'You cannot edit or delete this item because a friend has already reserved it for you! 🎁',
                            ),
                            backgroundColor: AppColors.primary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            duration: const Duration(seconds: 3),
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      }
                    : _deleteItem,
                style: OutlinedButton.styleFrom(
                  foregroundColor: isReservedForOwner 
                      ? AppColors.error.withOpacity(0.5)
                      : AppColors.error,
                  side: BorderSide(
                    color: isReservedForOwner 
                        ? AppColors.error.withOpacity(0.5)
                        : AppColors.error, 
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(buttonBorderRadius),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.delete_outline, 
                      size: 20, 
                      color: isReservedForOwner 
                          ? AppColors.error.withOpacity(0.5)
                          : AppColors.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Delete Item',
                      style: AppStyles.button.copyWith(
                        color: isReservedForOwner 
                            ? AppColors.error.withOpacity(0.5)
                            : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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

  // NOTE: _formatDate already exists above (yyyy-mm-dd). Keep one implementation only.

  // Action Handlers
  Future<void> _toggleReceivedStatus() async {
    final authService = Provider.of<AuthRepository>(context, listen: false);
    if (authService.isGuest) {
      final localization = Provider.of<LocalizationService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localization.translate('dialogs.pleaseLoginToMarkReceived')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      final item = _currentItem ?? widget.item;
      final isOwner = _isOwner();
      final isReservedByMe = _isReservedByMe(item);
      
      // If owner, use toggleReceivedStatus; if guest who reserved, use markAsPurchased
      if (isOwner) {
        // Owner: Toggle received status
        final currentStatus = item.isReceived;
        final newStatus = !currentStatus;

        // Optimistic update
        setState(() {
          _currentItem = item.copyWith(isReceived: newStatus);
        });

        // Call API with the correct value
        final updatedItemData = await _wishlistRepository.toggleReceivedStatus(
          itemId: item.id,
          isReceived: newStatus, // Send the new status directly (true or false)
        );
        final updatedItem = WishlistItem.fromJson(updatedItemData);

        if (!mounted) return;

        // Update with server response
        setState(() {
          _currentItem = updatedItem;
        });

        // Refresh item details
        await _fetchItemDetails();

        // Show success snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    updatedItem.isReceived ? Icons.check_circle : Icons.undo,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    updatedItem.isReceived
                        ? 'Marked as Received! ✅'
                        : 'Marked as Not Received',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              backgroundColor: updatedItem.isReceived
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
      } else if (isReservedByMe) {
        // Guest who reserved: Mark as purchased
        // Optimistic update
        setState(() {
          _currentItem = item.copyWith(isReceived: true);
        });

        // Call API to mark as purchased
        final updatedItemData = await _wishlistRepository.markAsPurchased(
          itemId: item.id,
          // purchasedBy is optional - API will use current user if not provided
        );
        final updatedItem = WishlistItem.fromJson(updatedItemData);

        if (!mounted) return;

        // Update with server response
        setState(() {
          _currentItem = updatedItem;
        });

        // Refresh item details
        await _fetchItemDetails();

        // Show success snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Item marked as purchased! 🎁',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
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
      }
    } catch (e) {
      // Revert optimistic update on error
      if (mounted) {
        setState(() {
          _currentItem = _currentItem ?? widget.item;
        });
        final localization = Provider.of<LocalizationService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localization.translate('dialogs.failedToUpdateStatus')}: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _editItem() {
    // Navigate to edit item screen
    final item = _currentItem ?? widget.item;
    
    // Check if item is reserved for owner (Teaser Mode)
    final isOwner = _isOwner();
    final isReserved = item.isReservedValue;
    final isReservedForOwner = isOwner && isReserved;
    
    if (isReservedForOwner) {
      // Show snackbar instead of editing
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'You cannot edit or delete this item because a friend has already reserved it for you! 🎁',
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    
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

  void _shareItem([WishlistItem? item]) {
    // Lightweight "share": copy link (if any) or item name to clipboard
    final it = item ?? _currentItem ?? widget.item;
    final url = _getItemUrl(it);
    final text = (url != null && url.isNotEmpty) ? url : it.name;

    Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      final localization = Provider.of<LocalizationService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localization.translate('dialogs.copiedToClipboard')),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _deleteItem() {
    final item = _currentItem ?? widget.item;
    
    // Check if item is reserved for owner (Teaser Mode)
    final isOwner = _isOwner();
    final isReserved = item.isReservedValue;
    final isReservedForOwner = isOwner && isReserved;
    
    if (isReservedForOwner) {
      // Show snackbar instead of showing delete dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'You cannot edit or delete this item because a friend has already reserved it for you! 🎁',
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    
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
        final localization = Provider.of<LocalizationService>(context, listen: false);
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
                Text(localization.translate('dialogs.deletingItem')),
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

class _InfoTile extends StatelessWidget {
  final double width;
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color chipColor;

  const _InfoTile({
    required this.width,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.chipColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: Colors.black.withOpacity(0.04),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: chipColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
