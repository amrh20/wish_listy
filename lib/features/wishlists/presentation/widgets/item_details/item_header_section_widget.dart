import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/features/wishlists/data/models/wishlist_model.dart';

class ItemHeaderSectionWidget extends StatelessWidget {
  final WishlistItem item;
  final bool isOwner;
  final String dateText;

  const ItemHeaderSectionWidget({
    super.key,
    required this.item,
    required this.isOwner,
    required this.dateText,
  });

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    final priorityColor = _getPriorityColor(item.priority);
    final isReserved = item.isReservedValue;
    final isReceived = item.isReceived;
    final isReservedForOwner = isOwner && isReserved && !isReceived;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          item.name,
          style: AppStyles.headingLarge.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 28,
            color: AppColors.textPrimary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        // Badge + Date Row
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Show Mystery Badge if reserved for owner (Teaser Mode) AND not received
                if (isReservedForOwner)
                  _buildMysteryBadge(localization)
                else if (isReceived)
                  _buildGiftedBadge(localization)
                else
                  _buildPriorityBadge(priorityColor),
                const SizedBox(width: 12),
                // Date
                Text(
                  '${localization.translate('details.addedOn')} $dateText',
                  style: AppStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMysteryBadge(LocalizationService localization) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF6A1B9A).withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6A1B9A).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.visibility_off,
            size: 16,
            color: Color(0xFF6A1B9A),
          ),
          const SizedBox(width: 8),
          Text(
            localization.translate('details.reservedByFriend'),
            style: const TextStyle(
              color: Color(0xFF6A1B9A),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftedBadge(LocalizationService localization) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.success.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle,
            size: 14,
            color: AppColors.success,
          ),
          const SizedBox(width: 6),
          Text(
            localization.translate('details.gifted'),
            style: const TextStyle(
              color: AppColors.success,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(Color priorityColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: priorityColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: priorityColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getPriorityIcon(item.priority),
            size: 14,
            color: priorityColor,
          ),
          const SizedBox(width: 6),
          Text(
            _getPriorityText(item.priority),
            style: TextStyle(
              color: priorityColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
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

  IconData _getPriorityIcon(ItemPriority priority) {
    switch (priority) {
      case ItemPriority.high:
        return Icons.local_fire_department;
      case ItemPriority.urgent:
        return Icons.priority_high;
      case ItemPriority.medium:
        return Icons.bolt;
      case ItemPriority.low:
        return Icons.spa;
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

