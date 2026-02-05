import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'package:wish_listy/core/widgets/decorative_background.dart';
import 'package:wish_listy/core/widgets/unified_snackbar.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/services/deep_link_service.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/features/wishlists/data/models/wishlist_model.dart';
import 'package:wish_listy/features/wishlists/data/repository/wishlist_repository.dart';
import 'package:wish_listy/features/wishlists/data/repository/guest_data_repository.dart';
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';
import 'package:wish_listy/features/wishlists/presentation/widgets/item_details/index.dart';

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
      
      // Deep link case: if wishlistId is empty, fetch item first to get wishlistId
      if (widget.item.wishlistId.isEmpty && widget.item.id.isNotEmpty) {
        final itemData = await _wishlistRepository.getItemById(widget.item.id);
        final fetchedItem = WishlistItem.fromJson(itemData);
        
        // Update widget.item with fetched wishlistId
        // Then continue with normal flow
        final updatedItem = WishlistItem(
          id: widget.item.id,
          wishlistId: fetchedItem.wishlistId,
          name: fetchedItem.name,
          description: fetchedItem.description,
          link: fetchedItem.link,
          priceRange: fetchedItem.priceRange,
          imageUrl: fetchedItem.imageUrl,
          priority: fetchedItem.priority,
          status: fetchedItem.status,
          createdAt: fetchedItem.createdAt,
          updatedAt: fetchedItem.updatedAt,
          isReceived: fetchedItem.isReceived,
          reservedBy: fetchedItem.reservedBy,
          wishlist: fetchedItem.wishlist,
        );
        
        if (mounted) {
          setState(() {
            _currentItem = updatedItem;
          });
        }
        
        // Now continue with normal fetch using the updated wishlistId
        // But we already have the item data, so we can use it directly
        _rawItemData = itemData;
        
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
          
          final ownerField = wishlistField['owner'];
          if (ownerField is Map<String, dynamic>) {
            wishlistOwnerId = ownerField['_id']?.toString() ?? ownerField['id']?.toString();
          } else if (ownerField is String) {
            wishlistOwnerId = ownerField;
          }
          
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
        return;
      }
      
      if (authService.isGuest) {
        // Load from local storage for guests

        final guestDataRepo = Provider.of<GuestDataRepository>(context, listen: false);
        final items = await guestDataRepo.getWishlistItems(widget.item.wishlistId);

        // Find the specific item by ID
        final item = items.firstWhere(
          (item) => item.id == widget.item.id,
          orElse: () {

            throw Exception(
              Provider.of<LocalizationService>(context, listen: false)
                  .translate('details.itemNotFound'),
            );
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

    return PopScope(
      canPop: Navigator.canPop(context),
      onPopInvoked: (didPop) {
        if (!didPop) {
          _handleBackNavigation();
        }
      },
      child: Scaffold(
        body: DecorativeBackground(
          showGifts: true,
          showCircles: true, // Enable gradient blobs
          child: SafeArea(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : _errorMessage != null
                  ? ItemDetailsErrorStateWidget(
                      message: _errorMessage!,
                      onRetry: _fetchItemDetails,
                    )
                  : _currentItem == null
                      ? Center(
                          child: Text(
                            Provider.of<LocalizationService>(context, listen: false)
                                .translate('details.itemNotFound'),
                            style: AppStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            ItemTopBarWidget(
                              isOwner: _isOwner(),
                              isReceived: item.isReceived,
                              isReserved: item.isReservedValue,
                              onBack: _handleBackNavigation,
                              onShare: () => _shareItem(item),
                              onEdit: _editItem,
                            ),
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
                                    ItemHeaderSectionWidget(
                                      item: item,
                                      isOwner: _isOwner(),
                                      dateText: _formatDate(item.createdAt),
                                    ),
                                    const SizedBox(height: 20),
                                    
                                    // Image
                                    if (item.imageUrl != null &&
                                        item.imageUrl!.trim().isNotEmpty) ...[
                                      ItemImageCardWidget(imageUrl: item.imageUrl!),
                                      const SizedBox(height: 20),
                                    ],
                                    
                                    // Status Card (Reserved/Purchased/Gifted/Available)
                                    ItemStatusCardWidget(
                                      item: item,
                                      isOwner: _isOwner(),
                                      isReservedByMe: _isReservedByMe(item),
                                      onMarkReceived: _toggleReceivedStatus,
                                    ),
                                    const SizedBox(height: 20),
                                    
                                    // Where to Buy Card
                                    ItemWhereToBuyCardWidget(
                                      url: _getItemUrl(item),
                                      storeName: _getStoreName(),
                                      storeLocation: _getStoreLocation(),
                                      onTap: () => _openStoreUrl(item),
                                    ),
                                    const SizedBox(height: 20),
                                    
                                    // Description
                                    ItemDescriptionWidget(description: item.description),
                                    
                                    // Add bottom padding for sticky bar
                                    if (_shouldShowBottomActionBar(item)) 
                                      const SizedBox(height: 100),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          ],
                        ),
        ),
      ),
      // Sticky Bottom Action Bar
      // Hide during loading to prevent showing button before data is ready
      // Hide when item is purchased/gifted for non-owners
      // Hide when item is received (gifted) for everyone
      // Show "Mark as Received" only for owner when purchased but not received
      bottomNavigationBar: _shouldShowBottomActionBar(item)
          ? ItemActionBarWidget(
              item: item,
              isOwner: _isOwner(),
              isReservedByMe: _isReservedByMe(item),
              onMarkReceived: _toggleReceivedStatus,
              onCancelReservation: () {
                final currentItem = _currentItem ?? item;
                _toggleReservationWithAction(currentItem, action: 'cancel');
              },
              onReserve: () => _toggleReservation(item),
            )
          : null,
      ),
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

  /// Determine if bottom action bar should be shown
  /// Owner: Only show "Mark as Received" if item is Reserved or Purchased (and not received)
  /// Non-Owner: Show standard guest actions (Reserve, Cancel Reservation, etc.)
  bool _shouldShowBottomActionBar(WishlistItem item) {
    // Hide during loading
    if (_isLoading || _currentItem == null) {
      return false;
    }

    final isPurchased = item.isPurchasedValue;
    final isReceived = item.isReceived;
    final isReserved = item.isReservedValue;
    final isOwner = _isOwner();

    // Owner View Logic
    if (isOwner) {
      // Owner should NOT see Reserve, Buy, or Undo actions
      // Only show "Mark as Received" if item is Reserved or Purchased (and not received)
      if (isReceived) {
        // Item is already received - no action needed
        return false;
      }
      
      // Show "Mark as Received" button if item is Reserved or Purchased
      if (isReserved || isPurchased) {
        return true;
      }
      
      // Item is Available - owner sees no action button (Edit is in top bar)
      return false;
    }

    // Non-Owner View Logic
    // Hide if item is received (gifted) - for everyone
    if (isReceived) {
      return false;
    }

    // Hide if purchased and user is NOT the owner
    // (purchaser should not see "Undo" action once purchase is confirmed)
    if (isPurchased && !isOwner) {
      return false;
    }

    // Show for available or reserved items (non-owner)
    return true;
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

  // Helper to determine source type

  String? _getStoreName() {
    return _rawItemData?['storeName']?.toString()?.trim() ?? 
           _rawItemData?['store']?.toString()?.trim();
  }

  String? _getStoreLocation() {
    return _rawItemData?['storeLocation']?.toString()?.trim();
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
    final localization = Provider.of<LocalizationService>(context, listen: false);
    if (authService.isGuest) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localization.translate('dialogs.pleaseLoginToReserve')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Show loading snackbar
    if (mounted) {
      UnifiedSnackbar.showLoading(
        context: context,
        message: action == 'reserve'
            ? (localization.translate('details.reservingItem') ?? 'Reserving...')
            : (localization.translate('details.cancellingReservation') ?? 'Cancelling reservation...'),
        duration: const Duration(minutes: 1),
      );
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
        final isNowReserved = action == 'reserve';

        UnifiedSnackbar.hideCurrent(context);
        UnifiedSnackbar.showSuccess(
          context: context,
          message: isNowReserved
              ? (localization.translate('dialogs.itemReservedSuccessfully') ?? 'Item reserved! 🎁')
              : (localization.translate('dialogs.reservationCancelledSuccessfully') ?? 'Reservation cancelled'),
        );
      }
    } catch (e) {
      // Revert optimistic update
      if (mounted) {
        UnifiedSnackbar.hideCurrent(context);
        setState(() {
          _currentItem = item;
        });
        final localization = Provider.of<LocalizationService>(context, listen: false);
        UnifiedSnackbar.showError(
          context: context,
          message: localization.translate('dialogs.failedToUpdateReservation') ?? 'Failed to update reservation',
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
        ItemDetailsInfoTileWidget(
          width: (MediaQuery.of(context).size.width - 16 * 2 - 12) / 2,
          title: Provider.of<LocalizationService>(context, listen: false).translate('details.priority'),
          value: _getPriorityText(item.priority),
          icon: Icons.priority_high,
          iconColor: priorityColor,
          chipColor: priorityColor.withOpacity(0.12),
        ),
        ItemDetailsInfoTileWidget(
          width: (MediaQuery.of(context).size.width - 16 * 2 - 12) / 2,
          title: Provider.of<LocalizationService>(context, listen: false).translate('details.status'),
          value: _getItemStatusText(item),
          icon: _getItemStatusIcon(item),
          iconColor: _getItemStatusColor(item),
          chipColor: _getItemStatusColor(item).withOpacity(0.12),
        ),
        ItemDetailsInfoTileWidget(
          width: (MediaQuery.of(context).size.width - 16 * 2 - 12) / 2,
          title: Provider.of<LocalizationService>(context, listen: false).translate('details.store'),
          value: (store.trim().isEmpty || store.trim() == 'null') ? '—' : store,
          icon: Icons.storefront_outlined,
          iconColor: AppColors.primary,
          chipColor: AppColors.primary.withOpacity(0.12),
        ),
        ItemDetailsInfoTileWidget(
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
    
    // Get wishlistId from currentItem (which has the latest data) or fallback to widget.item
    final wishlistId = _currentItem?.wishlistId ?? item.wishlistId;
    
    // Validate wishlistId before navigation
    if (wishlistId.isEmpty) {
      final localization = Provider.of<LocalizationService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localization.translate('dialogs.invalidWishlistId'),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Try to refresh item details to get the wishlistId
      _fetchItemDetails();
      return;
    }
    
    Navigator.pushNamed(
      context,
      AppRoutes.addItem,
      arguments: {
        'wishlistId': wishlistId,
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
    final it = item ?? _currentItem ?? widget.item;
    final itemName = it.name;
    
    // Use DeepLinkService to share the item
    DeepLinkService.shareItem(
      itemId: it.id,
      itemName: itemName,
    );
  }

  void _handleBackNavigation() {
    // Check if we can pop (normal navigation)
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }
    
    // If canPop is false, we came from deep link
    // Navigate to parent wishlist screen
    final item = _currentItem ?? widget.item;
    final wishlistId = item.wishlistId;
    
    if (wishlistId.isNotEmpty) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.wishlistItems,
        arguments: {
          'wishlistId': wishlistId,
          'wishlistName': _wishlistName ?? 'Wishlist',
          'totalItems': 0,
          'purchasedItems': 0,
          'isFriendWishlist': false,
        },
      );
    } else {
      // Fallback: navigate to home/main navigation
      Navigator.pushReplacementNamed(context, AppRoutes.mainNavigation);
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
    
    final localization = Provider.of<LocalizationService>(context, listen: false);
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
                localization.translate('details.deleteItem'),
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
