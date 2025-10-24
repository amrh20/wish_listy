import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_colors.dart';
import '../../../services/localization_service.dart';
import '../../custom_button.dart';

/// Widget for create event actions (Create and Save Draft buttons)
class CreateEventActionsWidget extends StatelessWidget {
  final VoidCallback onCreatePressed;
  final VoidCallback onSaveDraftPressed;
  final bool isLoading;
  final Color primaryColor;

  const CreateEventActionsWidget({
    super.key,
    required this.onCreatePressed,
    required this.onSaveDraftPressed,
    required this.isLoading,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context);

    return Column(
      children: [
        // Create Button
        CustomButton(
          text: localization.translate('events.createEvent'),
          onPressed: onCreatePressed,
          isLoading: isLoading,
          variant: ButtonVariant.gradient,
          gradientColors: [primaryColor, AppColors.accent],
        ),

        const SizedBox(height: 16),

        // Save Draft Button
        CustomButton(
          text: localization.translate('events.saveAsDraft'),
          onPressed: onSaveDraftPressed,
          variant: ButtonVariant.outline,
          customColor: primaryColor,
        ),

        const SizedBox(height: 100), // Bottom padding
      ],
    );
  }
}
