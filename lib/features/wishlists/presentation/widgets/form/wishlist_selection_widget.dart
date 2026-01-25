import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';

/// Widget for selecting a wishlist when adding an item
class WishlistSelectionWidget extends StatelessWidget {
  final List<Map<String, dynamic>> wishlists;
  final String selectedWishlistId;
  final bool isLoading;
  final Function(String) onWishlistSelected;
  final String Function() getTitle;

  const WishlistSelectionWidget({
    super.key,
    required this.wishlists,
    required this.selectedWishlistId,
    required this.isLoading,
    required this.onWishlistSelected,
    required this.getTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                getTitle(),
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (wishlists.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  Provider.of<LocalizationService>(context, listen: false)
                      .translate('cards.noWishlistsFound'),
                  style: AppStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: wishlists.map((wishlistData) {
                final wishlistId = wishlistData['id']?.toString() ??
                    wishlistData['_id']?.toString() ??
                    '';
                final wishlistName =
                    wishlistData['name']?.toString() ?? 'Unnamed';
                final isSelected = selectedWishlistId == wishlistId;

                return GestureDetector(
                  onTap: () => onWishlistSelected(wishlistId),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textTertiary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      wishlistName,
                      style: AppStyles.bodySmall.copyWith(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
