import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';

/// A unified header widget that provides consistent styling across all main pages.
/// Features title, subtitle, search bar, and action buttons.
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

  const UnifiedPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.titleIcon,
    this.titleIconColor,
    this.showSearch = false,
    this.searchHint,
    this.searchController,
    this.onSearchChanged,
    this.onSearchTap,
    this.actions,
    this.trailing,
    this.backgroundColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ??
          const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withOpacity(0.12),
            AppColors.primary.withOpacity(0.05),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
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
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: AppStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Actions
                if (actions != null && actions!.isNotEmpty) ...[
                  ...actions!.map((action) => _buildActionButton(action)),
                ],
                if (trailing != null) trailing!,
              ],
            ),

            // Search Bar
            if (showSearch) ...[
              const SizedBox(height: 16),
              _buildSearchBar(),
            ],
          ],
        ),
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
                  color: AppColors.shadow.withOpacity(0.08),
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
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.04),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(
            Icons.search_rounded,
            color: AppColors.textLight,
            size: 22,
          ),
          const SizedBox(width: 10),
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
                  color: AppColors.textMuted,
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
          const SizedBox(width: 14),
        ],
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
                  color: AppColors.shadow.withOpacity(0.08),
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

