import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/utils/category_images.dart';
import 'package:google_fonts/google_fonts.dart';

/// Modern 2025 wishlist card - Clean, minimal, and trendy
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
    return GestureDetector(
      onTap: widget.onView,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface, // White background
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.border.withOpacity(0.8),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Section (Header) - Pastel Purple Background
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.04),
                ),
                child: _buildHeader(),
              ),
              // Bottom Section (Body) - White Background
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCleanStats(),
                    const SizedBox(height: 12),
                    // Progress Bar below stats
                    _buildProgressIndicator(),
                    const SizedBox(height: 16),
                    _buildActionRow(),
                  ],
                ),
              ),
            ],
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
        // Category Avatar (Left) - Squircle Style
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.surface, // Surface background for contrast
            borderRadius: BorderRadius.circular(20), // Squircle
            boxShadow: [
              BoxShadow(
                color: _accentColor.withOpacity(0.15),
                offset: const Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: categoryImagePath != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(20), // Squircle
                  child: Image.asset(
                    categoryImagePath,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        CategoryImages.getCategoryIcon(widget.category),
                        color: _accentColor,
                        size: 32,
                      );
                    },
                  ),
                )
              : Icon(
                  CategoryImages.getCategoryIcon(widget.category),
                  color: _accentColor,
                  size: 32,
                ),
        ),

        const SizedBox(width: 16),

        // Title & Subtitle (Middle)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: GoogleFonts.readexPro(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                widget.description ??
                    '${widget.totalItems} ${widget.totalItems == 1 ? 'wish' : 'wishes'}',
                style: GoogleFonts.readexPro(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // Status Pill & Menu (Right)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusPill(),
            if (widget.onMenu != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: widget.onMenu,
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: 'More options',
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildStatusPill() {
    final isPublic = widget.isPublic;
    final backgroundColor = isPublic
        ? AppColors.success.withOpacity(0.15)
        : AppColors.info.withOpacity(0.15);
    final textColor = isPublic ? AppColors.success : AppColors.info;
    final label = isPublic ? 'Public' : 'Private';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(30), // Pill-shaped
      ),
      child: Text(
        label,
        style: GoogleFonts.readexPro(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildCleanStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(
          icon: Icons.card_giftcard_rounded,
          value: widget.totalItems.toString(),
          label: 'Wishes',
          color: AppColors.primary, // Match header theme (Purple)
        ),
        _buildStatItem(
          icon: Icons.check_circle_rounded,
          value: widget.giftedItems.toString(),
          label: 'Gifted',
          color: AppColors.primary, // Match header theme (Purple)
        ),
        _buildStatItem(
          icon: Icons.access_time_rounded,
          value: widget.todayItems.toString(),
          label: 'Today',
          color: AppColors.primary, // Match header theme (Purple)
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        // Icon Container with pastel background
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        // Bold number in middle
        Text(
          value,
          style: GoogleFonts.readexPro(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        // Small label at bottom
        Text(
          label,
          style: GoogleFonts.readexPro(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildActionRow() {
    return _AnimatedButton(
      onPressed: widget.onAddItem,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_accentColor, _accentColor.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(16), // Unified button radius
          boxShadow: [
            BoxShadow(
              color: _accentColor.withOpacity(0.4),
              offset: const Offset(0, 4),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'Add Wish',
              style: GoogleFonts.readexPro(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _progressAnimation.value,
            backgroundColor: _accentColor.withOpacity(0.15),
            minHeight: 4,
            valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
          ),
        );
      },
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
