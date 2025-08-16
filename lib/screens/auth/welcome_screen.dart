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

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatingController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _floatingAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    // Floating animation for decorative elements
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _floatingAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    // Pulse animation for the main icon
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Rotation animation for decorative elements
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_rotationController);
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Consumer<LocalizationService>(
      builder: (context, localization, child) {
        if (!mounted) return const SizedBox.shrink();

        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFF8FAFF),
                  const Color(0xFFF3F0FF),
                  AppColors.primary.withOpacity(0.05),
                  AppColors.secondary.withOpacity(0.03),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Animated background decorations
                _buildBackgroundDecorations(size),

                // Main content
                SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight:
                            MediaQuery.of(context).size.height -
                            MediaQuery.of(context).padding.top -
                            MediaQuery.of(context).padding.bottom,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            const SizedBox(height: 20),

                            // Enhanced Header
                            _buildEnhancedHeader(localization),

                            const SizedBox(height: 40),

                            // Enhanced Hero Section
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Enhanced Logo and App Name
                                  Column(
                                    children: [
                                      // Enhanced icon with gradient, shadow and animation
                                      TweenAnimationBuilder<double>(
                                        duration: const Duration(
                                          milliseconds: 1000,
                                        ),
                                        tween: Tween(begin: 0.0, end: 1.0),
                                        builder: (context, value, child) {
                                          return Transform.scale(
                                            scale: value,
                                            child: Container(
                                              width: 140,
                                              height: 140,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    AppColors.primary,
                                                    AppColors.primaryAccent,
                                                    AppColors.secondary,
                                                  ],
                                                  stops: [0.0, 0.5, 1.0],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(28),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppColors.primary
                                                        .withOpacity(0.3),
                                                    offset: const Offset(0, 12),
                                                    blurRadius: 30,
                                                    spreadRadius: 2,
                                                  ),
                                                  BoxShadow(
                                                    color: AppColors.secondary
                                                        .withOpacity(0.2),
                                                    offset: const Offset(0, 6),
                                                    blurRadius: 20,
                                                    spreadRadius: 1,
                                                  ),
                                                ],
                                              ),
                                              child: Center(
                                                child: Container(
                                                  width: 80,
                                                  height: 80,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                    border: Border.all(
                                                      color: Colors.white
                                                          .withOpacity(0.3),
                                                      width: 2,
                                                    ),
                                                  ),
                                                  child: Icon(
                                                    Icons.card_giftcard,
                                                    size: 48,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),

                                      const SizedBox(height: 32),

                                      // Enhanced App Name with shadow and animation
                                      TweenAnimationBuilder<double>(
                                        duration: const Duration(
                                          milliseconds: 800,
                                        ),
                                        tween: Tween(begin: 0.0, end: 1.0),
                                        builder: (context, value, child) {
                                          return Transform.scale(
                                            scale: value,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 24,
                                                    vertical: 12,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppColors.shadow
                                                        .withOpacity(0.1),
                                                    offset: const Offset(0, 6),
                                                    blurRadius: 20,
                                                    spreadRadius: 0,
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                localization.translate(
                                                  'app.name',
                                                ),
                                                style: AppStyles.headingLarge
                                                    .copyWith(
                                                      color: AppColors.primary,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 32,
                                                    ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),

                                      const SizedBox(height: 16),

                                      // Enhanced subtitle with better styling and animation
                                      TweenAnimationBuilder<double>(
                                        duration: const Duration(
                                          milliseconds: 1000,
                                        ),
                                        tween: Tween(begin: 0.0, end: 1.0),
                                        builder: (context, value, child) {
                                          return Opacity(
                                            opacity: value,
                                            child: Transform.translate(
                                              offset: Offset(
                                                0,
                                                20 * (1 - value),
                                              ),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                      vertical: 16,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppColors
                                                      .surfaceVariant
                                                      .withOpacity(0.5),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  border: Border.all(
                                                    color: AppColors.border
                                                        .withOpacity(0.3),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Text(
                                                  localization.translate(
                                                    'welcome.subtitle',
                                                  ),
                                                  style: AppStyles.bodyLarge
                                                      .copyWith(
                                                        color: AppColors
                                                            .textSecondary,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        height: 1.4,
                                                      ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),

                                      const SizedBox(height: 40),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Enhanced Action Buttons
                            _buildEnhancedButtons(localization),

                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
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

  Widget _buildBackgroundDecorations(Size size) {
    return Stack(
      children: [
        // Floating circles
        AnimatedBuilder(
          animation: _floatingAnimation,
          builder: (context, child) {
            return Positioned(
              top: 100 + _floatingAnimation.value,
              right: 30,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.secondary.withOpacity(0.05),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        AnimatedBuilder(
          animation: _floatingAnimation,
          builder: (context, child) {
            return Positioned(
              top: 200 - _floatingAnimation.value,
              left: 20,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent.withOpacity(0.1),
                      AppColors.primary.withOpacity(0.05),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // Rotating decorative element
        AnimatedBuilder(
          animation: _rotationAnimation,
          builder: (context, child) {
            return Positioned(
              bottom: 150,
              right: 50,
              child: Transform.rotate(
                angle: _rotationAnimation.value * 2 * 3.14159,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.success.withOpacity(0.1),
                        AppColors.info.withOpacity(0.05),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // Additional floating shapes
        AnimatedBuilder(
          animation: _floatingAnimation,
          builder: (context, child) {
            return Positioned(
              bottom: 300 + _floatingAnimation.value * 0.5,
              left: 40,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.warning.withOpacity(0.1),
                  border: Border.all(
                    color: AppColors.warning.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEnhancedHeader(LocalizationService localization) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Welcome badge with enhanced design
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 600),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, AppColors.primary.withOpacity(0.05)],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.15),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.1),
                      offset: const Offset(0, 8),
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.8),
                      offset: const Offset(0, 1),
                      blurRadius: 0,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.waving_hand, size: 18, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      localization.translate('welcome.title'),
                      style: AppStyles.headingSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // Enhanced Language Switcher
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 800),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: AppColors.border.withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow.withOpacity(0.08),
                      offset: const Offset(0, 8),
                      blurRadius: 24,
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.9),
                      offset: const Offset(0, 1),
                      blurRadius: 0,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: LanguageSwitcher(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeroSection(LocalizationService localization) {
    return Column(
      children: [
        // Main Title with Enhanced Typography
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 800),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 50 * (1 - value)),
                child: Column(
                  children: [
                    // App Name with Creative Typography
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary,
                          AppColors.primaryAccent,
                          AppColors.secondary,
                          AppColors.accent,
                        ],
                      ).createShader(bounds),
                      child: Text(
                        localization.translate('app.name'),
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -1.5,
                          height: 1.2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Tagline with elegant design
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        "Connect through thoughtful gifting",
                        style: AppStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEnhancedButtons(LocalizationService localization) {
    return Column(
      children: [
        // Get Started Button
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 1200),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primaryAccent,
                      AppColors.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      offset: const Offset(0, 12),
                      blurRadius: 30,
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      offset: const Offset(0, 6),
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(25),
                    onTap: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.mainNavigation,
                        (route) => false,
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.rocket_launch_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              localization.translate('welcome.getStarted'),
                              style: AppStyles.headingSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        // Already Have Account Button
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 1400),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow.withOpacity(0.08),
                      offset: const Offset(0, 8),
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.9),
                      offset: const Offset(0, 1),
                      blurRadius: 0,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(25),
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.login);
                    },
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.login_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            localization.translate(
                              'welcome.alreadyHaveAccount',
                            ),
                            style: AppStyles.headingSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
