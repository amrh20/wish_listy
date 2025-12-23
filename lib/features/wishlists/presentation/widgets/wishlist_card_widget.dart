import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/bottom_sheet_vectors.dart';
import 'package:wish_listy/core/widgets/decorated_bottom_sheet.dart';
import 'package:wish_listy/core/widgets/modern_wishlist_card.dart';
import 'package:wish_listy/features/wishlists/data/models/wishlist_model.dart';

/// Model for wishlist privacy settings
enum WishlistPrivacy { public, private, onlyInvited }

/// Model for wishlist summary data
class WishlistSummary {
  final String id;
  final String name;
  final String? description;
  final int itemCount;
  final int purchasedCount;
  final DateTime lastUpdated;
  final WishlistPrivacy privacy;
  final String? imageUrl;
  final String? eventName;
  final DateTime? eventDate;
  final String? category; // Added category field
  final List<WishlistItem> previewItems;

  WishlistSummary({
    required this.id,
    required this.name,
    this.description,
    required this.itemCount,
    required this.purchasedCount,
    required this.lastUpdated,
    this.privacy = WishlistPrivacy.public,
    this.imageUrl,
    this.eventName,
    this.eventDate,
    this.category, // Added category field
    this.previewItems = const [],
  });
}

/// Widget for displaying a wishlist card using the modern design
class WishlistCardWidget extends StatelessWidget {
  final WishlistSummary wishlist;
  final bool isEvent;
  final VoidCallback onTap;
  final VoidCallback onAddItem;
  final Function(String) onMenuAction;

  const WishlistCardWidget({
    super.key,
    required this.wishlist,
    required this.isEvent,
    required this.onTap,
    required this.onAddItem,
    required this.onMenuAction,
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
      onMenu: () => _showMenu(context),
    );
  }

  void _showMenu(BuildContext context) {
    DecoratedBottomSheet.show(
      context: context,
      vectorType: BottomSheetVectorType.menu,
      children: [
        // Menu options
        ListTile(
          leading: Icon(Icons.edit_outlined, color: AppColors.textPrimary),
          title: Text(
            'Edit Wishlist',
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
            'Share',
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
            'Delete',
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
