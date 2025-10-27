import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';

class CustomTopNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomTopNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localization, child) {
        if (!context.mounted) return const SizedBox.shrink();

        final navigationItems = [
          {
            'icon': Icons.home_outlined,
            'activeIcon': Icons.home_rounded,
            'label': localization.translate('navigation.home'),
            'color': AppColors.primary,
          },
          {
            'icon': Icons.favorite_outline,
            'activeIcon': Icons.favorite_rounded,
            'label': localization.translate('navigation.wishlist'),
            'color': AppColors.secondary,
          },
          {
            'icon': Icons.celebration_outlined,
            'activeIcon': Icons.celebration_rounded,
            'label': localization.translate('navigation.events'),
            'color': AppColors.accent,
          },
          {
            'icon': Icons.people_outline,
            'activeIcon': Icons.people_rounded,
            'label': localization.translate('navigation.friends'),
            'color': AppColors.info,
          },
          {
            'icon': Icons.person_outline,
            'activeIcon': Icons.person_rounded,
            'label': localization.translate('navigation.profile'),
            'color': AppColors.warning,
          },
        ];

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: AppColors.textTertiary.withOpacity(0.1),
                offset: const Offset(0, 2),
                blurRadius: 20,
                spreadRadius: 0,
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Container(
              height: 56, // Fixed height for the navigation bar
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: navigationItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isActive = currentIndex == index;

                  return _buildNavigationButton(item, index, isActive);
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavigationButton(
    Map<String, dynamic> item,
    int index,
    bool isActive,
  ) {
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? item['color'].withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: AppStyles.bodyMedium.copyWith(
            color: isActive ? item['color'] : AppColors.textPrimary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
          child: Text(
            item['label'],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
