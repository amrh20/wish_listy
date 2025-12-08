import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localization, child) {
        if (!context.mounted) return const SizedBox.shrink();

        final navigationItems = [
          {
            'icon': Icons.home_outlined,
            'activeIcon': Icons.home_rounded,
            'label': localization.translate('navigation.home'),
            'color': AppColors.primary,
          },
          {
            'icon': Icons.favorite_outline,
            'activeIcon': Icons.favorite_rounded,
            'label': localization.translate('navigation.wishlist'),
            'color': AppColors.primary,
          },
          {
            'icon': Icons.celebration_outlined,
            'activeIcon': Icons.celebration_rounded,
            'label': localization.translate('navigation.events'),
            'color': AppColors.primary,
          },
          {
            'icon': Icons.people_outline,
            'activeIcon': Icons.people_rounded,
            'label': localization.translate('navigation.friends'),
            'color': AppColors.primary,
          },
          {
            'icon': Icons.person_outline,
            'activeIcon': Icons.person_rounded,
            'label': localization.translate('navigation.profile'),
            'color': AppColors.primary,
          },
        ];

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: AppColors.textTertiary.withOpacity(0.1),
                offset: const Offset(0, -4),
                blurRadius: 20,
                spreadRadius: 0,
              ),
            ],
          ),
          child: SafeArea(
            child: Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: navigationItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isActive = currentIndex == index;

                  return _buildNavigationButton(item, index, isActive);
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavigationButton(
    Map<String, dynamic> item,
    int index,
    bool isActive,
  ) {
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? item['activeIcon'] : item['icon'],
                key: ValueKey(isActive),
                color: isActive ? AppColors.primary : AppColors.textPrimary,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: AppStyles.caption.copyWith(
                color: isActive ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
              child: Text(item['label']),
            ),
          ],
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

      canvas.drawCircle(
        Offset(size.width * 0.7, size.height * 0.3),
        1.5,
        sparklePaint,
      );
      canvas.drawCircle(
        Offset(size.width * 0.3, size.height * 0.25),
        1.0,
        sparklePaint,
      );
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
    bowPath.quadraticBezierTo(
      size.width * 0.4,
      size.height * 0.2,
      size.width * 0.35,
      size.height * 0.25,
    );
    bowPath.quadraticBezierTo(
      size.width * 0.4,
      size.height * 0.3,
      size.width * 0.5,
      size.height * 0.25,
    );
    bowPath.moveTo(size.width * 0.5, size.height * 0.25);
    bowPath.quadraticBezierTo(
      size.width * 0.6,
      size.height * 0.2,
      size.width * 0.65,
      size.height * 0.25,
    );
    bowPath.quadraticBezierTo(
      size.width * 0.6,
      size.height * 0.3,
      size.width * 0.5,
      size.height * 0.25,
    );

    canvas.drawPath(boxPath, paint);
    canvas.drawPath(ribbonVPath, paint);
    canvas.drawPath(ribbonHPath, paint);
    canvas.drawPath(bowPath, paint);

    if (isActive) {
      // Add sparkles around the gift
      final sparklePaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(size.width * 0.15, size.height * 0.4),
        1.0,
        sparklePaint,
      );
      canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.6),
        1.5,
        sparklePaint,
      );
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
    canvas.drawCircle(
      Offset(size.width * 0.35, size.height * 0.55),
      1.5,
      datePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.55),
      1.5,
      datePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.65, size.height * 0.55),
      1.5,
      datePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.35, size.height * 0.7),
      1.5,
      datePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.7),
      1.5,
      datePaint,
    );

    canvas.drawPath(calendarPath, paint);
    canvas.drawPath(topPath, paint);
    canvas.drawPath(hangPath, paint);

    if (isActive) {
      // Add celebration sparkles
      final sparklePaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(size.width * 0.15, size.height * 0.2),
        1.0,
        sparklePaint,
      );
      canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.2),
        1.0,
        sparklePaint,
      );
      canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.15),
        1.5,
        sparklePaint,
      );
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

    // Left person
    final leftHeadPath = Path();
    leftHeadPath.addOval(
      Rect.fromCircle(
        center: Offset(size.width * 0.3, size.height * 0.35),
        radius: size.width * 0.12,
      ),
    );

    final leftBodyPath = Path();
    leftBodyPath.moveTo(size.width * 0.3, size.height * 0.47);
    leftBodyPath.lineTo(size.width * 0.3, size.height * 0.75);
    leftBodyPath.moveTo(size.width * 0.2, size.height * 0.6);
    leftBodyPath.lineTo(size.width * 0.4, size.height * 0.6);

    // Right person
    final rightHeadPath = Path();
    rightHeadPath.addOval(
      Rect.fromCircle(
        center: Offset(size.width * 0.7, size.height * 0.35),
        radius: size.width * 0.12,
      ),
    );

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

      canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.25),
        1.0,
        sparklePaint,
      );
      canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.85),
        1.0,
        sparklePaint,
      );
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

    // Head
    final headPath = Path();
    headPath.addOval(
      Rect.fromCircle(
        center: Offset(size.width * 0.5, size.height * 0.35),
        radius: size.width * 0.15,
      ),
    );

    // Body
    final bodyPath = Path();
    bodyPath.moveTo(size.width * 0.35, size.height * 0.5);
    bodyPath.lineTo(size.width * 0.65, size.height * 0.5);
    bodyPath.lineTo(size.width * 0.65, size.height * 0.8);
    bodyPath.lineTo(size.width * 0.35, size.height * 0.8);
    bodyPath.close();

    // Eyes
    final leftEyePath = Path();
    leftEyePath.addOval(
      Rect.fromCircle(
        center: Offset(size.width * 0.42, size.height * 0.32),
        radius: size.width * 0.03,
      ),
    );

    final rightEyePath = Path();
    rightEyePath.addOval(
      Rect.fromCircle(
        center: Offset(size.width * 0.58, size.height * 0.32),
        radius: size.width * 0.03,
      ),
    );

    // Smile
    final smilePath = Path();
    smilePath.moveTo(size.width * 0.42, size.height * 0.4);
    smilePath.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.45,
      size.width * 0.58,
      size.height * 0.4,
    );

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

      canvas.drawCircle(
        Offset(size.width * 0.25, size.height * 0.25),
        1.0,
        sparklePaint,
      );
      canvas.drawCircle(
        Offset(size.width * 0.75, size.height * 0.25),
        1.0,
        sparklePaint,
      );
      canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.15),
        1.5,
        sparklePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
