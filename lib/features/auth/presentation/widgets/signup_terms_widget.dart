import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: agreeToTerms,
              onChanged: onChanged,
              activeColor: AppColors.primary,
              checkColor: Colors.white,
              fillColor: WidgetStateProperty.resolveWith<Color>(
                (Set<WidgetState> states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.primary;
                  }
                  return Colors.transparent;
                },
              ),
              side: BorderSide(
                color: agreeToTerms
                    ? AppColors.primary
                    : AppColors.border,
                width: 2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(!agreeToTerms),
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    localization.translate('auth.termsAndConditions'),
                    style: AppStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
