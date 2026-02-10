import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/widgets/primary_gradient_button.dart';
import 'package:wish_listy/core/widgets/decorative_background.dart';
import 'package:wish_listy/core/widgets/animated_background.dart';
import 'package:wish_listy/core/widgets/unified_snackbar.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/services/deep_link_service.dart';
import 'package:wish_listy/features/wishlists/data/models/wishlist_model.dart';
import 'package:wish_listy/features/wishlists/data/repository/wishlist_repository.dart';
import 'package:wish_listy/features/wishlists/data/repository/guest_data_repository.dart';
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/features/friends/data/models/user_model.dart' as friends;
import '../widgets/index.dart';
import 'package:wish_listy/features/profile/presentation/screens/guest_login_prompt_dialog.dart';

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
  String? _ownerId; // Owner ID of the wishlist

  final WishlistRepository _wishlistRepository = WishlistRepository();
  
  // Check if current user is the owner
  bool _isOwner() {
    final authService = Provider.of<AuthRepository>(context, listen: false);
    if (authService.isGuest || _ownerId == null) return false;
    return authService.userId == _ownerId;
  }

  Future<void> _shareWishlist() async {
    final authService = Provider.of<AuthRepository>(context, listen: false);
    if (authService.isGuest) {
      showDialog(
        context: context,
        builder: (_) => const GuestLoginPromptDialog(),
      );
      return;
    }

    await DeepLinkService.shareWishlist(
      wishlistId: widget.wishlistId,
      wishlistName: _wishlistName.isNotEmpty ? _wishlistName : widget.wishlistName,
    );
  }

  Future<void> _editWishlist() async {
    await Navigator.pushNamed(
      context,
      AppRoutes.createWishlist,
      arguments: {
        'wishlistId': widget.wishlistId,
        // Intentionally omit previousRoute so back returns here safely
      },
    );
    if (!mounted) return;
    await _loadWishlistDetails();
  }

  Future<void> _confirmAndDeleteWishlist() async {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    final wishlistDisplayName =
        _wishlistName.isNotEmpty ? _wishlistName : widget.wishlistName;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            localization.translate('wishlists.deleteWishlist'),
            style: AppStyles.headingSmall.copyWith(fontWeight: FontWeight.bold),
          ),
          content: Text(
            localization.translate(
              'wishlists.deleteWishlistConfirmation',
              args: {'name': wishlistDisplayName},
            ),
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                localization.translate('app.cancel'),
                style: AppStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                localization.translate('app.delete'),
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

    if (shouldDelete != true) return;
    if (!mounted) return;

    try {
      // Check if user is guest
      final authService = Provider.of<AuthRepository>(context, listen: false);

      if (authService.isGuest) {
        // Delete from local storage for guests
        final guestDataRepo = Provider.of<GuestDataRepository>(
          context,
          listen: false,
        );
        await guestDataRepo.deleteWishlist(widget.wishlistId);
      } else {
        await _wishlistRepository.deleteWishlist(widget.wishlistId);
      }

      if (!mounted) return;

      // Pop back to previous screen and let it refresh if it wants
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.mainNavigation,
          (route) => false,
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${localization.translate('wishlists.failedToDeleteWishlist')}: ${e.message}',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localization.translate('wishlists.failedToDeleteWishlistTryAgain'),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadWishlistDetails();
  }

  /// Refresh wishlist details (for pull-to-refresh)
  Future<void> _refreshWishlistDetails() async {
    await _loadWishlistDetails();
  }

  /// Load wishlist details and items from API or local storage
  Future<void> _loadWishlistDetails() async {
    final localization = Provider.of<LocalizationService>(context, listen: false);

    // Validate wishlistId
    if (widget.wishlistId.isEmpty) {

      setState(() {
        _errorMessage = localization.translate('wishlists.invalidWishlistId');
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
          throw Exception(localization.translate('wishlists.wishlistNotFound'));
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
                .where((item) => item.isReceived)
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
              ? localization.translate('wishlists.wishlistNotFound')
              : localization.translate('wishlists.failedToLoadWishlist'),
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
            .where((item) => item.isReceived)
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

      // Get owner ID from wishlist data
      final ownerId = data['owner']?['_id']?.toString() ?? 
                      data['owner']?['id']?.toString() ??
                      data['ownerId']?.toString() ??
                      data['user_id']?.toString() ??
                      data['userId']?.toString();

      if (mounted) {
        setState(() {
          _items = items;
          _totalItems = totalItems;
          _purchasedItems = purchasedItems;
          _wishlistName = data['name']?.toString() ?? widget.wishlistName;
          _category = category;
          _privacy = privacy;
          _createdAt = createdAt;
          _ownerId = ownerId;
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
            : localization.translate('wishlists.failedToLoadWishlist');
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
                        localization.translate('wishlists.unexpectedErrorOccurred'),
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
              label: localization.translate('common.retry'),
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

    // Parse status - support both 'status' and 'itemStatus' fields
    ItemStatus status = ItemStatus.desired;
    final statusStr = (data['itemStatus']?.toString() ?? 
                      data['status']?.toString() ?? 
                      'desired').toLowerCase();
    
    // Check if item is reserved using isReserved field or totalReserved > 0
    final isReserved = data['isReserved'] as bool? ?? 
                      (data['totalReserved'] as int? ?? 0) > 0;
    
    // If isReserved is true, set status to reserved
    if (isReserved) {
      status = ItemStatus.reserved;
    } else {
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

    // Parse isReceived and reservedBy
    final isReceived = data['isReceived'] as bool? ?? 
                      data['is_received'] as bool? ?? 
                      false;
    
    // Parse isPurchased: direct from API, fallback to isReceived
    final isPurchased = data['isPurchased'] as bool? ?? 
                       data['is_purchased'] as bool?;
    
    // Parse isReservedByMe: direct from API
    final isReservedByMe = data['isReservedByMe'] as bool? ?? 
                          data['is_reserved_by_me'] as bool?;
    
    // Parse isReserved: direct from API (use the value already parsed above)
    final isReservedFromApi = data['isReserved'] as bool? ?? 
                             data['is_reserved'] as bool?;
    
    // Parse availableQuantity: direct from API
    final availableQuantity = data['availableQuantity'] as int? ?? 
                             data['available_quantity'] as int?;
    
    // Parse reservedBy
    friends.User? reservedBy;
    if (data['reservedBy'] != null && data['reservedBy'] is Map) {
      try {
        reservedBy = friends.User.fromJson(data['reservedBy'] as Map<String, dynamic>);
      } catch (e) {
        reservedBy = null;
      }
    } else if (data['reserved_by'] != null && data['reserved_by'] is Map) {
      try {
        reservedBy = friends.User.fromJson(data['reserved_by'] as Map<String, dynamic>);
      } catch (e) {
        reservedBy = null;
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
      createdAt: createdAt,
      updatedAt: updatedAt,
      isReceived: isReceived,
      reservedBy: reservedBy,
      isPurchased: isPurchased,
      isReservedByMe: isReservedByMe,
      isReserved: isReservedFromApi,
      availableQuantity: availableQuantity,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<WishlistItem> get _filteredItems {
    final authService = Provider.of<AuthRepository>(context, listen: false);
    final isGuest = authService.isGuest;
    
    return _items.where((item) {
      final matchesSearch =
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (item.description?.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ??
              false);

      // For guest users, only apply search filter (no status/gifted filter)
      if (isGuest) {
        return matchesSearch;
      }

      switch (_selectedFilter) {
        case 'all':
          return matchesSearch;
        case 'available':
          // Available = isReserved == false AND isReceived == false
          final isReserved = item.isReservedValue;
          final isReceived = item.isReceived;
          return matchesSearch && !isReserved && !isReceived;
        case 'reserved':
          // Reserved = isReserved == true AND isReceived == false
          final isReserved = item.isReservedValue;
          final isReceived = item.isReceived;
          return matchesSearch && isReserved && !isReceived;
        case 'purchased':
        case 'gifted':
          // Gifted = isReceived == true
          final isReceived = item.isReceived;
          return matchesSearch && isReceived;
        default:
          return matchesSearch;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    if (_isLoading) {
      return WishlistItemsLoadingWidget(localization: localization);
    }

    if (_errorMessage != null) {
      return WishlistItemsErrorWidget(
        message: _errorMessage!,
        onRetry: _loadWishlistDetails,
        localization: localization,
      );
    }

    final authService = Provider.of<AuthRepository>(context, listen: false);
    final isGuest = authService.isGuest;

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
                        WishlistItemsHeaderWidget(
                          isOwner: _isOwner(),
                          isGuest: isGuest,
                          isFriendWishlist: widget.isFriendWishlist,
                          onBack: () => Navigator.pop(context),
                          onShare: _shareWishlist,
                          onAddItem: () async {
                            await Navigator.pushNamed(
                              context,
                              AppRoutes.addItem,
                              arguments: {
                                'wishlistId': widget.wishlistId,
                                'wishlistName': _wishlistName.isNotEmpty
                                    ? _wishlistName
                                    : widget.wishlistName,
                              },
                            );
                            if (!mounted) return;
                            _loadWishlistDetails();
                          },
                          onEdit: _editWishlist,
                          onDelete: _confirmAndDeleteWishlist,
                          localization: localization,
                        ),
                        const SizedBox(height: 20),
                        WishlistItemsTitleBlockWidget(
                          title: _wishlistName.isNotEmpty
                              ? _wishlistName
                              : widget.wishlistName,
                          totalItems: _totalItems,
                          purchasedItems: _purchasedItems,
                          isGuest: isGuest,
                          localization: localization,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: WishlistItemsSearchFilterWidget(
                      searchController: _searchController,
                      onSearchChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                      selectedFilter: _selectedFilter,
                      onFilterChanged: (value) {
                        setState(() => _selectedFilter = value);
                      },
                      isGuest: isGuest,
                      localization: localization,
                    ),
                  ),

                  // Scrollable Content
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return RefreshIndicator(
                          onRefresh: _refreshWishlistDetails,
                          color: AppColors.primary,
                          child: CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
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

                                    // Get current user ID
                                    final currentUserId = authService.userId;

                                    return WishlistItemCardWidget(
                                      item: item,
                                      priorityColor: priorityColor,
                                      onTap: () => _openItemDetails(item),
                                      // Show edit/delete menu for owner only (not for friend wishlists)
                                      onEdit: (widget.isFriendWishlist || !_isOwner())
                                          ? null
                                          : () => _editItem(item),
                                      onDelete: (widget.isFriendWishlist || !_isOwner())
                                          ? null
                                          : () => _deleteItem(item),
                                      // Disable swipe for friend wishlists and guest users
                                      enableSwipe:
                                          !widget.isFriendWishlist && !isGuest,
                                      // New parameters for Gift Lifecycle
                                      isOwner: _isOwner(),
                                      currentUserId: currentUserId,
                                      // Guest can reserve items in friend wishlists
                                      // Pass action explicitly: 'reserve' or 'cancel'
                                      onToggleReservation: (!_isOwner() && !isGuest)
                                          ? (String action) => _toggleReservation(item, action: action)
                                          : null,
                                      // Allow owner OR guest who reserved the item to mark as purchased
                                      onToggleReceivedStatus: (!isGuest && (_isOwner() || (item.isReservedByMe ?? false)))
                                          ? () {
                                              // If owner, use toggleReceivedStatus; if guest who reserved, use markAsPurchased
                                              if (_isOwner()) {
                                                _toggleReceivedStatus(item);
                                              } else {
                                                _markAsPurchased(item);
                                              }
                                            }
                                          : null,
                                    );
                                  }, childCount: _filteredItems.length),
                                ),
                              ),
                          ],
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

  /// Toggle reservation for an item
  /// [action] - 'reserve' or 'cancel' (required)
  Future<void> _toggleReservation(WishlistItem item, {required String action}) async {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    // Show loading snackbar
    if (mounted) {
      UnifiedSnackbar.showLoading(
        context: context,
        message: action == 'reserve'
            ? (loc.translate('details.reservingItem') ?? 'Reserving...')
            : (loc.translate('details.cancellingReservation') ?? 'Cancelling reservation...'),
        duration: const Duration(minutes: 1),
      );
    }

    try {
      final authService = Provider.of<AuthRepository>(context, listen: false);

      // Optimistic update so "Reserved" filter shows the item immediately
      setState(() {
        final index = _items.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          if (action == 'cancel') {
            _items[index] = item.copyWith(
              reservedBy: null,
              isReserved: false,
              isReservedByMe: false,
            );
          } else {
            final userId = authService.userId;
            _items[index] = item.copyWith(
              isReserved: true,
              isReservedByMe: true,
              reservedBy: userId != null && userId.isNotEmpty
                  ? friends.User(
                      id: userId,
                      fullName: '',
                      username: '',
                    )
                  : null,
            );
          }
        }
      });

      // Call API with explicit action
      final updatedItemData = await _wishlistRepository.toggleReservation(
        item.id,
        action: action,
      );
      final updatedItem = WishlistItem.fromJson(updatedItemData);

      if (!mounted) return;

      final isNowReserved = action == 'reserve';

      // Update with server response (no full refresh so Reserved filter keeps working)
      setState(() {
        final index = _items.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          _items[index] = updatedItem;
        }
      });

      if (mounted) {
        UnifiedSnackbar.hideCurrent(context);
        UnifiedSnackbar.showSuccess(
          context: context,
          message: isNowReserved
              ? (loc.translate('dialogs.itemReservedSuccessfully') ?? 'Item reserved! 🎁')
              : (loc.translate('dialogs.reservationCancelledSuccessfully') ?? 'Reservation cancelled'),
        );
      }
    } catch (e) {
      if (!mounted) return;

      UnifiedSnackbar.hideCurrent(context);
      // Revert optimistic update on error
      setState(() {
        final index = _items.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          _items[index] = item;
        }
      });

      if (mounted) {
        UnifiedSnackbar.showError(
          context: context,
          message: loc.translate('dialogs.failedToUpdateReservation') ?? 'Failed to update reservation',
        );
      }
    }
  }

  /// Mark item as purchased (for guest who reserved the item)
  Future<void> _markAsPurchased(WishlistItem item) async {
    try {
      // Optimistic update
      setState(() {
        final index = _items.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          _items[index] = item.copyWith(isReceived: true);
        }
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
        final index = _items.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          _items[index] = updatedItem;
        }
      });

      // Refresh wishlist items to ensure UI is up to date
      await _loadWishlistDetails();

      // Show success snackbar
      if (mounted) {
        final loc = Provider.of<LocalizationService>(context, listen: false);
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
                  loc.translate('dialogs.itemMarkedAsPurchased'),
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
    } catch (e) {
      // Revert optimistic update on error
      if (mounted) {
        setState(() {
          final index = _items.indexWhere((i) => i.id == item.id);
          if (index != -1) {
            _items[index] = item;
          }
        });
        final localization = Provider.of<LocalizationService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localization.translate('dialogs.failedToMarkAsPurchased')}: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Toggle received status for an item (Owner only)
  Future<void> _toggleReceivedStatus(WishlistItem item) async {
    try {
      // Get current status - use isReceived directly from the item
      final currentStatus = item.isReceived;
      // Calculate new status: if currently false, send true; if currently true, send false
      final newStatus = !currentStatus;

      // Optimistic update
      setState(() {
        final index = _items.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          _items[index] = item.copyWith(isReceived: newStatus);
        }
      });

      // Call API with the correct value (newStatus, not !currentStatus to be explicit)
      final updatedItemData = await _wishlistRepository.toggleReceivedStatus(
        itemId: item.id,
        isReceived: newStatus, // Send the new status directly (true or false)
      );
      final updatedItem = WishlistItem.fromJson(updatedItemData);

      if (!mounted) return;

      // Update with server response
      setState(() {
        final index = _items.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          _items[index] = updatedItem;
        }
      });

      // Show success snackbar
      if (mounted) {
        final loc = Provider.of<LocalizationService>(context, listen: false);
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
                      ? loc.translate('dialogs.markedAsReceived')
                      : loc.translate('dialogs.markedAsNotReceived'),
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
    } catch (e) {
      if (!mounted) return;

      // Revert optimistic update on error
      setState(() {
        final index = _items.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          _items[index] = item;
        }
      });

      // Show error snackbar
      if (mounted) {
        final loc = Provider.of<LocalizationService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc.translate('dialogs.failedToUpdateStatus'),
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
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 2,
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
            Provider.of<LocalizationService>(context, listen: false).translate('dialogs.deleteItem'),
            style: AppStyles.headingSmall.copyWith(fontWeight: FontWeight.bold),
          ),
          content: Text(
            Provider.of<LocalizationService>(context, listen: false).translate('dialogs.areYouSureDeleteItemFull', args: {'itemName': item.name}),
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                Provider.of<LocalizationService>(context, listen: false).translate('app.cancel'),
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
                Provider.of<LocalizationService>(context, listen: false).translate('app.delete'),
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
                    Provider.of<LocalizationService>(context, listen: false)
                        .translate('wishlists.unexpectedErrorOccurred'),
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
