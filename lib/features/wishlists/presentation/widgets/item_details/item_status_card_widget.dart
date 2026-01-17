import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/features/wishlists/data/models/wishlist_model.dart';

class ItemStatusCardWidget extends StatelessWidget {
  final WishlistItem item;
  final bool isOwner;
  final bool isReservedByMe;
  final VoidCallback? onMarkReceived;

  const ItemStatusCardWidget({
    super.key,
    required this.item,
    required this.isOwner,
    required this.isReservedByMe,
    this.onMarkReceived,
  });

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    final isPurchased = item.isPurchasedValue;
    final isReceived = item.isReceived;
    final isReserved = item.isReservedValue;
    final isReservedByOther = isReserved && !isReservedByMe;

    // Case 1: Reserved by Others
    if (isReservedByOther) {
      return _buildReservedCard(localization);
    }

    // Case 2: Purchased/Gifted
    if (isReceived || isPurchased) {
      return _buildPurchasedCard(localization, isPurchased, isReceived);
    }

    // Case 3: Available
    return _buildAvailableCard(localization);
  }

  Widget _buildReservedCard(LocalizationService localization) {
    final reservedByName = item.reservedBy?.fullName ?? 'a friend';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.orange.shade200,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.access_time_rounded,
              color: Colors.orange.shade700,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localization.translate('details.reserved'),
                  style: AppStyles.bodySmall.copyWith(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${localization.translate('details.reservedBy')} $reservedByName',
                  style: AppStyles.bodyMedium.copyWith(
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchasedCard(
    LocalizationService localization,
    bool isPurchased,
    bool isReceived,
  ) {
    final statusText = isReceived 
        ? localization.translate('details.gifted')
        : localization.translate('details.purchased');
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.green.shade200,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.card_giftcard_rounded,
              color: Colors.green.shade700,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: AppStyles.bodyMedium.copyWith(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (isPurchased && !isReceived && isOwner && onMarkReceived != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onMarkReceived,
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: Text(
                        localization.translate('details.markReceived'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableCard(LocalizationService localization) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localization.translate('details.available'),
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  localization.translate('details.available'),
                  style: AppStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

