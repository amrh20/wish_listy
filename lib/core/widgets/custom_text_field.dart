


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function()? onTap;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final String? errorText;
  final String? helperText;
  final bool isRequired;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.enabled = true,
    this.errorText,
    this.helperText,
    this.isRequired = false,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _labelAnimation;
  late Animation<Color?> _borderColorAnimation;
  
  bool _isFocused = false;
  bool _hasText = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkInitialText();
    widget.controller.addListener(_onTextChanged);
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _labelAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _borderColorAnimation = ColorTween(
      begin: AppColors.textTertiary.withOpacity(0.3),
      end: AppColors.primary,
    ).animate(_animationController);
  }

  void _checkInitialText() {
    _hasText = widget.controller.text.isNotEmpty;
    if (_hasText) {
      _animationController.value = 1.0;
    }
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
      if (hasText || _isFocused) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
    
    // Clear error when user starts typing
    if (_errorText != null && hasText) {
      setState(() {
        _errorText = null;
      });
    }
  }

  void _onFocusChanged(bool hasFocus) {
    setState(() {
      _isFocused = hasFocus;
    });

    if (hasFocus || _hasText) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _validateField() {
    if (widget.validator != null) {
      final error = widget.validator!(widget.controller.text);
      setState(() {
        _errorText = error;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayError = widget.errorText ?? _errorText;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Field Container
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.1),
                      offset: const Offset(0, 4),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ]
                : [],
          ),
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Focus(
                onFocusChange: _onFocusChanged,
                child: TextFormField(
                  controller: widget.controller,
                  obscureText: widget.obscureText,
                  keyboardType: widget.keyboardType,
                  onChanged: widget.onChanged,
                  onTap: widget.onTap,
                  readOnly: widget.readOnly,
                  enabled: widget.enabled,
                  maxLines: widget.maxLines,
                  maxLength: widget.maxLength,
                  inputFormatters: widget.inputFormatters,
                  onFieldSubmitted: (_) => _validateField(),
                  style: AppStyles.bodyLarge.copyWith(
                    color: widget.enabled 
                        ? AppColors.textPrimary 
                        : AppColors.textTertiary,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: widget.enabled
                        ? (_isFocused 
                            ? AppColors.surface 
                            : AppColors.surfaceVariant)
                        : AppColors.surfaceVariant.withOpacity(0.5),
                    
                    // Border styles
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.textTertiary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: displayError != null 
                            ? AppColors.error 
                            : AppColors.textTertiary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: displayError != null 
                            ? AppColors.error 
                            : AppColors.primary,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.error,
                        width: 1,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.error,
                        width: 2,
                      ),
                    ),
                    
                    // Content padding
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: widget.maxLines == 1 ? 16 : 12,
                    ),
                    
                    // Label
                    labelText: widget.label + (widget.isRequired ? ' *' : ''),
                    labelStyle: AppStyles.bodyMedium.copyWith(
                      color: _isFocused
                          ? (displayError != null ? AppColors.error : AppColors.primary)
                          : AppColors.textSecondary,
                      fontWeight: _isFocused ? FontWeight.w500 : FontWeight.normal,
                    ),
                    floatingLabelStyle: AppStyles.bodySmall.copyWith(
                      color: _isFocused
                          ? (displayError != null ? AppColors.error : AppColors.primary)
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    
                    // Hint
                    hintText: widget.hint,
                    hintStyle: AppStyles.bodyMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    
                    // Icons
                    prefixIcon: widget.prefixIcon != null
                        ? Icon(
                            widget.prefixIcon,
                            color: _isFocused
                                ? (displayError != null ? AppColors.error : AppColors.primary)
                                : AppColors.textTertiary,
                            size: 20,
                          )
                        : null,
                    suffixIcon: widget.suffixIcon,
                    
                    // Counter
                    counterStyle: AppStyles.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    
                    // Error text
                    errorText: null, // We handle error display separately
                    errorStyle: const TextStyle(height: 0),
                  ),
                ),
              );
            },
          ),
        ),
        
        // Error and Helper Text
        if (displayError != null || widget.helperText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Row(
              children: [
                if (displayError != null)
                  Icon(
                    Icons.error_outline,
                    size: 16,
                    color: AppColors.error,
                  ),
                if (displayError != null) const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    displayError ?? widget.helperText!,
                    style: AppStyles.caption.copyWith(
                      color: displayError != null 
                          ? AppColors.error 
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}