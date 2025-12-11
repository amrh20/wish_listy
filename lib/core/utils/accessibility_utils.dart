import 'package:flutter/material.dart';

/// Utility class for accessibility features
class AccessibilityUtils {
  // Minimum font size for readability (especially for seniors)
  static const double minFontSize = 12.0;

  // Minimum touch target size (WCAG AA standard)
  static const double minTouchTargetSize = 44.0;

  // Icon size constants
  static const double iconSizeSmall = 20.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeExtraLarge = 48.0;

  /// Get font size with text scaling support and minimum size enforcement
  static double getScaledFontSize(
    BuildContext context,
    double baseFontSize, {
    double? minSize,
  }) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final scaledSize = baseFontSize * textScaleFactor;
    final minimumSize = minSize ?? minFontSize;
    return scaledSize < minimumSize ? minimumSize : scaledSize;
  }

  /// Check if animations should be reduced
  static bool shouldReduceMotion(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  /// Check if high contrast mode is enabled
  static bool isHighContrast(BuildContext context) {
    return MediaQuery.of(context).highContrast;
  }

  /// Get animation duration based on accessibility preferences
  static Duration getAnimationDuration(
    BuildContext context,
    Duration defaultDuration,
  ) {
    if (shouldReduceMotion(context)) {
      return const Duration(milliseconds: 0);
    }
    return defaultDuration;
  }

  /// Get curve based on accessibility preferences
  static Curve getAnimationCurve(BuildContext context, Curve defaultCurve) {
    if (shouldReduceMotion(context)) {
      return Curves.linear;
    }
    return defaultCurve;
  }
}

