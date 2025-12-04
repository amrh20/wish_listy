import 'package:flutter/material.dart';

class AppColors {
  // Modern Primary Colors - Beautiful Purple Theme
  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryLight = Color(0xFFA78BFA);
  static const Color primaryDark = Color(0xFF5B21B6);
  static const Color primaryAccent = Color(0xFF8B5CF6);

  // Secondary Colors - Soft and Elegant
  static const Color secondary = Color(0xFF14B8A6); // Beautiful teal color
  static const Color secondaryLight = Color(0xFF2DD4BF); // Lighter teal
  static const Color secondaryDark = Color(0xFF0F766E); // Darker teal

  // Accent Colors - Vibrant and Eye-catching
  // Note: accent and error are the same color (0xFFEF4444)
  // accent is kept for backward compatibility, but error is the canonical name
  static Color get accent => error;
  static const Color accentLight = Color(0xFFF87171);
  static const Color accentDark = Color(0xFFDC2626);

  // Success Colors - Fresh and Positive
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF34D399);
  static const Color successDark = Color(0xFF059669);

  // Warning Colors - Warm and Friendly
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color warningDark = Color(0xFFD97706);

  // Info Colors - Cool and Trustworthy
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFF60A5FA);
  static const Color infoDark = Color(0xFF2563EB);

  // Special Colors - Unique and Beautiful
  static const Color pink = Color(0xFFEC4899);
  static const Color pinkLight = Color(0xFFF472B6);
  static const Color indigo = Color(0xFF6366F1);
  static const Color indigoLight = Color(0xFF818CF8);
  // Deprecated: Use secondary and secondaryLight instead
  @Deprecated('Use AppColors.secondary instead')
  static Color get teal => secondary;
  @Deprecated('Use AppColors.secondaryLight instead')
  static Color get tealLight => secondaryLight;
  static const Color orange = Color(0xFFFF6B35);
  static const Color orangeLight = Color(0xFFFF8A65);

  // Text Colors - Perfect Readability
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textLight = Color(0xFF64748B);
  static const Color textWhite = Color(0xFFFFFFFF);
  // Deprecated: Use textTertiary instead
  @Deprecated('Use AppColors.textTertiary instead')
  static Color get textMuted => textTertiary;
  static const Color textTertiary = Color(0xFF94A3B8);

  // Background Colors - Soft and Comfortable
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  // Deprecated: Use surface instead
  @Deprecated('Use AppColors.surface instead')
  static Color get card => surface;
  // Deprecated: Use surfaceVariant instead
  @Deprecated('Use AppColors.surfaceVariant instead')
  static Color get cardHover => surfaceVariant;
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  // Border Colors - Subtle and Elegant
  static const Color border = Color(0xFFE2E8F0);
  // References surfaceVariant to avoid duplication
  static Color get borderLight => surfaceVariant;
  static const Color borderDark = Color(0xFFCBD5E1);

  // Shadow Colors - Soft and Natural
  static const Color shadow = Color(0x1A000000);
  static const Color shadowLight = Color(0x0A000000);
  static const Color shadowDark = Color(0x33000000);

  // Pastel Card Colors - Soft and Modern
  static const Color cardBlue = Color(0xFFE0F4FF);      // Light sky blue
  static const Color cardPurple = Color(0xFFF3E8FF);    // Light lavender  
  static const Color cardGreen = Color(0xFFE8FFF3);     // Light mint
  static const Color cardPink = Color(0xFFFFE8F0);      // Light rose
  static const Color cardPeach = Color(0xFFFFF4E8);     // Light peach

  // Pastel Card Colors List (for easy iteration)
  static const List<Color> pastelCards = [
    cardBlue,
    cardPurple,
    cardGreen,
    cardPink,
  ];

  // Glassmorphism Colors
  static const Color glass = Color(0x80FFFFFF);
  static const Color glassDark = Color(0x80F8FAFC);

  // Dark Theme Colors
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFFCBD5E1);

  // Beautiful Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryAccent, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [error, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, pink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [success, successLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [warning, warningLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient infoGradient = LinearGradient(
    colors: [info, infoLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pinkGradient = LinearGradient(
    colors: [pink, pinkLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient indigoGradient = LinearGradient(
    colors: [indigo, indigoLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient tealGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [orange, orangeLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Radial Gradients for Special Effects
  static const RadialGradient primaryRadial = RadialGradient(
    colors: [primaryLight, primary],
    center: Alignment.center,
    radius: 0.8,
  );

  static const RadialGradient accentRadial = RadialGradient(
    colors: [accentLight, error],
    center: Alignment.center,
    radius: 0.8,
  );

  // Glassmorphism Gradients
  static const LinearGradient glassGradient = LinearGradient(
    colors: [glass, glassDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Error color - Canonical name for accent/error color
  static const Color error = Color(0xFFEF4444);
  
  // Additional colors for hardcoded hex values found in codebase
  // Auth screen background
  static const Color authBackground = Color(0xFFF8F9FF);
  
  // Cyan color used in auth screens
  static const Color cyan = Color(0xFF06B6D4);
  
  // Border colors for pastel cards (matching hardcoded values from unified_page_container)
  static const Color cardBlueBorder = Color(0xFFB3E0FF);
  static const Color cardPurpleBorder = Color(0xFFE0C8FF);
  static const Color cardGreenBorder = Color(0xFFC8FFE0);
  static const Color cardPinkBorder = Color(0xFFFFCDD8);
  static const Color cardPeachBorder = Color(0xFFFFE0C8);
}
