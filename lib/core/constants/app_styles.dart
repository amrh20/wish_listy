import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppStyles {
  // Beautiful Text Styles with Readex Pro Font (Trendy & Catchy)
  // Font sizes optimized for mobile screens
  static TextStyle get heading1 => GoogleFonts.readexPro(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    height: 1.1,
    letterSpacing: -0.5,
  );

  static TextStyle get heading2 => GoogleFonts.readexPro(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: -0.3,
  );

  static TextStyle get heading3 => GoogleFonts.readexPro(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
    letterSpacing: -0.2,
  );

  static TextStyle get heading4 => GoogleFonts.readexPro(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
    letterSpacing: -0.1,
  );

  // Additional text styles - optimized sizes
  static TextStyle get headingLarge => GoogleFonts.readexPro(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static TextStyle get headingMedium => GoogleFonts.readexPro(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle get headingSmall => GoogleFonts.readexPro(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static TextStyle get bodyLarge => GoogleFonts.readexPro(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.readexPro(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static TextStyle get bodySmall => GoogleFonts.readexPro(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static TextStyle get caption => GoogleFonts.readexPro(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
    height: 1.3,
  );

  static TextStyle get button => GoogleFonts.readexPro(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textWhite,
    height: 1.4,
    letterSpacing: 0.2,
  );

  static TextStyle get overline => const TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.textTertiary,
    height: 1.2,
    letterSpacing: 1.5,
    fontFamily: 'Inter',
  );

  // Enhanced Card Styles with Beautiful Shadows
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: AppColors.textTertiary.withOpacity(0.1),
        blurRadius: 25,
        offset: const Offset(0, 8),
        spreadRadius: 0,
      ),
      BoxShadow(
        color: AppColors.textTertiary.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 2),
        spreadRadius: 0,
      ),
    ],
  );

  static BoxDecoration get cardDecorationLight => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: AppColors.textTertiary.withOpacity(0.05),
        blurRadius: 15,
        offset: const Offset(0, 4),
        spreadRadius: 0,
      ),
    ],
  );

  static BoxDecoration get cardDecorationHover => BoxDecoration(
    color: AppColors.surfaceVariant,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: AppColors.textTertiary.withOpacity(0.2),
        blurRadius: 30,
        offset: const Offset(0, 12),
        spreadRadius: 0,
      ),
    ],
  );

  // Glassmorphism Card Style
  static BoxDecoration get glassCardDecoration => BoxDecoration(
    color: const Color(0x80FFFFFF),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: AppColors.surfaceVariant, width: 1),
    boxShadow: [
      BoxShadow(
        color: AppColors.textTertiary.withOpacity(0.05),
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
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
    textStyle: button.copyWith(color: AppColors.primary),
  );

  static ButtonStyle get gradientButton => ElevatedButton.styleFrom(
    backgroundColor: Colors.transparent,
    foregroundColor: AppColors.textWhite,
    elevation: 0,
    shadowColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    hintStyle: bodyMedium.copyWith(color: AppColors.textTertiary),
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
