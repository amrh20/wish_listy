import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/features/wishlists/data/models/wishlist_model.dart';

/// Modern swipeable wishlist item card widget
class WishlistItemCardWidget extends StatefulWidget {
  final WishlistItem item;
  final Color priorityColor;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool enableSwipe;
  final bool isOwner; // Whether current user is the owner
  final String? currentUserId; // Current user ID for reservation checks
  final Function(String action)? onToggleReservation; // Toggle reservation (Guest only) - action: 'reserve' or 'cancel'
  final VoidCallback? onToggleReceivedStatus; // Toggle received status (Owner only)

  const WishlistItemCardWidget({
    super.key,
    required this.item,
    required this.priorityColor,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.enableSwipe = true,
    this.isOwner = false,
    this.currentUserId,
    this.onToggleReservation,
    this.onToggleReceivedStatus,
  });

  @override
  State<WishlistItemCardWidget> createState() => _WishlistItemCardWidgetState();
}

class _WishlistItemCardWidgetState extends State<WishlistItemCardWidget> {
  void _handleDeleteWithConfirmation() {
    // Show confirmation dialog before deleting
    final localization = Provider.of<LocalizationService>(context, listen: false);
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(localization.translate('dialogs.deleteItem')),
          content: Text(localization.translate('dialogs.areYouSureDeleteItem').replaceAll('{itemName}', widget.item.name)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                localization.translate('common.cancel'),
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Call delete after confirmation
                widget.onDelete?.call();
                
                // Show confirmation snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${widget.item.name} ${localization.translate('messages.itemDeleted')}'),
                    backgroundColor: AppColors.textPrimary,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Text(
                localization.translate('app.delete'),
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getPriorityText(ItemPriority priority) {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    switch (priority) {
      case ItemPriority.high:
        return localization.translate('ui.priorityHigh') ?? 'High';
      case ItemPriority.medium:
        return localization.translate('ui.priorityMedium') ?? 'Medium';
      case ItemPriority.low:
        return localization.translate('ui.priorityLow') ?? 'Low';
      case ItemPriority.urgent:
        return localization.translate('ui.priorityUrgent') ?? 'Urgent';
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
    // Build the clean card content
    Widget cardContent = _ModernWishlistItemContent(
      item: widget.item,
      priorityColor: widget.priorityColor,
      onTap: widget.onTap,
      onEdit: widget.onEdit,
      onDelete: widget.onDelete,
      getPriorityText: _getPriorityText,
      getCategoryIcon: _getCategoryIcon,
      isOwner: widget.isOwner,
      currentUserId: widget.currentUserId,
      onToggleReservation: widget.onToggleReservation,
      onToggleReceivedStatus: widget.onToggleReceivedStatus,
    );

    // Check if item is reserved and user is owner (Teaser Mode)
    final isReserved = widget.item.isReservedValue;
    final isReservedForOwner = widget.isOwner && isReserved;
    
    // Helper function to show snackbar when trying to edit/delete reserved item
    void _showReservedItemSnackbar() {
      final loc = Provider.of<LocalizationService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loc.translate('ui.cannotEditReservedItem') ?? 'You cannot edit or delete this item because a friend has already reserved it for you!',
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

    // Wrap with Slidable only if swipe is enabled
    if (widget.enableSwipe) {
      return Slidable(
        key: Key(widget.item.id),
        // Right swipe (start-to-end): No longer used (removed purchase endpoint)
        startActionPane: null,
        // Left swipe (end-to-start): Edit and Delete
        endActionPane: (widget.onEdit != null || widget.onDelete != null)
            ? ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.5,
          children: [
            if (widget.onEdit != null)
              CustomSlidableAction(
                onPressed: isReservedForOwner 
                    ? (_) => _showReservedItemSnackbar()
                    : (_) => widget.onEdit?.call(),
                backgroundColor: isReservedForOwner 
                    ? AppColors.textTertiary.withOpacity(0.5) // Grey out if reserved
                    : AppColors.info, // Blue
                foregroundColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.edit, 
                      size: 28, 
                      color: isReservedForOwner 
                          ? Colors.white.withOpacity(0.7)
                          : Colors.white,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Provider.of<LocalizationService>(context, listen: false).translate('app.edit') ?? 'Edit',
                      style: TextStyle(
                        color: isReservedForOwner 
                            ? Colors.white.withOpacity(0.7)
                            : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            if (widget.onDelete != null)
              CustomSlidableAction(
                onPressed: isReservedForOwner 
                    ? (_) => _showReservedItemSnackbar()
                    : (_) => _handleDeleteWithConfirmation(),
                backgroundColor: isReservedForOwner 
                    ? AppColors.textTertiary.withOpacity(0.5) // Grey out if reserved
                    : AppColors.error, // Red
                foregroundColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.delete, 
                      size: 28, 
                      color: isReservedForOwner 
                          ? Colors.white.withOpacity(0.7)
                          : Colors.white,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Provider.of<LocalizationService>(context, listen: false).translate('app.delete') ?? 'Delete',
                      style: TextStyle(
                        color: isReservedForOwner 
                            ? Colors.white.withOpacity(0.7)
                            : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
              )
            : null,
        child: cardContent,
      );
    }

    // Return card without swipe actions
    return cardContent;
  }
}

/// Internal widget for the card content
class _ModernWishlistItemContent extends StatelessWidget {
  final WishlistItem item;
  final Color priorityColor;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String Function(ItemPriority) getPriorityText;
  final IconData Function(String) getCategoryIcon;
  final bool isOwner;
  final String? currentUserId;
  final Function(String action)? onToggleReservation; // action: 'reserve' or 'cancel'
  final VoidCallback? onToggleReceivedStatus;

  const _ModernWishlistItemContent({
    required this.item,
    required this.priorityColor,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    required this.getPriorityText,
    required this.getCategoryIcon,
    this.isOwner = false,
    this.currentUserId,
    this.onToggleReservation,
    this.onToggleReceivedStatus,
  });

  @override
  Widget build(BuildContext context) {
    // Determine visual state based on isOwner and item status
    // Use direct API values with fallback to computed values
    // IMPORTANT:
    // `isPurchasedValue` falls back to `isReceived`, which is correct for some calculations,
    // but for UI states we must distinguish between:
    // - Purchased (isPurchased == true AND isReceived == false)
    // - Gifted/Received (isReceived == true)
    final isReceived = item.isReceived;
    final isPurchased = item.isPurchased ?? false;
    final isReservedByMe = item.isReservedByMe ?? (item.reservedBy?.id == currentUserId);
    final isReserved = item.isReservedValue; // isReserved ?? (reservedBy != null)
    final isReservedByOther = isReserved && !isReservedByMe;
    
    // Case A: Owner
    if (isOwner) {
      return _buildOwnerCard(context, isPurchased: isPurchased, isReceived: isReceived);
    }
    
    // Case B: Guest
    return _buildGuestCard(
      context,
      isPurchased: isPurchased,
      isReceived: isReceived,
      isReservedByMe: isReservedByMe,
      isReservedByOther: isReservedByOther,
    );
  }

  Widget _buildOwnerCard(
    BuildContext context, {
    required bool isPurchased,
    required bool isReceived,
  }) {
    final hasMenu = onEdit != null || onDelete != null;
    final isReserved = item.isReservedValue; // Check if item is reserved (Teaser Mode)
    // Hide edit if purchased OR reserved (Teaser Mode) OR already received (gifted)
    final shouldShowEdit = onEdit != null && !isPurchased && !isReserved && !isReceived;
    final theme = Theme.of(context);
    
    // Helper function to show snackbar when trying to edit/delete reserved item
    void _showReservedItemSnackbar() {
      final loc = Provider.of<LocalizationService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loc.translate('ui.cannotEditReservedItem') ?? 'You cannot edit or delete this item because a friend has already reserved it for you!',
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

    // Apply subtle opacity if purchased (owner can still interact)
    // Increased opacity to make card clearer (0.85 instead of 0.75)
    final shouldDim = isPurchased || isReceived;
    
    return Opacity(
      opacity: shouldDim ? 0.85 : 1.0,
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              // Add border for reserved items (Teaser Mode) to make them stand out
              // Add green border for received items
              border: isReceived
                  ? Border.all(
                      color: AppColors.success.withOpacity(0.4), // Green border for received
                      width: 2,
                    )
                  : (isReserved && !isPurchased
                      ? Border.all(
                          color: const Color(0xFF6A1B9A).withOpacity(0.3), // Deep Purple border
                          width: 1.5,
                        )
                      : null),
              boxShadow: [
                BoxShadow(
                  color: isReceived
                      ? AppColors.success.withOpacity(0.15) // Green shadow for received
                      : (isReserved && !isPurchased
                          ? const Color(0xFF6A1B9A).withOpacity(0.1) // Purple shadow for reserved
                          : Colors.black.withOpacity(0.05)),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Main Content Row (Image + Title/Category + Menu)
                  InkWell(
                    onTap: onTap, // Allow tap even if purchased to view details
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon/Image - Show gift icon if received
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isReceived
                                ? AppColors.success.withOpacity(0.15) // Green background for received
                                : (isPurchased
                                    ? AppColors.success.withOpacity(0.15)
                                    : priorityColor.withOpacity(0.1)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isReceived
                                ? Icons.card_giftcard_rounded // Gift icon for received items
                                : getCategoryIcon('General'),
                            color: isReceived
                                ? AppColors.success // Green icon for received
                                : (isPurchased ? AppColors.success : priorityColor),
                            size: 24,
                          ),
                        ),
                    const SizedBox(width: 12),
                    // Title & Category Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: AppStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              decoration: isPurchased
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                              color: isPurchased
                                  ? AppColors.textTertiary
                                  : AppColors.textPrimary,
                            ),
                            child: Text(item.name),
                          ),
                          const SizedBox(height: 4),
                          // Show Mystery Badge if reserved (Teaser Mode) AND not received, otherwise show priority
                          if (isReserved && !isReceived)
                            // Mystery Badge for Teaser Mode - Longer and clearer text
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.visibility_off,
                                      size: 14,
                                      color: const Color(0xFF6A1B9A), // Deep Purple
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        Provider.of<LocalizationService>(context, listen: false).translate('ui.reservedByAFriend') ?? 'Reserved by a friend',
                                        style: AppStyles.caption.copyWith(
                                          color: const Color(0xFF6A1B9A), // Deep Purple
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  Provider.of<LocalizationService>(context, listen: false).translate('ui.friendReservedThisGift') ?? 'A friend has reserved this gift for you!',
                                  style: AppStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 10,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            )
                          else if (isReceived)
                            // Gifted Badge - Item is received
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 14,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  Provider.of<LocalizationService>(context, listen: false).translate('ui.gifted') ?? 'Gifted',
                                  style: AppStyles.caption.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          else if (isPurchased)
                            // Purchased Badge - Purchased but not received yet
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 14,
                                  color: AppColors.success,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  Provider.of<LocalizationService>(context, listen: false).translate('ui.purchasedWithCheck') ?? 'Purchased',
                                  style: AppStyles.caption.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          else
                            // Priority Badge (default)
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: priorityColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  getPriorityText(item.priority),
                                  style: AppStyles.caption.copyWith(
                                    color: priorityColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    // 3-Dots Menu (Top Right)
                    // Show menu if available, but grey out if reserved (Teaser Mode) or purchased
                    if (hasMenu)
                      PopupMenuButton<String>(
                        color: Colors.white,
                        icon: Icon(
                          Icons.more_vert,
                          // Keep menu accessible when isReceived == true (so user can delete),
                          // but grey it out when reserved/purchased and NOT received.
                          color: ((isReserved || isPurchased) && !isReceived)
                              ? AppColors.textTertiary.withOpacity(0.5) // Grey out if reserved or purchased
                              : AppColors.textTertiary,
                          size: 20,
                        ),
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        onSelected: (value) {
                          // Owner rules:
                          // - Edit is disabled when reserved/purchased/received
                          // - Delete is allowed when received (gifted) even if reserved
                          if (value == 'edit') {
                            if (isReserved || isPurchased || isReceived) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isReceived
                                        ? 'This gift is already marked as received and can’t be edited.'
                                        : (isPurchased
                                            ? 'This item has been purchased and cannot be edited.'
                                            : 'This item is reserved and cannot be edited.'),
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
                            onEdit?.call();
                            return;
                          }

                          if (value == 'delete') {
                            // Block delete only when reserved and NOT received (teaser mode),
                            // and when purchased but NOT received.
                            if ((isReserved && !isReceived) || (isPurchased && !isReceived)) {
                              if (isPurchased) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'This item has been purchased and cannot be deleted.',
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
                              } else {
                                _showReservedItemSnackbar();
                              }
                              return;
                            }
                            onDelete?.call();
                          }
                        },
                        itemBuilder: (context) => [
                          if (onEdit != null)
                            PopupMenuItem<String>(
                              value: 'edit',
                              enabled: !isReserved && !isPurchased && !isReceived,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit,
                                    color: (isReserved || isPurchased || isReceived)
                                        ? AppColors.textTertiary.withOpacity(0.5)
                                        : AppColors.textPrimary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    Provider.of<LocalizationService>(context, listen: false).translate('app.edit') ?? 'Edit',
                                    style: AppStyles.bodyMedium.copyWith(
                                      color: (isReserved || isPurchased || isReceived)
                                          ? AppColors.textTertiary.withOpacity(0.5)
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (onDelete != null)
                            PopupMenuItem<String>(
                              value: 'delete',
                              // Allow delete if received (gifted), even if reserved.
                              enabled: !(isPurchased && !isReceived) && !(isReserved && !isReceived),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete,
                                    color: ((isReserved || isPurchased) && !isReceived)
                                        ? AppColors.error.withOpacity(0.5)
                                        : AppColors.error, 
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    Provider.of<LocalizationService>(context, listen: false).translate('app.delete') ?? 'Delete',
                                    style: AppStyles.bodyMedium.copyWith(
                                      color: ((isReserved || isPurchased) && !isReceived)
                                          ? AppColors.error.withOpacity(0.5)
                                          : AppColors.error,
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
              // 2. Spacing
              if (onToggleReceivedStatus != null)
                const SizedBox(height: 8),
              // 3. Status Toggle (Bottom Right)
              if (onToggleReceivedStatus != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: _buildReceivedStatusToggle(context, item.isReceived, theme),
                ),
                ],
              ),
            ),
          ),
          // Gift icon badge in top right corner when received
          if (isReceived)
            Positioned(
              top: 8,
              // Move the badge slightly left so it doesn't overlap the 3-dots menu.
              right: hasMenu ? 44 : 8,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.celebration_rounded, // Celebration/gift icon
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Show confirmation dialog before toggling reservation status
  void _confirmToggleReservation(BuildContext context, bool isReservedByMe) {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            isReservedByMe ? (loc.translate('ui.cancelReservationQuestion') ?? 'Cancel Reservation?') : (loc.translate('ui.reserveGiftQuestion') ?? 'Reserve Gift?'),
            style: AppStyles.headingSmall.copyWith(fontWeight: FontWeight.bold),
          ),
          content: Text(
            isReservedByMe
                ? (loc.translate('ui.cancelReservationConfirmContent') ?? 'This will release the item so others can reserve it. Are you sure?')
                : (loc.translate('ui.reserveGiftConfirmContent') ?? 'This will mark the item as reserved by you, preventing others from reserving it. Continue?'),
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                loc.translate('app.cancel'),
                style: AppStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Pass explicit action: 'cancel' if reserved by me, 'reserve' otherwise
                onToggleReservation?.call(isReservedByMe ? 'cancel' : 'reserve');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                loc.translate('dialogs.confirm') ?? 'Confirm',
                style: AppStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Show confirmation dialog before marking as purchased
  void _confirmMarkAsPurchased(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            loc.translate('ui.markAsPurchasedQuestion') ?? 'Mark as Purchased?',
            style: AppStyles.headingSmall.copyWith(fontWeight: FontWeight.bold),
          ),
          content: Text(
            loc.translate('ui.markAsPurchasedContent') ?? 'This will mark the item as purchased and received. Have you already bought this gift?',
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                loc.translate('app.cancel'),
                style: AppStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onToggleReceivedStatus?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                loc.translate('ui.markAsPurchased') ?? 'Mark as Purchased',
                style: AppStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Show confirmation dialog before toggling received status
  void _confirmToggleStatus(BuildContext context, bool isReceived) {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            isReceived ? (loc.translate('ui.undoReceivedQuestion') ?? 'Undo Received Status?') : (loc.translate('ui.markAsReceivedQuestion') ?? 'Mark as Received?'),
            style: AppStyles.headingSmall.copyWith(fontWeight: FontWeight.bold),
          ),
          content: Text(
            isReceived
                ? (loc.translate('ui.undoReceivedContent') ?? 'This will mark the item as active again.')
                : (loc.translate('ui.markAsReceivedContent') ?? 'This will mark the item as purchased and received. Are you sure you got this gift?'),
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                loc.translate('app.cancel'),
                style: AppStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onToggleReceivedStatus?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                loc.translate('dialogs.confirm') ?? 'Confirm',
                style: AppStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Build the sleek interactive status toggle widget
  Widget _buildReceivedStatusToggle(BuildContext context, bool isReceived, ThemeData theme) {
    final isPurchased = item.isPurchasedValue;
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final markReceivedLabel = loc.translate('details.markReceived') ?? 'Mark Received';

    if (isReceived) {
      // State B: Item IS Received - Hide action button, show status text
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          textDirection: Directionality.of(context),
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              Provider.of<LocalizationService>(context, listen: false).translate('ui.markedAsGifted') ?? 'Received',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    } else if (isPurchased && !isReceived) {
      // State C: Item is Purchased by another friend but NOT Received yet
      // Show status text + action button for owner to confirm receipt
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.warning.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  color: AppColors.warning,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    loc.translate('details.purchasedAwaitingConfirmation') ?? 'Purchased by another friend, awaiting confirmation from you that you have received it',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Action button
          ElevatedButton.icon(
            onPressed: () => _confirmToggleStatus(context, isReceived),
            icon: const Icon(
              Icons.check_circle_outline,
              size: 16,
              color: Colors.white,
            ),
            label: Text(
              markReceivedLabel,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          ),
        ],
      );
    } else {
      // State A: Item is NOT Received and NOT Purchased - Show action button
      return ElevatedButton.icon(
        onPressed: () => _confirmToggleStatus(context, isReceived),
        icon: const Icon(
          Icons.check_circle_outline,
          size: 16,
          color: Colors.white,
        ),
        label: Text(
          markReceivedLabel,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
      );
    }
  }

  Widget _buildGuestCard(
    BuildContext context, {
    required bool isPurchased,
    required bool isReceived,
    required bool isReservedByMe,
    required bool isReservedByOther,
  }) {
    // Case A: Gifted/Received (isReceived == true) - Highest Priority for NON-OWNER too
    // This fixes the bug where non-owners were seeing "Reserved/Taken" instead of "Gifted".
    if (isReceived) {
      return Opacity(
        opacity: 0.9,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.success.withOpacity(0.45),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withOpacity(0.12),
                blurRadius: 8,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    textDirection: Directionality.of(context),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.card_giftcard_rounded,
                          color: AppColors.success,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.name,
                              style: AppStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              textDirection: Directionality.of(context),
                              mainAxisSize: MainAxisSize.min,
                              children: Directionality.of(context) == TextDirection.rtl
                                  ? [
                                      Text(
                                        Provider.of<LocalizationService>(context, listen: false).translate('ui.gifted') ?? 'Gifted',
                                        style: AppStyles.caption.copyWith(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(
                                        Icons.check_circle,
                                        size: 14,
                                        color: AppColors.success,
                                      ),
                                    ]
                                  : [
                                      const Icon(
                                        Icons.check_circle,
                                        size: 14,
                                        color: AppColors.success,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        Provider.of<LocalizationService>(context, listen: false).translate('ui.gifted') ?? 'Gifted',
                                        style: AppStyles.caption.copyWith(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.celebration_rounded,
                        color: AppColors.success,
                        size: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.success.withOpacity(0.18),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        Provider.of<LocalizationService>(context, listen: false).translate('ui.markedAsGifted') ?? 'Received',
                        style: AppStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Case B: Purchased (isPurchased == true AND isReceived == false)
    if (isPurchased) {
      return Opacity(
        opacity: 0.85, // Increased opacity to make card clearer
        child: Container(
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
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: InkWell(
              onTap: onTap, // Allow tap to view details even if purchased
              borderRadius: BorderRadius.circular(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.textTertiary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      getCategoryIcon('General'),
                      color: AppColors.textTertiary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title & Status Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.name,
                          style: AppStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.lineThrough,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Purchased Badge (purchased but not received yet)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
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
                                size: 12,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Purchased',
                                style: AppStyles.caption.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Case B: Reserved by Me (isReservedByMe == true) - High Priority
    if (isReservedByMe) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.success,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.success.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Content Row
              InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        getCategoryIcon('General'),
                        color: AppColors.success,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title & Status Column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.name,
                            style: AppStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            textDirection: Directionality.of(context),
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 14,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                Provider.of<LocalizationService>(context, listen: false).translate('ui.reservedByYou') ?? 'Reserved by You',
                                style: AppStyles.caption.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Spacing
              if (onToggleReservation != null || (onToggleReceivedStatus != null && !isPurchased))
                const SizedBox(height: 8),
              // Action Buttons Row (Cancel Reservation + Mark as Purchased)
              if (onToggleReservation != null || (onToggleReceivedStatus != null && !isPurchased))
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Mark as Purchased Button (if not purchased yet and onToggleReceivedStatus is available)
                    if (onToggleReceivedStatus != null && !isPurchased)
                      ElevatedButton.icon(
                        onPressed: () => _confirmMarkAsPurchased(context),
                        icon: Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: Text(
                          Provider.of<LocalizationService>(context, listen: false).translate('ui.markAsPurchased') ?? 'Mark as Purchased',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    // Cancel Reservation Button (Error/Red Style)
                    if (onToggleReservation != null)
                      OutlinedButton.icon(
                        onPressed: () {
                          // Explicitly pass 'cancel' action for Cancel Reservation button
                          _confirmToggleReservation(context, true);
                        },
                        icon: Icon(
                          Icons.close,
                          size: 16,
                          color: AppColors.error,
                        ),
                        label: Text(
                          Provider.of<LocalizationService>(context, listen: false).translate('ui.cancelReserve') ?? 'Cancel Reserve',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          side: BorderSide(color: AppColors.error, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      );
    }

    // Case C: Reserved by Someone Else (isReserved == true && !isReservedByMe)
    if (isReservedByOther) {
      return Opacity(
        opacity: 0.8, // Dimmed to show unavailability
        child: Container(
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
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Content Row
                InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon with Status Badge overlay
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.textTertiary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              getCategoryIcon('General'),
                              color: AppColors.textTertiary,
                              size: 24,
                            ),
                          ),
                          // Status Badge overlay (top-right corner)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey[800]!.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                textDirection: Directionality.of(context),
                                children: [
                                  Icon(
                                    Icons.lock_outline,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    Provider.of<LocalizationService>(context, listen: false).translate('ui.reserved') ?? 'Reserved',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      // Title & Status Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.name,
                              style: AppStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              textDirection: Directionality.of(context),
                              children: [
                                if (item.reservedBy?.profileImage != null)
                                  CircleAvatar(
                                    radius: 8,
                                    backgroundImage: NetworkImage(item.reservedBy!.profileImage!),
                                  )
                                else
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        item.reservedBy?.fullName.substring(0, 1).toUpperCase() ?? '?',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    Provider.of<LocalizationService>(context, listen: false).translate('ui.reservedByOthers') ?? 'Reserved by others',
                                    style: AppStyles.caption.copyWith(
                                      color: AppColors.textTertiary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Lock icon
                      Icon(
                        Icons.lock_outline,
                        color: AppColors.textTertiary,
                        size: 18,
                      ),
                    ],
                  ),
                ),
                // Spacing
                const SizedBox(height: 8),
                // Status Label (replaces action button) - Full width container
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      Provider.of<LocalizationService>(context, listen: false).translate('ui.takenByAnotherFriend') ?? 'Taken by another friend',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
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

    // Case B4: Available
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
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Content Row
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      getCategoryIcon('General'),
                      color: priorityColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title & Priority Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.name,
                          style: AppStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: priorityColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              getPriorityText(item.priority),
                              style: AppStyles.caption.copyWith(
                                color: priorityColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Spacing
            if (onToggleReservation != null)
              const SizedBox(height: 8),
            // Case D: Reserve This Gift Button (Available items only)
            if (onToggleReservation != null)
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    // Explicitly pass 'reserve' action for Reserve button
                    _confirmToggleReservation(context, false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    Provider.of<LocalizationService>(context, listen: false).translate('ui.reserveThisGift') ?? 'Reserve This Gift',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

