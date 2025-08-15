import 'package:flutter/material.dart';

class AppColors {
  // Modern Primary Colors - Beautiful Purple Theme
  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryLight = Color(0xFFA78BFA);
  static const Color primaryDark = Color(0xFF5B21B6);
  static const Color primaryAccent = Color(0xFF8B5CF6);
  
  // Secondary Colors - Soft and Elegant
  static const Color secondary = Color(0xFFF8FAFC);
  static const Color secondaryLight = Color(0xFFFFFFFF);
  static const Color secondaryDark = Color(0xFFE2E8F0);
  
  // Accent Colors - Vibrant and Eye-catching
  static const Color accent = Color(0xFFEF4444);
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
  static const Color teal = Color(0xFF14B8A6);
  static const Color tealLight = Color(0xFF2DD4BF);
  
  // Text Colors - Perfect Readability
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textLight = Color(0xFF64748B);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textTertiary = Color(0xFF94A3B8);
  
  // Background Colors - Soft and Comfortable
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardHover = Color(0xFFF1F5F9);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  
  // Border Colors - Subtle and Elegant
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color borderDark = Color(0xFFCBD5E1);
  
  // Shadow Colors - Soft and Natural
  static const Color shadow = Color(0x1A000000);
  static const Color shadowLight = Color(0x0A000000);
  static const Color shadowDark = Color(0x33000000);
  
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
    colors: [accent, accentLight],
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
    colors: [teal, tealLight],
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
    colors: [accentLight, accent],
    center: Alignment.center,
    radius: 0.8,
  );
  
  // Glassmorphism Gradients
  static const LinearGradient glassGradient = LinearGradient(
    colors: [glass, glassDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Error and warning colors
  static const Color error = Color(0xFFEF4444);
}
