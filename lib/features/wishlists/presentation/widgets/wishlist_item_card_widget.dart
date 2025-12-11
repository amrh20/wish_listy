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
    if (widget.enableSwipe && widget.onToggleGifted != null) {
      return Slidable(
        key: Key(widget.item.id),
        startActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.25,
          children: [
            CustomSlidableAction(
              onPressed: (_) => widget.onToggleGifted?.call(),
              backgroundColor: const Color(0xFF2ECC71),
              foregroundColor: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check, size: 28, color: Colors.white),
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
        ),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.5,
          children: [
            if (widget.onEdit != null)
              CustomSlidableAction(
                onPressed: (_) => widget.onEdit?.call(),
                backgroundColor: const Color(0xFF6366F1), // Indigo
                foregroundColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit_rounded, size: 28, color: Colors.white),
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
                onPressed: (_) => widget.onDelete?.call(),
                backgroundColor: const Color(0xFFEF4444), // Red/Salmon
                foregroundColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_rounded, size: 28, color: Colors.white),
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
        ),
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isPurchased
                ? const Color(0xFF2ECC71).withOpacity(0.15)
                : priorityColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            getCategoryIcon('General'),
            color: isPurchased ? const Color(0xFF2ECC71) : priorityColor,
            size: 24,
          ),
        ),
        title: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: AppStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            decoration:
                isPurchased ? TextDecoration.lineThrough : TextDecoration.none,
            color: isPurchased ? Colors.grey : AppColors.textPrimary,
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
                const SizedBox(width: 12),
                // Category
                Text(
                  'General',
                  style: AppStyles.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Purchase Toggle IconButton - only show if onToggleGifted is provided
            if (onToggleGifted != null) ...[
              IconButton(
                onPressed: () {
                  // This callback is handled separately and won't trigger ListTile.onTap
                  onToggleGifted?.call();
                },
                iconSize: 20.0,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ),
                icon: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isPurchased
                        ? const Color(0xFF2ECC71)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: isPurchased
                        ? null
                        : Border.all(
                            color: Colors.grey.withOpacity(0.3),
                            width: 2,
                          ),
                  ),
                  child: isPurchased
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 8),
            ],
            // Context Menu PopupMenuButton - show if edit/delete are available
            if (onEdit != null || onDelete != null)
              PopupMenuButton<String>(
                color: Colors.white,
                icon: Icon(
                  Icons.more_vert,
                  color: AppColors.textTertiary,
                  size: 20,
                ),
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
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
                          Icon(Icons.delete, color: Colors.red, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            'Delete',
                            style: AppStyles.bodyMedium.copyWith(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              )
            else if (onToggleGifted == null)
              // For friend wishlists, only show purchase status indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isPurchased ? const Color(0xFF2ECC71) : Colors.transparent,
                  shape: BoxShape.circle,
                  border: isPurchased
                      ? null
                      : Border.all(
                          color: Colors.grey.withOpacity(0.3),
                          width: 2,
                        ),
                ),
                child: isPurchased
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

