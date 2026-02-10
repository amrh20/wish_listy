import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';

/// Widget for create/update event actions button
class CreateEventActionsWidget extends StatelessWidget {
  final VoidCallback onCreatePressed;
  final bool isLoading;
  final bool isEnabled;
  final Color primaryColor;
  final String? buttonText; // Optional custom button text

  const CreateEventActionsWidget({
    super.key,
    required this.onCreatePressed,
    required this.isLoading,
    this.isEnabled = true,
    required this.primaryColor,
    this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context);

    // Use custom text if provided, otherwise use default based on context
    final String displayText = buttonText ??
        localization.translate('events.createEvent');

    return Column(
      children: [
        // Create/Update Button
        CustomButton(
          text: displayText,
          onPressed: (isEnabled && !isLoading) ? onCreatePressed : null,
          isLoading: isLoading,
          variant: ButtonVariant.gradient,
          gradientColors: [primaryColor, AppColors.accent],
        ),

        const SizedBox(height: 100), // Bottom padding
      ],
    );
  }
}
