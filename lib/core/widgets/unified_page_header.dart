import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/widgets/unified_tab_bar.dart';

/// A unified header widget that provides consistent styling across all main pages.
/// Features title, search bar with filter icon in rounded lavender container.
/// Can optionally include integrated tabs within the same pink background.
class UnifiedPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? titleIcon;
  final Color? titleIconColor;
  final bool showSearch;
  final String? searchHint;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchTap;
  final List<HeaderAction>? actions;
  final Widget? trailing;
  final Color? backgroundColor;
  final EdgeInsets? padding;

  // Integrated tabs parameters
  final List<UnifiedTab>? tabs;
  final int? selectedTabIndex;
  final ValueChanged<int>? onTabChanged;
  final Color? selectedTabColor;

  // Margin control
  final double? bottomMargin;

  // Custom bottom content (e.g., wishlist card for home screen)
  final Widget? bottomContent;

  const UnifiedPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.titleIcon,
    this.titleIconColor,
    this.showSearch = true,
    this.searchHint,
    this.searchController,
    this.onSearchChanged,
    this.onSearchTap,
    this.actions,
    this.trailing,
    this.backgroundColor,
    this.padding,
    this.tabs,
    this.selectedTabIndex,
    this.onTabChanged,
    this.selectedTabColor,
    this.bottomMargin,
    this.bottomContent,
  });

  // Dynamic border radius based on tabs presence and bottomContent
  BorderRadius get _borderRadius {
    if (tabs != null && tabs!.isNotEmpty || bottomContent != null) {
      // مع tabs أو bottomContent: مستدير من الأعلى فقط (لإخفاء التضارب مع container)
      return const BorderRadius.only(
        topLeft: Radius.circular(36),
        topRight: Radius.circular(36),
      );
    } else {
      // بدون tabs أو bottomContent: مستدير من كل الجهات
      return BorderRadius.circular(36);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Adjust bottom margin when tabs are present to connect with container
    // Or use custom bottomMargin if provided
    final calculatedBottomMargin =
        bottomMargin ?? ((tabs != null && tabs!.isNotEmpty) ? 0.0 : 16.0);

    return Container(
      margin: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 16,
        bottom: calculatedBottomMargin,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.cardPurple,
        borderRadius: _borderRadius,
        boxShadow: [
          BoxShadow(
            color: AppColors.textTertiary.withOpacity(0.1),
            offset: const Offset(0, 4),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: _borderRadius,
        child: Stack(
          children: [
            // Decorative background elements
            _buildDecorativeElements(),

            // Main content
            Container(
              padding:
                  padding ??
                  const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 24,
                    bottom: 24,
                  ),
              child: SafeArea(
                bottom: false,
                minimum: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title Row
                    Row(
                      children: [
                        // Title with optional icon
                        if (titleIcon != null) ...[
                          Icon(
                            titleIcon,
                            color: titleIconColor ?? AppColors.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: AppStyles.headingLarge.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 28,
                                ),
                              ),
                              if (subtitle != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  subtitle!,
                                  style: AppStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Actions
                        if (actions != null && actions!.isNotEmpty) ...[
                          ...actions!.map(
                            (action) => _buildActionButton(action),
                          ),
                        ],
                        if (trailing != null) trailing!,
                      ],
                    ),

                    // Search Bar
                    if (showSearch) ...[
                      const SizedBox(height: 20),
                      _buildSearchBar(),
                    ],

                    // Integrated Tabs
                    if (tabs != null && tabs!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildIntegratedTabs(),
                    ],

                    // Bottom Content (e.g., wishlist card for home screen)
                    if (bottomContent != null) ...[
                      const SizedBox(height: 16),
                      bottomContent!,
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build decorative background elements
  Widget _buildDecorativeElements() {
    return Positioned.fill(
      child: Stack(
        children: [
          // Top right gift icon
          Positioned(
            top: -10,
            right: 30,
            child: Icon(
              Icons.card_giftcard_rounded,
              size: 70,
              color: Colors.white.withOpacity(0.15),
            ),
          ),

          // Bottom left heart
          Positioned(
            bottom: -15,
            left: 20,
            child: Icon(
              Icons.favorite_rounded,
              size: 60,
              color: AppColors.accent.withOpacity(0.12),
            ),
          ),

          // Top left circle
          Positioned(
            top: -20,
            left: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.08),
              ),
            ),
          ),

          // Bottom right star
          Positioned(
            bottom: 10,
            right: 50,
            child: Icon(
              Icons.star_rounded,
              size: 35,
              color: AppColors.accent.withOpacity(0.15),
            ),
          ),

          // Middle small circle
          Positioned(
            top: 40,
            right: -10,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withOpacity(0.1),
              ),
            ),
          ),

          // Small sparkle icon
          Positioned(
            top: 20,
            left: 80,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 25,
              color: Colors.white.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(HeaderAction action) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: action.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textTertiary.withOpacity(0.1),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    action.icon,
                    color: action.iconColor ?? AppColors.textPrimary,
                    size: 22,
                  ),
                ),
                // Badge
                if (action.showBadge)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: action.badgeCount != null ? 16 : 8,
                      height: action.badgeCount != null ? 16 : 8,
                      decoration: BoxDecoration(
                        color: action.badgeColor ?? AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: action.badgeCount != null
                          ? Center(
                              child: Text(
                                action.badgeCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.textTertiary.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(Icons.search_rounded, color: AppColors.textTertiary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              onTap: onSearchTap,
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: searchHint ?? 'Search...',
                hintStyle: AppStyles.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
                filled: false,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  // Build integrated tabs within the header
  Widget _buildIntegratedTabs() {
    if (tabs == null ||
        tabs!.isEmpty ||
        selectedTabIndex == null ||
        onTabChanged == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(tabs!.length, (index) {
          final tab = tabs![index];
          final isSelected = index == selectedTabIndex;

          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onTabChanged!(index),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (selectedTabColor ?? AppColors.primary)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon
                      if (tab.icon != null) ...[
                        Icon(
                          tab.icon,
                          size: 18,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                      ],

                      // Label
                      Flexible(
                        child: Text(
                          tab.label,
                          style: AppStyles.bodyMedium.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Badge
                      if (tab.badgeCount != null && tab.badgeCount! > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withOpacity(0.3)
                                : (tab.badgeColor ?? AppColors.accent),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            tab.badgeCount.toString(),
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Represents an action button in the header
class HeaderAction {
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;
  final bool showBadge;
  final int? badgeCount;
  final Color? badgeColor;

  const HeaderAction({
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.showBadge = false,
    this.badgeCount,
    this.badgeColor,
  });
}

/// A simpler version of the header for screens that only need a title and actions
class SimplePageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<HeaderAction>? actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const SimplePageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.showBackButton = false,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 8),
      child: Row(
        children: [
          if (showBackButton)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onBackPressed ?? () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_rounded,
                      color: AppColors.textPrimary,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          if (leading != null) leading!,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppStyles.headingLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actions != null)
            ...actions!.map((action) => _buildActionButton(action)),
        ],
      ),
    );
  }

  Widget _buildActionButton(HeaderAction action) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: action.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textTertiary.withOpacity(0.1),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    action.icon,
                    color: action.iconColor ?? AppColors.textPrimary,
                    size: 22,
                  ),
                ),
                if (action.showBadge)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: action.badgeCount != null ? 16 : 8,
                      height: action.badgeCount != null ? 16 : 8,
                      decoration: BoxDecoration(
                        color: action.badgeColor ?? AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: action.badgeCount != null
                          ? Center(
                              child: Text(
                                action.badgeCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
