import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/services/deep_link_service.dart';
import 'package:wish_listy/core/widgets/app_logo.dart';
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';
import 'package:wish_listy/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:wish_listy/features/profile/presentation/screens/main_navigation.dart';
import 'package:wish_listy/features/wishlists/data/repository/guest_data_repository.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _breathingAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    _startSplashSequence();
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  void _startSplashSequence() async {
    if (kDebugMode) {

    }

    // Wait 3 seconds for splash animation
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Get auth repository to check authentication state
    final authRepository = Provider.of<AuthRepository>(context, listen: false);

    // Wait for auth initialization if still loading
    if (authRepository.isLoading) {
      // Wait a bit more for initialization to complete
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (!mounted) return;

    // Navigate with fade transition
    final isAuthenticated = authRepository.isAuthenticated;

    if (kDebugMode) {

    }

    // Determine which screen to show
    Widget targetScreen;

    if (isAuthenticated) {
      // Authenticated users always go to MainNavigation
      targetScreen = const MainNavigation();
    } else {
      // For guest users, check if they have existing wishlists
      final guestDataRepo = Provider.of<GuestDataRepository>(
        context,
        listen: false,
      );
      final hasGuestData = await guestDataRepo.hasGuestData();

      if (kDebugMode) {

      }

      if (!mounted) return;

      // If guest has wishlists, skip onboarding and go directly to MainNavigation
      // Otherwise, show onboarding screen
      targetScreen = hasGuestData
          ? const MainNavigation()
          : const OnboardingScreen();
    }

    // If a deep link already pushed a screen on top of SplashScreen,
    // don't override it by navigating to Home/MainNavigation.
    final isCurrent = ModalRoute.of(context)?.isCurrent ?? false;
    if (!isCurrent) {
      debugPrint(
        '🟡 SplashScreen: Not current route anymore, skipping auto navigation (likely deep link).',
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return targetScreen;
        },
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );

    // If the app was opened via a deep link (cold start), navigate to it now.
    // This MUST happen after SplashScreen pushes the target screen, otherwise
    // SplashScreen's pushReplacement would override the deep link navigation.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinkService().navigatePendingIfAny();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, AppColors.primary.withOpacity(0.1)],
          ),
        ),
        child: Center(
          child: ScaleTransition(
            scale: _breathingAnimation,
            child: const AppLogo(size: 120, showText: false),
          ),
        ),
      ),
    );
  }
}
