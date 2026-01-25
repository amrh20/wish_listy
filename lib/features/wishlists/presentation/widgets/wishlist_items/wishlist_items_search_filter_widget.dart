import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'wishlist_filter_chip_widget.dart';

/// Search TextField + filter chips (All, Available, Reserved, Gifted).
class WishlistItemsSearchFilterWidget extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;
  final bool isGuest;
  final LocalizationService localization;

  const WishlistItemsSearchFilterWidget({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.isGuest,
    required this.localization,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.surfaceVariant,
              width: 1,
            ),
          ),
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: localization.translate('dialogs.searchWishes'),
              hintStyle: AppStyles.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
              prefixIcon: Icon(
                Icons.search_outlined,
                color: AppColors.textTertiary,
                size: 20,
              ),
              filled: true,
              fillColor: Colors.transparent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.secondary,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            style: AppStyles.bodyMedium,
          ),
        ),
        const SizedBox(height: 16),
        if (!isGuest)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                WishlistFilterChipWidget(
                  value: 'all',
                  label: localization.translate('ui.all'),
                  icon: Icons.all_inclusive,
                  isSelected: selectedFilter == 'all',
                  onTap: () => onFilterChanged('all'),
                ),
                const SizedBox(width: 8),
                WishlistFilterChipWidget(
                  value: 'available',
                  label: localization.translate('ui.available'),
                  icon: Icons.shopping_bag_outlined,
                  isSelected: selectedFilter == 'available',
                  onTap: () => onFilterChanged('available'),
                ),
                const SizedBox(width: 8),
                WishlistFilterChipWidget(
                  value: 'reserved',
                  label: localization.translate('ui.reserved'),
                  icon: Icons.lock_outline,
                  isSelected: selectedFilter == 'reserved',
                  onTap: () => onFilterChanged('reserved'),
                ),
                const SizedBox(width: 8),
                WishlistFilterChipWidget(
                  value: 'purchased',
                  label: localization.translate('ui.gifted'),
                  icon: Icons.check_circle_outline,
                  isSelected: selectedFilter == 'purchased',
                  onTap: () => onFilterChanged('purchased'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
