import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wish_listy/core/constants/app_colors.dart';

class AppTheme {
  // Colors - Reference AppColors for consistency
  static Color get primary => AppColors.primary;
  static Color get primaryLight => AppColors.primaryLight;
  static Color get primaryDark => AppColors.primaryDark;

  static Color get secondary => AppColors.secondary;
  static Color get secondaryLight => AppColors.secondaryLight;
  static Color get secondaryDark => AppColors.secondaryDark;

  static Color get accent => AppColors.accent;
  static Color get success => AppColors.success;
  static Color get warning => AppColors.warning;
  static Color get error => AppColors.error;

  static Color get background => AppColors.background;
  static Color get surface => AppColors.surface;
  static Color get onSurface => AppColors.textPrimary;

  // Text Styles
  static TextStyle get heading1 => GoogleFonts.readexPro(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: onSurface,
  );

  static TextStyle get heading2 => GoogleFonts.readexPro(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: onSurface,
  );

  static TextStyle get heading3 => GoogleFonts.readexPro(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: onSurface,
  );

  static TextStyle get bodyLarge => GoogleFonts.readexPro(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: onSurface,
  );

  static TextStyle get bodyMedium => GoogleFonts.readexPro(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: onSurface,
  );

  static TextStyle get bodySmall => GoogleFonts.readexPro(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: onSurface,
  );

  static TextStyle get button => GoogleFonts.readexPro(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: surface,
  );

  // Spacing
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 16.0; // Updated to match AppStyles.primaryButton
  static const double radiusLarge = 20.0;
  static const double radiusXLarge = 24.0;

  // Shadows
  static List<BoxShadow> get shadowSmall => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get shadowMedium => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get shadowLarge => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  // Helper method to create locale-aware TextTheme
  static TextTheme _getTextTheme(Locale locale, ThemeData baseTheme, {bool isDark = false}) {
    final isArabic = locale.languageCode == 'ar';
    final textColor = isDark ? AppColors.textPrimary : onSurface;

    if (isArabic) {
      // Use Alexandria for Arabic
      return GoogleFonts.alexandriaTextTheme(baseTheme.textTheme).copyWith(
        displayLarge: GoogleFonts.alexandria(
          fontSize: 57,
          fontWeight: FontWeight.w400,
          color: textColor,
        ),
        displayMedium: GoogleFonts.alexandria(
          fontSize: 45,
          fontWeight: FontWeight.w400,
          color: textColor,
        ),
        displaySmall: GoogleFonts.alexandria(
          fontSize: 36,
          fontWeight: FontWeight.w400,
          color: textColor,
        ),
        headlineLarge: GoogleFonts.alexandria(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
        headlineMedium: GoogleFonts.alexandria(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
        headlineSmall: GoogleFonts.alexandria(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        titleLarge: GoogleFonts.alexandria(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        titleMedium: GoogleFonts.alexandria(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        titleSmall: GoogleFonts.alexandria(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        bodyLarge: GoogleFonts.alexandria(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textColor,
        ),
        bodyMedium: GoogleFonts.alexandria(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textColor,
        ),
        bodySmall: GoogleFonts.alexandria(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: textColor,
        ),
        labelLarge: GoogleFonts.alexandria(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.surface : surface,
        ),
        labelMedium: GoogleFonts.alexandria(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        labelSmall: GoogleFonts.alexandria(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      );
    } else {
      // Use Ubuntu for English
      return GoogleFonts.ubuntuTextTheme(baseTheme.textTheme).copyWith(
        headlineLarge: heading1.copyWith(color: textColor),
        headlineMedium: heading2.copyWith(color: textColor),
        headlineSmall: heading3.copyWith(color: textColor),
        bodyLarge: bodyLarge.copyWith(color: textColor),
        bodyMedium: bodyMedium.copyWith(color: textColor),
        bodySmall: bodySmall.copyWith(color: textColor),
        labelLarge: button.copyWith(color: isDark ? AppColors.surface : surface),
      );
    }
  }

  // Theme Data
  static ThemeData lightTheme({Locale? locale}) {
    final currentLocale = locale ?? const Locale('en');
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: surface,
        onSurface: onSurface,
        error: error,
      ),
    );
    
    return baseTheme.copyWith(
      textTheme: _getTextTheme(currentLocale, baseTheme, isDark: false),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: surface,
          textStyle: _getTextTheme(currentLocale, baseTheme, isDark: false).labelLarge,
          padding: const EdgeInsets.symmetric(
            horizontal: spacing24,
            vertical: spacing12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          elevation: 0,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        shadowColor: Colors.black.withValues(alpha: 0.1),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing12,
        ),
      ),
    );
  }

  static ThemeData darkTheme({Locale? locale}) {
    final currentLocale = locale ?? const Locale('en');
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: error,
      ),
    );
    
    return baseTheme.copyWith(
      textTheme: _getTextTheme(currentLocale, baseTheme, isDark: true),
      // Note: For primary action buttons, use PrimaryGradientButton widget instead.
      // This theme is kept for Material defaults and backward compatibility.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: AppColors.surface,
          textStyle: _getTextTheme(currentLocale, baseTheme, isDark: true).labelLarge,
          padding: const EdgeInsets.symmetric(
            horizontal: spacing24,
            vertical: spacing12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          elevation: 0,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        shadowColor: Colors.black.withValues(alpha: 0.3),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing12,
        ),
      ),
    );
  }
}
