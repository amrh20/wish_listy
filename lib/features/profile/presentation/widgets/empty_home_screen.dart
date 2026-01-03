import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/utils/app_routes.dart';

/// Empty Home Screen with interactive stacked cards animation
class EmptyHomeScreen extends StatefulWidget {
  const EmptyHomeScreen({super.key});

  @override
  State<EmptyHomeScreen> createState() => _EmptyHomeScreenState();
}

class _EmptyHomeScreenState extends State<EmptyHomeScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0; // 0=Wishlists, 1=Events, 2=Friends

  static const Duration _cardAnimDuration = Duration(milliseconds: 420);
  static const Curve _cardAnimCurve = Curves.easeInOutCubic;
  static const double _stackCardWidth = 180;
  static const double _stackCardHeight = 200; // Reduced from 230 for better fit
  static const double _stackCardRadius = 52; // Continuous squircle-like radius

  // Card data
  final List<_CardData> _cards = [
    _CardData(
      icon: Icons.favorite_border_rounded,
      label: 'My Wishlists',
      color: AppColors.primary,
      route: AppRoutes.createWishlist,
      actionText: 'Create new Wishlist',
      categoryTitle: 'Wishlists',
      countPlaceholder: '0 lists',
    ),
    _CardData(
      icon: Icons.event_outlined,
      label: 'My Events',
      // Color swap: Events -> Accent (Pink)
      color: AppColors.accent,
      route: AppRoutes.createEvent,
      actionText: 'Create new Event',
      categoryTitle: 'Events',
      countPlaceholder: '0 events',
    ),
    _CardData(
      icon: Icons.people_outline_rounded,
      label: 'My Friends',
      // Color swap: Friends -> Secondary (Teal)
      color: AppColors.secondary,
      route: AppRoutes.addFriend,
      actionText: 'Add new Friend',
      categoryTitle: 'Friends',
      countPlaceholder: '0 friends',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedCard = _cards[_selectedIndex];
    return Padding(
      padding: const EdgeInsets.only(
        left: 24.0,
        right: 24.0,
        top: 16.0,
        bottom: 100.0, // Bottom padding to clear BottomNavigationBar
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Stacked Cards
          SizedBox(height: 260, child: _buildAngledStack()),
          
          const SizedBox(height: 28), // Tightened spacing between stack and text
          
          // Dynamic Contextual Text (Category + count)
          _buildContextualInfo(selectedCard),
          
          const SizedBox(height: 20), // Tightened spacing between text and button
          
          // Dynamic Main CTA (compact pill)
          _buildDynamicMainCta(selectedCard),
        ],
      ),
    );
  }

  Widget _buildAngledStack() {
    // Visual roles: back, middle, front (like the reference image)
    final order = <int>[
      (_selectedIndex + 2) % 3, // back
      (_selectedIndex + 1) % 3, // middle
      _selectedIndex, // front
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final centerLeft = (width - _stackCardWidth) / 2;

        // Poses tuned to match the reference:
        // - Back: higher, left, rotated (-)
        // - Middle: slightly lower, right, rotated (+)
        // - Front: lowest, centered, near-straight
        final positions = <_CardPose>[
          _CardPose(
            top: 4,
            dx: -34,
            turns: -14 / 360,
            scale: 1.0,
            opacity: 0.62,
          ),
          _CardPose(
            top: 30,
            dx: 34,
            turns: 10 / 360,
            scale: 1.0,
            opacity: 0.68,
          ),
          _CardPose(
            top: 64,
            dx: 0,
            turns: 0 / 360,
            scale: 1.0,
            opacity: 0.78,
          ),
        ];

        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (int role = 0; role < 3; role++)
              _buildPosedCard(
                index: order[role],
                pose: positions[role],
                centerLeft: centerLeft,
              ),
          ],
        );
      },
    );
  }

  Widget _buildPosedCard({
    required int index,
    required _CardPose pose,
    required double centerLeft,
  }) {
    final card = _cards[index];
    final isSelected = index == _selectedIndex;

    // Softer translucent background (glassy look)
    final baseBg = card.color.withOpacity(isSelected ? 0.70 : 0.60);

    // Slight extra "depth" shadow for the front card
    final shadowStrength = isSelected ? 0.10 : 0.07;

    return AnimatedPositioned(
      duration: _cardAnimDuration,
      curve: _cardAnimCurve,
      top: pose.top,
      left: centerLeft + pose.dx,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!isSelected) {
            setState(() => _selectedIndex = index);
          }
        },
        child: AnimatedOpacity(
          duration: _cardAnimDuration,
          curve: _cardAnimCurve,
          opacity: pose.opacity,
          child: AnimatedScale(
            duration: _cardAnimDuration,
            curve: _cardAnimCurve,
            scale: pose.scale,
            child: AnimatedRotation(
              duration: _cardAnimDuration,
              curve: _cardAnimCurve,
              turns: pose.turns,
              child: Material(
                color: Colors.transparent,
                shape: ContinuousRectangleBorder(
                  borderRadius: BorderRadius.circular(_stackCardRadius),
                ),
                elevation: 0,
                child: Ink(
                  width: _stackCardWidth,
                  height: _stackCardHeight,
                  decoration: ShapeDecoration(
                    shape: ContinuousRectangleBorder(
                      borderRadius: BorderRadius.circular(_stackCardRadius),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        baseBg,
                        card.color.withOpacity(isSelected ? 0.58 : 0.50),
                      ],
                    ),
                    shadows: [
                      BoxShadow(
                        color: AppColors.textPrimary.withOpacity(shadowStrength),
                        blurRadius: 22,
                        offset: const Offset(0, 12),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContextualInfo(_CardData selectedCard) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
      child: Column(
        key: ValueKey('context_info_${selectedCard.categoryTitle}'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            selectedCard.categoryTitle,
            style: AppStyles.headingSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            selectedCard.countPlaceholder,
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary.withOpacity(0.75),
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicMainCta(_CardData selectedCard) {
    final Color bg = selectedCard.color;
    final String text = switch (selectedCard.route) {
      AppRoutes.createWishlist => 'Create first wishlist',
      AppRoutes.addFriend => 'Add first friend',
      AppRoutes.createEvent => 'Create first event',
      _ => selectedCard.actionText,
    };

    final double maxWidth = MediaQuery.of(context).size.width;
    final double buttonWidth = (maxWidth * 0.78).clamp(220.0, 320.0);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: Tween<double>(begin: 0.96, end: 1.0).animate(anim),
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: SizedBox(
        key: ValueKey('main_cta_${selectedCard.categoryTitle}'),
        width: buttonWidth,
        height: 52,
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(
              context,
              selectedCard.route,
              arguments: selectedCard.route == AppRoutes.createWishlist
                  ? {'previousRoute': AppRoutes.mainNavigation}
                  : null,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: Colors.white,
            elevation: 8,
            shadowColor: bg.withOpacity(0.35),
            shape: const StadiumBorder(),
          ),
          child: Text(
            text,
            style: AppStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _CardPose {
  final double top;
  final double dx;
  final double turns;
  final double scale;
  final double opacity;

  const _CardPose({
    required this.top,
    required this.dx,
    required this.turns,
    required this.scale,
    required this.opacity,
  });
}

class _CardData {
  final IconData icon;
  final String label;
  final Color color;
  final String route;
  final String actionText;
  final String categoryTitle;
  final String countPlaceholder;

  _CardData({
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
    required this.actionText,
    required this.categoryTitle,
    required this.countPlaceholder,
  });
}

