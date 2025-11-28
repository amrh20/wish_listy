import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/widgets/app_logo.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    _startSplashSequence();
  }

  void _startSplashSequence() async {
    if (kDebugMode) {
      debugPrint('Splash screen: Starting sequence...');
    }

    // Wait for splash to complete (minimum 2 seconds for smooth UX)
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Get auth repository to check authentication state
    final authRepository = Provider.of<AuthRepository>(
      context,
      listen: false,
    );

    // Wait for auth initialization if still loading
    if (authRepository.isLoading) {
      // Wait a bit more for initialization to complete
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (!mounted) return;

    // Check authentication state and navigate accordingly
    if (authRepository.isAuthenticated) {
      // User is logged in, navigate to main navigation (home screen)
      if (kDebugMode) {
        debugPrint('Splash screen: User is authenticated, navigating to main navigation...');
      }
      Navigator.pushReplacementNamed(context, AppRoutes.mainNavigation);
    } else {
      // User is not logged in (guest), navigate to welcome screen
      if (kDebugMode) {
        debugPrint('Splash screen: User is guest, navigating to welcome screen...');
      }
      Navigator.pushReplacementNamed(context, AppRoutes.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localization, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo
                const AppLogo(size: 120, showText: false),

                const SizedBox(height: 40),

                // App Title
                Text(
                  localization.translate('app.splashTitle'),
                  style: AppStyles.headingLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                // App Subtitle
                Text(
                  localization.translate('app.splashSubtitle'),
                  style: AppStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 60),

                // Loading Indicator
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
