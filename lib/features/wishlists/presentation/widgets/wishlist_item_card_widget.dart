import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
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
  final VoidCallback? onToggleReservation; // Toggle reservation (Guest only)
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
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Delete Item'),
          content: Text('Are you sure you want to delete "${widget.item.name}"?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
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
                    content: Text('${widget.item.name} deleted'),
                    backgroundColor: AppColors.textPrimary,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Text(
                'Delete',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );
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
                onPressed: (_) => widget.onEdit?.call(),
                      backgroundColor: AppColors.info, // Blue
                foregroundColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                          Icon(Icons.edit, size: 28, color: Colors.white),
                    SizedBox(height: 4),
                    Text(
                      'Edit',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            if (widget.onDelete != null)
              CustomSlidableAction(
                      onPressed: (_) => _handleDeleteWithConfirmation(),
                      backgroundColor: AppColors.error, // Red
                foregroundColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                          Icon(Icons.delete, size: 28, color: Colors.white),
                    SizedBox(height: 4),
                    Text(
                      'Delete',
                      style: TextStyle(
                        color: Colors.white,
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
  final VoidCallback? onToggleReservation;
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
    final isReceived = item.isReceived;
    final isReservedByMe = item.reservedBy?.id == currentUserId;
    final isReservedByOther = item.reservedBy != null && !isReservedByMe;
    
    // Case A: Owner
    if (isOwner) {
      return _buildOwnerCard(context, isReceived);
    }
    
    // Case B: Guest
    return _buildGuestCard(context, isReceived, isReservedByMe, isReservedByOther);
  }

  Widget _buildOwnerCard(BuildContext context, bool isReceived) {
    final hasMenu = onEdit != null || onDelete != null;
    final shouldShowEdit = onEdit != null && !isReceived; // Hide edit if received

    return Opacity(
      opacity: isReceived ? 0.7 : 1.0,
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
        child: Stack(
          children: [
            // Main content
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isReceived
                      ? AppColors.success.withOpacity(0.15)
                      : priorityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  getCategoryIcon('General'),
                  color: isReceived ? AppColors.success : priorityColor,
                  size: 24,
                ),
              ),
              title: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  decoration: isReceived
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  color: isReceived
                      ? AppColors.textTertiary
                      : AppColors.textPrimary,
                ),
                child: Text(item.name),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
              onTap: onTap,
            ),
            // Received tag
            if (isReceived)
              Positioned(
                top: 10,
                right: (hasMenu && shouldShowEdit) ? 44 : 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.success.withOpacity(0.25),
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
                        'Received',
                        style: AppStyles.caption.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // 3-dots menu (hide edit if received)
            if (hasMenu && shouldShowEdit)
              Positioned(
                top: 8,
                right: 8,
                child: PopupMenuButton<String>(
                  color: Colors.white,
                  icon: Icon(
                    Icons.more_vert,
                    color: AppColors.textTertiary,
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
                    if (value == 'edit') {
                      onEdit?.call();
                    } else if (value == 'delete') {
                      onDelete?.call();
                    }
                  },
                  itemBuilder: (context) => [
                    if (onEdit != null)
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit,
                              color: AppColors.textPrimary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Edit',
                              style: AppStyles.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (onDelete != null)
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: AppColors.error, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              'Delete',
                              style: AppStyles.bodyMedium.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            // Toggle Received Status Button (Owner only)
            if (onToggleReceivedStatus != null)
              Positioned(
                bottom: 8,
                right: 8,
                child: ElevatedButton(
                  onPressed: onToggleReceivedStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isReceived
                        ? AppColors.textSecondary
                        : AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isReceived ? 'Undo Received' : 'Mark as Received',
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

  Widget _buildGuestCard(BuildContext context, bool isReceived, bool isReservedByMe, bool isReservedByOther) {
    final hasMenu = onEdit != null || onDelete != null;

    // Case B1: Received
    if (isReceived) {
      return Opacity(
        opacity: 0.7,
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
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
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
            title: Text(
              item.name,
              style: AppStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.lineThrough,
                color: AppColors.textTertiary,
              ),
            ),
            subtitle: const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Already Gifted',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            onTap: onTap,
          ),
        ),
      );
    }

    // Case B2: Reserved by Me
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
        child: Stack(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
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
              title: Text(
                item.name,
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 14,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Reserved by You',
                      style: AppStyles.caption.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              onTap: onTap,
            ),
            // Cancel Reservation Button
            if (onToggleReservation != null)
              Positioned(
                bottom: 8,
                right: 8,
                child: TextButton.icon(
                  onPressed: onToggleReservation,
                  icon: Icon(
                    Icons.cancel_outlined,
                    size: 16,
                    color: AppColors.error,
                  ),
                  label: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // Case B3: Reserved by Someone Else
    if (isReservedByOther) {
      return Opacity(
        opacity: 0.6,
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
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
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
            title: Text(
              item.name,
              style: AppStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
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
                      'Reserved by ${item.reservedBy?.fullName ?? 'Someone'}',
                      style: AppStyles.caption.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            trailing: Icon(
              Icons.lock_outline,
              color: AppColors.textTertiary,
              size: 18,
            ),
            onTap: null, // Disabled
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
      child: Stack(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: AnimatedContainer(
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
            title: Text(
              item.name,
              style: AppStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
            onTap: onTap,
          ),
          // Reserve Gift Button
          if (onToggleReservation != null)
            Positioned(
              bottom: 8,
              right: 8,
              child: ElevatedButton(
                onPressed: onToggleReservation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Reserve Gift',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

