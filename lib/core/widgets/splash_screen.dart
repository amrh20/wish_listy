import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/services/deep_link_service.dart';
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
    with SingleTickerProviderStateMixin {
  late AnimationController _exitController;
  late Animation<double> _exitOpacity;

  Widget? _targetScreen;
  bool _exitComplete = false;

  @override
  void initState() {
    super.initState();

    _exitController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInOut),
    );

    _startSplashSequence();
  }

  @override
  void dispose() {
    _exitController.dispose();
    super.dispose();
  }

  void _startSplashSequence() async {
    final targetScreen = await _resolveTargetScreen();

    if (!mounted) return;
    if (targetScreen == null) return;

    setState(() => _targetScreen = targetScreen);

    final isCurrent = ModalRoute.of(context)?.isCurrent ?? false;
    if (!isCurrent) return;

    _exitController.forward().then((_) {
      if (!mounted || _exitComplete) return;
      _exitComplete = true;
      _doNavigate();
    });
  }

  void _doNavigate() {
    if (!mounted || _targetScreen == null) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => _targetScreen!,
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          );
          return FadeTransition(opacity: curved, child: child);
        },
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinkService().navigatePendingIfAny();
    });
  }

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

    final guestDataRepo =
        Provider.of<GuestDataRepository>(context, listen: false);
    final hasGuestData = await guestDataRepo.hasGuestData();

    if (!mounted) return null;

    return hasGuestData ? const MainNavigation() : const OnboardingScreen();
  }

  Widget _buildSplashContent() {
    return Container(
      color: AppColors.primary,
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.textWhite,
          strokeWidth: 3,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _exitController,
        builder: (context, _) {
          return Opacity(
            opacity: _exitOpacity.value,
            child: _buildSplashContent(),
          );
        },
      ),
    );
  }
}
