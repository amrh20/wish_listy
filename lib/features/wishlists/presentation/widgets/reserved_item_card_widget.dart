import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/widgets/confirmation_dialog.dart';
import 'package:wish_listy/features/wishlists/data/models/wishlist_model.dart';

class ReservedItemCardWidget extends StatelessWidget {
  final WishlistItem item;
  final VoidCallback onCancelReservation;
  final VoidCallback onTap;

  const ReservedItemCardWidget({
    super.key,
    required this.item,
    required this.onCancelReservation,
    required this.onTap,
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
    ConfirmationDialog.show(
      context: context,
      isSuccess: false, // Error/destructive action
      title: 'Un-reserve this gift?',
      message: 'Others might buy it.',
      primaryActionLabel: 'Un-reserve',
      onPrimaryAction: onCancelReservation,
      secondaryActionLabel: 'Cancel',
      onSecondaryAction: () {
        // Just close the dialog
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final owner = item.wishlist?.owner;
    final ownerName = owner?.fullName ?? 'Unknown';
    final ownerImage = owner?.profileImage;

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
              color: Colors.grey.shade200,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // Item Image (Leading)
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.primary.withOpacity(0.1),
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
                        Icons.card_giftcard,
                        color: AppColors.primary,
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
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
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
                            'For $ownerName',
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
              // Cancel Button (Trailing)
              IconButton(
                icon: const Icon(
                  Icons.cancel_outlined,
                  color: AppColors.error,
                  size: 24,
                ),
                onPressed: () => _showCancelConfirmation(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

