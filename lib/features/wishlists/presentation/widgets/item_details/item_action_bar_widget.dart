import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'package:wish_listy/features/wishlists/data/models/wishlist_model.dart';
import 'package:wish_listy/features/wishlists/presentation/utils/reservation_expiry_helper.dart';
import 'package:wish_listy/features/wishlists/presentation/utils/reserved_by_me_state_helper.dart';

class ItemActionBarWidget extends StatelessWidget {
  final WishlistItem item;
  final bool isOwner;
  final bool isReservedByMe;
  final VoidCallback? onMarkReceived;
  final VoidCallback? onMarkAsNotReceived;
  final VoidCallback? onCancelReservation;
  final VoidCallback? onReserve;
  final VoidCallback? onExtendReservation;
  final VoidCallback? onMarkAsPurchased;
  final bool isExtendingReservation;

  const ItemActionBarWidget({
    super.key,
    required this.item,
    required this.isOwner,
    required this.isReservedByMe,
    this.onMarkReceived,
    this.onMarkAsNotReceived,
    this.onCancelReservation,
    this.onReserve,
    this.onExtendReservation,
    this.onMarkAsPurchased,
    this.isExtendingReservation = false,
  });

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    final isPurchased = item.isPurchasedValue;
    final isReserved = item.isReservedValue;
    final isReservedByOther = isReserved && !isReservedByMe;
    final reservedByMeState =
        getReservedByMeState(item, isReservedByMe: isReservedByMe);

    // Owner View: Only show "Mark as Received" for Reserved or Purchased items
    if (isOwner) {
      // When received (gifted), show celebratory banner for owner too
      if (item.isReceived) {
        return _buildCelebratoryBanner(context, localization);
      }
      // Show "Mark as Received" if item is Reserved or Purchased
      if (isReserved || isPurchased) {
        return _buildOwnerMarkReceivedBar(context, localization, isPurchased);
      }
      // Item is Available - owner sees no action button (Edit is in top bar)
      return const SizedBox.shrink();
    }

    // Non-Owner View: Standard guest actions with reserved-by-me state priority
    // State A: I reserved and friend already received → celebratory banner, no CTAs
    if (reservedByMeState == ReservedByMeState.received) {
      return _buildCelebratoryBanner(context, localization);
    }

    // State B: I reserved and already purchased, waiting for friend confirmation → waiting message, no CTAs
    if (reservedByMeState == ReservedByMeState.purchasedAwaitingReceipt) {
      return _buildPurchasedAwaitingBar(context, localization);
    }

    // Generic received state for non-reservers
    if (item.isReceived) {
      return _buildReceivedBar(context, localization);
    }

    // Purchased but not received and not reserved by me – no bottom bar
    if (isPurchased && !item.isReceived) {
      return const SizedBox.shrink();
    }

    // State C: Reserved by ME (only when not purchased/received)
    if (isReservedByMe) {
      return _buildReservedByMeBar(context, localization);
    }

    // Reserved by OTHERS (Guest view)
    if (isReservedByOther) {
      return _buildReservedByOthersBar(context, localization);
    }

