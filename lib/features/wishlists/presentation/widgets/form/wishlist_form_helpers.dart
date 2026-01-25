import 'package:flutter/material.dart';
import 'package:wish_listy/core/services/localization_service.dart';

/// Helper class for wishlist form utilities (privacy, category helpers)
class WishlistFormHelpers {
  /// Get privacy icon based on privacy type
  static IconData getPrivacyIcon(String privacy) {
    switch (privacy) {
      case 'public':
        return Icons.public;
      case 'private':
        return Icons.lock;
      case 'friends':
        return Icons.people;
      default:
        return Icons.public;
    }
  }

  /// Get privacy title based on privacy type
  static String getPrivacyTitle(
      String privacy, LocalizationService localization) {
    switch (privacy) {
      case 'public':
        return localization.translate('wishlists.public');
      case 'private':
        return localization.translate('wishlists.private');
      case 'friends':
        return localization.translate('wishlists.friendsOnly');
      default:
        return privacy;
    }
  }

  /// Get privacy description based on privacy type
  static String getPrivacyDescription(
    String privacy,
    LocalizationService localization,
  ) {
    switch (privacy) {
      case 'public':
        return localization.translate('events.publicDescription');
      case 'private':
        return localization.translate('events.privateDescription');
      case 'friends':
        return localization.translate('events.friendsOnlyDescription');
      default:
        return '';
    }
  }

  /// Get category display name based on category type
  static String getCategoryDisplayName(
    String category,
    LocalizationService localization,
  ) {
    switch (category) {
      case 'general':
        return localization.translate('common.general');
      case 'birthday':
        return localization.translate('events.birthday');
      case 'wedding':
        return localization.translate('events.wedding');
      case 'graduation':
        return localization.translate('events.graduation');
      case 'anniversary':
        return localization.translate('events.anniversary');
      case 'holiday':
        return localization.translate('common.holiday');
      case 'babyShower':
        return localization.translate('events.babyShower');
      case 'housewarming':
        return localization.translate('events.housewarming');
      case 'custom':
        return localization.translate('events.other');
      default:
        return category;
    }
  }

  /// Get icon for category filter chips
  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'general':
        return Icons.category_outlined;
      case 'birthday':
        return Icons.cake_outlined;
      case 'wedding':
        return Icons.favorite_outline;
      case 'graduation':
        return Icons.school_outlined;
      case 'anniversary':
        return Icons.celebration_outlined;
      case 'holiday':
        return Icons.card_giftcard_outlined;
      case 'babyshower':
        return Icons.child_care_outlined;
      case 'housewarming':
        return Icons.home_outlined;
      case 'custom':
        return Icons.edit_outlined;
      default:
        return Icons.label_outline;
    }
  }
}
