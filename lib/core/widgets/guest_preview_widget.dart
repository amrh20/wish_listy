import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';

/// Widget that shows a preview of restricted content with a CTA to sign up
class GuestPreviewWidget extends StatelessWidget {
  final String title;
  final String description;
  final Widget? previewContent;
  final String? ctaText;
  final VoidCallback? onSignUp;

  const GuestPreviewWidget({
    super.key,
    required this.title,
    required this.description,
    this.previewContent,
    this.ctaText,
    this.onSignUp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Lock icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_outline,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            title,
            style: AppStyles.headingMediumWithContext(context).copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            description,
            style: AppStyles.bodyMediumWithContext(context).copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          // Preview content if provided
          if (previewContent != null) ...[
            const SizedBox(height: 20),
            Opacity(
              opacity: 0.5,
              child: previewContent!,
            ),
          ],

          const SizedBox(height: 24),

          // CTA Button
          CustomButton(
            text: ctaText ?? 'Sign Up to Access',
            onPressed: onSignUp ??
                () {
                  Navigator.pushNamed(context, AppRoutes.signup);
                },
            variant: ButtonVariant.gradient,
            gradientColors: [AppColors.primary, AppColors.secondary],
            size: ButtonSize.large,
          ),
        ],
      ),
    );
  }
}

