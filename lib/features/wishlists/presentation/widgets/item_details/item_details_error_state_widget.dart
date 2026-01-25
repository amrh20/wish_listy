import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';

/// Error state view for item details screen with retry.
class ItemDetailsErrorStateWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ItemDetailsErrorStateWidget({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: AppStyles.headingMedium.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Retry',
              onPressed: onRetry,
              variant: ButtonVariant.primary,
            ),
          ],
        ),
      ),
    );
  }
}
