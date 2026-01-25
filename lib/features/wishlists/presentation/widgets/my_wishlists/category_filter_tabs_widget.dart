import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/features/wishlists/presentation/widgets/form/wishlist_form_helpers.dart';

/// Horizontal filter tabs for wishlist categories (All + category chips).
class CategoryFilterTabsWidget extends StatelessWidget {
  final List<String> categories;
  final Map<String, int> categoryCounts;
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;
  final LocalizationService localization;

  const CategoryFilterTabsWidget({
    super.key,
    required this.categories,
    required this.categoryCounts,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.localization,
  });

  @override
  Widget build(BuildContext context) {
    final isRTL = localization.isRTL;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Directionality(
        textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(
              Icons.filter_list_rounded,
              size: 20,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            _CategoryChip(
              label: localization.translate('ui.all'),
              category: null,
              isSelected: selectedCategory == null,
              icon: Icons.list_rounded,
              count: categoryCounts['all'] ?? 0,
              onTap: () => onCategorySelected(null),
            ),
            const SizedBox(width: 8),
            ...categories.map((category) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _CategoryChip(
                  label: WishlistFormHelpers.getCategoryDisplayName(
                    category,
                    localization,
                  ),
                  category: category,
                  isSelected: selectedCategory == category,
                  icon: WishlistFormHelpers.getCategoryIcon(category),
                  count: categoryCounts[category] ?? 0,
                  onTap: () => onCategorySelected(category),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final String? category;
  final bool isSelected;
  final IconData icon;
  final int count;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.category,
    required this.isSelected,
    required this.icon,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primary : AppColors.textTertiary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppStyles.bodySmall.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textTertiary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: AppStyles.caption.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
