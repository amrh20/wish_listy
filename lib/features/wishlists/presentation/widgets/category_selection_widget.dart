import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/widgets/custom_text_field.dart';
import 'package:wish_listy/core/services/localization_service.dart';

/// Widget for selecting category when creating/editing wishlist
class CategorySelectionWidget extends StatelessWidget {
  final List<String> categoryOptions;
  final String? selectedCategory; // Nullable - null means no category selected
  final bool isCustomCategory;
  final TextEditingController customCategoryController;
  final Function(String?) onCategorySelected; // Can pass null to deselect
  final String Function(String) getCategoryDisplayName;
  final String Function() getTitle;
  final String? Function(String?)? customCategoryValidator;

  const CategorySelectionWidget({
    super.key,
    required this.categoryOptions,
    required this.selectedCategory,
    required this.isCustomCategory,
    required this.customCategoryController,
    required this.onCategorySelected,
    required this.getCategoryDisplayName,
    required this.getTitle,
    this.customCategoryValidator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.category_outlined,
                color: AppColors.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: AppStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    children: [
                      TextSpan(text: getTitle()),
                      TextSpan(
                        text: ' (${_getOptionalText(context)})',
                        style: AppStyles.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categoryOptions.map((category) {
              final isSelected = selectedCategory == category;
              final isCustom = category == 'custom';

              return GestureDetector(
                onTap: () {
                  // Toggle behavior: if clicking the same category, deselect it
                  if (isSelected) {
                    onCategorySelected(null);
                  } else {
                    onCategorySelected(category);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.secondary
                        : isCustom
                            ? AppColors.surfaceVariant.withOpacity(0.5)
                            : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                    border: isCustom && !isSelected
                        ? Border.all(
                            color: AppColors.primary.withOpacity(0.4),
                            width: 1.5,
                            style: BorderStyle.solid,
                          )
                        : Border.all(
                            color: isSelected
                                ? AppColors.secondary
                                : AppColors.textTertiary.withOpacity(0.3),
                            width: 1,
                          ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isCustom && !isSelected)
                        Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: AppColors.primary,
                        )
                      else if (isCustom && isSelected)
                        Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: Colors.white,
                        ),
                      if (isCustom) const SizedBox(width: 6),
                      Text(
                        getCategoryDisplayName(category),
                        style: AppStyles.bodySmall.copyWith(
                          color: isSelected
                              ? Colors.white
                              : isCustom
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                          fontWeight: isSelected || isCustom
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          // Show custom category input field when "Custom" is selected
          if (isCustomCategory) ...[
            const SizedBox(height: 16),
            CustomTextField(
              controller: customCategoryController,
              label: 'Custom Category',
              hint: 'Enter your custom category name',
              prefixIcon: Icons.edit_outlined,
              validator: customCategoryValidator,
            ),
          ],
        ],
      ),
    );
  }

  String _getOptionalText(BuildContext context) {
    return Provider.of<LocalizationService>(
      context,
      listen: false,
    ).translate('common.optional') ?? 
        (Provider.of<LocalizationService>(context, listen: false).currentLanguage == 'ar' 
            ? '(اختياري)' 
            : '(Optional)');
  }
}

