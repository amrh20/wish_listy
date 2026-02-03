import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/bottom_sheet_vectors.dart';

/// A bottom sheet with a decorative vector character positioned at the top
/// The vector is positioned half outside and half inside the sheet
class DecoratedBottomSheet extends StatefulWidget {
  /// The type of vector to display
  final BottomSheetVectorType vectorType;

  /// Optional title for the bottom sheet
  final String? title;

  /// The content widgets to display in the bottom sheet
  final List<Widget> children;

  /// Optional height constraint
  final double? height;

  const DecoratedBottomSheet({
    super.key,
    required this.vectorType,
    required this.children,
    this.title,
    this.height,
  });

  @override
  State<DecoratedBottomSheet> createState() => _DecoratedBottomSheetState();

  /// Show the decorated bottom sheet
  static Future<T?> show<T>({
    required BuildContext context,
    required BottomSheetVectorType vectorType,
    required List<Widget> children,
    String? title,
    double? height,
    bool isDismissible = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: isDismissible,
      builder: (context) => DecoratedBottomSheet(
        vectorType: vectorType,
        title: title,
        height: height,
        children: children,
      ),
    );
  }
}

class _DecoratedBottomSheetState extends State<DecoratedBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Fade animation for the whole sheet
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Slide animation for the sheet
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Scale animation for the decorative vector.
    // For menu-style sheets (e.g., wishlist options), use a softer scale to avoid
    // noticeable "shake" on open. For other types keep the richer bounce animation.
    if (widget.vectorType == BottomSheetVectorType.menu) {
      _scaleAnimation = Tween<double>(
        begin: 0.9,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOutCubic,
        ),
      );
    } else {
      _scaleAnimation = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 0.0, end: 1.1)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 60,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.1, end: 0.95)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 20,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 0.95, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 20,
        ),
      ]).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.2, 1.0, curve: Curves.elasticOut),
        ),
      );
    }

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: child,
          ),
        );
      },
      child: _buildSheet(),
    );
  }

  Widget _buildSheet() {
    return Container(
      margin: const EdgeInsets.only(top: 40), // Space for the vector
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Main bottom sheet content
          Container(
            width: double.infinity,
            height: widget.height,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 50), // Space for vector overlap

                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Title if provided
                if (widget.title != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    widget.title!,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    child: SafeArea(
                      top: false,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: widget.children,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Decorative vector positioned half outside
          Positioned(
            top: -35, // Half of 70px
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                );
              },
              child: _buildVector(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVector() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            offset: const Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipOval(
        child: widget.vectorType.assetPath != null
            ? Image.asset(
                widget.vectorType.assetPath!,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback placeholder if image is not found
                  return _buildIconPlaceholder();
                },
              )
            : _buildIconPlaceholder(),
      ),
    );
  }

  Widget _buildIconPlaceholder() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.8),
            AppColors.accent.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        _getIconForVectorType(),
        color: Colors.white,
        size: 35,
      ),
    );
  }

  IconData _getIconForVectorType() {
    switch (widget.vectorType) {
      case BottomSheetVectorType.menu:
        return Icons.more_horiz_rounded;
      case BottomSheetVectorType.friends:
        return Icons.people_rounded;
      case BottomSheetVectorType.creation:
        return Icons.add_circle_rounded;
      case BottomSheetVectorType.filter:
        return Icons.filter_list_rounded;
      case BottomSheetVectorType.settings:
        return Icons.settings_rounded;
      case BottomSheetVectorType.celebration:
        return Icons.celebration_rounded;
    }
  }
}

