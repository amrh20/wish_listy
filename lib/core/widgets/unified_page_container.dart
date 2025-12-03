import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';

/// A unified container widget that provides consistent styling across all main pages.
/// Features rounded corners, soft gradient background, and optional decorative elements.
class UnifiedPageContainer extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final bool showTopRadius;
  final double topRadius;
  final EdgeInsets? padding;
  final bool showShadow;

  const UnifiedPageContainer({
    super.key,
    required this.child,
    this.backgroundColor,
    this.showTopRadius = true,
    this.topRadius = 24.0,
    this.padding,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withOpacity(0.95),
        borderRadius: showTopRadius
            ? BorderRadius.only(
                topLeft: Radius.circular(topRadius),
                topRight: Radius.circular(topRadius),
              )
            : null,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: AppColors.shadow.withOpacity(0.08),
                  offset: const Offset(0, -4),
                  blurRadius: 16,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: showTopRadius
            ? BorderRadius.only(
                topLeft: Radius.circular(topRadius),
                topRight: Radius.circular(topRadius),
              )
            : BorderRadius.zero,
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );
  }
}

/// A gradient background wrapper for the entire page
class UnifiedPageBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? gradientColors;

  const UnifiedPageBackground({
    super.key,
    required this.child,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors ??
              [
                AppColors.primary.withOpacity(0.08),
                AppColors.background,
                AppColors.background,
              ],
          stops: const [0.0, 0.3, 1.0],
        ),
      ),
      child: child,
    );
  }
}

/// A card with pastel background color
class PastelCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final int colorIndex;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final bool showBorder;

  const PastelCard({
    super.key,
    required this.child,
    this.color,
    this.colorIndex = 0,
    this.padding,
    this.margin,
    this.borderRadius = 16.0,
    this.onTap,
    this.showBorder = true,
  });

  Color get cardColor {
    if (color != null) return color!;
    return AppColors.pastelCards[colorIndex % AppColors.pastelCards.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: showBorder
                  ? Border.all(
                      color: _getBorderColor(cardColor),
                      width: 1,
                    )
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Color _getBorderColor(Color bgColor) {
    // Create a slightly darker version of the background color for the border
    if (bgColor == AppColors.cardBlue) {
      return const Color(0xFFB3E0FF);
    } else if (bgColor == AppColors.cardPurple) {
      return const Color(0xFFE0C8FF);
    } else if (bgColor == AppColors.cardGreen) {
      return const Color(0xFFC8FFE0);
    } else if (bgColor == AppColors.cardPink) {
      return const Color(0xFFFFCDD8);
    } else if (bgColor == AppColors.cardPeach) {
      return const Color(0xFFFFE0C8);
    }
    return bgColor.withOpacity(0.5);
  }
}

