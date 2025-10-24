import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../services/localization_service.dart';

/// Signup Terms Widget
/// Contains the terms and conditions checkbox
class SignupTermsWidget extends StatelessWidget {
  final bool agreeToTerms;
  final ValueChanged<bool?> onChanged;

  const SignupTermsWidget({
    super.key,
    required this.agreeToTerms,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localization, child) {
        return Row(
          children: [
            Checkbox(
              value: agreeToTerms,
              onChanged: onChanged,
              activeColor: AppColors.primary,
            ),
            Expanded(
              child: Text(
                localization.translate('auth.termsAndConditions'),
                style: AppStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
