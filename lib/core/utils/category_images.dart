import 'package:flutter/material.dart';

/// Helper class for category images
class CategoryImages {
  /// Get the image path for a category
  static String? getCategoryImagePath(String? category) {
    if (category == null) return null;
    
    switch (category.toLowerCase()) {
      case 'birthday':
        return 'assets/images/categories/Birthday.png';
      case 'wedding':
        return 'assets/images/categories/Wedding.png';
      case 'graduation':
        return 'assets/images/categories/graduation.png';
      case 'babyshower':
      case 'baby_shower':
      case 'baby shower':
        return 'assets/images/categories/baby shower.png';
      case 'christmas':
        return 'assets/images/categories/Christmas.png';
      default:
        return null;
    }
  }

  /// Get a default icon for a category (fallback)
  static IconData getCategoryIcon(String? category) {
    if (category == null) return Icons.favorite_rounded;
    
    switch (category.toLowerCase()) {
      case 'birthday':
        return Icons.cake_rounded;
      case 'wedding':
        return Icons.favorite_rounded;
      case 'graduation':
        return Icons.school_rounded;
      case 'babyshower':
      case 'baby_shower':
      case 'baby shower':
        return Icons.child_care_rounded;
      case 'christmas':
        return Icons.card_giftcard_rounded;
      case 'anniversary':
        return Icons.celebration_rounded;
      default:
        return Icons.favorite_rounded;
    }
  }
}

