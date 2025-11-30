import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';

/// Modern Segmented Control with sliding indicator
class SegmentedControlWidget extends StatefulWidget {
  final TabController tabController;
  final List<SegmentedControlItem> items;

  const SegmentedControlWidget({
    super.key,
    required this.tabController,
    required this.items,
  });

  @override
  State<SegmentedControlWidget> createState() => _SegmentedControlWidgetState();
}

class _SegmentedControlWidgetState extends State<SegmentedControlWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _indicatorController;
  late Animation<double> _indicatorAnimation;

  @override
  void initState() {
    super.initState();
    _indicatorController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _indicatorAnimation = CurvedAnimation(
      parent: _indicatorController,
      curve: Curves.easeInOut,
    );
    _updateIndicatorPosition();
    widget.tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_onTabChanged);
    _indicatorController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    _updateIndicatorPosition();
  }

  void _updateIndicatorPosition() {
    _indicatorController.animateTo(
      widget.tabController.index / (widget.items.length - 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final containerWidth = constraints.maxWidth;
          final itemWidth = containerWidth / widget.items.length;

          return Stack(
            children: [
              // Sliding indicator
              AnimatedBuilder(
                animation: _indicatorAnimation,
                builder: (context, child) {
                  final indicatorPosition = _indicatorAnimation.value *
                      (widget.items.length - 1) *
                      itemWidth;

                  return Positioned(
                    left: indicatorPosition,
                    top: 4,
                    bottom: 4,
                    child: Container(
                      width: itemWidth,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                },
              ),
              // Tab buttons
              Row(
                children: widget.items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isSelected = widget.tabController.index == index;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        widget.tabController.animateTo(index);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (item.icon != null) ...[
                              Icon(
                                item.icon,
                                size: 16,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                              const SizedBox(width: 6),
                            ],
                            Flexible(
                              child: Text(
                                item.label,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: AppStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Item model for Segmented Control
class SegmentedControlItem {
  final String label;
  final IconData? icon;

  const SegmentedControlItem({
    required this.label,
    this.icon,
  });
}

