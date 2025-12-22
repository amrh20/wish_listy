import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/features/wishlists/data/models/wishlist_model.dart';

/// Modern swipeable wishlist item card widget
class WishlistItemCardWidget extends StatefulWidget {
  final WishlistItem item;
  final bool isPurchased;
  final Color priorityColor;
  final VoidCallback onTap;
  final VoidCallback? onToggleGifted;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool enableSwipe;

  const WishlistItemCardWidget({
    super.key,
    required this.item,
    required this.isPurchased,
    required this.priorityColor,
    required this.onTap,
    this.onToggleGifted,
    this.onEdit,
    this.onDelete,
    this.enableSwipe = true,
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
      isPurchased: widget.isPurchased,
      priorityColor: widget.priorityColor,
      onTap: widget.onTap,
      onToggleGifted: widget.onToggleGifted,
      onEdit: widget.onEdit,
      onDelete: widget.onDelete,
      getPriorityText: _getPriorityText,
      getCategoryIcon: _getCategoryIcon,
    );

    // Wrap with Slidable only if swipe is enabled
    if (widget.enableSwipe) {
      return Slidable(
        key: Key(widget.item.id),
        // Right swipe (start-to-end): Mark as Gifted (only if NOT purchased)
        startActionPane: widget.onToggleGifted != null && !widget.isPurchased
            ? ActionPane(
                motion: const DrawerMotion(),
                extentRatio: 0.25,
                children: [
                  CustomSlidableAction(
                    onPressed: (_) => widget.onToggleGifted?.call(),
                    backgroundColor: AppColors.success, // Green
                    foregroundColor: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.card_giftcard, size: 28, color: Colors.white),
                        SizedBox(height: 4),
                        Text(
                          'Gift',
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
  final bool isPurchased;
  final Color priorityColor;
  final VoidCallback onTap;
  final VoidCallback? onToggleGifted;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String Function(ItemPriority) getPriorityText;
  final IconData Function(String) getCategoryIcon;

  const _ModernWishlistItemContent({
    required this.item,
    required this.isPurchased,
    required this.priorityColor,
    required this.onTap,
    this.onToggleGifted,
    this.onEdit,
    this.onDelete,
    required this.getPriorityText,
    required this.getCategoryIcon,
  });

  @override
  Widget build(BuildContext context) {
    final hasMenu = onEdit != null || onDelete != null;

    return Opacity(
      opacity: isPurchased ? 0.7 : 1.0,
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
                  color: isPurchased
                      ? AppColors.success.withOpacity(0.15)
                      : priorityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  getCategoryIcon('General'),
                  color: isPurchased ? AppColors.success : priorityColor,
                  size: 24,
                ),
              ),
              title: AnimatedDefaultTextStyle(
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
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Priority dot + text
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
            // Purchased/Gifted tag
            if (isPurchased)
              Positioned(
                top: 10,
                right: hasMenu ? 44 : 8,
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
                        'Gifted',
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
            // 3-dots menu at top-right (for Edit/Delete)
            if (hasMenu)
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
            // Gift Action Button at bottom-right (only show if NOT purchased)
            if (onToggleGifted != null && !isPurchased)
              Positioned(
                bottom: 8,
                right: 8,
                child: Tooltip(
                  message: 'Mark as Gifted',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onToggleGifted,
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.card_giftcard_outlined,
                          color: Colors.grey[400],
                          size: 24,
                        ),
                      ),
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

