import 'package:flutter/material.dart';
import 'dart:math';
import '../constants/app_colors.dart';

class DecorativeBackground extends StatefulWidget {
  final Widget? child;
  final bool showGifts;
  final bool showCircles;

  const DecorativeBackground({
    super.key,
    this.child,
    this.showGifts = true,
    this.showCircles = true,
  });

  @override
  State<DecorativeBackground> createState() => _DecorativeBackgroundState();
}

class _DecorativeBackgroundState extends State<DecorativeBackground>
    with TickerProviderStateMixin {
  late AnimationController _floatingController;
  late AnimationController _rotationController;
  late Animation<double> _floatingAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _floatingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _floatingAnimation = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * pi,
    ).animate(_rotationController);
  }

  void _startAnimations() {
    if (mounted) {
      _floatingController.repeat(reverse: true);
      _rotationController.repeat();
    }
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade50,
            Colors.blue.shade50,
            Colors.white,
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Decorative Circles
          if (widget.showCircles) _buildDecorativeCircles(),

          // Gift Shapes
          if (widget.showGifts) _buildGiftShapes(),

          // Floating Dots
          _buildFloatingDots(),

          // Child Content
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }

  Widget _buildDecorativeCircles() {
    return Stack(
      children: [
        // Top Right Circle
        Positioned(
          top: -80,
          right: -60,
          child: AnimatedBuilder(
            animation: _floatingAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _floatingAnimation.value),
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.08),
                        AppColors.primary.withOpacity(0.03),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Bottom Left Circle
        Positioned(
          bottom: -100,
          left: -80,
          child: AnimatedBuilder(
            animation: _floatingAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -_floatingAnimation.value),
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.secondary.withOpacity(0.06),
                        AppColors.secondary.withOpacity(0.02),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Center Right Small Circle
        Positioned(
          top: MediaQuery.of(context).size.height * 0.4,
          right: -30,
          child: AnimatedBuilder(
            animation: _floatingAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_floatingAnimation.value, 0),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.accent.withOpacity(0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGiftShapes() {
    return Stack(
      children: [
        // Gift Box 1
        Positioned(
          top: MediaQuery.of(context).size.height * 0.15,
          left: 30,
          child: AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationAnimation.value * 0.1,
                child: AnimatedBuilder(
                  animation: _floatingAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        _floatingAnimation.value * 0.5,
                        _floatingAnimation.value,
                      ),
                      child: CustomPaint(
                        painter: GiftBoxPainter(
                          color: AppColors.primary.withOpacity(0.06),
                        ),
                        size: const Size(40, 40),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),

        // Gift Box 2
        Positioned(
          bottom: MediaQuery.of(context).size.height * 0.25,
          right: 40,
          child: AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: -_rotationAnimation.value * 0.08,
                child: AnimatedBuilder(
                  animation: _floatingAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        -_floatingAnimation.value * 0.3,
                        _floatingAnimation.value * 0.8,
                      ),
                      child: CustomPaint(
                        painter: GiftBoxPainter(
                          color: AppColors.accent.withOpacity(0.05),
                        ),
                        size: const Size(35, 35),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),

        // Heart Shape
        Positioned(
          top: MediaQuery.of(context).size.height * 0.6,
          left: 50,
          child: AnimatedBuilder(
            animation: _floatingAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  _floatingAnimation.value * 0.7,
                  -_floatingAnimation.value,
                ),
                child: CustomPaint(
                  painter: HeartPainter(color: Colors.pink.withOpacity(0.04)),
                  size: const Size(30, 30),
                ),
              );
            },
          ),
        ),

        // Star Shape
        Positioned(
          top: MediaQuery.of(context).size.height * 0.3,
          right: 60,
          child: AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationAnimation.value * 0.15,
                child: AnimatedBuilder(
                  animation: _floatingAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        _floatingAnimation.value * 0.4,
                        _floatingAnimation.value * 0.6,
                      ),
                      child: CustomPaint(
                        painter: StarPainter(
                          color: Colors.amber.withOpacity(0.06),
                        ),
                        size: const Size(25, 25),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingDots() {
    return Stack(
      children: List.generate(8, (index) {
        final random = Random(index);
        return Positioned(
          top: random.nextDouble() * MediaQuery.of(context).size.height,
          left: random.nextDouble() * MediaQuery.of(context).size.width,
          child: AnimatedBuilder(
            animation: _floatingAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  _floatingAnimation.value * (random.nextDouble() - 0.5) * 2,
                  _floatingAnimation.value * (random.nextDouble() - 0.5) * 2,
                ),
                child: Container(
                  width: 4 + random.nextDouble() * 4,
                  height: 4 + random.nextDouble() * 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: [
                      AppColors.primary,
                      AppColors.secondary,
                      AppColors.accent,
                      Colors.pink,
                      Colors.amber,
                    ][index % 5].withOpacity(0.1),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}

class GiftBoxPainter extends CustomPainter {
  final Color color;

  GiftBoxPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Gift box body
    final rect = Rect.fromLTWH(
      size.width * 0.2,
      size.height * 0.3,
      size.width * 0.6,
      size.height * 0.5,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      paint,
    );

    // Gift box lid
    final lidRect = Rect.fromLTWH(
      size.width * 0.15,
      size.height * 0.25,
      size.width * 0.7,
      size.height * 0.15,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(lidRect, const Radius.circular(4)),
      paint,
    );

    // Ribbon vertical
    final ribbonV = Rect.fromLTWH(
      size.width * 0.45,
      size.height * 0.25,
      size.width * 0.1,
      size.height * 0.55,
    );
    canvas.drawRect(ribbonV, strokePaint);

    // Ribbon horizontal
    final ribbonH = Rect.fromLTWH(
      size.width * 0.15,
      size.height * 0.45,
      size.width * 0.7,
      size.height * 0.1,
    );
    canvas.drawRect(ribbonH, strokePaint);

    // Bow
    final bowPath = Path();
    bowPath.moveTo(size.width * 0.4, size.height * 0.15);
    bowPath.quadraticBezierTo(
      size.width * 0.35,
      size.height * 0.05,
      size.width * 0.45,
      size.height * 0.1,
    );
    bowPath.quadraticBezierTo(
      size.width * 0.55,
      size.height * 0.05,
      size.width * 0.6,
      size.height * 0.15,
    );
    bowPath.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.2,
      size.width * 0.4,
      size.height * 0.15,
    );
    canvas.drawPath(bowPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HeartPainter extends CustomPainter {
  final Color color;

  HeartPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width * 0.5, size.height * 0.25);

    // Left curve
    path.cubicTo(
      size.width * 0.2,
      size.height * 0.1,
      size.width * 0.1,
      size.height * 0.6,
      size.width * 0.5,
      size.height * 0.9,
    );

    // Right curve
    path.cubicTo(
      size.width * 0.9,
      size.height * 0.6,
      size.width * 0.8,
      size.height * 0.1,
      size.width * 0.5,
      size.height * 0.25,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StarPainter extends CustomPainter {
  final Color color;

  StarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width * 0.4;
    final innerRadius = size.width * 0.2;

    for (int i = 0; i < 5; i++) {
      final outerAngle = (i * 2 * pi / 5) - pi / 2;
      final innerAngle = ((i + 0.5) * 2 * pi / 5) - pi / 2;

      final outerX = center.dx + outerRadius * cos(outerAngle);
      final outerY = center.dy + outerRadius * sin(outerAngle);

      final innerX = center.dx + innerRadius * cos(innerAngle);
      final innerY = center.dy + innerRadius * sin(innerAngle);

      if (i == 0) {
        path.moveTo(outerX, outerY);
      } else {
        path.lineTo(outerX, outerY);
      }
      path.lineTo(innerX, innerY);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
