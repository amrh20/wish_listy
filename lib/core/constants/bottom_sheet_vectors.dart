/// Bottom sheet vector types and asset paths
enum BottomSheetVectorType {
  /// Menu actions (edit, share, delete)
  menu,

  /// Friend selection and invitation
  friends,

  /// Creating wishlists, events, items
  creation,

  /// Sort and filter options
  filter,

  /// Settings and profile preferences
  settings,

  /// Success and celebration actions
  celebration,
}

/// Extension to get asset path for each vector type
extension BottomSheetVectorTypeExtension on BottomSheetVectorType {
  /// Get the asset path for this vector type
  /// Returns null if image doesn't exist (will fallback to icon)
  String? get assetPath {
    switch (this) {
      case BottomSheetVectorType.menu:
        return null; // Removed: 'assets/vectors/bottom_sheets/menu_character.png';
      case BottomSheetVectorType.friends:
        return 'assets/vectors/bottom_sheets/friends_character.png';
      case BottomSheetVectorType.creation:
        return null; // Removed: 'assets/vectors/bottom_sheets/creation_character.png';
      case BottomSheetVectorType.filter:
        return 'assets/vectors/bottom_sheets/filter_character.png';
      case BottomSheetVectorType.settings:
        return 'assets/vectors/bottom_sheets/settings_character.png';
      case BottomSheetVectorType.celebration:
        return 'assets/vectors/bottom_sheets/celebration_character.png';
    }
  }

  /// Get a description of what this vector type is used for
  String get description {
    switch (this) {
      case BottomSheetVectorType.menu:
        return 'Menu actions like edit, share, and delete';
      case BottomSheetVectorType.friends:
        return 'Friend selection and invitation screens';
      case BottomSheetVectorType.creation:
        return 'Creating wishlists, events, or adding items';
      case BottomSheetVectorType.filter:
        return 'Sort and filter options';
      case BottomSheetVectorType.settings:
        return 'Settings and profile preferences';
      case BottomSheetVectorType.celebration:
        return 'Success actions and celebrations';
    }
  }
}

