import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/features/wishlists/presentation/widgets/wishlist_card_widget.dart';

/// Helper class for category visual styling
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

/// Get category visual styling
_CategoryVisual _getCategoryVisual(String? categoryRaw) {
  final category = (categoryRaw ?? 'Other').trim();
  final normalized = category.toLowerCase();

  // Normalize a few common values
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

/// Format category label
String _formatCategoryLabel(String? categoryRaw) {
  final category = (categoryRaw ?? 'Other').trim();
  if (category.isEmpty) return 'Other';
  if (category.toLowerCase() == 'general') return 'Other';
  // Capitalize first letter
  return category[0].toUpperCase() + category.substring(1);
}

/// Modern 2025 wishlist card - Clean, minimal, and trendy
class ModernWishlistCard extends StatefulWidget {
  final String title;
  final String? description;
  final WishlistPrivacy privacy;
  final int totalItems;
  final int giftedItems;
  final int todayItems;
  final double completionPercentage;
  final VoidCallback onView;
  final VoidCallback onAddItem;
  final VoidCallback? onMenu;
  final VoidCallback? onEdit;
  final Color? accentColor;
  final String? imageUrl;
  final String? category; // Added for category images
  final DateTime? eventDate; // For days left calculation
  final List<String> previewItemNames; // For guest-style bubbles preview
  final bool isReadOnly; // If true, hide all action buttons and menu

  const ModernWishlistCard({
    super.key,
    required this.title,
    this.description,
    this.privacy = WishlistPrivacy.public,
    required this.totalItems,
    required this.giftedItems,
    this.todayItems = 0,
    required this.completionPercentage,
    required this.onView,
    required this.onAddItem,
    this.onMenu,
    this.onEdit,
    this.accentColor,
    this.imageUrl,
    this.category,
    this.eventDate,
    this.previewItemNames = const [],
    this.isReadOnly = false, // Default to false for backward compatibility
  });

  @override
  State<ModernWishlistCard> createState() => _ModernWishlistCardState();
}

class _ModernWishlistCardState extends State<ModernWishlistCard>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final categoryVisual = _getCategoryVisual(widget.category);
    final categoryColor = categoryVisual.foregroundColor;
    final categoryName = _formatCategoryLabel(widget.category);
    final hasItems = widget.totalItems > 0;
    final hasDescription =
        widget.description != null && widget.description!.trim().isNotEmpty;

    return Container(
      constraints: const BoxConstraints(
        maxWidth: double.infinity,
        minWidth: 0,
      ),
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
          onTap: widget.onView,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Section: Header
              widget.isReadOnly
                  ? _buildCompactHeader(categoryVisual, categoryName, hasDescription)
                  : _buildFullHeader(categoryVisual, categoryColor, categoryName, hasDescription),

              const SizedBox(height: 16),

              // 2. Middle Section: Bubbles Preview (only if has items AND previewItemNames is not empty)
              if (hasItems && widget.previewItemNames.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: _buildPreviewBubbles(),
                  ),
                ),
              ],

              // 3. Bottom Section: Action Button (Only if 0 items and not read-only)
              if (!hasItems && !widget.isReadOnly) ...[
                const SizedBox(height: 16),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onAddItem,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: double.infinity,
                        maxWidth: double.infinity,
                      ),
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Add Your First Wish',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
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

  /// Compact header for read-only cards (Home Screen)
  Widget _buildCompactHeader(
    _CategoryVisual categoryVisual,
    String categoryName,
    bool hasDescription,
  ) {
    return Row(
      children: [
        // Small Icon
        Icon(
          categoryVisual.icon,
          size: 24,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 8),
        // Wishlist Name (Expanded)
        Expanded(
          child: Text(
            widget.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Full header with icon, metadata, and menu (default)
  Widget _buildFullHeader(
    _CategoryVisual categoryVisual,
    Color categoryColor,
    String categoryName,
    bool hasDescription,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // A. The Hero Icon (Left Side) - LARGE & COLORFUL
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
        // B. Title & Metadata (Right Side)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.onMenu != null)
                    IconButton(
                      onPressed: widget.onMenu,
                      icon: const Icon(
                        Icons.more_vert,
                        color: Colors.grey,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      tooltip: 'Options',
                    ),
                ],
              ),
              const SizedBox(height: 4),
              // Metadata Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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
                  Flexible(
                    child: Text(
                      '• ${widget.totalItems} ${widget.totalItems == 1 ? Provider.of<LocalizationService>(context, listen: false).translate('cards.wish') : Provider.of<LocalizationService>(context, listen: false).translate('cards.wishes')}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (hasDescription) ...[
                const SizedBox(height: 10),
                Text(
                  widget.description!.trim(),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPreviewBubbles() {
    final preview = widget.previewItemNames.take(3).toList();
    final bubbles = <Widget>[
      for (final name in preview)
        _IconBubble(
          itemName: name,
          background: Colors.purple.shade50,
        ),
    ];

    if (widget.totalItems > 3) {
      bubbles.add(_MoreCountBubble(count: widget.totalItems - 3));
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
}

/// Category chip widget
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
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            )
          : const Icon(
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

    canvas.drawCircle(center, radius, fill);

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
