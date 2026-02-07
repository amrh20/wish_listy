import 'package:flutter/foundation.dart';

enum FriendWishlistPrivacy { public, friends, private, unknown }

FriendWishlistPrivacy friendWishlistPrivacyFromJson(dynamic value) {
  final v = value?.toString().toLowerCase();
  switch (v) {
    case 'public':
      return FriendWishlistPrivacy.public;
    case 'friends':
    case 'friends_only':
    case 'friends-only':
      return FriendWishlistPrivacy.friends;
    case 'private':
      return FriendWishlistPrivacy.private;
    default:
      return FriendWishlistPrivacy.unknown;
  }
}

@immutable
class FriendWishlistOwnerModel {
  final String fullName;
  final String username;

  const FriendWishlistOwnerModel({
    required this.fullName,
    required this.username,
  });

  factory FriendWishlistOwnerModel.fromJson(Map<String, dynamic> json) {
    return FriendWishlistOwnerModel(
      fullName: json['fullName']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
    );
  }
}

@immutable
class PreviewItem {
  final String? id;
  final String? name;
  final String? image;

  const PreviewItem({
    this.id,
    this.name,
    this.image,
  });

  factory PreviewItem.fromJson(Map<String, dynamic> json) {
    return PreviewItem(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      name: json['name']?.toString(),
      image: json['image']?.toString() ?? json['imageUrl']?.toString(),
    );
  }
}

@immutable
class FriendWishlistModel {
  final String id;
  final String name;
  final String? description;
  final FriendWishlistPrivacy privacy;
  final String? category;
  final FriendWishlistOwnerModel? owner;
  final int itemCount;
  final List<PreviewItem> previewItems;
  final DateTime? createdAt;

  const FriendWishlistModel({
    required this.id,
    required this.name,
    this.description,
    required this.privacy,
    this.category,
    this.owner,
    required this.itemCount,
    this.previewItems = const [],
    this.createdAt,
  });

  factory FriendWishlistModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['_id'] ?? json['id'];
    DateTime? createdAt;
    final createdRaw = json['createdAt'] ?? json['created_at'];
    if (createdRaw != null) {
      try {
        createdAt = DateTime.parse(createdRaw.toString());
      } catch (_) {}
    }

    final ownerJson = json['owner'];
    
    // Parse previewItems array
    List<PreviewItem> previewItems = [];
    final previewItemsJson = json['previewItems'] ?? json['preview_items'];
    if (previewItemsJson is List) {
      previewItems = previewItemsJson
          .map((item) => item is Map<String, dynamic>
              ? PreviewItem.fromJson(item)
              : const PreviewItem())
          .toList();
    }
    
    return FriendWishlistModel(
      id: rawId?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      privacy: friendWishlistPrivacyFromJson(json['privacy']),
      category: json['category']?.toString(),
      owner: ownerJson is Map<String, dynamic>
          ? FriendWishlistOwnerModel.fromJson(ownerJson)
          : null,
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 
                 (json['item_count'] as num?)?.toInt() ?? 0,
      previewItems: previewItems,
      createdAt: createdAt,
    );
  }
}

