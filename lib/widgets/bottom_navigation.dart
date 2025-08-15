import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_styles.dart';
import 'dart:math' as math;

class CustomBottomNavigation extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<CustomBottomNavigation> createState() => _CustomBottomNavigationState();
}

class _CustomBottomNavigationState extends State<CustomBottomNavigation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _bounceAnimations;
  late List<AnimationController> _particleControllers;
  late List<List<Animation<double>>> _particleAnimations;

  @override
  void initState() {
    super.initState();
    
    _controllers = List.generate(5, (index) => AnimationController(
      duration: Duration(milliseconds: 300 + (index * 50)),
      vsync: this,
    ));
    
    _scaleAnimations = _controllers.map((controller) => 
      Tween<double>(begin: 1.0, end: 1.1).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut)
      )
    ).toList();
    
    _bounceAnimations = _controllers.map((controller) => 
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.bounceOut)
      )
    ).toList();

    // Particle animations for each tab
    _particleControllers = List.generate(5, (index) => AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    ));
    
    _particleAnimations = List.generate(5, (index) => 
      List.generate(8, (particleIndex) => Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _particleControllers[index],
        curve: Curves.easeOut,
      )))
    );
    
    // Start initial animations
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) _controllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var controller in _particleControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        'icon': _buildCustomHomeIcon,
        'activeIcon': _buildCustomHomeIconActive,
        'label': 'Home',
        'gradient': AppColors.primaryGradient,
        'color': AppColors.primary,
      },
      {
        'icon': _buildCustomWishlistIcon,
        'activeIcon': _buildCustomWishlistIconActive,
        'label': 'Wishlist',
        'gradient': AppColors.pinkGradient,
        'color': AppColors.pink,
      },
      {
        'icon': _buildCustomEventsIcon,
        'activeIcon': _buildCustomEventsIconActive,
        'label': 'Events',
        'gradient': AppColors.tealGradient,
        'color': AppColors.secondary,
      },
      {
        'icon': _buildCustomFriendsIcon,
        'activeIcon': _buildCustomFriendsIconActive,
        'label': 'Friends',
        'gradient': AppColors.indigoGradient,
        'color': AppColors.indigo,
      },
      {
        'icon': _buildCustomProfileIcon,
        'activeIcon': _buildCustomProfileIconActive,
        'label': 'Profile',
        'gradient': AppColors.orangeGradient,
        'color': AppColors.orange,
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 30,
            offset: const Offset(0, -10),
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isActive = widget.currentIndex == index;

              return AnimatedBuilder(
                animation: _controllers[index],
                builder: (context, child) {
                  return Transform.scale(
                    scale: isActive ? _scaleAnimations[index].value : 1.0,
                    child: Stack(
                      children: [
                        // Particle effects for active tab
                        if (isActive) _buildParticleEffects(index, item['color']),
                        _buildNavigationItem(
                          item: item,
                          isActive: isActive,
                          onTap: () {
                            // Haptic feedback
                            HapticFeedback.lightImpact();
                            if (isActive) {
                              HapticFeedback.mediumImpact();
                            }
                            
                            widget.onTap(index);
                            _controllers[index].forward().then((_) {
                              _controllers[index].reverse();
                            });
                            
                            // Trigger particle animation
                            if (isActive) {
                              _particleControllers[index].forward().then((_) {
                                _particleControllers[index].reset();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildParticleEffects(int tabIndex, Color color) {
    return AnimatedBuilder(
      animation: _particleControllers[tabIndex],
      builder: (context, child) {
        return Stack(
          children: List.generate(8, (particleIndex) {
            final animation = _particleAnimations[tabIndex][particleIndex];
            final angle = (particleIndex * 45) * (math.pi / 180);
            final radius = 40.0 * animation.value;
            final x = math.cos(angle) * radius;
            final y = math.sin(angle) * radius;
            
            return Positioned(
              left: 20 + x,
              top: 12 + y,
              child: Transform.scale(
                scale: (1.0 - animation.value) * 0.5,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: color.withOpacity(1.0 - animation.value),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildNavigationItem({
    required Map<String, dynamic> item,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isActive ? item['gradient'] : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ] : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                isActive ? item['activeIcon'] : item['icon'],
                key: ValueKey(isActive),
                color: isActive ? AppColors.textWhite : AppColors.textLight,
                size: 26,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item['label'],
              style: AppStyles.caption.copyWith(
                color: isActive ? AppColors.textWhite : AppColors.textLight,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomHomeIcon() {
    return Container(
      width: 26,
      height: 26,
      child: CustomPaint(
        painter: HomeIconPainter(
          color: AppColors.textLight,
          isActive: false,
        ),
      ),
    );
  }

  Widget _buildCustomHomeIconActive() {
    return Container(
      width: 26,
      height: 26,
      child: CustomPaint(
        painter: HomeIconPainter(
          color: AppColors.textWhite,
          isActive: true,
        ),
      ),
    );
  }

  Widget _buildCustomWishlistIcon() {
    return Container(
      width: 26,
      height: 26,
      child: CustomPaint(
        painter: WishlistIconPainter(
          color: AppColors.textLight,
          isActive: false,
        ),
      ),
    );
  }

  Widget _buildCustomWishlistIconActive() {
    return Container(
      width: 26,
      height: 26,
      child: CustomPaint(
        painter: WishlistIconPainter(
          color: AppColors.textWhite,
          isActive: true,
        ),
      ),
    );
  }

  Widget _buildCustomEventsIcon() {
    return Container(
      width: 26,
      height: 26,
      child: CustomPaint(
        painter: EventsIconPainter(
          color: AppColors.textLight,
          isActive: false,
        ),
      ),
    );
  }

  Widget _buildCustomEventsIconActive() {
    return Container(
      width: 26,
      height: 26,
      child: CustomPaint(
        painter: EventsIconPainter(
          color: AppColors.textWhite,
          isActive: true,
        ),
      ),
    );
  }

  Widget _buildCustomFriendsIcon() {
    return Container(
      width: 26,
      height: 26,
      child: CustomPaint(
        painter: FriendsIconPainter(
          color: AppColors.textLight,
          isActive: false,
        ),
      ),
    );
  }

  Widget _buildCustomFriendsIconActive() {
    return Container(
      width: 26,
      height: 26,
      child: CustomPaint(
        painter: FriendsIconPainter(
          color: AppColors.textWhite,
          isActive: true,
        ),
      ),
    );
  }

  Widget _buildCustomProfileIcon() {
    return Container(
      width: 26,
      height: 26,
      child: CustomPaint(
        painter: ProfileIconPainter(
          color: AppColors.textLight,
          isActive: false,
        ),
      ),
    );
  }

  Widget _buildCustomProfileIconActive() {
    return Container(
      width: 26,
      height: 26,
      child: CustomPaint(
        painter: ProfileIconPainter(
          color: AppColors.textWhite,
          isActive: true,
        ),
      ),
    );
  }
}

// Custom Icon Painters
class HomeIconPainter extends CustomPainter {
  final Color color;
  final bool isActive;

  HomeIconPainter({required this.color, required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = isActive ? 2.5 : 2.0
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // House outline
    final path = Path();
    path.moveTo(size.width * 0.5, size.height * 0.2);
    path.lineTo(size.width * 0.8, size.height * 0.4);
    path.lineTo(size.width * 0.8, size.height * 0.8);
    path.lineTo(size.width * 0.2, size.height * 0.8);
    path.lineTo(size.width * 0.2, size.height * 0.4);
    path.close();

    // Door
    final doorPath = Path();
    doorPath.moveTo(size.width * 0.4, size.height * 0.8);
    doorPath.lineTo(size.width * 0.4, size.height * 0.6);
    doorPath.lineTo(size.width * 0.6, size.height * 0.6);
    doorPath.lineTo(size.width * 0.6, size.height * 0.8);

    // Window
    final windowPath = Path();
    windowPath.moveTo(size.width * 0.3, size.height * 0.5);
    windowPath.lineTo(size.width * 0.3, size.height * 0.35);
    windowPath.lineTo(size.width * 0.45, size.height * 0.35);
    windowPath.lineTo(size.width * 0.45, size.height * 0.5);
    windowPath.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(doorPath, paint);
    canvas.drawPath(windowPath, paint);

    if (isActive) {
      // Add some sparkles
      final sparklePaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.3), 1.5, sparklePaint);
      canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.25), 1.0, sparklePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class WishlistIconPainter extends CustomPainter {
  final Color color;
  final bool isActive;

  WishlistIconPainter({required this.color, required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = isActive ? 2.5 : 2.0
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Gift box
    final boxPath = Path();
    boxPath.moveTo(size.width * 0.2, size.height * 0.3);
    boxPath.lineTo(size.width * 0.8, size.height * 0.3);
    boxPath.lineTo(size.width * 0.8, size.height * 0.8);
    boxPath.lineTo(size.width * 0.2, size.height * 0.8);
    boxPath.close();

    // Ribbon vertical
    final ribbonVPath = Path();
    ribbonVPath.moveTo(size.width * 0.5, size.height * 0.3);
    ribbonVPath.lineTo(size.width * 0.5, size.height * 0.8);

    // Ribbon horizontal
    final ribbonHPath = Path();
    ribbonHPath.moveTo(size.width * 0.2, size.height * 0.5);
    ribbonHPath.lineTo(size.width * 0.8, size.height * 0.5);

    // Bow
    final bowPath = Path();
    bowPath.moveTo(size.width * 0.5, size.height * 0.25);
    bowPath.quadraticBezierTo(size.width * 0.4, size.height * 0.2, size.width * 0.35, size.height * 0.25);
    bowPath.quadraticBezierTo(size.width * 0.4, size.height * 0.3, size.width * 0.5, size.height * 0.25);
    bowPath.moveTo(size.width * 0.5, size.height * 0.25);
    bowPath.quadraticBezierTo(size.width * 0.6, size.height * 0.2, size.width * 0.65, size.height * 0.25);
    bowPath.quadraticBezierTo(size.width * 0.6, size.height * 0.3, size.width * 0.5, size.height * 0.25);

    canvas.drawPath(boxPath, paint);
    canvas.drawPath(ribbonVPath, paint);
    canvas.drawPath(ribbonHPath, paint);
    canvas.drawPath(bowPath, paint);

    if (isActive) {
      // Add sparkles around the gift
      final sparklePaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.4), 1.0, sparklePaint);
      canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.6), 1.5, sparklePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class EventsIconPainter extends CustomPainter {
  final Color color;
  final bool isActive;

  EventsIconPainter({required this.color, required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = isActive ? 2.5 : 2.0
      ..style = PaintingStyle.stroke;

    // Calendar base
    final calendarPath = Path();
    calendarPath.moveTo(size.width * 0.2, size.height * 0.3);
    calendarPath.lineTo(size.width * 0.8, size.height * 0.3);
    calendarPath.lineTo(size.width * 0.8, size.height * 0.8);
    calendarPath.lineTo(size.width * 0.2, size.height * 0.8);
    calendarPath.close();

    // Calendar top
    final topPath = Path();
    topPath.moveTo(size.width * 0.2, size.height * 0.3);
    topPath.lineTo(size.width * 0.8, size.height * 0.3);
    topPath.lineTo(size.width * 0.8, size.height * 0.4);
    topPath.lineTo(size.width * 0.2, size.height * 0.4);
    topPath.close();

    // Hanging part
    final hangPath = Path();
    hangPath.moveTo(size.width * 0.35, size.height * 0.3);
    hangPath.lineTo(size.width * 0.35, size.height * 0.25);
    hangPath.lineTo(size.width * 0.65, size.height * 0.25);
    hangPath.lineTo(size.width * 0.65, size.height * 0.3);

    // Date numbers
    final datePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Simple dots representing dates
    canvas.drawCircle(Offset(size.width * 0.35, size.height * 0.55), 1.5, datePaint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.55), 1.5, datePaint);
    canvas.drawCircle(Offset(size.width * 0.65, size.height * 0.55), 1.5, datePaint);
    canvas.drawCircle(Offset(size.width * 0.35, size.height * 0.7), 1.5, datePaint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.7), 1.5, datePaint);

    canvas.drawPath(calendarPath, paint);
    canvas.drawPath(topPath, paint);
    canvas.drawPath(hangPath, paint);

    if (isActive) {
      // Add celebration sparkles
      final sparklePaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.2), 1.0, sparklePaint);
      canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.2), 1.0, sparklePaint);
      canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.15), 1.5, sparklePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class FriendsIconPainter extends CustomPainter {
  final Color color;
  final bool isActive;

  FriendsIconPainter({required this.color, required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = isActive ? 2.5 : 2.0
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Left person
    final leftHeadPath = Path();
    leftHeadPath.addOval(Rect.fromCircle(
      center: Offset(size.width * 0.3, size.height * 0.35),
      radius: size.width * 0.12,
    ));

    final leftBodyPath = Path();
    leftBodyPath.moveTo(size.width * 0.3, size.height * 0.47);
    leftBodyPath.lineTo(size.width * 0.3, size.height * 0.75);
    leftBodyPath.moveTo(size.width * 0.2, size.height * 0.6);
    leftBodyPath.lineTo(size.width * 0.4, size.height * 0.6);

    // Right person
    final rightHeadPath = Path();
    rightHeadPath.addOval(Rect.fromCircle(
      center: Offset(size.width * 0.7, size.height * 0.35),
      radius: size.width * 0.12,
    ));

    final rightBodyPath = Path();
    rightBodyPath.moveTo(size.width * 0.7, size.height * 0.47);
    rightBodyPath.lineTo(size.width * 0.7, size.height * 0.75);
    rightBodyPath.moveTo(size.width * 0.6, size.height * 0.6);
    rightBodyPath.lineTo(size.width * 0.8, size.height * 0.6);

    // Connection line
    final connectionPath = Path();
    connectionPath.moveTo(size.width * 0.42, size.height * 0.35);
    connectionPath.lineTo(size.width * 0.58, size.height * 0.35);

    canvas.drawPath(leftHeadPath, paint);
    canvas.drawPath(leftBodyPath, paint);
    canvas.drawPath(rightHeadPath, paint);
    canvas.drawPath(rightBodyPath, paint);
    canvas.drawPath(connectionPath, paint);

    if (isActive) {
      // Add friendship sparkles
      final sparklePaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.25), 1.0, sparklePaint);
      canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.85), 1.0, sparklePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ProfileIconPainter extends CustomPainter {
  final Color color;
  final bool isActive;

  ProfileIconPainter({required this.color, required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = isActive ? 2.5 : 2.0
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Head
    final headPath = Path();
    headPath.addOval(Rect.fromCircle(
      center: Offset(size.width * 0.5, size.height * 0.35),
      radius: size.width * 0.15,
    ));

    // Body
    final bodyPath = Path();
    bodyPath.moveTo(size.width * 0.35, size.height * 0.5);
    bodyPath.lineTo(size.width * 0.65, size.height * 0.5);
    bodyPath.lineTo(size.width * 0.65, size.height * 0.8);
    bodyPath.lineTo(size.width * 0.35, size.height * 0.8);
    bodyPath.close();

    // Eyes
    final leftEyePath = Path();
    leftEyePath.addOval(Rect.fromCircle(
      center: Offset(size.width * 0.42, size.height * 0.32),
      radius: size.width * 0.03,
    ));

    final rightEyePath = Path();
    rightEyePath.addOval(Rect.fromCircle(
      center: Offset(size.width * 0.58, size.height * 0.32),
      radius: size.width * 0.03,
    ));

    // Smile
    final smilePath = Path();
    smilePath.moveTo(size.width * 0.42, size.height * 0.4);
    smilePath.quadraticBezierTo(size.width * 0.5, size.height * 0.45, size.width * 0.58, size.height * 0.4);

    canvas.drawPath(headPath, paint);
    canvas.drawPath(bodyPath, paint);
    canvas.drawPath(leftEyePath, paint);
    canvas.drawPath(rightEyePath, paint);
    canvas.drawPath(smilePath, paint);

    if (isActive) {
      // Add profile sparkles
      final sparklePaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.25), 1.0, sparklePaint);
      canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.25), 1.0, sparklePaint);
      canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.15), 1.5, sparklePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
