import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/features/wishlists/data/models/wishlist_model.dart';

class ItemPriorityBadgeWidget extends StatelessWidget {
  final ItemPriority priority;

  const ItemPriorityBadgeWidget({
    super.key,
    required this.priority,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getPriorityColor(priority);
    final text = _getPriorityText(priority);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.priority_high, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(ItemPriority priority) {
    switch (priority) {
      case ItemPriority.high:
      case ItemPriority.urgent:
        return AppColors.error;
      case ItemPriority.medium:
        return AppColors.warning;
      case ItemPriority.low:
        return AppColors.info;
    }
  }

  String _getPriorityText(ItemPriority priority) {
    switch (priority) {
      case ItemPriority.high:
        return 'High';
      case ItemPriority.urgent:
        return 'Urgent';
      case ItemPriority.medium:
        return 'Medium';
      case ItemPriority.low:
        return 'Low';
    }
  }
}

