import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppStyles {
  // Beautiful Text Styles with Custom Fonts
  static TextStyle get heading1 => const TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    height: 1.1,
    letterSpacing: -0.5,
    fontFamily: 'Poppins',
  );
  
  static TextStyle get heading2 => const TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: -0.3,
    fontFamily: 'Poppins',
  );
  
  static TextStyle get heading3 => const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
    letterSpacing: -0.2,
    fontFamily: 'Poppins',
  );
  
  static TextStyle get heading4 => const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
    letterSpacing: -0.1,
    fontFamily: 'Poppins',
  );
  
  // Additional text styles
  static TextStyle get headingLarge => const TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static TextStyle get headingMedium => const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );
  
  static TextStyle get headingSmall => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );
  
  static TextStyle get bodyLarge => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  
  static TextStyle get bodyMedium => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );
  
  static TextStyle get bodySmall => const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );
  
  static TextStyle get caption => const TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
    height: 1.3,
  );
  
  static TextStyle get button => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textWhite,
    height: 1.4,
    letterSpacing: 0.2,
    fontFamily: 'Inter',
  );
  
  static TextStyle get overline => const TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
    height: 1.2,
    letterSpacing: 1.5,
    fontFamily: 'Inter',
  );
  
  // Enhanced Card Styles with Beautiful Shadows
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: AppColors.shadow,
        blurRadius: 25,
        offset: const Offset(0, 8),
        spreadRadius: 0,
      ),
      BoxShadow(
        color: AppColors.shadowLight,
        blurRadius: 10,
        offset: const Offset(0, 2),
        spreadRadius: 0,
      ),
    ],
  );
  
  static BoxDecoration get cardDecorationLight => BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: AppColors.shadowLight,
        blurRadius: 15,
        offset: const Offset(0, 4),
        spreadRadius: 0,
      ),
    ],
  );
  
  static BoxDecoration get cardDecorationHover => BoxDecoration(
    color: AppColors.cardHover,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: AppColors.shadowDark,
        blurRadius: 30,
        offset: const Offset(0, 12),
        spreadRadius: 0,
      ),
    ],
  );
  
  // Glassmorphism Card Style
  static BoxDecoration get glassCardDecoration => BoxDecoration(
    color: AppColors.glass,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: AppColors.borderLight,
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: AppColors.shadowLight,
        blurRadius: 20,
        offset: const Offset(0, 8),
        spreadRadius: 0,
      ),
    ],
  );
  
  // Beautiful Button Styles
  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.textWhite,
    elevation: 0,
    shadowColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
    textStyle: button,
  );
  
  static ButtonStyle get secondaryButton => ElevatedButton.styleFrom(
    backgroundColor: AppColors.secondary,
    foregroundColor: AppColors.textPrimary,
    elevation: 0,
    shadowColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: AppColors.border),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
    textStyle: button.copyWith(color: AppColors.textPrimary),
  );
  
  static ButtonStyle get outlineButton => OutlinedButton.styleFrom(
    foregroundColor: AppColors.primary,
    side: BorderSide(color: AppColors.primary, width: 2),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
    textStyle: button.copyWith(color: AppColors.primary),
  );
  
  static ButtonStyle get gradientButton => ElevatedButton.styleFrom(
    backgroundColor: Colors.transparent,
    foregroundColor: AppColors.textWhite,
    elevation: 0,
    shadowColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
    textStyle: button,
  );
  
  // Enhanced Input Styles
  static InputDecoration get inputDecoration => InputDecoration(
    filled: true,
    fillColor: AppColors.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: AppColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: AppColors.accent, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    hintStyle: bodyMedium.copyWith(color: AppColors.textMuted),
  );
  
  // Special Effects Styles
  static BoxDecoration get neonGlow => BoxDecoration(
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withOpacity(0.3),
        blurRadius: 20,
        offset: const Offset(0, 0),
        spreadRadius: 0,
      ),
      BoxShadow(
        color: AppColors.primary.withOpacity(0.1),
        blurRadius: 40,
        offset: const Offset(0, 0),
        spreadRadius: 0,
      ),
    ],
  );
  
  static BoxDecoration get softGlow => BoxDecoration(
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withOpacity(0.1),
        blurRadius: 30,
        offset: const Offset(0, 10),
        spreadRadius: 0,
      ),
    ],
  );
  
  // Animation Curves
  static const Curve bounceCurve = Curves.bounceOut;
  static const Curve elasticCurve = Curves.elasticOut;
  static const Curve smoothCurve = Curves.easeInOutCubic;
  static const Curve fastCurve = Curves.fastOutSlowIn;
}
