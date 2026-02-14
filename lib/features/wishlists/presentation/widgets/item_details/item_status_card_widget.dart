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

    // Case 1: Gifted/Received – show celebratory card (no "reserved by friend")
    if (isReceived) {
      return _buildGiftedCard(context, localization);
    }

    // Case 2: Purchased but not yet received
    if (isPurchased) {
      return _buildPurchasedCard(context, localization);
    }

    // Case 3: Reserved by Others
    if (isReservedByOther) {
      return _buildReservedCard(context, localization);
    }

    // Case 4: Available
    return _buildAvailableCard(context, localization);
  }

  BoxDecoration _flatCardDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
    );
  }

  Widget _buildReservedCard(BuildContext context, LocalizationService localization) {
    final reservedByName = item.reservedBy?.fullName ?? 'a friend';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _flatCardDecoration(context),
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

  Widget _buildGiftedCard(BuildContext context, LocalizationService localization) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: _flatCardDecoration(context),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.celebration_rounded,
                color: Colors.green.shade700,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              localization.translate('details.giftedStatus'),
              style: AppStyles.bodyMedium.copyWith(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              localization.translate('details.giftedCelebration'),
              style: AppStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchasedCard(
    BuildContext context,
    LocalizationService localization,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _flatCardDecoration(context),
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
                  localization.translate('details.purchased'),
                  style: AppStyles.bodyMedium.copyWith(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (isOwner && onMarkReceived != null) ...[
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

  Widget _buildAvailableCard(BuildContext context, LocalizationService localization) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _flatCardDecoration(context),
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
            child: Text(
              localization.translate('details.available'),
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

