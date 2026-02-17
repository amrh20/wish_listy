import 'package:flutter/material.dart';

class AppColors {
  // ===========================================================================
  // 1. BRAND COLORS (The Core Identity)
  // ===========================================================================

  // Primary: Royal Purple (Trust, Luxury, Creativity)
  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryLight = Color(0xFFA78BFA);
  static const Color primaryDark = Color(0xFF5B21B6);

  // Secondary: Teal (Balance, Freshness - Great contrast with Purple)
  static const Color secondary = Color(0xFF14B8A6);
  static const Color secondaryLight = Color(0xFF2DD4BF);
  static const Color secondaryDark = Color(0xFF0F766E);

  // Accent: Hot Pink (Playful, Action - Better than Red for "Gifts")
  // UX Note: Use this for FABs, CTAs, or "Love" icons.
  static const Color accent = Color(0xFFEC4899);
  static const Color accentLight = Color(0xFFF472B6);

  // ===========================================================================
  // 2. SEMANTIC COLORS (Functional Meanings)
  // ===========================================================================

  // Error: Red (Destructive actions only)
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFF87171);

  // Success: Green (Completed actions)
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF34D399);

  // Warning: Amber (Alerts)
  static const Color warning = Color(0xFFF59E0B);

  // Info: Blue (Links, Information)
  static const Color info = Color(0xFF3B82F6);

  // Purchased (Light blue – professional, distinct from Gifted green)
  static const Color purchasedLight = Color(0xFFE3F2FD); // Light blue background
  static const Color purchased = Color(0xFF1565C0);       // Dark blue text/icon

  // ===========================================================================
  // 3. NEUTRAL COLORS (Backgrounds & Text)
  // ===========================================================================

  static const Color background = Color(0xFFF8FAFC); // Very light blue-grey
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  static const Color textPrimary = Color(0xFF1E293B); // Almost Black
  static const Color textSecondary = Color(0xFF475569); // Dark Grey
  static const Color textTertiary = Color(
    0xFF94A3B8,
  ); // Light Grey (Placeholder)
  static const Color textWhite = Color(0xFFFFFFFF);

  static const Color border = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFFCBD5E1);

  // ===========================================================================
  // 4. UI SPECIFIC (Cards & Decor)
  // ===========================================================================

  // Pastel Colors (Perfect for Wishlist Categories/Cards)
  // Kept these because they fit the "Gift" theme nicely
  static const Color cardBlue = Color(0xFFE0F4FF);
  static const Color cardPurple = Color(0xFFF3E8FF);
  static const Color cardGreen = Color(0xFFE8FFF3);
  static const Color cardPink = Color(0xFFFFE8F0);
  static const Color cardPeach = Color(0xFFFFF4E8);

  // Border colors for cards (Organized matching the pastels)
  static const Color cardBlueBorder = Color(0xFFB3E0FF);
  static const Color cardPurpleBorder = Color(0xFFE0C8FF);
  static const Color cardGreenBorder = Color(0xFFC8FFE0);
  static const Color cardPinkBorder = Color(0xFFFFCDD8);
  static const Color cardPeachBorder = Color(0xFFFFE0C8);

  static const List<Color> pastelCards = [
    cardBlue,
    cardPurple,
    cardGreen,
    cardPink,
    cardPeach,
  ];

  // Auth Specific (Moved here to be official)
  static const Color authBackground = Color(0xFFF8F9FF);

  // ===========================================================================
  // 5. GRADIENTS (Reduced to Essentials)
  // ===========================================================================

  // Use this for the Main App Bar or Primary Buttons
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      primary,
      Color(0xFF8B5CF6),
    ], // Smooth transition to slightly lighter purple
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Use this for "Premium" or "Special" badges
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Use this for Background overlays
  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x80FFFFFF), Color(0x80F8FAFC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ===========================================================================
  // 6. HIGH CONTRAST COLORS (Accessibility for Seniors)
  // ===========================================================================

  // High contrast variants for better visibility
  static const Color primaryHighContrast = Color(0xFF5B21B6); // Darker purple
  static const Color secondaryHighContrast = Color(0xFF0F766E); // Darker teal
  static const Color textPrimaryHighContrast = Color(0xFF000000); // Pure black
  static const Color textSecondaryHighContrast = Color(0xFF1E293B); // Dark grey
  static const Color backgroundHighContrast = Color(0xFFFFFFFF); // Pure white
  static const Color surfaceHighContrast = Color(0xFFFFFFFF); // Pure white
  static const Color borderHighContrast = Color(0xFF000000); // Pure black

  /// Get color based on high contrast preference
  static Color getColor(BuildContext context, {
    required Color normalColor,
    required Color highContrastColor,
  }) {
    final isHighContrast = MediaQuery.of(context).highContrast;
    return isHighContrast ? highContrastColor : normalColor;
  }
}
