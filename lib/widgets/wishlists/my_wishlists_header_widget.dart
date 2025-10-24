import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../services/localization_service.dart';

/// Header widget for My Wishlists screen
class MyWishlistsHeaderWidget extends StatelessWidget {
  final VoidCallback onSearchPressed;
  final VoidCallback onMenuActionExport;
  final VoidCallback onMenuActionSettings;

  const MyWishlistsHeaderWidget({
    super.key,
    required this.onSearchPressed,
    required this.onMenuActionExport,
    required this.onMenuActionSettings,
  });

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                localization.translate('wishlists.myWishlists'),
                style: AppStyles.headingLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // Search Button
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: onSearchPressed,
                icon: Icon(Icons.search_rounded, color: AppColors.textPrimary),
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
            ),
            const SizedBox(width: 8),
            // Menu Button
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'export') {
                    onMenuActionExport();
                  } else if (value == 'settings') {
                    onMenuActionSettings();
                  }
                },
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.textPrimary,
                ),
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.download_outlined, size: 20),
                        SizedBox(width: 12),
                        Text(localization.translate('common.export')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings_outlined, size: 20),
                        SizedBox(width: 12),
                        Text(localization.translate('profile.settings')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
