import 'package:flutter/material.dart';
import 'dart:math';
import '../constants/app_colors.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget? child;
  final List<Color>? colors;
  final bool showParticles;

  const AnimatedBackground({
    super.key,
    this.child,
    this.colors,
    this.showParticles = true,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _gradientController;
  late AnimationController _particleController;
  late Animation<double> _gradientAnimation;
  late List<Particle> _particles;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeParticles();
    _startAnimations();
  }

  void _initializeControllers() {
    _gradientController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _gradientAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_gradientController);
  }

  void _initializeParticles() {
    _particles = List.generate(
      8,
      (index) => Particle(),
    ); // Reduced from 15 to 8 for better performance
  }

  void _startAnimations() {
    if (mounted) {
      _gradientController.repeat();
      if (widget.showParticles) {
        _particleController.repeat();
      }
    }
  }

  @override
  void dispose() {
    _gradientController.stop();
    _particleController.stop();
    _gradientController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Animated Gradient Background
        AnimatedBuilder(
          animation: _gradientAnimation,
          builder: (context, child) {
            if (!mounted) return const SizedBox.shrink();

            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors:
                      widget.colors ??
                      [
                        Colors.white,
                        Colors.blue.shade50.withOpacity(0.3),
                        Colors.purple.shade50.withOpacity(0.2),
                        Colors.white,
                      ],
                  stops: [
                    0.0,
                    0.3 + (_gradientAnimation.value * 0.2),
                    0.7 + (_gradientAnimation.value * 0.1),
                    1.0,
                  ],
                ),
              ),
            );
          },
        ),

        // Floating Particles
        if (widget.showParticles)
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              if (!mounted) return const SizedBox.shrink();

              return CustomPaint(
                painter: ParticlesPainter(
                  particles: _particles,
                  animation: _particleController.value,
                ),
                size: Size.infinite,
              );
            },
          ),

        // Geometric Shapes
        _buildFloatingShapes(),

        // Child Content
        if (widget.child != null) widget.child!,
      ],
    );
  }

  Widget _buildFloatingShapes() {
    return Stack(
      children: [
        // Top Right Circle
        Positioned(
          top: -50,
          right: -50,
          child: AnimatedBuilder(
            animation: _gradientController,
            builder: (context, child) {
              if (!mounted) return const SizedBox.shrink();

              return Transform.rotate(
                angle: _gradientAnimation.value * 2 * pi,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.blue.shade100.withOpacity(0.4),
                        Colors.blue.shade50.withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Bottom Left Shape
        Positioned(
          bottom: -30,
          left: -30,
          child: AnimatedBuilder(
            animation: _gradientController,
            builder: (context, child) {
              if (!mounted) return const SizedBox.shrink();

              return Transform.rotate(
                angle: -_gradientAnimation.value * 1.5 * pi,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.purple.shade100.withOpacity(0.3),
                        Colors.pink.shade50.withOpacity(0.2),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Center Right Triangle
        Positioned(
          top: MediaQuery.of(context).size.height * 0.3,
          right: -20,
          child: AnimatedBuilder(
            animation: _gradientController,
            builder: (context, child) {
              if (!mounted) return const SizedBox.shrink();

              return Transform.rotate(
                angle: _gradientAnimation.value * pi,
                child: CustomPaint(
                  painter: TrianglePainter(
                    color: Colors.green.shade100.withOpacity(0.25),
                  ),
                  size: const Size(80, 80),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class Particle {
  late double x;
  late double y;
  late double size;
  late double speedX;
  late double speedY;
  late Color color;
  late double opacity;

  Particle() {
    reset();
  }

  void reset() {
    x = Random().nextDouble();
    y = Random().nextDouble();
    size = Random().nextDouble() * 4 + 1;
    speedX = (Random().nextDouble() - 0.5) * 0.002;
    speedY = (Random().nextDouble() - 0.5) * 0.002;
    opacity = Random().nextDouble() * 0.3 + 0.05;

    List<Color> colors = [
      Colors.blue.shade300,
      Colors.purple.shade300,
      Colors.green.shade300,
      Colors.pink.shade300,
    ];
    color = colors[Random().nextInt(colors.length)];
  }

  void update() {
    x += speedX;
    y += speedY;

    if (x < 0 || x > 1 || y < 0 || y > 1) {
      reset();
    }
  }
}

class ParticlesPainter extends CustomPainter {
  final List<Particle> particles;
  final double animation;

  ParticlesPainter({required this.particles, required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      particle.update();

      final paint = Paint()
        ..color = particle.color.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
