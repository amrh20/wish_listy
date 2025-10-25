import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';
import 'package:wish_listy/core/widgets/custom_text_field.dart';

/// Signup Form Widget
/// Contains all the input fields and validation for the signup form
class SignupFormWidget extends StatelessWidget {
  final TextEditingController fullNameController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final String? fullNameError;
  final String? usernameError;
  final String? passwordError;
  final String? confirmPasswordError;
  final VoidCallback onPasswordToggle;
  final VoidCallback onConfirmPasswordToggle;

  const SignupFormWidget({
    super.key,
    required this.fullNameController,
    required this.usernameController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    this.fullNameError,
    this.usernameError,
    this.passwordError,
    this.confirmPasswordError,
    required this.onPasswordToggle,
    required this.onConfirmPasswordToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localization, child) {
        return Column(
          children: [
            // Full Name Field
            CustomTextField(
              controller: fullNameController,
              label: localization.translate('auth.fullName'),
              hint: localization.translate('auth.enterFullName'),
              prefixIcon: Icons.person_outlined,
              isRequired: true,
              validator: (value) {
                final authRepository = AuthRepository();
                final validationError = authRepository.validateFullName(
                  value ?? '',
                );
                if (validationError != null) {
                  return validationError;
                }
                return null;
              },
            ),

            // Full Name Error Message
            if (fullNameError != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.error, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      fullNameError!,
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),

            // Username Field (Email or Phone)
            CustomTextField(
              controller: usernameController,
              label: 'Email or Phone',
              hint: 'Enter your email or phone number',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.person_outlined,
              isRequired: true,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Email or phone number is required';
                }
                final authRepository = AuthRepository();
                final validationError = authRepository.validateUsername(value!);
                if (validationError != null) {
                  return validationError;
                }
                return null;
              },
            ),

            // Username Error Message
            if (usernameError != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.error, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      usernameError!,
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),

            // Password Field
            CustomTextField(
              controller: passwordController,
              label: localization.translate('auth.password'),
              hint: localization.translate('auth.createPassword'),
              obscureText: obscurePassword,
              prefixIcon: Icons.lock_outlined,
              isRequired: true,
              suffixIcon: IconButton(
                onPressed: onPasswordToggle,
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter a password';
                }
                final authRepository = AuthRepository();
                final validationError = authRepository.validatePassword(value!);
                if (validationError != null) {
                  return validationError;
                }
                return null;
              },
            ),

            // Password Error Message
            if (passwordError != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.error, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      passwordError!,
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),

            // Confirm Password Field
            CustomTextField(
              controller: confirmPasswordController,
              label: localization.translate('auth.confirmPassword'),
              hint: localization.translate('auth.confirmPasswordHint'),
              obscureText: obscureConfirmPassword,
              prefixIcon: Icons.lock_outlined,
              isRequired: true,
              suffixIcon: IconButton(
                onPressed: onConfirmPasswordToggle,
                icon: Icon(
                  obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return localization.translate('auth.pleaseConfirmPassword');
                }
                if (value != passwordController.text) {
                  return localization.translate('auth.passwordsDoNotMatch');
                }
                return null;
              },
            ),

            // Confirm Password Error Message
            if (confirmPasswordError != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.error, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      confirmPasswordError!,
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 32),
          ],
        );
      },
    );
  }
}
