import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/bottom_sheet_vectors.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/core/widgets/decorated_bottom_sheet.dart';
import 'package:wish_listy/core/widgets/modern_wishlist_card.dart';
import 'package:wish_listy/features/wishlists/presentation/widgets/shared/wishlist_summary.dart';

export 'package:wish_listy/features/wishlists/presentation/widgets/shared/wishlist_summary.dart';

/// Widget for displaying a wishlist card using the modern design
class WishlistCardWidget extends StatelessWidget {
  final WishlistSummary wishlist;
  final bool isEvent;
  final VoidCallback onTap;
  final VoidCallback onAddItem;
  final Function(String) onMenuAction;
  final bool isReadOnly; // If true, hide all action buttons and menu

  const WishlistCardWidget({
    super.key,
    required this.wishlist,
    required this.isEvent,
    required this.onTap,
    required this.onAddItem,
    required this.onMenuAction,
    this.isReadOnly = false, // Default to false for backward compatibility
  });

  @override
  Widget build(BuildContext context) {
    final progress = wishlist.itemCount > 0
        ? (wishlist.purchasedCount / wishlist.itemCount) * 100
        : 0.0;

    // Calculate today items (mock - replace with actual data from API if available)
    final todayItems = 0;

    // Determine description based on event or personal
    String? description;
    if (isEvent && wishlist.eventName != null) {
      description = wishlist.eventName;
    } else {
      description = wishlist.description;
    }

    // Determine accent color based on type
    final accentColor = isEvent ? AppColors.accent : AppColors.primary;

    return ModernWishlistCard(
      title: wishlist.name,
      description: description,
      privacy: wishlist.privacy,
      totalItems: wishlist.itemCount,
      giftedItems: wishlist.purchasedCount,
      todayItems: todayItems,
      completionPercentage: progress,
      accentColor: accentColor,
      category: wishlist.category, // Pass category for image display
      eventDate: wishlist.eventDate, // Pass eventDate for days left calculation
      previewItemNames: wishlist.previewItems.map((e) => e.name).toList(),
      onView: onTap,
      onAddItem: onAddItem,
      onEdit: () => onMenuAction('edit'),
      onMenu: isReadOnly ? null : () => _showMenu(context),
      isReadOnly: isReadOnly,
    );
  }

  void _showMenu(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    DecoratedBottomSheet.show(
      context: context,
      vectorType: BottomSheetVectorType.menu,
      children: [
        // Add New Wish action
        ListTile(
          leading: Icon(Icons.add_circle_outline, color: AppColors.primary),
          title: Text(
            localization.translate('wishlists.addNewWish') ?? 'Add New Wish',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          onTap: () {
            Navigator.pop(context); // Close bottom sheet
            // Navigate to Add Item screen with wishlist ID pre-selected
            Navigator.pushNamed(
              context,
              AppRoutes.addItem,
              arguments: wishlist.id,
            );
          },
        ),
        // Menu options
        ListTile(
          leading: Icon(Icons.edit_outlined, color: AppColors.textPrimary),
          title: Text(
            localization.translate('events.editWishlist'),
            style: TextStyle(color: AppColors.textPrimary),
          ),
          onTap: () {
            Navigator.pop(context);
            onMenuAction('edit');
          },
        ),
        ListTile(
          leading: Icon(Icons.share_outlined, color: AppColors.textPrimary),
          title: Text(
            localization.translate('events.share'),
            style: TextStyle(color: AppColors.textPrimary),
          ),
          onTap: () {
            Navigator.pop(context);
            onMenuAction('share');
          },
        ),
        ListTile(
          leading: Icon(Icons.delete_outline, color: AppColors.error),
          title: Text(
            localization.translate('events.delete'),
            style: TextStyle(
                color: AppColors.error, fontWeight: FontWeight.w600),
          ),
          onTap: () {
            Navigator.pop(context);
            onMenuAction('delete');
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
