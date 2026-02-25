import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';

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
    return Consumer2<LocalizationService, AuthRepository>(
      builder: (context, localization, authService, child) {
        if (!context.mounted) return const SizedBox.shrink();

        // Responsive layout tuning for small screens (e.g., 320dp / 360dp)
        final width = MediaQuery.of(context).size.width;
        final bool isVerySmallWidth = width <= 320;
        final bool isSmallWidth = width > 320 && width <= 360;

        // Outer container margin (keeps nav away from screen edges)
        final EdgeInsets containerMargin = EdgeInsets.symmetric(
          horizontal: isVerySmallWidth
              ? 8
              : (isSmallWidth
                  ? 12
                  : 16), // default margin for larger screens
          vertical: isVerySmallWidth
              ? 10
              : (isSmallWidth ? 14 : 20),
        );

        // Inner padding around GNav
        final EdgeInsets gnavPadding = EdgeInsets.symmetric(
          horizontal: isVerySmallWidth
              ? 6
              : (isSmallWidth ? 8 : 8),
          vertical: isVerySmallWidth
              ? 8
              : (isSmallWidth ? 9 : 10),
        );

        // Icon size & gap between icon and label
        final double iconSize = isVerySmallWidth
            ? 22
            : (isSmallWidth ? 24 : 26);
        final double gap = isVerySmallWidth ? 3 : 4;

        // Label text size (Arabic labels stay inside pill on narrow screens)
        final double labelFontSize = isVerySmallWidth
            ? 10
            : (isSmallWidth ? 11 : 12);

        // Tab configurations with color themes
        // Screens: 0=Home, 1=Wishlist, 2=Events, 3=Friends, 4=Profile
        // GNav: 0=Home, 1=Wishlist, 2=Events, 3=Friends, 4=Profile
        final tabs = [
          {
            'icon': Icons.home_rounded,
            'text': localization.translate('navigation.home'),
            'color': AppColors.primary, // Purple
            'isRestricted': false,
          },
          {
            'icon': Icons.favorite_rounded,
            'text': localization.translate('navigation.wishlist'),
            'color': AppColors.accent, // Pink
            'isRestricted': false,
          },
          {
            'icon': Icons.celebration_rounded,
            'text': localization.translate('navigation.events'),
            'color': AppColors.secondary, // Teal
            'isRestricted': true,
          },
          {
            'icon': Icons.diversity_3_rounded,
            'text': localization.translate('navigation.friends'),
            'color': AppColors.success, // Green (for Friends)
            'isRestricted': true,
          },
          {
            'icon': Icons.face_rounded,
            'text': localization.translate('navigation.profile'),
            'color': AppColors.info, // Blue
            'isRestricted': true,
          },
        ];

        // Map currentIndex directly (now we have 5 tabs matching 5 screens)
        final gNavIndex = currentIndex;

        final bottomSafe = MediaQuery.of(context).padding.bottom;
        return SafeArea(
          child: Container(
            margin: EdgeInsets.only(
              left: containerMargin.left,
              top: containerMargin.top,
              right: containerMargin.right,
              bottom: containerMargin.bottom + bottomSafe + 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95), // Subtle background
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -4), // Top shadow to separate from content
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Padding(
              padding: gnavPadding,
              child: GNav(
                gap: gap,
                color: AppColors.textTertiary, // Inactive icon/text color
                activeColor:
                    tabs[gNavIndex]['color'] as Color, // Active icon/text color
                iconSize: iconSize,
                textStyle: AppStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: labelFontSize,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isVerySmallWidth
                      ? 8
                      : (isSmallWidth ? 10 : 12),
                  vertical: isVerySmallWidth
                      ? 8
                      : (isSmallWidth ? 9 : 10),
                ),
                duration: const Duration(milliseconds: 300),
                tabBackgroundColor: (tabs[gNavIndex]['color'] as Color)
                    .withOpacity(0.15),
                tabBorderRadius: 24,
                curve: Curves.easeInOutCubic,
                selectedIndex: gNavIndex,
                haptic: true,
                backgroundColor: Colors.transparent,
                onTabChange: (index) {
                  // GNav indices now match screen indices directly (0-4)
                  // Always call onTap - main_navigation will handle restrictions and show lock sheet
                  onTap(index);
                },
                tabs: tabs.map((tab) {
                  return GButton(
                    icon: tab['icon'] as IconData,
                    text: tab['text'] as String,
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}
