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

  // Theme Data
  static ThemeData get lightTheme {
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
      textTheme: GoogleFonts.readexProTextTheme(baseTheme.textTheme).copyWith(
        headlineLarge: heading1,
        headlineMedium: heading2,
        headlineSmall: heading3,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: button,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: surface,
          textStyle: button,
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

  static ThemeData get darkTheme {
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
      textTheme: GoogleFonts.readexProTextTheme(baseTheme.textTheme).copyWith(
        headlineLarge: heading1.copyWith(color: AppColors.textPrimary),
        headlineMedium: heading2.copyWith(color: AppColors.textPrimary),
        headlineSmall: heading3.copyWith(color: AppColors.textPrimary),
        bodyLarge: bodyLarge.copyWith(color: AppColors.textPrimary),
        bodyMedium: bodyMedium.copyWith(color: AppColors.textPrimary),
        bodySmall: bodySmall.copyWith(color: AppColors.textPrimary),
        labelLarge: button.copyWith(color: AppColors.surface),
      ),
      // Note: For primary action buttons, use PrimaryGradientButton widget instead.
      // This theme is kept for Material defaults and backward compatibility.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: AppColors.surface,
          textStyle: button,
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
