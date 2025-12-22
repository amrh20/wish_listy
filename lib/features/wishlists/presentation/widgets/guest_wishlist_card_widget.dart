import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/features/wishlists/data/models/wishlist_model.dart';
import 'package:wish_listy/features/wishlists/presentation/widgets/wishlist_card_widget.dart';

class _CategoryVisual {
  final IconData icon;
  final Color color;

  const _CategoryVisual({required this.icon, required this.color});
}

_CategoryVisual _getCategoryVisual(String? categoryRaw) {
  final category = (categoryRaw ?? 'Other').trim();
  final normalized = category.toLowerCase();

  // Normalize a few common values coming from local storage / old flows
  final effective = (normalized == 'general' || normalized == 'other')
      ? 'other'
      : normalized;

  switch (effective) {
    case 'birthday':
      return const _CategoryVisual(icon: Icons.cake_rounded, color: Colors.pink);
    case 'wedding':
      return const _CategoryVisual(icon: Icons.favorite_rounded, color: Colors.red);
    case 'graduation':
      return const _CategoryVisual(icon: Icons.school_rounded, color: Colors.blue);
    default:
      return const _CategoryVisual(icon: Icons.star_rounded, color: AppColors.primary);
  }
}

String _formatCategoryLabel(String? categoryRaw) {
  final category = (categoryRaw ?? 'Other').trim();
  if (category.isEmpty) return 'Other';
  if (category.toLowerCase() == 'general') return 'Other';
  // Capitalize first letter, keep rest as-is for now.
  return category[0].toUpperCase() + category.substring(1);
}

class GuestWishlistCardWidget extends StatelessWidget {
  final WishlistSummary wishlist;
  final VoidCallback onTap;

  const GuestWishlistCardWidget({
    super.key,
    required this.wishlist,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final categoryVisual = _getCategoryVisual(wishlist.category);
    final categoryLabel = _formatCategoryLabel(wishlist.category);
    final description = wishlist.description?.trim();
    final hasDescription = description != null && description.isNotEmpty;
    final hasPreviewItems = wishlist.previewItems.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: Colors.black.withOpacity(0.03),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      wishlist.name,
                      style: AppStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _CategoryChip(
                    icon: categoryVisual.icon,
                    color: categoryVisual.color,
                    label: categoryLabel,
                  ),
                ],
              ),
              if (hasDescription) ...[
                const SizedBox(height: 8),
                Text(
                  description!,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: hasPreviewItems
                          ? _buildPreviewBubbles(wishlist.previewItems)
                          : [
                              _CategoryBubble(
                                icon: categoryVisual.icon,
                                color: categoryVisual.color,
                              ),
                            ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onTap,
                    icon: const Icon(
                      Icons.arrow_forward_ios,
                      size: 18,
                      color: AppColors.textTertiary,
                    ),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 40, minHeight: 40),
                    tooltip: 'View Details',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPreviewBubbles(List<WishlistItem> items) {
    final preview = items.take(3).toList();
    final widgets = <Widget>[];

    for (var i = 0; i < preview.length; i++) {
      final item = preview[i];
      final icon = _priorityIcon(item.priority);
      final bg = _priorityColor(item.priority).withOpacity(0.12);

      widgets.add(
        _IconBubble(
          icon: icon,
          background: bg,
          foreground: _priorityColor(item.priority),
        ),
      );

      if (i != preview.length - 1) {
        widgets.add(const SizedBox(width: 12));
      }
    }

    return widgets;
  }

  IconData _priorityIcon(ItemPriority priority) {
    switch (priority) {
      case ItemPriority.high:
        return Icons.local_fire_department_rounded;
      case ItemPriority.low:
        return Icons.spa_rounded;
      case ItemPriority.medium:
      default:
        return Icons.bolt_rounded;
    }
  }

  Color _priorityColor(ItemPriority priority) {
    switch (priority) {
      case ItemPriority.high:
        return Colors.redAccent;
      case ItemPriority.low:
        return Colors.teal;
      case ItemPriority.medium:
      default:
        return AppColors.primary;
    }
  }
}

class _CategoryChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _CategoryChip({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppStyles.caption.copyWith(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color foreground;

  const _IconBubble({
    required this.icon,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        icon,
        size: 22,
        color: foreground.withOpacity(0.9),
      ),
    );
  }
}

class _CategoryBubble extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _CategoryBubble({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        icon,
        size: 22,
        color: color,
      ),
    );
  }
}


