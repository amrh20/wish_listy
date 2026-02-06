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
    // Phase 3: Minimum 1 second splash; run auth/guest check in parallel so we
    // navigate as soon as both the delay and the check are done.
    final minSplashDelay = Future.delayed(const Duration(seconds: 1));
    final targetScreenFuture = _resolveTargetScreen();

    final results = await Future.wait([minSplashDelay, targetScreenFuture]);

    if (!mounted) return;

    final targetScreen = results[1] as Widget?;
    if (targetScreen == null || !mounted) return;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinkService().navigatePendingIfAny();
    });
  }

  /// Resolves the target screen (MainNavigation, OnboardingScreen) based on
  /// auth state and guest data. Returns null if widget is unmounted.
  Future<Widget?> _resolveTargetScreen() async {
    final authRepository = Provider.of<AuthRepository>(context, listen: false);

    if (authRepository.isLoading) {
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (!mounted) return null;

    final isAuthenticated = authRepository.isAuthenticated;

    if (isAuthenticated) {
      return const MainNavigation();
    }

    final guestDataRepo = Provider.of<GuestDataRepository>(
      context,
      listen: false,
    );
    final hasGuestData = await guestDataRepo.hasGuestData();

    if (!mounted) return null;

    return hasGuestData
        ? const MainNavigation()
        : const OnboardingScreen();
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
