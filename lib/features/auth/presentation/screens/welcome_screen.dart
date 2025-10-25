import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'package:wish_listy/core/widgets/language_switcher.dart';
import 'package:wish_listy/core/widgets/app_logo.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localization, child) {
        return Scaffold(
          body: Stack(
            children: [
              // White Background with Gift Decorations
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.white,
                child: Stack(
                  children: [
                    // Gift Box Decorations
                    _buildGiftDecorations(),
                  ],
                ),
              ),

              // Main Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      // Header with Language Switcher
                      _buildHeader(localization),

                      // Main Content Area
                      Expanded(
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Logo Section
                                _buildLogoSection(localization),

                                const SizedBox(height: 60),

                                // Features Preview
                                _buildFeaturesPreview(localization),

                                const SizedBox(height: 60),

                                // Action Buttons
                                _buildActionButtons(localization),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(LocalizationService localization) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Welcome Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, AppColors.primary.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.08),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.waving_hand, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  localization.translate('welcome.title'),
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Language Switcher
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withOpacity(0.05),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: const LanguageSwitcher(),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoSection(LocalizationService localization) {
    return Column(
      children: [
        // App Logo with Glow Effect
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.primary.withOpacity(0.1),
                AppColors.primary.withOpacity(0.05),
                Colors.transparent,
              ],
              stops: const [0.3, 0.7, 1.0],
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.15),
                  offset: const Offset(0, 8),
                  blurRadius: 24,
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
            child: const AppLogo(size: 80, showText: false),
          ),
        ),

        const SizedBox(height: 24),

        // App Name
        Text(
          localization.translate('app.name'),
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -1.2,
            height: 1.1,
          ),
        ),

        const SizedBox(height: 12),

        // Subtitle
        Text(
          localization.translate('welcome.subtitle'),
          style: AppStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeaturesPreview(LocalizationService localization) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildFeatureItem(
          icon: Icons.favorite_outline,
          title: localization.translate('features.createWishlists'),
          color: AppColors.primary,
        ),
        _buildFeatureItem(
          icon: Icons.people_outline,
          title: localization.translate('features.shareWithFriends'),
          color: AppColors.secondary,
        ),
        _buildFeatureItem(
          icon: Icons.celebration_outlined,
          title: localization.translate('features.organizeEvents'),
          color: AppColors.accent,
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3), width: 1),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(LocalizationService localization) {
    return Column(
      children: [
        // Get Started Button (Guest Mode)
        CustomButton(
          text: localization.translate('welcome.getStarted'),
          onPressed: () async {
            // Set user as guest
            final authService = Provider.of<AuthRepository>(
              context,
              listen: false,
            );
            await authService.loginAsGuest();

            // Navigate to guest user scenario
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.mainNavigation,
              (route) => false,
            );
          },
          variant: ButtonVariant.gradient,
          gradientColors: [AppColors.primary, AppColors.secondary],
          icon: Icons.rocket_launch_rounded,
        ),

        const SizedBox(height: 16),

        // Login Button
        CustomButton(
          text: localization.translate('welcome.alreadyHaveAccount'),
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.login);
          },
          variant: ButtonVariant.outline,
          icon: Icons.login_rounded,
        ),
      ],
    );
  }

  Widget _buildGiftDecorations() {
    return Stack(
      children: [
        // Floating Gift Box 1 - Top Right
        AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Positioned(
              top: 80 + (_fadeAnimation.value * 10),
              right: 30,
              child: Transform.rotate(
                angle: 0.1,
                child: _buildGiftBox(
                  size: 60,
                  color: AppColors.primary.withOpacity(0.1),
                  ribbonColor: AppColors.primary.withOpacity(0.3),
                ),
              ),
            );
          },
        ),

        // Floating Gift Box 2 - Left Side
        AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Positioned(
              top: 200 - (_fadeAnimation.value * 8),
              left: 20,
              child: Transform.rotate(
                angle: -0.15,
                child: _buildGiftBox(
                  size: 45,
                  color: AppColors.accent.withOpacity(0.08),
                  ribbonColor: AppColors.accent.withOpacity(0.25),
                ),
              ),
            );
          },
        ),

        // Floating Gift Box 3 - Bottom Right
        AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return Positioned(
              bottom: 150 + (_slideAnimation.value.dy * 20),
              right: 50,
              child: Transform.rotate(
                angle: 0.2,
                child: _buildGiftBox(
                  size: 55,
                  color: AppColors.secondary.withOpacity(0.1),
                  ribbonColor: AppColors.secondary.withOpacity(0.3),
                ),
              ),
            );
          },
        ),

        // Small Gift Box 4 - Bottom Left
        AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Positioned(
              bottom: 300 + (_fadeAnimation.value * 5),
              left: 40,
              child: Transform.rotate(
                angle: -0.1,
                child: _buildGiftBox(
                  size: 35,
                  color: AppColors.success.withOpacity(0.08),
                  ribbonColor: AppColors.success.withOpacity(0.25),
                ),
              ),
            );
          },
        ),

        // Gift Box 5 - Middle Right
        AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return Positioned(
              top: 350 - (_slideAnimation.value.dy * 15),
              right: 20,
              child: Transform.rotate(
                angle: 0.05,
                child: _buildGiftBox(
                  size: 40,
                  color: AppColors.warning.withOpacity(0.08),
                  ribbonColor: AppColors.warning.withOpacity(0.25),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildGiftBox({
    required double size,
    required Color color,
    required Color ribbonColor,
  }) {
    return CustomPaint(
      painter: GiftBoxPainter(color: color, ribbonColor: ribbonColor),
      size: Size(size, size),
    );
  }
}

class GiftBoxPainter extends CustomPainter {
  final Color color;
  final Color ribbonColor;

  GiftBoxPainter({required this.color, required this.ribbonColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = ribbonColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final ribbonFillPaint = Paint()
      ..color = ribbonColor.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    // Gift box body
    final rect = Rect.fromLTWH(
      size.width * 0.2,
      size.height * 0.3,
      size.width * 0.6,
      size.height * 0.5,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      strokePaint,
    );

    // Gift box lid
    final lidRect = Rect.fromLTWH(
      size.width * 0.15,
      size.height * 0.25,
      size.width * 0.7,
      size.height * 0.15,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(lidRect, const Radius.circular(6)),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(lidRect, const Radius.circular(6)),
      strokePaint,
    );

    // Ribbon vertical
    final ribbonV = Rect.fromLTWH(
      size.width * 0.45,
      size.height * 0.25,
      size.width * 0.1,
      size.height * 0.55,
    );
    canvas.drawRect(ribbonV, ribbonFillPaint);

    // Ribbon horizontal
    final ribbonH = Rect.fromLTWH(
      size.width * 0.15,
      size.height * 0.45,
      size.width * 0.7,
      size.height * 0.1,
    );
    canvas.drawRect(ribbonH, ribbonFillPaint);

    // Bow - Enhanced version
    final bowPaint = Paint()
      ..color = ribbonColor
      ..style = PaintingStyle.fill;

    // Left bow part
    final leftBowPath = Path();
    leftBowPath.moveTo(size.width * 0.35, size.height * 0.15);
    leftBowPath.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.05,
      size.width * 0.4,
      size.height * 0.1,
    );
    leftBowPath.quadraticBezierTo(
      size.width * 0.45,
      size.height * 0.18,
      size.width * 0.35,
      size.height * 0.15,
    );
    canvas.drawPath(leftBowPath, bowPaint);

    // Right bow part
    final rightBowPath = Path();
    rightBowPath.moveTo(size.width * 0.65, size.height * 0.15);
    rightBowPath.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.05,
      size.width * 0.6,
      size.height * 0.1,
    );
    rightBowPath.quadraticBezierTo(
      size.width * 0.55,
      size.height * 0.18,
      size.width * 0.65,
      size.height * 0.15,
    );
    canvas.drawPath(rightBowPath, bowPaint);

    // Center knot
    final knotRect = Rect.fromLTWH(
      size.width * 0.47,
      size.height * 0.12,
      size.width * 0.06,
      size.height * 0.08,
    );
    canvas.drawOval(knotRect, bowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
