import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';

/// Widget for selecting priority when adding an item
class PrioritySelectionWidget extends StatelessWidget {
  final List<String> priorities;
  final String selectedPriority;
  final Function(String) onPrioritySelected;
  final String Function(String) getPriorityDisplayName;
  final Color Function(String) getPriorityColor;
  final IconData Function(String) getPriorityIcon;
  final String Function() getTitle;

  const PrioritySelectionWidget({
    super.key,
    required this.priorities,
    required this.selectedPriority,
    required this.onPrioritySelected,
    required this.getPriorityDisplayName,
    required this.getPriorityColor,
    required this.getPriorityIcon,
    required this.getTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_outlined, color: AppColors.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                getTitle(),
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: priorities.map((priority) {
              final isSelected = selectedPriority == priority;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onPrioritySelected(priority),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? getPriorityColor(priority).withOpacity(0.1)
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? getPriorityColor(priority)
                            : AppColors.textTertiary.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          getPriorityIcon(priority),
                          color: isSelected
                              ? getPriorityColor(priority)
                              : AppColors.textTertiary,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          getPriorityDisplayName(priority),
                          style: AppStyles.caption.copyWith(
                            color: isSelected
                                ? getPriorityColor(priority)
                                : AppColors.textTertiary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
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
      ),
    );
  }
}
