import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../services/localization_service.dart';
import '../../utils/app_routes.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/language_switcher.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localization, child) {
        if (!mounted) return const SizedBox.shrink();
        
        // Debug: Print current language and check translations
        debugPrint('Welcome Screen - Current Language: ${localization.currentLanguage}');
        debugPrint('Welcome Screen - Is Loading: ${localization.isLoading}');
        debugPrint('Welcome Screen - App Name: ${localization.translate('app.name')}');
        debugPrint('Welcome Screen - Welcome Title: ${localization.translate('welcome.title')}');
        
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Header with Language Switcher
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 40), // Placeholder for balance
                      Text(
                        localization.translate('welcome.title'),
                        style: AppStyles.headingMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Temporary simple button instead of LanguageSwitcher
                      LanguageSwitcher(),
                    ],
                  ),
                  
                  const SizedBox(height: 60),
                  
                  // Logo and App Name
                  Column(
                    children: [
                      // Simple icon instead of AnimatedLogo
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.card_giftcard,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        localization.translate('app.name'),
                        style: AppStyles.headingLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        localization.translate('welcome.subtitle'),
                        style: AppStyles.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 80),
                  
                  // Action Buttons
                  Column(
                    children: [
                      CustomButton(
                        text: localization.translate('welcome.getStarted'),
                        onPressed: () {
                          // Navigate directly to main app (home screen with tabs)
                          Navigator.pushNamedAndRemoveUntil(
                            context, 
                            AppRoutes.mainNavigation, 
                            (route) => false
                          );
                        },
                        variant: ButtonVariant.primary,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      CustomButton(
                        text: localization.translate('welcome.alreadyHaveAccount'),
                        onPressed: () {
                          // Navigate to login screen
                          Navigator.pushNamed(context, AppRoutes.login);
                        },
                        variant: ButtonVariant.outline,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}