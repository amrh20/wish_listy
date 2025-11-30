import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';

enum PrimaryAction { search, edit, none }

/// Unified AppBar widget for consistent header design across main screens
class UnifiedAppBar extends StatefulWidget {
  final String title;
  final PrimaryAction primaryAction;
  final VoidCallback? onSearchChanged;
  final VoidCallback? onEditPressed;
  final VoidCallback? onNotificationsPressed;
  final VoidCallback? onSettingsPressed;
  final VoidCallback? onProfilePressed;

  const UnifiedAppBar({
    super.key,
    required this.title,
    this.primaryAction = PrimaryAction.none,
    this.onSearchChanged,
    this.onEditPressed,
    this.onNotificationsPressed,
    this.onSettingsPressed,
    this.onProfilePressed,
  });

  @override
  State<UnifiedAppBar> createState() => _UnifiedAppBarState();
}

class _UnifiedAppBarState extends State<UnifiedAppBar> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchMode = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearchMode() {
    setState(() {
      _isSearchMode = !_isSearchMode;
      if (!_isSearchMode) {
        _searchController.clear();
        if (widget.onSearchChanged != null) {
          widget.onSearchChanged!();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            // Title or Search Field
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.1, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                    child: _isSearchMode
                        ? Container(
                            key: const ValueKey('search'),
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
                          controller: _searchController,
                          autofocus: true,
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
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                          onChanged: (value) {
                            if (widget.onSearchChanged != null) {
                              widget.onSearchChanged!();
                            }
                          },
                        ),
                          )
                    : Row(
                        key: const ValueKey('title'),
                        children: [
                          Icon(
                            Icons.favorite_rounded,
                            color: AppColors.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primary.withOpacity(0.8),
                                ],
                              ).createShader(bounds),
                              child: Text(
                                widget.title,
                                style: AppStyles.headingLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 28,
                                  letterSpacing: -0.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            // Primary Action Button (Search/Edit)
            if (widget.primaryAction != PrimaryAction.none) ...[
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: widget.primaryAction == PrimaryAction.search
                      ? _toggleSearchMode
                      : widget.onEditPressed,
                  icon: Icon(
                    widget.primaryAction == PrimaryAction.search
                        ? (_isSearchMode
                            ? Icons.close_rounded
                            : Icons.search_rounded)
                        : Icons.edit_outlined,
                    color: AppColors.textPrimary,
                    size: 22,
                  ),
                  padding: const EdgeInsets.all(10),
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

