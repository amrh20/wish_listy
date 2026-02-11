import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/deep_link_service.dart';
import 'package:wish_listy/core/services/localization_service.dart';
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

  late final AnimationController _watermarkController;

  // Card data (use translation keys for localized strings)
  final List<_CardData> _cards = [
    _CardData(
      icon: Icons.favorite_border_rounded,
      color: AppColors.primary,
      route: AppRoutes.createWishlist,
      categoryTitleKey: 'home.emptyView.categoryWishlists',
      countPlaceholderKey: 'home.emptyView.countLists',
      ctaKey: 'home.emptyView.createFirstWishlist',
      watermarkIcon: Icons.card_giftcard_rounded,
    ),
    _CardData(
      icon: Icons.event_outlined,
      color: AppColors.accent,
      route: AppRoutes.createEvent,
      categoryTitleKey: 'home.emptyView.categoryEvents',
      countPlaceholderKey: 'home.emptyView.countEvents',
      ctaKey: 'home.emptyView.createFirstEvent',
      watermarkIcon: Icons.calendar_month_rounded,
    ),
    _CardData(
      icon: Icons.people_outline_rounded,
      color: AppColors.secondary,
      route: AppRoutes.addFriend,
      categoryTitleKey: 'home.emptyView.categoryFriends',
      countPlaceholderKey: 'home.emptyView.countFriends',
      ctaKey: 'home.emptyView.addFirstFriend',
      watermarkIcon: Icons.group_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _watermarkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _watermarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context);
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
          _buildContextualInfo(context, selectedCard, localization),
          
          const SizedBox(height: 20), // Tightened spacing between text and button
          
          // Dynamic Main CTA (compact pill)
          _buildDynamicMainCta(context, selectedCard, localization),
          const SizedBox(height: 16),
          // Invite friends (secondary action)
          TextButton.icon(
            onPressed: () {
              final message = localization.translate('invite.inviteFriendsShareMessage') +
                  DeepLinkService.inviteLink;
              DeepLinkService.shareAppInvite(message);
            },
            icon: const Icon(Icons.share_outlined, size: 20),
            label: Text(
              localization.translate('invite.inviteFriendsButton'),
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
          ),
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
                // IMPORTANT: Clip card content so watermark icon is clipped to card bounds
                // even when positioned with negative offsets (bottom-right corner effect)
                clipBehavior: Clip.antiAlias,
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
                  child: Stack(
                    // Clip within the card bounds (Material already clips to shape)
                    clipBehavior: Clip.hardEdge,
                    children: [
                      _WatermarkIcon(
                        controller: _watermarkController,
                        icon: card.watermarkIcon,
                        // Different phase per card so they don't breathe in sync
                        phase: index * 0.9,
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

  Widget _buildContextualInfo(
    BuildContext context,
    _CardData selectedCard,
    LocalizationService localization,
  ) {
    final categoryTitle = localization.translate(selectedCard.categoryTitleKey);
    final countPlaceholder =
        localization.translate(selectedCard.countPlaceholderKey);
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
        key: ValueKey('context_info_${selectedCard.categoryTitleKey}'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            categoryTitle.isNotEmpty ? categoryTitle : selectedCard.categoryTitleKey,
            style: AppStyles.headingSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            countPlaceholder.isNotEmpty ? countPlaceholder : selectedCard.countPlaceholderKey,
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

  Widget _buildDynamicMainCta(
    BuildContext context,
    _CardData selectedCard,
    LocalizationService localization,
  ) {
    final Color bg = selectedCard.color;
    final String text = localization.translate(selectedCard.ctaKey);
    final String buttonText = text.isNotEmpty ? text : selectedCard.ctaKey;

    final double maxWidth = MediaQuery.of(context).size.width;
    final double buttonWidth = (maxWidth * 0.78).clamp(220.0, 320.0);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: Tween<double>(begin: 0.96, end: 1.0).animate(anim),
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: SizedBox(
        key: ValueKey('main_cta_${selectedCard.categoryTitleKey}'),
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
            buttonText,
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
  final Color color;
  final String route;
  final String categoryTitleKey;
  final String countPlaceholderKey;
  final String ctaKey;
  final IconData watermarkIcon;

  _CardData({
    required this.icon,
    required this.color,
    required this.route,
    required this.categoryTitleKey,
    required this.countPlaceholderKey,
    required this.ctaKey,
    required this.watermarkIcon,
  });
}

class _WatermarkIcon extends StatelessWidget {
  final AnimationController controller;
  final IconData icon;
  final double phase;

  const _WatermarkIcon({
    required this.controller,
    required this.icon,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    // Subtle watermark size
    const iconSize = 35.0;
    // Animation amplitude: icons start from top and fall down
    const amplitude = 8.0;
    // Positive offsets: icon positioned INSIDE card from top-left
    // 15px from top and 15px from left (inside the card bounds)
    const topOffset = 15.0; // Positive = inside card from top
    const leftOffset = 15.0; // Positive = inside card from left
    // Subtle rotation for dynamic feel
    const rotationAngle = -0.2; // radians (approximately -11.5 degrees)
    // Very subtle opacity (just a texture)
    const iconOpacity = 0.12;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        // Animation: start from top (negative) and move down (positive dy)
        // Using sin wave: value goes from -1 to 1, so we map it to fall from top
        final t = controller.value * 2 * math.pi;
        // Map sin to range [0, 1] so icon starts higher and falls down
        final normalizedValue = (math.sin(t + phase) + 1) / 2; // Range: 0 to 1
        // Start from -amplitude (higher) and move to 0 (lower)
        final dy = -amplitude + (normalizedValue * amplitude);

        return Positioned(
          top: topOffset,
          left: leftOffset,
          child: IgnorePointer(
            child: Transform.translate(
              offset: Offset(0, dy),
              child: Transform.rotate(
                angle: rotationAngle,
                child: Opacity(
                  opacity: iconOpacity,
                  child: Icon(
                    icon,
                    size: iconSize,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

