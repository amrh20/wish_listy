import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';

/// Signup Actions Widget
/// Contains the signup button and login link
class SignupActionsWidget extends StatelessWidget {
  final bool isLoading;
  final bool isFormValid;
  final VoidCallback onSignupPressed;

  const SignupActionsWidget({
    super.key,
    required this.isLoading,
    required this.isFormValid,
    required this.onSignupPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localization, child) {
        return Column(
          children: [
            // Signup Button
            CustomButton(
              text: isLoading
                  ? localization.translate('auth.creatingAccount')
                  : localization.translate('auth.signup'),
              onPressed: (isLoading || !isFormValid) ? null : onSignupPressed,
              variant: ButtonVariant.primary,
            ),

            const SizedBox(height: 24),

            // Login Link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  localization.translate('auth.alreadyHaveAccount'),
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacementNamed(context, AppRoutes.login);
                  },
                  child: Text(
                    localization.translate('auth.login'),
                    style: AppStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
