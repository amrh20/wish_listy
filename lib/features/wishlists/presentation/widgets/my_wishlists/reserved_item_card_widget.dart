import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/widgets/confirmation_dialog.dart';
import 'package:wish_listy/features/wishlists/data/models/wishlist_model.dart';
import 'package:wish_listy/features/wishlists/presentation/utils/reservation_expiry_helper.dart';
import 'package:wish_listy/features/wishlists/presentation/widgets/item_details/reservation_deadline_bottom_sheet.dart';

class ReservedItemCardWidget extends StatelessWidget {
  final WishlistItem item;
  final VoidCallback onCancelReservation;
  final VoidCallback onTap;
  final VoidCallback? onMarkAsPurchased;
  final void Function(DateTime newDate)? onExtend;

  const ReservedItemCardWidget({
    super.key,
    required this.item,
    required this.onCancelReservation,
    required this.onTap,
    this.onMarkAsPurchased,
    this.onExtend,
  });

  String _getInitials(String fullName) {
    if (fullName.isEmpty) return '?';
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return fullName[0].toUpperCase();
  }

  void _showCancelConfirmation(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    ConfirmationDialog.show(
      context: context,
      isSuccess: false,
      title: localization.translate('details.unreserveGiftTitle'),
      message: localization.translate('details.unreserveGiftMessage'),
      primaryActionLabel: localization.translate('details.cancelReservation'),
      onPrimaryAction: onCancelReservation,
      secondaryActionLabel: localization.translate('common.cancel'),
      onSecondaryAction: () {},
      accentColor: AppColors.warning,
      icon: Icons.undo_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    final owner = item.wishlist?.owner;
    final ownerName = owner?.fullName ?? localization.translate('common.unknown');
    final ownerImage = owner?.profileImage;
    final isPurchased = item.isPurchasedValue;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPurchased
                  ? AppColors.success.withOpacity(0.3)
                  : Colors.grey.shade200,
              width: isPurchased ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isPurchased
                    ? AppColors.success.withOpacity(0.1)
                    : Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item Image (Leading)
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isPurchased
                          ? AppColors.success.withOpacity(0.15)
                          : AppColors.primary.withOpacity(0.1),
                      image: item.imageUrl != null && item.imageUrl!.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(item.imageUrl!),
                              fit: BoxFit.cover,
                              onError: (_, __) {},
                            )
                          : null,
                    ),
                    child: item.imageUrl == null || item.imageUrl!.isEmpty
                        ? Icon(
                            isPurchased ? Icons.card_giftcard : Icons.card_giftcard,
                            color: isPurchased ? AppColors.success : AppColors.primary,
                            size: 24,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  // Title and Subtitle (Expanded)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Item Name (Bold)
                        Text(
                          item.name,
                          style: AppStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isPurchased
                                ? AppColors.textTertiary
                                : AppColors.textPrimary,
                            decoration: isPurchased
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Thankful message if purchased, otherwise owner row
                        if (isPurchased)
                          // Purchased: show different message based on isReceived
                          Row(
                            children: [
                              Icon(
                                item.isReceived ? Icons.check_circle : Icons.schedule_rounded,
                                size: 14,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  item.isReceived
                                      ? (localization.translate(
                                          'details.friendReceivedGift',
                                          args: {'name': ownerName},
                                        ) ?? 'Thanks! $ownerName received your gift 🎉')
                                      : (localization.translate(
                                          'details.purchasedAwaitingFriendReceipt',
                                        ) ?? 'Thanks for purchasing the gift. Waiting for your friend to receive it.'),
                                  style: AppStyles.bodySmall.copyWith(
                                    color: AppColors.success,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                        else
                          // Owner Row
                          Row(
                            children: [
                              // Small Avatar
                              CircleAvatar(
                                radius: 8,
                                backgroundColor: AppColors.primary.withOpacity(0.2),
                                backgroundImage: ownerImage != null &&
                                        ownerImage.isNotEmpty
                                    ? NetworkImage(ownerImage)
                                    : null,
                                child: ownerImage == null || ownerImage.isEmpty
                                    ? Text(
                                        _getInitials(ownerName),
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 6),
                              // Owner Name Text
                              Expanded(
                                child: Text(
                                  localization.translate(
                                    'details.forOwner',
                                    args: {'name': ownerName},
                                  ),
                                  style: AppStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  if (!isPurchased && (onMarkAsPurchased != null || onCancelReservation != null))
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => _showActionsBottomSheet(context),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      visualDensity: VisualDensity.compact,
                      color: AppColors.textSecondary,
                    ),
                ],
              ),
              // Expiry in its own row, Extend action in row below
              if (!isPurchased && item.reservedUntil != null) ...[
                const SizedBox(height: 10),
                _buildExpiryRow(context, item.reservedUntil!, localization),
                if (onExtend != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (_remainingExtensions() > 0)
                        OutlinedButton(
                          onPressed: () => _openExtendSheet(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: Text(
                            localization.translate('details.extendReservationWithCount', args: {'count': _remainingExtensions()}) ?? 'Extend Reservation (${_remainingExtensions()} attempts left)',
                            style: AppStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                              fontSize: 12,
                            ),
                          ),
                        )
                      else
                        Text(
                          localization.translate('details.maxExtensionsReached') ?? 'Max extensions reached',
                          style: AppStyles.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showActionsBottomSheet(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    final hasActions = onMarkAsPurchased != null || onCancelReservation != null;
    if (!hasActions) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(sheetContext).padding.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (onMarkAsPurchased != null)
              ListTile(
                leading: Icon(Icons.check_circle_outline, color: AppColors.success),
                title: Text(
                  localization.translate('ui.markAsPurchased') ?? 'Mark as Purchased',
                  style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _showMarkAsPurchasedConfirmation(context);
                },
              ),
            if (onCancelReservation != null)
              ListTile(
                leading: Icon(Icons.close, color: AppColors.error),
                title: Text(
                  localization.translate('details.cancelReservation') ?? 'Cancel Reservation',
                  style: AppStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _showCancelConfirmation(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  int _remainingExtensions() {
    final ext = item.extensionCount > 2 ? 2 : item.extensionCount;
    return 2 - ext;
  }

  Widget _buildExpiryRow(BuildContext context, DateTime reservedUntil, LocalizationService localization) {
    final format = formatReservationExpiry(reservedUntil, localization);
    final color = format.isUrgent ? AppColors.warning : AppColors.textSecondary;
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.access_time_rounded, size: 12, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            format.text,
            style: theme.textTheme.labelSmall?.copyWith(color: color) ??
                AppStyles.bodySmall.copyWith(color: color, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _openExtendSheet(BuildContext context) async {
    await ReservationDeadlineBottomSheet.show(
      context,
      isExtension: true,
      initialDeadline: item.reservedUntil,
      onConfirm: (DateTime? date) {
        if (date != null) onExtend?.call(date);
      },
    );
  }

  void _showMarkAsPurchasedConfirmation(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    ConfirmationDialog.show(
      context: context,
      isSuccess: true,
      title: localization.translate('ui.markAsPurchasedQuestion') ?? 'Mark as Purchased?',
      message: localization.translate('ui.markAsPurchasedContent') ?? 'This will mark the item as purchased and received. Have you already bought this gift?',
      primaryActionLabel: localization.translate('ui.markAsPurchased') ?? 'Mark as Purchased',
      onPrimaryAction: () {
        onMarkAsPurchased?.call();
      },
      secondaryActionLabel: localization.translate('common.cancel') ?? 'Cancel',
      onSecondaryAction: () {},
    );
  }
}

