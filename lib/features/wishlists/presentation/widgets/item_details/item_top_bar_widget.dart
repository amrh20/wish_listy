import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/services/localization_service.dart';

class ItemTopBarWidget extends StatelessWidget {
  final bool isOwner;
  final bool isReceived;
  final bool isReserved;
  final VoidCallback onBack;
  final VoidCallback? onShare;
  final VoidCallback? onEdit;

  const ItemTopBarWidget({
    super.key,
    required this.isOwner,
    required this.isReceived,
    required this.isReserved,
    required this.onBack,
    this.onShare,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    final isReservedForOwner = isOwner && isReserved;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            color: AppColors.textPrimary,
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const Spacer(),
          // Only show Share and Edit if user is owner
          if (isOwner) ...[
            if (onShare != null)
              IconButton(
                tooltip: localization.translate('app.share'),
                onPressed: onShare,
                icon: const Icon(Icons.share_outlined, size: 22),
                color: AppColors.textPrimary,
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            if (!isReceived && !isReservedForOwner && onEdit != null)
              IconButton(
                tooltip: localization.translate('app.edit'),
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 22),
                color: AppColors.textPrimary,
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            // Show disabled Edit button if reserved (Teaser Mode)
            if (!isReceived && isReservedForOwner)
              IconButton(
                tooltip: localization.translate('app.edit'),
                onPressed: () => _showReservedItemSnackbar(context, localization),
                icon: const Icon(
                  Icons.edit_outlined, 
                  size: 22,
                ),
                color: AppColors.textTertiary.withOpacity(0.5),
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ],
      ),
    );
  }

  void _showReservedItemSnackbar(BuildContext context, LocalizationService localization) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          localization.translate('details.cannotEditDeleteReserved'),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

