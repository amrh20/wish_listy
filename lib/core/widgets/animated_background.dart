import 'package:flutter/material.dart';
import 'dart:math';

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

            final defaultColors = [
              Colors.white,
              Colors.blue.shade50.withOpacity(0.3),
              Colors.purple.shade50.withOpacity(0.2),
              Colors.white,
            ];
            final colors = widget.colors ?? defaultColors;
            
            // Generate stops based on the number of colors
            final stops = List.generate(
              colors.length,
              (index) {
                if (colors.length == 1) {
                  return 0.0;
                }
                // Distribute stops evenly, with animation effect
                final baseStop = index / (colors.length - 1);
                if (index == 0) {
                  return 0.0;
                } else if (index == colors.length - 1) {
                  return 1.0;
                } else {
                  // Add animation effect to middle stops
                  final animationOffset = _gradientAnimation.value * 0.1;
                  return baseStop + animationOffset;
                }
              },
            );
            
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                  stops: stops,
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

        // Child Content
        if (widget.child != null) widget.child!,
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
