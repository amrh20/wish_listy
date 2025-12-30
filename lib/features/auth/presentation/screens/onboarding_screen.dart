import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'package:wish_listy/core/widgets/language_switcher.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late List<AnimationController> _slideControllers;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  List<OnboardingSlide> _buildSlides(LocalizationService localization) {
    return [
      OnboardingSlide(
        title: localization.translate('onboarding.createWishlists.title'),
        description: localization.translate('onboarding.createWishlists.description'),
        icon: Icons.favorite_outline,
        color: AppColors.primary,
        gradientColors: [AppColors.primary, AppColors.primaryLight],
      ),
      OnboardingSlide(
        title: localization.translate('onboarding.shareWithFriends.title'),
        description: localization.translate('onboarding.shareWithFriends.description'),
        icon: Icons.people_outline,
        color: AppColors.secondary,
        gradientColors: [AppColors.secondary, AppColors.secondaryLight],
      ),
      OnboardingSlide(
        title: localization.translate('onboarding.organizeEvents.title'),
        description: localization.translate('onboarding.organizeEvents.description'),
        icon: Icons.celebration_outlined,
        color: AppColors.accent,
        gradientColors: [AppColors.accent, AppColors.accentLight],
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _pageController.addListener(_onPageChanged);
  }

  void _initializeAnimations() {
    _slideControllers = List.generate(
      3,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );

    _fadeAnimations = _slideControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeOut,
        ),
      );
    }).toList();

    _slideAnimations = _slideControllers.map((controller) {
      return Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeOutCubic,
        ),
      );
    }).toList();

    // Start animation for first slide
    _slideControllers[0].forward();
  }

  void _onPageChanged() {
    final newPage = _pageController.page?.round() ?? 0;
    if (newPage != _currentPage) {
      setState(() {
        _currentPage = newPage;
      });
      // Trigger animation for new slide
      _slideControllers[newPage].forward(from: 0.0);
    }
  }

  void _skipToLast() {
    _pageController.animateToPage(
      2,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToNextPage(LocalizationService localization) {
    final slides = _buildSlides(localization);
    if (_currentPage < slides.length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }


  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _slideControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localization, child) {
        return Scaffold(
          body: Stack(
            children: [
              // Background with decorative shapes
              _buildBackground(),

              // Main Content
              SafeArea(
                child: Column(
                  children: [
                    // Header with Skip button and Language Switcher
                    _buildHeader(localization),

                    // PageView for slides
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final slides = _buildSlides(localization);
                          return PageView.builder(
                            controller: _pageController,
                            itemCount: slides.length,
                            itemBuilder: (context, index) {
                              return _buildSlide(slides[index], index);
                            },
                          );
                        },
                      ),
                    ),

                    // Footer with Skip, PageIndicator, and Next button
                    _buildFooter(localization),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackground() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: Stack(
        children: [
              // Decorative shapes based on current slide
          AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              final localization = Provider.of<LocalizationService>(context, listen: false);
              final slides = _buildSlides(localization);
              final slide = slides[_currentPage];
              return CustomPaint(
                painter: DecorativeShapesPainter(
                  color: slide.color.withOpacity(0.08),
                ),
                size: Size.infinite,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(LocalizationService localization) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Welcome Badge (only on first slide)
          if (_currentPage == 0)
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
            )
          else
            const SizedBox.shrink(),

          // Language Switcher only
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textTertiary.withOpacity(0.05),
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

  Widget _buildSlide(OnboardingSlide slide, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with gradient background
          AnimatedBuilder(
            animation: _fadeAnimations[index],
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimations[index],
                child: SlideTransition(
                  position: _slideAnimations[index],
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: slide.gradientColors,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: slide.color.withOpacity(0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      slide.icon,
                      size: 70,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 60),

          // Title
          AnimatedBuilder(
            animation: _fadeAnimations[index],
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimations[index],
                child: SlideTransition(
                  position: _slideAnimations[index],
                  child: Text(
                    slide.title,
                    style: AppStyles.headingLarge.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Description
          AnimatedBuilder(
            animation: _fadeAnimations[index],
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimations[index],
                child: SlideTransition(
                  position: _slideAnimations[index],
                  child: Text(
                    slide.description,
                    style: AppStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(LocalizationService localization) {
    final slides = _buildSlides(localization);
    final isLastPage = _currentPage == slides.length - 1;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 32.0),
      child: Column(
        children: [
          // Footer Row: Skip | PageIndicator | Next/Get Started
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Skip Button (left) - only show if not on last page
              if (!isLastPage)
                TextButton(
                  onPressed: _skipToLast,
                  child: Text(
                    localization.translate('onboarding.skip'),
                    style: AppStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                const SizedBox(width: 56), // Match Next button width for balance

              // Page Indicator (center)
              Expanded(
                child: Builder(
                  builder: (context) {
                    final slides = _buildSlides(localization);
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        slides.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == index ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? slides[index].color
                                : AppColors.textTertiary.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Next Button (right) - circular button with arrow
              if (!isLastPage)
                _buildNextButton(localization, () => _goToNextPage(localization))
              else
                const SizedBox(width: 56), // Match Skip button width for balance
            ],
          ),

          // Action Buttons (only on last slide)
          if (isLastPage) ...[
            const SizedBox(height: 24),
            _buildActionButtons(localization),
          ],
        ],
      ),
    );
  }

  Widget _buildNextButton(LocalizationService localization, VoidCallback onTap) {
    final slides = _buildSlides(localization);
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            slides[_currentPage].color,
            slides[_currentPage].gradientColors[1],
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: slides[_currentPage].color.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: const Icon(
            Icons.arrow_forward_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(LocalizationService localization) {
    final slides = _buildSlides(localization);
    return AnimatedOpacity(
      opacity: _currentPage == slides.length - 1 ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 32.0),
        child: Column(
          children: [
            // Sign In Button (Primary Action)
            CustomButton(
              text: localization.translate('welcome.alreadyHaveAccount'),
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.login);
              },
              variant: ButtonVariant.gradient,
              gradientColors: [AppColors.primary, AppColors.secondary],
              size: ButtonSize.medium,
              icon: Icons.login_rounded,
            ),

            const SizedBox(height: 16),

            // Explore as Guest Button (Secondary Action)
            CustomButton(
              text: localization.translate('onboarding.exploreAsGuest'),
              onPressed: () async {
                final authService = Provider.of<AuthRepository>(
                  context,
                  listen: false,
                );
                await authService.loginAsGuest();

                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.mainNavigation,
                  (route) => false,
                );
              },
              variant: ButtonVariant.outline,
              icon: Icons.rocket_launch_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingSlide {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<Color> gradientColors;

  OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.gradientColors,
  });
}

class DecorativeShapesPainter extends CustomPainter {
  final Color color;

  DecorativeShapesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw soft circular shapes
    final shapes = [
      Offset(size.width * 0.1, size.height * 0.15),
      Offset(size.width * 0.9, size.height * 0.25),
      Offset(size.width * 0.2, size.height * 0.7),
      Offset(size.width * 0.85, size.height * 0.8),
    ];

    for (final shape in shapes) {
      canvas.drawCircle(
        shape,
        80,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

