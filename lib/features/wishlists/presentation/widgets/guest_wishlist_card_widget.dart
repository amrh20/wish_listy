import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/features/wishlists/data/models/wishlist_model.dart';
import 'package:wish_listy/features/wishlists/presentation/widgets/wishlist_card_widget.dart';

class _CategoryVisual {
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  const _CategoryVisual({
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
  });
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
      return _CategoryVisual(
        icon: Icons.cake_rounded,
        backgroundColor: Colors.orange.shade50,
        foregroundColor: Colors.orange.shade700,
      );
    case 'wedding':
      return _CategoryVisual(
        icon: Icons.favorite_rounded,
        backgroundColor: Colors.teal.shade50,
        foregroundColor: Colors.teal.shade700,
      );
    case 'graduation':
      return _CategoryVisual(
        icon: Icons.school_rounded,
        backgroundColor: Colors.lightBlue.shade50,
        foregroundColor: Colors.lightBlue.shade700,
      );
    default:
      return _CategoryVisual(
        icon: Icons.star_rounded,
        backgroundColor: Colors.grey.shade100,
        foregroundColor: Colors.grey.shade700,
      );
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
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const GuestWishlistCardWidget({
    super.key,
    required this.wishlist,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final categoryVisual = _getCategoryVisual(wishlist.category);
    final categoryName = _formatCategoryLabel(wishlist.category);
    final hasItems = wishlist.itemCount > 0;
    final description = wishlist.description?.trim();
    final hasDescription = description != null && description.isNotEmpty;

    final categoryColor = categoryVisual.foregroundColor;
    final wishesText = '• ${wishlist.itemCount} ${wishlist.itemCount == 1 ? 'Wish' : 'Wishes'}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
            // 1. Top Section: Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // A. The Hero Icon (Left Side)
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    categoryVisual.icon,
                    size: 30,
                    color: categoryColor,
                  ),
                ),
                const SizedBox(width: 16),
                // B. Title & Metadata
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              wishlist.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (onEdit != null && onDelete != null)
                            PopupMenuButton<String>(
                              tooltip: 'Options',
                              icon: const Icon(Icons.more_vert, color: Colors.grey),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                              onSelected: (value) {
                                if (value == 'edit') onEdit?.call();
                                if (value == 'delete') onDelete?.call();
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                        color: AppColors.textPrimary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Edit',
                                        style: AppStyles.bodyMedium.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: AppColors.error,
                                      ),
                                      const SizedBox(width: 8),
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
                            )
                          else
                            const Icon(Icons.more_vert, color: Colors.grey),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: categoryColor.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              categoryName,
                              style: TextStyle(
                                color: categoryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            wishesText,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      if (hasDescription) ...[
                        const SizedBox(height: 10),
                        Text(
                          description!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 2. Middle Section: Bubbles Preview (only if has items)
            if (hasItems) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: _buildPreviewBubbles(
                    totalCount: wishlist.itemCount,
                    previewItems: wishlist.previewItems,
                  ),
                ),
              ),
            ],

            // 3. Bottom Section: Action Button (Only if 0 items)
            if (!hasItems) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Add Your First Wish',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPreviewBubbles({
    required int totalCount,
    required List<WishlistItem> previewItems,
  }) {
    final preview = previewItems.take(3).toList();

    final bubbles = <Widget>[
      for (final item in preview)
        _IconBubble(
          itemName: item.name,
          background: Colors.purple.shade50,
        ),
    ];

    if (totalCount > 3) {
      bubbles.add(_MoreCountBubble(count: totalCount - 3));
    } else {
      final remaining = 3 - bubbles.length;
      for (var i = 0; i < remaining; i++) {
        bubbles.add(const _PlaceholderBubble());
      }
    }

    final spaced = <Widget>[];
    for (int i = 0; i < bubbles.length; i++) {
      spaced.add(bubbles[i]);
      if (i != bubbles.length - 1) spaced.add(const SizedBox(width: 12));
    }

    return spaced;
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
  final Color backgroundColor;
  final Color foregroundColor;
  final String label;

  const _CategoryChip({
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foregroundColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppStyles.caption.copyWith(
              fontSize: 12,
              color: foregroundColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  final String itemName;
  final Color background;

  const _IconBubble({
    required this.itemName,
    required this.background,
  });

  String _getInitial(String name) {
    if (name.isEmpty) return '';
    return name.trim()[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initial = _getInitial(itemName);
    final hasInitial = initial.isNotEmpty;

    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
      ),
      child: hasInitial
          ? Center(
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            )
          : Icon(
              Icons.card_giftcard,
              size: 18,
              color: AppColors.primary,
            ),
    );
  }
}

class _PlaceholderBubble extends StatelessWidget {
  const _PlaceholderBubble();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: CustomPaint(
        painter: _DashedCirclePainter(
          color: Colors.grey.withOpacity(0.45),
        ),
        child: Center(
          child: Icon(
            Icons.add,
            size: 16,
            color: Colors.grey.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
}

class _MoreCountBubble extends StatelessWidget {
  final int count;

  const _MoreCountBubble({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.10),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary.withOpacity(0.20),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '+$count',
        style: AppStyles.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;

  _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final fill = Paint()
      ..color = Colors.grey.withOpacity(0.06)
      ..style = PaintingStyle.fill;

    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.shortestSide / 2;

    // subtle fill
    canvas.drawCircle(center, radius, fill);

    // dashed border
    final path = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius - 1));
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    const dashLength = 4.0;
    const gapLength = 3.0;
    double distance = 0.0;
    while (distance < metric.length) {
      final next = distance + dashLength;
      final extract = metric.extractPath(
        distance,
        next.clamp(0.0, metric.length),
      );
      canvas.drawPath(extract, paint);
      distance += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}



