import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../constants/app_colors.dart';
import '../constants/mock_data.dart';
import '../widgets/profile_header.dart';
import '../widgets/stats_cards.dart';
import '../widgets/events_section.dart';
import '../widgets/wishes_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _backgroundController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 8000),
      vsync: this,
    )..repeat();
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.linear,
    ));
    
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Beautiful Background with Animated Elements
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _backgroundAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: BackgroundPainter(_backgroundAnimation.value),
                );
              },
            ),
          ),
          
          // Main Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Profile Header
                    SliverToBoxAdapter(
                      child: ProfileHeader(
                        user: MockData.currentUser,
                        notificationCount: 3,
                      ),
                    ),
                    
                    // Stats Cards
                    SliverToBoxAdapter(
                      child: StatsCards(user: MockData.currentUser),
                    ),
                    
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                    
                    // Events Section
                    SliverToBoxAdapter(
                      child: EventsSection(
                        events: MockData.events,
                        onSeeAll: () {
                          // Navigate to events page
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Events page coming soon!'),
                              backgroundColor: AppColors.primary,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                    
                    // Wishes Section
                    SliverToBoxAdapter(
                      child: WishesSection(
                        wishes: MockData.wishes,
                        onSeeAll: () {
                          // Navigate to wishes page
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Wishes page coming soon!'),
                              backgroundColor: AppColors.primary,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Beautiful Background Painter
class BackgroundPainter extends CustomPainter {
  final double animationValue;

  BackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [
          AppColors.primary.withOpacity(0.05),
          AppColors.primary.withOpacity(0.02),
          Colors.transparent,
        ],
        stops: const [0.0, 0.7, 1.0],
        center: Alignment.topRight,
        radius: size.width * 0.8,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Animated circles
    final circlePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.primary.withOpacity(0.03);

    // Top right circle
    canvas.drawCircle(
      Offset(
        size.width * 0.8 + (animationValue * 20),
        size.height * 0.1 - (animationValue * 10),
      ),
      80 + (animationValue * 20),
      circlePaint,
    );

    // Bottom left circle
    canvas.drawCircle(
      Offset(
        size.width * 0.2 - (animationValue * 15),
        size.height * 0.8 + (animationValue * 15),
      ),
      60 + (animationValue * 15),
      circlePaint,
    );

    // Center gradient
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );

    // Floating particles
    for (int i = 0; i < 5; i++) {
      final particlePaint = Paint()
        ..style = PaintingStyle.fill
        ..color = AppColors.primary.withOpacity(0.1 - (i * 0.02));

      final x = (size.width * 0.1) + (i * size.width * 0.2) + (animationValue * 30);
      final y = (size.height * 0.3) + (i * size.height * 0.1) - (animationValue * 20);

      canvas.drawCircle(
        Offset(x, y),
        3 + (i * 2),
        particlePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
