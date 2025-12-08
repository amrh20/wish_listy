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
        color: backgroundColor ?? AppColors.background,
        borderRadius: showTopRadius
            ? BorderRadius.only(
                topLeft: Radius.circular(topRadius),
                topRight: Radius.circular(topRadius),
              )
            : null,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: AppColors.textTertiary.withOpacity(0.1),
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
          colors:
              gradientColors ??
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
