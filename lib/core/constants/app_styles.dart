import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';
import '../utils/accessibility_utils.dart';
import '../services/localization_service.dart';

class AppStyles {
  // Static cache for current language (updated when language changes)
  static String _cachedLanguage = 'en';

  // Initialize cached language (call this during app startup)
  static Future<void> initializeLanguageCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedLanguage = prefs.getString('selected_language') ?? 'en';
    } catch (e) {
      _cachedLanguage = 'en';
    }
  }

  // Update cached language (call this when language changes)
  static void updateLanguageCache(String languageCode) {
    _cachedLanguage = languageCode;
  }

  // Get current language synchronously (uses cache)
  static String _getCurrentLanguage() {
    return _cachedLanguage;
  }
  // Icon size constants for standardization
  static const double iconSizeSmall = AccessibilityUtils.iconSizeSmall;
  static const double iconSizeMedium = AccessibilityUtils.iconSizeMedium;
  static const double iconSizeLarge = AccessibilityUtils.iconSizeLarge;
  static const double iconSizeExtraLarge = AccessibilityUtils.iconSizeExtraLarge;

  // Helper method to get text style with accessibility support
  static TextStyle _getTextStyle({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? height,
    double? letterSpacing,
    BuildContext? context,
    double? minSize,
  }) {
    // Calculate scaled font size if context is provided
    final finalFontSize = context != null
        ? AccessibilityUtils.getScaledFontSize(
            context,
            fontSize,
            minSize: minSize ?? AccessibilityUtils.minFontSize,
          )
        : fontSize;

    // Check if Arabic language is being used
    bool isArabic = false;
    if (context != null) {
      try {
        final localization = Provider.of<LocalizationService>(context, listen: false);
        isArabic = localization.currentLanguage == 'ar';
        // Update cache when we successfully get language from context
        _cachedLanguage = localization.currentLanguage;
      } catch (e) {
        // If Provider is not available, use cached language
        isArabic = _getCurrentLanguage() == 'ar';
      }
    } else {
      // When context is null, use cached language
      isArabic = _getCurrentLanguage() == 'ar';
    }

    // Use Alexandria for Arabic, Ubuntu for English
    if (isArabic) {
      return GoogleFonts.alexandria(
        fontSize: finalFontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );
    } else {
      return GoogleFonts.ubuntu(
        fontSize: finalFontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );
    }
  }

  // Beautiful Text Styles with Ubuntu Font for English, Alexandria for Arabic
  // Font sizes optimized for mobile screens with accessibility support
  
  // Context-aware methods for accessibility (use these when you have BuildContext)
  static TextStyle heading1WithContext(BuildContext context) => _getTextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        height: 1.1,
        letterSpacing: -0.5,
        context: context,
      );

  static TextStyle heading2WithContext(BuildContext context) => _getTextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.2,
        letterSpacing: -0.3,
        context: context,
      );

  static TextStyle heading3WithContext(BuildContext context) => _getTextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
        letterSpacing: -0.2,
        context: context,
      );

  static TextStyle heading4WithContext(BuildContext context) => _getTextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.4,
        letterSpacing: -0.1,
        context: context,
      );

  // Additional text styles - optimized sizes
  static TextStyle headingLargeWithContext(BuildContext context) => _getTextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.2,
        context: context,
      );

  static TextStyle headingMediumWithContext(BuildContext context) => _getTextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
        context: context,
      );

  static TextStyle headingSmallWithContext(BuildContext context) => _getTextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
        context: context,
      );

  static TextStyle bodyLargeWithContext(BuildContext context) => _getTextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
        context: context,
      );

  static TextStyle bodyMediumWithContext(BuildContext context) => _getTextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
        context: context,
        minSize: AccessibilityUtils.minFontSize,
      );

  static TextStyle bodySmallWithContext(BuildContext context) => _getTextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.4,
        context: context,
        minSize: AccessibilityUtils.minFontSize,
      );

  static TextStyle captionWithContext(BuildContext context) => _getTextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        color: AppColors.textTertiary,
        height: 1.3,
        context: context,
        minSize: AccessibilityUtils.minFontSize,
      );

  // Getters for backward compatibility (default styles without scaling)
  static TextStyle get heading1 => _getTextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        height: 1.1,
        letterSpacing: -0.5,
      );

  static TextStyle get heading2 => _getTextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        height: 1.2,
        letterSpacing: -0.3,
      );

  static TextStyle get heading3 => _getTextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
        letterSpacing: -0.2,
      );

  static TextStyle get heading4 => _getTextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.4,
        letterSpacing: -0.1,
      );

  static TextStyle get headingLarge => _getTextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        height: 1.2,
      );

  static TextStyle get headingMedium => _getTextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get headingSmall => _getTextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  static TextStyle get bodyLarge => _getTextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get bodyMedium => _getTextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
        minSize: AccessibilityUtils.minFontSize,
      );

  static TextStyle get bodySmall => _getTextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.4,
        minSize: AccessibilityUtils.minFontSize,
      );

  static TextStyle get caption => _getTextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        color: AppColors.textTertiary,
        height: 1.3,
        minSize: AccessibilityUtils.minFontSize,
      );

  // Button style - needs context for language detection
  // For backward compatibility, this defaults to Ubuntu
  // Use buttonWithContext when you have BuildContext available
  static TextStyle get button => GoogleFonts.ubuntu(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textWhite,
    height: 1.4,
    letterSpacing: 0.2,
  );

  // Context-aware button style that uses Alexandria for Arabic
  static TextStyle buttonWithContext(BuildContext context) {
    try {
      final localization = Provider.of<LocalizationService>(context, listen: false);
      final isArabic = localization.currentLanguage == 'ar';
      
      if (isArabic) {
        return GoogleFonts.alexandria(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textWhite,
          height: 1.4,
          letterSpacing: 0.2,
        );
      }
    } catch (e) {
      // Fallback to default if Provider is not available
    }
    
    return GoogleFonts.ubuntu(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.textWhite,
      height: 1.4,
      letterSpacing: 0.2,
    );
  }

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
  // Note: For new primary buttons, use PrimaryGradientButton widget instead.
  // This style is kept for backward compatibility.
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
