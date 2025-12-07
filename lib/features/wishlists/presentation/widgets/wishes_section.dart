import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/features/wishlists/data/models/wish.dart';

class WishesSection extends StatefulWidget {
  final List<Wish> wishes;
  final VoidCallback? onSeeAll;

  const WishesSection({super.key, required this.wishes, this.onSeeAll});

  @override
  State<WishesSection> createState() => _WishesSectionState();
}

class _WishesSectionState extends State<WishesSection>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.wishes.isEmpty)
          _buildEmptyState()
        else
          SizedBox(
            height: 180, // Increased height to prevent overflow
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              itemCount: widget.wishes.length,
              itemBuilder: (context, index) {
                final wish = widget.wishes[index];
                return _buildWishCard(wish, index);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildWishCard(Wish wish, int index) {
    final isHovered = _hoveredIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 240,
        decoration: isHovered
            ? AppStyles.cardDecorationHover
            : AppStyles.cardDecorationLight,
        child: ClipRRect(
          // Added ClipRRect to prevent overflow
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Wish Image with Hover Effect
              Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    height: isHovered ? 160 : 150,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: Image.network(
                        wish.imageUrl,
                        width: 240,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 240,
                            height: isHovered ? 160 : 150,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                            ),
                            child: Icon(
                              Icons.image_not_supported,
                              color: AppColors.textWhite,
                              size: 50,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // Favorite Icon with Animation
                  Positioned(
                    top: 12,
                    right: 12,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: wish.isFavorite
                            ? AppColors.accent
                            : AppColors.surface.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        wish.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: wish.isFavorite
                            ? AppColors.textWhite
                            : AppColors.textTertiary,
                        size: 18,
                      ),
                    ),
                  ),
                  // Hover Overlay
                  if (isHovered)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 160,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                    ),
                ],
              ),

              // Wish Details
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wish.title,
                      style: AppStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      wish.description,
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: wish.priorityColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: wish.priorityColor.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            wish.priorityText,
                            style: AppStyles.caption.copyWith(
                              color: wish.priorityColor,
                              fontWeight: FontWeight.w700,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sentiment_very_dissatisfied,
            size: 50,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 10),
          Text(
            'No wishes yet!',
            style: AppStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}
