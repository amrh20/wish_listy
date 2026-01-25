import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/widgets/primary_gradient_button.dart';

/// Simple error view for wishlist items screen with retry.
class WishlistItemsErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final LocalizationService localization;

  const WishlistItemsErrorWidget({
    super.key,
    required this.message,
    required this.onRetry,
    required this.localization,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                message,
                style: AppStyles.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              PrimaryGradientButton(
                text: localization.translate('common.retry'),
                icon: Icons.refresh,
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
