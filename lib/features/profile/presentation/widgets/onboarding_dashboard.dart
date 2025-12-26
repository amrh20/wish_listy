import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/features/profile/presentation/screens/main_navigation.dart';

/// Onboarding dashboard for new users (empty state)
class OnboardingDashboard extends StatefulWidget {
  const OnboardingDashboard({super.key});

  @override
  State<OnboardingDashboard> createState() => _OnboardingDashboardState();
}

class _OnboardingDashboardState extends State<OnboardingDashboard>
    with TickerProviderStateMixin {
  // Page entrance animations
  late AnimationController _controller;
  late Animation<Offset> _iconSlideAnimation;
  late Animation<double> _iconScaleAnimation;
  late Animation<Offset> _cardsSlideAnimation;
  late Animation<double> _cardsFadeAnimation;

  // Continuous floating animation for gift icon
  late AnimationController _floatingController;
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();

    // Page entrance animations
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _iconSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    _iconScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _cardsSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _cardsFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
      ),
    );

    // Continuous floating animation
    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    _floatingAnimation = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(
        parent: _floatingController,
        curve: Curves.easeInOut,
      ),
    );

    // Start entrance animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Floating Gift Animation - Centered
          SlideTransition(
            position: _iconSlideAnimation,
            child: ScaleTransition(
              scale: _iconScaleAnimation,
              child: const FloatingGiftAnimation(),
            ),
          ),
          const SizedBox(height: 60), // Spacing between icon and cards
          // Action Cards - Slide up + fade in
          SlideTransition(
            position: _cardsSlideAnimation,
            child: FadeTransition(
              opacity: _cardsFadeAnimation,
              child: Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.person_add_rounded,
                      title: 'Add Friends',
                      subtitle: 'See their wishes',
                      iconBackgroundColor: const Color(0xFFB2DFDB), // Green/teal
                      iconColor: const Color(0xFF00796B),
                      onTap: () {
                        // Navigate to Add Friend screen
                        Navigator.pushNamed(
                          context,
                          AppRoutes.addFriend,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 24), // Spacing between cards
                  Expanded(
                    child: _ActionCard(
                      icon: Icons.add_circle_outline_rounded,
                      title: 'Make a Wish',
                      subtitle: 'Add items you love',
                      iconBackgroundColor: AppColors.primary, // Primary color
                      iconColor: Colors.white, // White icon
                      onTap: () {
                        // Navigate to Create Wishlist
                        Navigator.pushNamed(
                          context,
                          AppRoutes.createWishlist,
                          arguments: {
                            'previousRoute': AppRoutes.mainNavigation,
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40), // Bottom padding
        ],
      ),
    );
  }
}


class _ActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconBackgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconBackgroundColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _scaleController.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(24), // Increased internal padding
          decoration: BoxDecoration(
            color: Colors.white, // Pure white background
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: widget.iconBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.iconColor,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                style: AppStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600, // Semi-bold (600)
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                style: AppStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary.withOpacity(0.7), // 0.7 opacity
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Floating Gift Animation Widget ---
class FloatingGiftAnimation extends StatefulWidget {
  const FloatingGiftAnimation({super.key});

  @override
  State<FloatingGiftAnimation> createState() => _FloatingGiftAnimationState();
}

class _FloatingGiftAnimationState extends State<FloatingGiftAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _positionAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2, milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);

    _positionAnimation = Tween<double>(begin: 0, end: -15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // The Floating Icon
                  Transform.translate(
                    offset: Offset(0, _positionAnimation.value),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback to icon if logo not found
                        return Icon(
                          Icons.card_giftcard_rounded,
                          size: 120,
                          color: AppColors.primary,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  // The Breathing Shadow
                  Opacity(
                    opacity: 0.2 + (0.1 * _controller.value), // Fade slightly
                    child: Transform.scale(
                      scale: 1.0 - (0.2 * _controller.value), // Shrink when gift goes up
                      child: Container(
                        width: 60,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.2),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

