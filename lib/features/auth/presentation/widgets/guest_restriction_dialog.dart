import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';

class GuestRestrictionDialog extends StatelessWidget {
  final String featureName;
  final String? customMessage;

  const GuestRestrictionDialog({
    super.key,
    required this.featureName,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localization, child) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    color: Colors.white,
                    size: 40,
                  ),
                ),

                const SizedBox(height: 20),

                // Title
                Text(
                  localization.translate('guest.restrictions.title'),
                  style: AppStyles.heading4.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Message
                Text(
                  customMessage ??
                      localization.translate('guest.restrictions.message'),
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: localization.translate('app.cancel'),
                        onPressed: () => Navigator.of(context).pop(),
                        variant: ButtonVariant.outline,
                        size: ButtonSize.small,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: localization.translate(
                          'guest.restrictions.loginButton',
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.pushNamed(context, AppRoutes.login);
                        },
                        variant: ButtonVariant.gradient,
                        size: ButtonSize.small,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void show(
    BuildContext context,
    String featureName, {
    String? customMessage,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => GuestRestrictionDialog(
        featureName: featureName,
        customMessage: customMessage,
      ),
    );
  }
}
