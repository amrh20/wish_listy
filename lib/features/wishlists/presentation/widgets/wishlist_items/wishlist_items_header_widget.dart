import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/services/localization_service.dart';

/// Header row: back button, share/add actions, overflow menu (share / edit / delete).
class WishlistItemsHeaderWidget extends StatelessWidget {
  final bool isOwner;
  final bool isGuest;
  final bool isFriendWishlist;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onAddItem;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final LocalizationService localization;

  const WishlistItemsHeaderWidget({
    super.key,
    required this.isOwner,
    required this.isGuest,
    required this.isFriendWishlist,
    required this.onBack,
    required this.onShare,
    required this.onAddItem,
    required this.onEdit,
    required this.onDelete,
    required this.localization,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.textPrimary,
            size: 20,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const Spacer(),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isGuest && !isFriendWishlist)
              IconButton(
                tooltip: 'Share',
                onPressed: onShare,
                icon: Icon(Icons.share, color: AppColors.primary),
              ),
            if (!isFriendWishlist)
              IconButton(
                onPressed: onAddItem,
                icon: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            if (!isFriendWishlist)
              PopupMenuButton<String>(
                tooltip: 'More',
                icon: const Icon(
                  Icons.more_vert,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'share':
                      onShare();
                      break;
                    case 'edit':
                      onEdit();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) {
                  final items = <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share_outlined, size: 18, color: AppColors.textPrimary),
                          const SizedBox(width: 10),
                          Text(
                            localization.translate('wishlists.shareWishlist'),
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ];
                  if (!isGuest && isOwner) {
                    items.addAll([
                      const PopupMenuDivider(),
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18, color: AppColors.textPrimary),
                            const SizedBox(width: 10),
                            Text(
                              localization.translate('wishlists.editWishlist'),
                              style: TextStyle(color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                            const SizedBox(width: 10),
                            Text(
                              localization.translate('wishlists.deleteWishlist'),
                              style: const TextStyle(color: AppColors.error),
                            ),
                          ],
                        ),
                      ),
                    ]);
                  }
                  return items;
                },
              ),
          ],
        ),
      ],
    );
  }
}
