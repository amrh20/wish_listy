import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';

/// Compact horizontal tile widget for displaying a wishlist linked to an event
class EventWishlistTile extends StatelessWidget {
  final String wishlistName;
  final int itemCount;
  final int? reservedCount;
  final VoidCallback onTap;
  final VoidCallback? onUnlink;
  final bool showUnlinkAction;

  const EventWishlistTile({
    super.key,
    required this.wishlistName,
    required this.itemCount,
    this.reservedCount,
    required this.onTap,
    this.onUnlink,
    this.showUnlinkAction = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Leading Icon Container
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.card_giftcard,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Middle Info Section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Wishlist Name
                        Text(
                          wishlistName,
                          style: AppStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Item Count Subtitle
                        Text(
                          _buildSubtitleText(context),
                          style: AppStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Trailing Actions (Menu + Arrow)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Unlink Menu (if enabled and callback provided)
                      if (showUnlinkAction && onUnlink != null)
                        IconButton(
                          onPressed: () => _showUnlinkMenu(context),
                          icon: Icon(
                            Icons.more_vert,
                            size: 20,
                            color: AppColors.textTertiary,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          tooltip: Provider.of<LocalizationService>(context, listen: false).translate('events.wishlistOptions'),
                        ),
                      if (showUnlinkAction && onUnlink != null)
                        const SizedBox(width: 4),
                      // Trailing Arrow
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppColors.textTertiary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _buildSubtitleText(BuildContext context) {
    final t = Provider.of<LocalizationService>(context, listen: false);
    final itemLabel = itemCount == 1
        ? t.translate('events.itemSingular')
        : t.translate('events.itemPlural');
    if (reservedCount != null && reservedCount! > 0) {
      final reserved = t.translate('events.reserved');
      return '$itemCount $itemLabel • $reservedCount $reserved';
    }
    return '$itemCount $itemLabel';
  }

  void _showUnlinkMenu(BuildContext context) {
    final t = Provider.of<LocalizationService>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Unlink option
              ListTile(
                leading: Icon(
                  Icons.link_off,
                  color: AppColors.error,
                ),
                title: Text(
                  t.translate('events.unlinkWishlistTitle'),
                  style: AppStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
                subtitle: Text(
                  t.translate('events.unlinkWishlistSubtitle'),
                  style: AppStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onUnlink?.call();
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

