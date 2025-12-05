import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/utils/category_images.dart';

/// Modern wishlist card with glassmorphism, animations, and stats
class ModernWishlistCard extends StatefulWidget {
  final String title;
  final String? description;
  final bool isPublic;
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

  const ModernWishlistCard({
    super.key,
    required this.title,
    this.description,
    this.isPublic = false,
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
    this.category, // Added for category images
  });

  @override
  State<ModernWishlistCard> createState() => _ModernWishlistCardState();
}

class _ModernWishlistCardState extends State<ModernWishlistCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _progressAnimation;

  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _animationController.forward();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Fade in animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Slide up animation
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
          ),
        );

    // Progress bar animation
    _progressAnimation =
        Tween<double>(
          begin: 0.0,
          end: widget.completionPercentage / 100,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
          ),
        );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color get _accentColor => widget.accentColor ?? AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.identity()
              ..translate(0.0, _isHovered ? -4.0 : 0.0),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildCard(),
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _accentColor.withOpacity(0.12),
            AppColors.pink.withOpacity(0.08),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withOpacity(_isHovered ? 0.25 : 0.15),
            offset: Offset(0, _isHovered ? 12 : 8),
            blurRadius: _isHovered ? 32 : 24,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                width: 1.5,
                color: _accentColor.withOpacity(0.2),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildStatsCards(),
                  const SizedBox(height: 16),
                  _buildProgressBar(),
                  const SizedBox(height: 16),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final categoryImagePath = CategoryImages.getCategoryImagePath(
      widget.category,
    );

    return Row(
      children: [
        // Category image or icon with gradient background
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: categoryImagePath == null
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_accentColor, AppColors.pink],
                  )
                : null,
            color: categoryImagePath != null ? Colors.white : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _accentColor.withOpacity(0.3),
                offset: const Offset(0, 4),
                blurRadius: 12,
              ),
            ],
          ),
          child: categoryImagePath != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    categoryImagePath,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        CategoryImages.getCategoryIcon(widget.category),
                        color: Colors.white,
                        size: 24,
                      );
                    },
                  ),
                )
              : Icon(
                  CategoryImages.getCategoryIcon(widget.category),
                  color: Colors.white,
                  size: 24,
                ),
        ),

        const SizedBox(width: 12),

        // Title and badge
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: AppStyles.headingSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.isPublic) ...[
                    const SizedBox(width: 8),
                    _buildPublicBadge(),
                  ],
                ],
              ),
              if (widget.description != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.description!,
                  style: AppStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),

        // Action buttons (Edit and Menu)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Edit button
            if (widget.onEdit != null)
              IconButton(
                onPressed: widget.onEdit,
                icon: Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Edit Wishlist',
              ),
            if (widget.onEdit != null && widget.onMenu != null)
              const SizedBox(width: 8),
            // Menu button
            if (widget.onMenu != null)
              IconButton(
                onPressed: widget.onMenu,
                icon: Icon(Icons.more_vert, color: AppColors.textLight, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'More options',
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPublicBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Public',
        style: AppStyles.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.card_giftcard_rounded,
            value: widget.totalItems.toString(),
            label: 'Gifts',
            color: _accentColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.check_circle_rounded,
            value: widget.giftedItems.toString(),
            label: 'Gifted',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.access_time_rounded,
            value: widget.todayItems.toString(),
            label: 'Today',
            color: AppColors.info,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return _HoverableStatCard(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: AppStyles.headingSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Completion',
              style: AppStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${widget.completionPercentage.toInt()}%',
              style: AppStyles.bodySmall.copyWith(
                color: _accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return Container(
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  // Progress fill with gradient
                  FractionallySizedBox(
                    widthFactor: _progressAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [_accentColor, AppColors.pink],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _accentColor.withOpacity(0.4),
                            offset: const Offset(0, 0),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _AnimatedButton(
            onPressed: widget.onView,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_accentColor, AppColors.pink],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _accentColor.withOpacity(0.3),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.visibility_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'View',
                    style: AppStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _AnimatedButton(
            onPressed: widget.onAddItem,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _accentColor.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outline_rounded,
                    color: _accentColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Add Wish',
                    style: AppStyles.bodyMedium.copyWith(
                      color: _accentColor,
                      fontWeight: FontWeight.w600,
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
}

/// Hoverable stat card with scale animation
class _HoverableStatCard extends StatefulWidget {
  final Widget child;

  const _HoverableStatCard({required this.child});

  @override
  State<_HoverableStatCard> createState() => _HoverableStatCardState();
}

class _HoverableStatCardState extends State<_HoverableStatCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// Animated button with scale effect
class _AnimatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;

  const _AnimatedButton({required this.onPressed, required this.child});

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : (_isHovered ? 1.02 : 1.0),
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Compact version for grid/list views
class CompactWishlistCard extends StatelessWidget {
  final String title;
  final int totalItems;
  final int giftedItems;
  final double completionPercentage;
  final VoidCallback onTap;
  final Color? accentColor;

  const CompactWishlistCard({
    super.key,
    required this.title,
    required this.totalItems,
    required this.giftedItems,
    required this.completionPercentage,
    required this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2), width: 1),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                offset: const Offset(0, 4),
                blurRadius: 12,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon and title
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [color, AppColors.pink]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: AppStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Stats
              Row(
                children: [
                  _buildCompactStat(
                    Icons.card_giftcard_rounded,
                    totalItems.toString(),
                    color,
                  ),
                  const SizedBox(width: 16),
                  _buildCompactStat(
                    Icons.check_circle_rounded,
                    giftedItems.toString(),
                    AppColors.success,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Progress
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: completionPercentage / 100,
                  backgroundColor: AppColors.borderLight,
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 6,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                '${completionPercentage.toInt()}% complete',
                style: AppStyles.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactStat(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: AppStyles.bodySmall.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
