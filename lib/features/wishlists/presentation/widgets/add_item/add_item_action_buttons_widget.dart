import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';

/// Action buttons widget for add item screen
class AddItemActionButtonsWidget extends StatelessWidget {
  final bool isEditing;
  final bool isNameEmpty;
  final bool isLoading;
  final VoidCallback onSave;
  final String Function() getButtonText;

  const AddItemActionButtonsWidget({
    super.key,
    required this.isEditing,
    required this.isNameEmpty,
    required this.isLoading,
    required this.onSave,
    required this.getButtonText,
  });

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: getButtonText(),
      onPressed: isNameEmpty || isLoading ? null : onSave,
      isLoading: isLoading,
      variant: ButtonVariant.gradient,
      gradientColors: [AppColors.primary, AppColors.secondary],
    );
  }
}
