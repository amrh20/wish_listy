import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'package:wish_listy/core/theme/app_theme.dart' as theme;

class EmptyMyEvents extends StatelessWidget {
  final LocalizationService localization;

  const EmptyMyEvents({super.key, required this.localization});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use the full available height to center content properly
        final availableHeight = constraints.maxHeight;
        // Keep empty state scrollable so RefreshIndicator works.
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: availableHeight.isFinite && availableHeight > 0 
                ? availableHeight 
                : MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: theme.AppTheme.spacing32,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: AppColors.accentGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.celebration_outlined,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: theme.AppTheme.spacing16),
                    Text(
                      localization.translate('events.noEventsYet'),
                      style: AppStyles.headingMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: theme.AppTheme.spacing12),
                    Text(
                      localization.translate('events.createFirstEventDescription'),
                      style: AppStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: theme.AppTheme.spacing24),
                    CustomButton(
                      text: localization.translate('events.createEvent'),
                      onPressed: () {
                        AppRoutes.pushNamed(context, AppRoutes.createEvent);
                      },
                      customColor: AppColors.accent,
                      icon: Icons.add_rounded,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class EmptyInvitedEvents extends StatelessWidget {
  final LocalizationService localization;

  const EmptyInvitedEvents({super.key, required this.localization});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use the full available height to center content properly
        final availableHeight = constraints.maxHeight;
        // Keep empty state scrollable so RefreshIndicator works.
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: availableHeight.isFinite && availableHeight > 0 
                ? availableHeight 
                : MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: theme.AppTheme.spacing32,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.secondary, AppColors.secondaryLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.mail_outline,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: theme.AppTheme.spacing16),
                    Text(
                      localization.translate('events.noInvitationsYet'),
                      style: AppStyles.headingMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: theme.AppTheme.spacing12),
                    Text(
                      localization.translate('events.noInvitationsDescription'),
                      style: AppStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
