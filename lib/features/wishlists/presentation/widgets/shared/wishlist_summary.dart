import 'package:wish_listy/features/wishlists/data/models/wishlist_model.dart';

/// Model for wishlist privacy settings
enum WishlistPrivacy { public, private, onlyInvited }

/// Model for wishlist summary data
class WishlistSummary {
  final String id;
  final String name;
  final String? description;
  final int itemCount;
  final int purchasedCount;
  final DateTime lastUpdated;
  final WishlistPrivacy privacy;
  final String? imageUrl;
  final String? eventName;
  final DateTime? eventDate;
  final String? category;
  final List<WishlistItem> previewItems;

  WishlistSummary({
    required this.id,
    required this.name,
    this.description,
    required this.itemCount,
    required this.purchasedCount,
    required this.lastUpdated,
    this.privacy = WishlistPrivacy.public,
    this.imageUrl,
    this.eventName,
    this.eventDate,
    this.category,
    this.previewItems = const [],
  });
}
