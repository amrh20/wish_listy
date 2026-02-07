import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';

class GuestLoginPromptDialog extends StatelessWidget {
  const GuestLoginPromptDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.lock_open_rounded,
                color: AppColors.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Save & Share your Wishlist! 🎁',
              style: AppStyles.headingSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'To share this list with your friends and keep it forever, you need to create an account. It takes seconds!',
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Sign Up / Login',
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.login);
                },
                variant: ButtonVariant.primary,
                icon: Icons.login_rounded,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: 'Cancel',
                onPressed: () => Navigator.pop(context),
                variant: ButtonVariant.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

