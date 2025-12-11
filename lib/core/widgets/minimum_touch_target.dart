import 'package:flutter/material.dart';
import 'package:wish_listy/core/utils/accessibility_utils.dart';

/// Widget that ensures a minimum touch target size (44x44px) for accessibility
/// Wraps any widget and adds padding if needed to meet minimum size requirements
class MinimumTouchTarget extends StatelessWidget {
  final Widget child;
  final double? minSize;
  final AlignmentGeometry alignment;

  const MinimumTouchTarget({
    super.key,
    required this.child,
    this.minSize,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final minimumSize = minSize ?? AccessibilityUtils.minTouchTargetSize;

    return SizedBox(
      width: minimumSize,
      height: minimumSize,
      child: Align(
        alignment: alignment,
        child: child,
      ),
    );
  }
}

/// Extension to easily wrap widgets with minimum touch target
extension MinimumTouchTargetExtension on Widget {
  Widget withMinimumTouchTarget({double? minSize}) {
    return MinimumTouchTarget(
      minSize: minSize,
      child: this,
    );
  }
}

