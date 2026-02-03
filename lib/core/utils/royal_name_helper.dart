/// Utility class for checking if a name matches "Royal Names"
/// (An Easter Egg feature for specific family members)
class RoyalNameHelper {
  // List of royal names (case-insensitive)
  static const List<String> _royalNames = [
    'nelly',
    'marwa',
    'نيللي',
    'مروه',
    'مروة',
  ];

  /// Normalizes Arabic text by replacing 'ة' with 'ه'
  /// This allows "مروة" and "مروه" to be treated as the same
  static String _normalizeArabic(String text) {
    return text.replaceAll('ة', 'ه');
  }

  /// Checks if the given full name contains any royal name
  /// 
  /// [fullName] - The user's full name to check
  /// 
  /// Returns true if the name matches any royal name (case-insensitive, Arabic normalized)
  /// 
  /// TODO: Feature temporarily disabled - re-enable when needed
  /// This feature displays a crown icon above the profile avatar for specific names (Marwa, Nelly)
  static bool isRoyalName(String fullName) {
    // FEATURE TEMPORARILY DISABLED - Return false to disable crown tag display
    // To re-enable: Remove the return statement below and uncomment the logic
    return false;

    // Original logic (commented out - re-enable when needed):
    // if (fullName.isEmpty) return false;
    //
    // // Convert to lowercase and normalize Arabic
    // final normalizedName = _normalizeArabic(fullName.toLowerCase().trim());
    //
    // // Check if any royal name is contained in the normalized name
    // for (final royalName in _royalNames) {
    //   final normalizedRoyalName = _normalizeArabic(royalName.toLowerCase());
    //   if (normalizedName.contains(normalizedRoyalName)) {
    //     return true;
    //   }
    // }
    //
    // return false;
  }
}

