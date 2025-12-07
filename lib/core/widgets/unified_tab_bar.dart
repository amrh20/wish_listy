import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';

/// A unified tab bar widget with pill-shaped indicators and badge support.
/// Provides consistent tab styling across all main pages.
class UnifiedTabBar extends StatelessWidget {
  final List<UnifiedTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? unselectedTextColor;

  const UnifiedTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabChanged,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.selectedColor,
    this.unselectedTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: padding ?? const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.textTertiary.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final tab = tabs[index];
          final isSelected = index == selectedIndex;

          return Expanded(
            child: _buildTab(
              tab: tab,
              isSelected: isSelected,
              onTap: () => onTabChanged(index),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTab({
    required UnifiedTab tab,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? (selectedColor ?? AppColors.primary)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              if (tab.icon != null) ...[
                Icon(
                  tab.icon,
                  size: 18,
                  color: isSelected
                      ? Colors.white
                      : (unselectedTextColor ?? AppColors.textSecondary),
                ),
                const SizedBox(width: 6),
              ],

              // Label
              Flexible(
                child: Text(
                  tab.label,
                  style: AppStyles.bodyMedium.copyWith(
                    color: isSelected
                        ? Colors.white
                        : (unselectedTextColor ?? AppColors.textSecondary),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Badge
              if (tab.badgeCount != null && tab.badgeCount! > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.25)
                        : (tab.badgeColor ?? AppColors.primary).withOpacity(
                            0.15,
                          ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    tab.badgeCount.toString(),
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (tab.badgeColor ?? AppColors.primary),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
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
}

/// Represents a single tab in the unified tab bar
class UnifiedTab {
  final String label;
  final IconData? icon;
  final int? badgeCount;
  final Color? badgeColor;

  const UnifiedTab({
    required this.label,
    this.icon,
    this.badgeCount,
    this.badgeColor,
  });
}

/// A secondary style tab bar with underline indicator
class UnifiedUnderlineTabBar extends StatelessWidget {
  final List<UnifiedTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;
  final EdgeInsets? padding;
  final Color? indicatorColor;

  const UnifiedUnderlineTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabChanged,
    this.padding,
    this.indicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final tab = tabs[index];
          final isSelected = index == selectedIndex;

          return Expanded(
            child: _buildTab(
              tab: tab,
              isSelected: isSelected,
              onTap: () => onTabChanged(index),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTab({
    required UnifiedTab tab,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Label
                  Text(
                    tab.label,
                    style: AppStyles.bodyMedium.copyWith(
                      color: isSelected
                          ? (indicatorColor ?? AppColors.primary)
                          : AppColors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),

                  // Badge
                  if (tab.badgeCount != null && tab.badgeCount! > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: tab.badgeColor ?? AppColors.accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        tab.badgeCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Indicator line
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: isSelected ? 40 : 0,
              decoration: BoxDecoration(
                color: indicatorColor ?? AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A toggle-style tab bar (similar to iOS segmented control)
class UnifiedSegmentedTabBar extends StatelessWidget {
  final List<UnifiedTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;
  final EdgeInsets? margin;
  final Color? selectedColor;
  final Color? backgroundColor;

  const UnifiedSegmentedTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabChanged,
    this.margin,
    this.selectedColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      height: 44,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        children: [
          // Animated indicator
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            left:
                (MediaQuery.of(context).size.width - 40) /
                    tabs.length *
                    selectedIndex +
                2,
            top: 2,
            bottom: 2,
            width: (MediaQuery.of(context).size.width - 40) / tabs.length - 4,
            child: Container(
              decoration: BoxDecoration(
                color: selectedColor ?? AppColors.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (selectedColor ?? AppColors.primary).withOpacity(
                      0.3,
                    ),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),

          // Tab buttons
          Row(
            children: List.generate(tabs.length, (index) {
              final tab = tabs[index];
              final isSelected = index == selectedIndex;

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onTabChanged(index),
                    borderRadius: BorderRadius.circular(22),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (tab.icon != null) ...[
                            Icon(
                              tab.icon,
                              size: 16,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            tab.label,
                            style: AppStyles.bodyMedium.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
