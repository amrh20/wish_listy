import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum ButtonVariant { primary, secondary, outline, text, gradient }

enum ButtonSize { small, medium, large }

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final Color? customColor;
  final Color? customTextColor;
  final List<Color>? gradientColors;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
    this.customColor,
    this.customTextColor,
    this.gradientColors,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: widget.onPressed != null && !widget.isLoading
                ? _handleTapDown
                : null,
            onTapUp: widget.onPressed != null && !widget.isLoading
                ? _handleTapUp
                : null,
            onTapCancel: _handleTapCancel,
            onTap: widget.onPressed != null && !widget.isLoading
                ? widget.onPressed
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: widget.fullWidth ? double.infinity : null,
              height: _getButtonHeight(),
              decoration: _getButtonDecoration(),
              child: _buildButtonContent(),
            ),
          ),
        );
      },
    );
  }

  double _getButtonHeight() {
    switch (widget.size) {
      case ButtonSize.small:
        return 40;
      case ButtonSize.medium:
        return 52;
      case ButtonSize.large:
        return 60;
    }
  }

  BoxDecoration _getButtonDecoration() {
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    switch (widget.variant) {
      case ButtonVariant.primary:
        return BoxDecoration(
          color: isEnabled
              ? (widget.customColor ?? AppColors.primary)
              : (widget.customColor ?? AppColors.primary).withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isEnabled && !_isPressed
              ? [
                  BoxShadow(
                    color: (widget.customColor ?? AppColors.primary)
                        .withOpacity(0.3),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : [],
        );

      case ButtonVariant.secondary:
        return BoxDecoration(
          color: isEnabled
              ? AppColors.surfaceVariant
              : AppColors.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEnabled
                ? (widget.customColor ?? AppColors.primary)
                : AppColors.textTertiary,
            width: 1,
          ),
        );

      case ButtonVariant.outline:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEnabled
                ? (widget.customColor ?? AppColors.primary)
                : AppColors.textTertiary,
            width: 2,
          ),
        );

      case ButtonVariant.text:
        return BoxDecoration(
          color: _isPressed
              ? (widget.customColor ?? AppColors.primary).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        );

      case ButtonVariant.gradient:
        return BoxDecoration(
          gradient: LinearGradient(
            colors:
                widget.gradientColors ??
                [AppColors.primary, AppColors.secondary],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isEnabled && !_isPressed
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : [],
        );
    }
  }

  Widget _buildButtonContent() {
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    final textColor = _getTextColor(isEnabled);
    final fontSize = _getFontSize();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.size == ButtonSize.small ? 12 : 16,
        vertical: widget.size == ButtonSize.small ? 8 : 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isLoading) ...[
            SizedBox(
              width: fontSize,
              height: fontSize,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(textColor),
              ),
            ),
            const SizedBox(width: 8),
          ] else if (widget.icon != null) ...[
            Icon(widget.icon, color: textColor, size: fontSize + 2),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              widget.text,
              style: TextStyle(
                color: textColor,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTextColor(bool isEnabled) {
    if (!isEnabled) {
      // Use white text with opacity for disabled primary buttons
      if (widget.variant == ButtonVariant.primary ||
          widget.variant == ButtonVariant.gradient) {
        return Colors.white.withOpacity(0.6);
      }
      return AppColors.textTertiary;
    }

    if (widget.customTextColor != null) {
      return widget.customTextColor!;
    }

    switch (widget.variant) {
      case ButtonVariant.primary:
      case ButtonVariant.gradient:
        return Colors.white;
      case ButtonVariant.secondary:
      case ButtonVariant.outline:
      case ButtonVariant.text:
        return widget.customColor ?? AppColors.primary;
    }
  }

  double _getFontSize() {
    switch (widget.size) {
      case ButtonSize.small:
        return 14;
      case ButtonSize.medium:
        return 16;
      case ButtonSize.large:
        return 18;
    }
  }
}
