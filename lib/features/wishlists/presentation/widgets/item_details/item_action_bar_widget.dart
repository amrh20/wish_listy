import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'package:wish_listy/features/wishlists/data/models/wishlist_model.dart';

class ItemActionBarWidget extends StatelessWidget {
  final WishlistItem item;
  final bool isOwner;
  final bool isReservedByMe;
  final VoidCallback? onMarkReceived;
  final VoidCallback? onCancelReservation;
  final VoidCallback? onReserve;

  const ItemActionBarWidget({
    super.key,
    required this.item,
    required this.isOwner,
    required this.isReservedByMe,
    this.onMarkReceived,
    this.onCancelReservation,
    this.onReserve,
  });

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    final isPurchased = item.isPurchasedValue;
    final isReserved = item.isReservedValue;
    final isReservedByOther = isReserved && !isReservedByMe;

    // Owner View: Only show "Mark as Received" for Reserved or Purchased items
    if (isOwner) {
      // Owner should NOT see Reserve, Buy, or Undo actions
      // Only show "Mark as Received" if item is Reserved or Purchased (and not received)
      if (item.isReceived) {
        // Item is already received - no action needed
        return const SizedBox.shrink();
      }
      
      // Show "Mark as Received" if item is Reserved or Purchased
      if (isReserved || isPurchased) {
        return _buildOwnerMarkReceivedBar(localization);
      }
      
      // Item is Available - owner sees no action button (Edit is in top bar)
      return const SizedBox.shrink();
    }

    // Non-Owner View: Standard guest actions
    // Case A: Item is Received - No action needed
    if (item.isReceived) {
      return _buildReceivedBar(localization);
    }

    // Case A.5: Purchased but not Received (should not show for non-owners)
    if (isPurchased && !item.isReceived) {
      return const SizedBox.shrink();
    }

    // Case B: Reserved by ME
    if (isReservedByMe) {
      return _buildReservedByMeBar(localization);
    }

    // Case C: Reserved by OTHERS (Guest view)
    if (isReservedByOther) {
      return _buildReservedByOthersBar(localization);
    }

    // Case D: Available - Clean Primary Button
    return _buildAvailableBar(localization);
  }

  Widget _buildReceivedBar(LocalizationService localization) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Text(
              '🎁',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                localization.translate('details.giftReceivedPurchased'),
                style: AppStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchasedAwaitingBar(LocalizationService localization) {
    return Container(
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.warning.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  color: AppColors.warning,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    localization.translate('details.purchasedAwaitingConfirmation'),
                    style: AppStyles.bodyMedium.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (onMarkReceived != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onMarkReceived,
                  icon: const Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: Text(
                    localization.translate('details.markReceived'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReservedByMeBar(LocalizationService localization) {
    return Container(
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.green.shade200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                localization.translate('details.reservedByYou') ?? 'Reserved by You',
                style: AppStyles.bodyMedium.copyWith(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (onCancelReservation != null)
              TextButton(
                onPressed: onCancelReservation,
                child: Text(
                  localization.translate('details.undo'),
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservedByOthersBar(LocalizationService localization) {
    return Container(
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.grey.shade600, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                localization.translate('details.alreadyReservedByFriend'),
                style: AppStyles.bodyMedium.copyWith(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableBar(LocalizationService localization) {
    return Container(
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: onReserve != null
              ? CustomButton(
                  text: localization.translate('details.reserveGift'),
                  onPressed: onReserve,
                  variant: ButtonVariant.gradient,
                  gradientColors: const [AppColors.primary, AppColors.secondary],
                  icon: Icons.bookmark_outline,
                  size: ButtonSize.large,
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  /// Build "Mark as Received" button for owner view
  /// Matches the style from wishlist_item_card_widget.dart
  Widget _buildOwnerMarkReceivedBar(LocalizationService localization) {
    return Container(
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: onMarkReceived != null
              ? ElevatedButton.icon(
                  onPressed: onMarkReceived,
                  icon: const Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: Text(
                    localization.translate('details.markReceived'),
                    style: AppStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}

