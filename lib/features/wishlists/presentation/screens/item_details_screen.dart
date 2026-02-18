import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/utils/app_constants.dart';
import 'package:wish_listy/core/widgets/confirmation_dialog.dart';
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
  bool _isExtendingReservation = false;
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
        backgroundColor: Colors.transparent,
        extendBody: true,
        extendBodyBehindAppBar: true,
        appBar: _isLoading || _errorMessage != null || _currentItem == null
            ? null
            : AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                titleSpacing: 0.0,
                centerTitle: false,
                systemOverlayStyle: SystemUiOverlayStyle.dark,
                iconTheme: IconThemeData(color: AppColors.textPrimary, size: 22),
                leading: Padding(
                  padding: EdgeInsets.zero,
                  child: GestureDetector(
                    onTap: _handleBackNavigation,
                    behavior: HitTestBehavior.opaque,
                    child: Icon(
                      Icons.arrow_back_ios,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                actions: _isOwner()
                    ? [
                        IconButton(
                          tooltip: Provider.of<LocalizationService>(context, listen: false).translate('app.share'),
                          onPressed: () => _shareItem(item),
                          icon: const Icon(Icons.share_outlined, size: 22),
                          color: AppColors.textPrimary,
                          style: IconButton.styleFrom(
                            padding: const EdgeInsets.all(8),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        if (!item.isReceived && !(item.isReservedValue && _isOwner()))
                          IconButton(
                            tooltip: Provider.of<LocalizationService>(context, listen: false).translate('app.edit'),
                            onPressed: _editItem,
                            icon: const Icon(Icons.edit_outlined, size: 22),
                            color: AppColors.textPrimary,
                            style: IconButton.styleFrom(
                              padding: const EdgeInsets.all(8),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          )
                        else
                          IconButton(
                            tooltip: Provider.of<LocalizationService>(context, listen: false).translate('app.edit'),
                            onPressed: _showReservedItemSnackbarForEdit,
                            icon: const Icon(Icons.edit_outlined, size: 22),
                            color: AppColors.textTertiary.withOpacity(0.5),
                            style: IconButton.styleFrom(
                              padding: const EdgeInsets.all(8),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                      ]
                    : null,
              ),
        body: Stack(
          children: [
            DecorativeBackground(
              showGifts: true,
              showCircles: true,
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(20, 2 + kToolbarHeight, 20, 0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ) ??
                                              AppStyles.headingLarge.copyWith(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 26,
                                                color: AppColors.textPrimary,
                                              ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 12),
                                        _buildMetadataBadge(item, _formatDate(item.createdAt)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child: RefreshIndicator(
                                      onRefresh: _refreshItemDetails,
                                      color: AppColors.primary,
                                      child: SingleChildScrollView(
                                        physics: const AlwaysScrollableScrollPhysics(),
                                        padding: const EdgeInsets.only(bottom: 24),
                                        child: _buildSingleContentCard(item),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
              ),
            ),
            // Confetti Lottie disabled: animation asset contained a trophy/cup graphic;
            // user requested to remove the cup entirely from the screen.
          ],
        ),
      bottomNavigationBar: _shouldShowBottomActionBar(item)
          ? Material(
              color: Colors.transparent,
              elevation: 0.0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 20),
                  child: ItemActionBarWidget(
                    item: item,
                    isOwner: _isOwner(),
                    isReservedByMe: _isReservedByMe(item),
                    onMarkReceived: _toggleReceivedStatus,
                    onCancelReservation: () {
                      final currentItem = _currentItem ?? item;
                      final loc = Provider.of<LocalizationService>(context, listen: false);
                      ConfirmationDialog.show(
                        context: context,
                        isSuccess: false,
                        title: loc.translate('details.unreserveGiftTitle') ?? 'Changed your mind?',
                        message: loc.translate('details.unreserveGiftMessage') ?? 'By canceling, this gift will be available for others to reserve. Do you want to proceed?',
                        primaryActionLabel: loc.translate('details.cancelReservation'),
                        onPrimaryAction: () => _toggleReservationWithAction(currentItem, action: 'cancel'),
                        secondaryActionLabel: loc.translate('common.cancel'),
                        onSecondaryAction: () {},
                        accentColor: AppColors.warning,
                        icon: Icons.undo_rounded,
                      );
                    },
                    onReserve: () => _openReservationDeadlineSheet(item),
                    onExtendReservation: () => _openExtendReservationSheet(_currentItem ?? item),
                    isExtendingReservation: _isExtendingReservation,
                    onMarkAsNotReceived: () => _showMarkAsNotReceivedConfirmation(_currentItem ?? item),
                  ),
                ),
              ),
            )
          : null,
      ),
    );
  }

  /// Description block: show content or placeholder when empty so layout doesn't look broken.
  Widget _buildDescriptionSection(String? description) {
    final hasDescription = description != null && description.trim().isNotEmpty;
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final label = loc.translate('details.description') ?? 'Description';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppStyles.bodySmall.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          hasDescription ? description!.trim() : (loc.translate('details.noDescription') ?? 'No description'),
          style: AppStyles.bodyMedium.copyWith(
            color: hasDescription ? AppColors.textPrimary : AppColors.textTertiary,
            height: 1.5,
            fontStyle: hasDescription ? FontStyle.normal : FontStyle.italic,
          ),
        ),
      ],
    );
  }

  /// Single white card: status badge + image, description, where to buy, price.
  Widget _buildSingleContentCard(WishlistItem item) {
    final statusText = _getItemStatusText(item);
    final statusColor = _getItemStatusColor(item);
    final statusIcon = _getItemStatusIcon(item);
    final hasWhereToBuy = (_getItemUrl(item) != null && _getItemUrl(item)!.trim().isNotEmpty) ||
        (_getStoreName() != null && _getStoreName()!.trim().isNotEmpty) ||
        (_getStoreLocation() != null && _getStoreLocation()!.trim().isNotEmpty);
    final hasDescription = item.description != null && item.description!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Reserve space below status badge so content doesn't clash
                const SizedBox(height: 36),
                if (item.imageUrl != null && item.imageUrl!.trim().isNotEmpty) ...[
                  _buildItemImageWithOptionalGiftedOverlay(item),
                  const SizedBox(height: 20),
                ],
                if (item.isReceived) ...[
                  Center(
                    child: Icon(
                      Icons.celebration,
                      color: const Color(0xFF2E7D32),
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildGiftedMessageCard(context),
                  const SizedBox(height: 20),
                ],
                if (item.isPurchasedValue && !item.isReceived) ...[
                  _buildPurchasedPendingMessageCard(context),
                  const SizedBox(height: 20),
                ],
                if (item.description != null && item.description!.trim().isNotEmpty) ...[
                  _buildDescriptionSection(item.description),
                  const SizedBox(height: 20),
                ],
                ItemWhereToBuyCardWidget(
                  url: _getItemUrl(item),
                  storeName: _getStoreName(),
                  storeLocation: _getStoreLocation(),
                  onTap: () => _openStoreUrl(item),
                ),
                if (hasWhereToBuy) const SizedBox(height: 20),
                if (!hasDescription && !hasWhereToBuy && !_isGiftedOrPurchased(item)) ...[
                  Text(
                    Provider.of<LocalizationService>(context, listen: false).translate('details.noSpecificStoreListed') ?? 'No specific store listed. You can find this gift anywhere!',
                    style: AppStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                if (_getDisplayPrice(item) != null) ...[
                  Text(
                    Provider.of<LocalizationService>(context, listen: false).translate('details.price') ?? 'Price',
                    style: AppStyles.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _getDisplayPrice(item)!,
                    style: AppStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_shouldShowBottomActionBar(item)) const SizedBox(height: 80),
              ],
            ),
          ),
          Positioned.directional(
            textDirection: Directionality.of(context),
            top: 12,
            end: 12,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 16, color: statusColor),
                const SizedBox(width: 6),
                Text(
                  statusText,
                  style: AppStyles.bodySmall.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isGiftedOrPurchased(WishlistItem item) {
    return item.isReceived || item.isPurchasedValue;
  }

  Widget _buildItemImageWithOptionalGiftedOverlay(WishlistItem item) {
    final isReceived = item.isReceived;
    final isPurchasedPending = item.isPurchasedValue && !isReceived;
    if (!isReceived && !isPurchasedPending) {
      return ItemImageCardWidget(imageUrl: item.imageUrl!);
    }
    // Received: trophy/gift celebration style. Purchased pending: "On the way" style.
    final isCelebration = isReceived;
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final label = isCelebration
        ? (loc.translate('details.gifted') ?? 'Granted')
        : (loc.translate('details.purchasedPendingLabel') ?? 'Purchased & Pending');
    final accentColor = isCelebration ? const Color(0xFF2E7D32) : AppColors.purchased;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        ItemImageCardWidget(imageUrl: item.imageUrl!),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: isCelebration
                  ? Center(
                      child: Text(
                        label,
                        style: AppStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                          fontSize: 18,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.schedule_rounded, color: accentColor, size: 28),
                        const SizedBox(width: 10),
                        Text(
                          label,
                          style: AppStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGiftedMessageCard(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    final text = localization.translate('details.giftedMessageCard') ??
        'Someone special has already granted this wish. It\'s no longer available for others.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, color: const Color(0xFF2E7D32), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppStyles.bodyMedium.copyWith(
                color: const Color(0xFF1B5E20),
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// "Waiting for confirmation" / "On the way" card when purchased but not yet received.
  Widget _buildPurchasedPendingMessageCard(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    final text = localization.translate('details.purchasedAwaitingConfirmation') ??
        'This gift has been purchased and is on its way. Waiting for confirmation of receipt.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.purchasedLight.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.purchased.withOpacity(0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.purchased.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.schedule_rounded, color: AppColors.purchased, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.purchased,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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

  /// Shows confirmation dialog for "I didn't get this yet" (mark as not received).
  void _showMarkAsNotReceivedConfirmation(WishlistItem item) {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    ConfirmationDialog.show(
      context: context,
      isSuccess: false,
      title: loc.translate('details.notReceivedYetTitle') ?? 'Not received yet?',
      message: loc.translate('details.notReceivedYetMessage') ??
          'We will notify the buyer to check the status, and the gift will be marked as not purchased. Proceed?',
      primaryActionLabel: loc.translate('dialogs.confirm') ?? 'Proceed',
      onPrimaryAction: () => _performMarkAsNotReceived(item),
      secondaryActionLabel: loc.translate('common.cancel'),
      onSecondaryAction: () {},
      accentColor: AppColors.warning,
      icon: Icons.help_outline_rounded,
    );
  }

  /// Calls API to mark item as not received, then updates state and shows success.
  Future<void> _performMarkAsNotReceived(WishlistItem item) async {
    try {
      final updatedItemData =
          await _wishlistRepository.markItemAsNotReceived(item.id);
      final updatedItem = WishlistItem.fromJson(updatedItemData);

      if (!mounted) return;

      setState(() {
        _currentItem = updatedItem;
      });
      await _fetchItemDetails();

      if (!mounted) return;
      final loc = Provider.of<LocalizationService>(context, listen: false);
      UnifiedSnackbar.showSuccess(
        context: context,
        message: loc.translate('messages.itemMarkedNotReceived') ?? 'Status updated. The buyer will be notified.',
      );
    } catch (e) {
      if (!mounted) return;
      final loc = Provider.of<LocalizationService>(context, listen: false);
      UnifiedSnackbar.showError(
        context: context,
        message: loc.translate('dialogs.failedToUpdateStatus') ??
            'Failed to update status. Please try again.',
      );
    }
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
    // When received (gifted), show bottom bar with celebratory banner
    if (isReceived) {
      return true;
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

  Color _getPriorityColor(ItemPriority priority) {
    switch (priority) {
      case ItemPriority.high:
      case ItemPriority.urgent:
        return AppColors.error;
      case ItemPriority.medium:
        return AppColors.warning;
      case ItemPriority.low:
        return AppColors.info;
    }
  }

  String _getPriorityText(ItemPriority priority) {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    switch (priority) {
      case ItemPriority.high:
        return loc.translate('ui.priorityHigh') ?? 'High';
      case ItemPriority.urgent:
        return loc.translate('ui.priorityUrgent') ?? 'Urgent';
      case ItemPriority.medium:
        return loc.translate('ui.priorityMedium') ?? 'Medium';
      case ItemPriority.low:
        return loc.translate('ui.priorityLow') ?? 'Low';
    }
  }

  Widget _buildMetadataBadge(WishlistItem item, String dateText) {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    final isOwner = _isOwner();
    final isReserved = item.isReservedValue;
    final isReceived = item.isReceived;
    final isPurchased = item.isPurchasedValue;
    // Show "Reserved by friend" only when reserved and NOT purchased (purchased replaces reservation in the UI)
    final isReservedForOwner = isOwner && isReserved && !isReceived && !isPurchased;
    final priorityColor = _getPriorityColor(item.priority);

    Widget badge;
    if (isReceived) {
      // Received (Granted) – elegant chip, no border, subtle green tint
      badge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, size: 14, color: AppColors.success),
            const SizedBox(width: 6),
            Text(
              localization.translate('details.gifted'),
              style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    } else if (isReservedForOwner) {
      // Reserved by a friend (owner view) – only when not purchased
      badge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF6A1B9A).withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF6A1B9A).withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.visibility_off, size: 16, color: Color(0xFF6A1B9A)),
            const SizedBox(width: 8),
            Text(
              localization.translate('details.reservedByFriend'),
              style: const TextStyle(color: Color(0xFF6A1B9A), fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    } else {
      // Priority (available, etc.)
      badge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: priorityColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: priorityColor.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getPriorityIcon(item.priority), size: 14, color: priorityColor),
            const SizedBox(width: 6),
            Text(
              _getPriorityText(item.priority),
              style: TextStyle(color: priorityColor, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    }
    // When purchased, hide top status entirely – only show date; status is in bottom action bar
    if (isPurchased) {
      return Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          '${localization.translate('details.addedOn')} $dateText',
          style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 12),
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        badge,
        const SizedBox(height: 8),
        Text(
          '${localization.translate('details.addedOn')} $dateText',
          style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  void _showReservedItemSnackbarForEdit() {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.translate('details.cannotEditDeleteReserved')),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  bool _isReceived(WishlistItem item) {
    return item.isReceived;
  }

  // Helper functions to determine item status (matching wishlist_items_screen logic)
  String _getItemStatusText(WishlistItem item) {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final isPurchased = item.isPurchasedValue;
    final isReserved = item.isReservedValue;
    final isReceived = item.isReceived;
    
    if (isReceived) {
      return loc.translate('details.gifted') ?? 'Granted';
    } else if (isPurchased && !isReceived) {
      return loc.translate('ui.purchased') ?? 'Purchased';
    } else if (isReserved) {
      return loc.translate('ui.reserved') ?? 'Reserved';
    } else {
      return loc.translate('ui.available') ?? 'Available';
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
      return AppColors.purchased; // Light blue theme for Purchased
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

  Future<void> _openReservationDeadlineSheet(WishlistItem item) async {
    await ReservationDeadlineBottomSheet.show(
      context,
      onConfirm: (DateTime? reservedUntil) {
        _toggleReservationWithAction(item, action: 'reserve', reservedUntil: reservedUntil);
      },
    );
  }

  /// Opens the reservation deadline bottom sheet in extension mode.
  /// On confirm, calls the API with the selected [reservedUntil] date.
  /// Pre-selects the item's current [reservedUntil] in the date picker.
  Future<void> _openExtendReservationSheet(WishlistItem item) async {
    await ReservationDeadlineBottomSheet.show(
      context,
      isExtension: true,
      initialDeadline: item.reservedUntil,
      onConfirm: (DateTime? reservedUntil) {
        if (reservedUntil != null) {
          _extendReservation(item, reservedUntil);
        }
      },
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
    DateTime? reservedUntil,
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

      // Optimistic update
      setState(() {
        if (action == 'cancel') {
          _currentItem = item.copyWith(reservedBy: null);
        } else {
          // Will be updated from API response
        }
      });

      // Call API with explicit action (and optional reservedUntil for reserve)
      final updatedItemData = await _wishlistRepository.toggleReservation(
        item.id,
        action: action,
        reservedUntil: action == 'reserve' ? reservedUntil : null,
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

  Future<void> _extendReservation(WishlistItem item, DateTime reservedUntil) async {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    if (!mounted) return;
    setState(() => _isExtendingReservation = true);
    try {
      final updatedItemData = await _wishlistRepository.extendReservation(item.id, reservedUntil);
      final updatedItem = WishlistItem.fromJson(updatedItemData);
      if (mounted) {
        setState(() {
          _currentItem = updatedItem;
          _isExtendingReservation = false;
        });
        await _fetchItemDetails();
        UnifiedSnackbar.showSuccess(
          context: context,
          message: localization.translate('dialogs.reservationExtendedSuccessfully') ?? 'Reservation extended!',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExtendingReservation = false);
        UnifiedSnackbar.showError(
          context: context,
          message: localization.translate('dialogs.failedToExtendReservation') ?? 'Failed to extend reservation',
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
                          Provider.of<LocalizationService>(context, listen: false).translate('app.edit') ?? 'Edit',
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
                          Provider.of<LocalizationService>(context, listen: false).translate('app.delete') ?? 'Delete',
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
              Provider.of<LocalizationService>(context, listen: false).translate('app.delete') ?? 'Delete',
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
