import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';

/// Action buttons widget for create wishlist screen
class CreateWishlistActionButtonsWidget extends StatelessWidget {
  final bool isEditing;
  final bool isFormValid;
  final bool isLoading;
  final VoidCallback onCreate;
  final VoidCallback onCancel;
  final String Function() getCreateButtonText;

  const CreateWishlistActionButtonsWidget({
    super.key,
    required this.isEditing,
    required this.isFormValid,
    required this.isLoading,
    required this.onCreate,
    required this.onCancel,
    required this.getCreateButtonText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomButton(
          text: getCreateButtonText(),
          onPressed: isFormValid && !isLoading ? onCreate : null,
          isLoading: isLoading,
          variant: ButtonVariant.gradient,
          gradientColors: [AppColors.primary, AppColors.secondary],
          icon: isEditing ? Icons.save_rounded : Icons.favorite_rounded,
        ),
        const SizedBox(height: 12),
        Builder(
          builder: (context) {
            final localization = Provider.of<LocalizationService>(context, listen: false);
            return CustomButton(
              text: localization.translate('common.cancel'),
              onPressed: onCancel,
              variant: ButtonVariant.outline,
            );
          },
        ),
      ],
    );
  }
}

