import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';

/// Signup Success Dialog Widget
/// Shows success message after successful registration
class SignupSuccessDialog extends StatelessWidget {
  final Map<String, dynamic> response;
  final String userName;
  final String userEmail;

  const SignupSuccessDialog({
    super.key,
    required this.response,
    required this.userName,
    required this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localization, child) {
        // Extract user data from response
        final userData = response['user'] ?? response['data'];
        final userName = userData?['fullName'] ?? this.userName;
        final userUsername = userData?['username'] ?? this.userEmail;
        final isEmailVerified = userData?['emailVerified'] ?? false;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: AppColors.success,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),

              // Success message
              Text(
                localization.translate('auth.accountCreated'),
                style: AppStyles.headingMedium,
                textAlign: TextAlign.center,
              ),

              // User welcome message
              const SizedBox(height: 8),
              Text(
                'Welcome, $userName!',
                style: AppStyles.bodyLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),
              Text(
                userUsername,
                style: AppStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Email verification status
              if (!isEmailVerified) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.warning.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.email_outlined,
                        color: AppColors.warning,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          localization.translate('auth.verifyEmail'),
                          style: AppStyles.bodySmall.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Continue button
              CustomButton(
                text: localization.translate('auth.continue'),
                onPressed: () {
                  Navigator.of(context).pop();
                  AppRoutes.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.mainNavigation,
                  );
                },
                variant: ButtonVariant.primary,
              ),
            ],
          ),
        );
      },
    );
  }
}