    // Available - Clean Primary Button
    return _buildAvailableBar(context, localization);
  }

  Color _getBarSurfaceColor(BuildContext context) {
    return Colors.transparent;
  }

  Widget _buildReceivedBar(BuildContext context, LocalizationService localization) {
    return _buildCelebratoryBanner(context, localization);
  }

  /// Celebratory banner when item is gifted/received (Mission Accomplished).
  Widget _buildCelebratoryBanner(BuildContext context, LocalizationService localization) {
    const mintGreen = Color(0xFF98D4BB);
    const softGold = Color(0xFFE8D5A3);
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 12),
      decoration: BoxDecoration(
        color: _getBarSurfaceColor(context),
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.92, end: 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(scale: value, child: child);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                mintGreen,
                softGold,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: mintGreen.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              localization.translate('details.wishGrantedBanner') ?? 'Woot woot! This wish just came true! 🎉',
              textAlign: TextAlign.center,
              style: AppStyles.bodyLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPurchasedAwaitingBar(BuildContext context, LocalizationService localization) {
    return Container(
      padding: const EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: 10,
      ),
      color: _getBarSurfaceColor(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.warning.withOpacity(0.25),
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
                    localization.translate('details.purchasedByYouAwaitingConfirmation'),
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
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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

  Widget _buildReservedByMeBar(BuildContext context, LocalizationService localization) {
    final reservedUntil = item.reservedUntil;
    final expiryFormat = reservedUntil != null ? formatReservationExpiry(reservedUntil, localization) : null;
    final expiryText = expiryFormat?.text;
    final extensionCount = item.extensionCount;
    final remaining = 2 - (extensionCount > 2 ? 2 : (extensionCount));
    final maxExtensionsReached = remaining <= 0;

    return Container(
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: 12,
      ),
      color: _getBarSurfaceColor(context),
      child: Builder(
        builder: (context) {
          final primary = Theme.of(context).colorScheme.primary;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: _getBarSurfaceColor(context),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top: Status & Expiration
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle, color: AppColors.primaryDark, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            localization.translate('details.reservedByYou') ?? 'Reserved by You',
                            style: AppStyles.bodyMedium.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (expiryText != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              expiryText,
                              style: AppStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                // Divider
                const SizedBox(height: 12),
                // Bottom: Action buttons stacked vertically
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top: Primary action - Mark as Purchased (full-width)
                    if (onMarkAsPurchased != null)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: onMarkAsPurchased,
                          icon: const Icon(
                            Icons.check_circle_outline,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: Text(
                            localization.translate('ui.markAsPurchased') ?? 'Mark Purchased',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    // Middle: Secondary action - Extend (full-width outlined)
                    if (onExtendReservation != null) ...[
                      if (onMarkAsPurchased != null) const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: Tooltip(
                          message: maxExtensionsReached
                              ? localization.translate('details.maxExtensionsReached')
                              : '',
                          child: OutlinedButton(
                            onPressed: maxExtensionsReached || isExtendingReservation
                                ? null
                                : onExtendReservation,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: maxExtensionsReached
                                  ? AppColors.textTertiary
                                  : AppColors.primaryDark,
                              side: BorderSide(
                                width: 1.5,
                                color: maxExtensionsReached
                                    ? AppColors.textTertiary
                                    : AppColors.primaryDark,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: isExtendingReservation
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(
                                    maxExtensionsReached
                                        ? localization.translate('details.maxExtensionsReached')
                                        : localization.translate(
                                            'details.extendReservationWithCount',
                                            args: {'count': remaining},
                                          ),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: maxExtensionsReached
                                          ? AppColors.textTertiary
                                          : AppColors.primaryDark,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                    // Bottom: Destructive action - Cancel Reservation (text-only, full-width)
                    if (onCancelReservation != null) ...[
                      if (onMarkAsPurchased != null || onExtendReservation != null)
                        const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: onCancelReservation,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          child: Text(
                            localization.translate('details.cancelReservation'),
                            style: const TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReservedByOthersBar(BuildContext context, LocalizationService localization) {
    return Container(
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: 12,
      ),
      color: _getBarSurfaceColor(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _getBarSurfaceColor(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.25),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_outline, color: AppColors.primaryDark, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                localization.translate('details.alreadyReservedByFriend'),
                style: AppStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
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

  Widget _buildAvailableBar(BuildContext context, LocalizationService localization) {
    return Container(
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: 16,
      ),
      color: _getBarSurfaceColor(context),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: onReserve != null
              ? CustomButton(
                  text: localization.translate('details.reserveGift'),
                  onPressed: onReserve,
                  variant: ButtonVariant.primary,
                  size: ButtonSize.large,
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  /// Build "Mark as Received" button for owner view.
  /// State 3: When item is purchased but not received, show both primary (Mark as Received)
  /// and secondary (Not yet) buttons side by side. "Not yet" triggers onMarkAsNotReceived
  /// which calls the API to mark item as not received (reverts to available).
  Widget _buildOwnerMarkReceivedBar(
    BuildContext context,
    LocalizationService localization, [
    bool isPurchased = false,
  ]) {
    final showNotReceivedButton =
        isPurchased && !item.isReceived && onMarkAsNotReceived != null;

    return Container(
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: 16,
      ),
      color: _getBarSurfaceColor(context),
      child: SafeArea(
        top: false,
        child: showNotReceivedButton
            ? Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onMarkReceived,
                      icon: const Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: Text(
                        localization.translate('details.markReceived') ??
                            'I got it ✨',
                        style: AppStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onMarkAsNotReceived,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: BorderSide(color: AppColors.textSecondary.withOpacity(0.5)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        localization.translate('details.notReceivedYetButton') ??
                            'Not yet',
                        style: AppStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : (onMarkReceived != null
                ? SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onMarkReceived,
                      icon: const Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: Text(
                        localization.translate('details.markReceived') ??
                            'I got it ✨',
                        style: AppStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                    ),
                  )
                : const SizedBox.shrink()),
      ),
    );
  }
}

