import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';

class EmptyMyEvents extends StatelessWidget {
  final LocalizationService localization;

  const EmptyMyEvents({super.key, required this.localization});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.celebration_outlined,
              size: 60,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            localization.translate('events.noEvents'),
            style: AppStyles.headingMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            localization.translate('events.createEvent'),
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          CustomButton(
            text: localization.translate('events.createEvent'),
            onPressed: () {
              AppRoutes.pushNamed(context, AppRoutes.createEvent);
            },
            variant: ButtonVariant.primary,
            customColor: AppColors.accent,
          ),
        ],
      ),
    );
  }
}

class EmptyInvitedEvents extends StatelessWidget {
  final LocalizationService localization;

  const EmptyInvitedEvents({super.key, required this.localization});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.mail_outline,
              size: 60,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            localization.translate('events.noInvitations'),
            style: AppStyles.headingMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            localization.translate('events.invited'),
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
