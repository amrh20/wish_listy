import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';

/// Top overlay toast widget for displaying success/error/info messages
/// Appears at the top of the screen with high z-index (above all UI elements)
class TopOverlayToast {
  static OverlayEntry? _currentOverlay;
  
  /// Show success toast at top of screen
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _show(context, message, AppColors.success, Icons.check_circle, duration);
  }
  
  /// Show error toast at top of screen
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(context, message, AppColors.error, Icons.error_outline, duration);
  }
  
  /// Show info toast at top of screen
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _show(context, message, AppColors.info, Icons.info_outline, duration);
  }
  
  /// Internal method to show overlay
  static void _show(
    BuildContext context,
    String message,
    Color backgroundColor,
    IconData icon,
    Duration duration,
  ) {
    // Remove existing overlay if any
    _hide(context);
    
    // Get overlay state
    final overlay = Overlay.of(context);
    if (overlay == null) return;
    
    // Create overlay entry
    _currentOverlay = OverlayEntry(
      builder: (context) => _TopOverlayWidget(
        message: message,
        backgroundColor: backgroundColor,
        icon: icon,
        onDismiss: () => _hide(context),
      ),
    );
    
    // Insert overlay
    overlay.insert(_currentOverlay!);
    
    // Auto dismiss after duration
    Future.delayed(duration, () {
      _hide(context);
    });
  }
  
  /// Hide current overlay
  static void _hide(BuildContext context) {
    if (_currentOverlay != null) {
      _currentOverlay!.remove();
      _currentOverlay = null;
    }
  }
  
  /// Hide overlay (public method)
  static void dismiss(BuildContext context) {
    _hide(context);
  }
}

/// Top overlay widget
class _TopOverlayWidget extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final IconData icon;
  final VoidCallback onDismiss;
  
  const _TopOverlayWidget({
    required this.message,
    required this.backgroundColor,
    required this.icon,
    required this.onDismiss,
  });
  
  @override
  State<_TopOverlayWidget> createState() => _TopOverlayWidgetState();
}

class _TopOverlayWidgetState extends State<_TopOverlayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    _controller.forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final localization = LocalizationService();
    final isRTL = localization.isRTL;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    
    // Position overlay at top with safe spacing from status bar
    // Using 8px below status bar to avoid covering important UI elements
    final topPosition = statusBarHeight + 8;
    
    return Positioned(
      top: topPosition,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(
                maxHeight: 56, // Compact height to avoid blocking UI
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.icon,
                    color: Colors.white,
                    size: 18, // Slightly smaller icon
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      widget.message,
                      style: AppStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontSize: 13, // Slightly smaller font
                        fontWeight: FontWeight.w500,
                      ),
                      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                      maxLines: 2, // Limit to 2 lines max
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: widget.onDismiss,
                    child: Icon(
                      Icons.close,
                      color: Colors.white.withOpacity(0.8),
                      size: 16, // Smaller close icon
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

