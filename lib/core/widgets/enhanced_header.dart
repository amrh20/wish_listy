import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';

enum HeaderType { wishlist, events, friends, profile }

/// Enhanced header widget with gradient background and decorative elements
class EnhancedHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final HeaderType type;
  final Widget? actionButton;
  final bool showSearch;
  final VoidCallback? onSearchPressed;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;

  const EnhancedHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.type,
    this.actionButton,
    this.showSearch = false,
    this.onSearchPressed,
    this.searchController,
    this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        gradient: _getGradient(),
      ),
      child: Stack(
        children: [
          // Decorative circles in background
          ..._buildDecorativeCircles(),
          // Main content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  // Title with icon
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getIcon(),
                          size: 28,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: AppStyles.headingLarge.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                offset: const Offset(0, 2),
                                blurRadius: 6,
                              ),
                              Shadow(
                                color: Colors.black.withOpacity(0.2),
                                offset: const Offset(0, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (actionButton != null) actionButton!,
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Subtitle or Search
                  if (subtitle != null && !showSearch)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        subtitle!,
                        style: AppStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.2),
                              offset: const Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (showSearch && searchController != null)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: TextField(
                        controller: searchController,
                        style: AppStyles.bodyLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          hintStyle: AppStyles.bodyMedium.copyWith(
                            color: AppColors.textTertiary,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        onChanged: onSearchChanged,
                      ),
                    ),
                  const Spacer(),
                  // Wave divider at bottom
                  CustomPaint(
                    size: Size(MediaQuery.of(context).size.width, 40),
                    painter: WavePainter(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _getGradient() {
    switch (type) {
      case HeaderType.wishlist:
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFE0F7FA), // Teal/Cyan light
            Colors.white,
          ],
          stops: const [0.0, 1.0],
        );
      case HeaderType.events:
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFCE4EC), // Pink/Red light
            Colors.white,
          ],
          stops: const [0.0, 1.0],
        );
      case HeaderType.friends:
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFE3F2FD), // Blue light
            Colors.white,
          ],
          stops: const [0.0, 1.0],
        );
      case HeaderType.profile:
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFFF3E0), // Orange light
            Colors.white,
          ],
          stops: const [0.0, 1.0],
        );
    }
  }

  IconData _getIcon() {
    switch (type) {
      case HeaderType.wishlist:
        return Icons.favorite_rounded;
      case HeaderType.events:
        return Icons.event_rounded;
      case HeaderType.friends:
        return Icons.people_rounded;
      case HeaderType.profile:
        return Icons.person_rounded;
    }
  }

  List<Widget> _buildDecorativeCircles() {
    return [
      Positioned(
        top: 20,
        right: 30,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.08),
          ),
        ),
      ),
      Positioned(
        top: 60,
        right: 100,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.06),
          ),
        ),
      ),
      Positioned(
        top: 100,
        left: 40,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.05),
          ),
        ),
      ),
      Positioned(
        top: 140,
        left: 120,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.07),
          ),
        ),
      ),
    ];
  }
}

/// Custom painter for wave divider
class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.5);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.3,
      size.width * 0.5,
      size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.7,
      size.width,
      size.height * 0.5,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

