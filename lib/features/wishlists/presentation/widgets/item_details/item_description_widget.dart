import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';

class ItemDescriptionWidget extends StatelessWidget {
  final String? description;

  const ItemDescriptionWidget({
    super.key,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final desc = description?.trim();
    if (desc == null || desc.isEmpty) {
      return const SizedBox.shrink();
    }

    final localization = Provider.of<LocalizationService>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localization.translate('details.description'),
          style: AppStyles.bodySmall.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          desc,
          style: AppStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

