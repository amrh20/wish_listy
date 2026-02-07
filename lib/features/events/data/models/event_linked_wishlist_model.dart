import 'package:flutter/foundation.dart';

enum EventWishlistPrivacy { public, friends, private, unknown }
EventWishlistPrivacy eventWishlistPrivacyFromJson(dynamic value) {
  final v = value?.toString().toLowerCase();
  switch (v) {
    case 'public':
      return EventWishlistPrivacy.public;
    case 'friends':
    case 'friends_only':
    case 'friends-only':
      return EventWishlistPrivacy.friends;
    case 'private':
      return EventWishlistPrivacy.private;
    default:
      return EventWishlistPrivacy.unknown;
  }
}

enum EventItemPriority { low, medium, high, unknown }
EventItemPriority eventItemPriorityFromJson(dynamic value) {
  final v = value?.toString().toLowerCase();
  switch (v) {
    case 'low':
      return EventItemPriority.low;
    case 'medium':
      return EventItemPriority.medium;
    case 'high':
      return EventItemPriority.high;
    default:
      return EventItemPriority.unknown;
  }
}

enum EventItemStatus { available, reserved, purchased, unknown }
EventItemStatus eventItemStatusFromJson(dynamic value) {
  final v = value?.toString().toLowerCase();
  switch (v) {
    case 'available':
      return EventItemStatus.available;
    case 'reserved':
      return EventItemStatus.reserved;
    case 'purchased':
      return EventItemStatus.purchased;
    default:
      return EventItemStatus.unknown;
  }
}

@immutable
class EventLinkedWishlistOwnerModel {
  final String fullName;
  final String username;

  const EventLinkedWishlistOwnerModel({
    required this.fullName,
    required this.username,
  });

  factory EventLinkedWishlistOwnerModel.fromJson(Map<String, dynamic> json) {
    return EventLinkedWishlistOwnerModel(
      fullName: json['fullName']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
    );
  }
}

@immutable
class EventLinkedWishlistItemModel {
  final String id;
  final String name;
  final String? description;
  final String? image;
  final EventItemPriority priority;
  final int quantity;
  final EventItemStatus itemStatus;
  final bool isReservedByMe;
  final int totalReserved;
  final int remainingQuantity;

  const EventLinkedWishlistItemModel({
    required this.id,
    required this.name,
    this.description,
    this.image,
    required this.priority,
    required this.quantity,
    required this.itemStatus,
    required this.isReservedByMe,
    required this.totalReserved,
    required this.remainingQuantity,
  });

  factory EventLinkedWishlistItemModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['_id'] ?? json['id'];
    return EventLinkedWishlistItemModel(
      id: rawId?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      image: json['image']?.toString(),
      priority: eventItemPriorityFromJson(json['priority']),
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      itemStatus: eventItemStatusFromJson(json['itemStatus']),
      isReservedByMe: json['isReservedByMe'] == true,
      totalReserved: (json['totalReserved'] as num?)?.toInt() ?? 0,
      remainingQuantity: (json['remainingQuantity'] as num?)?.toInt() ?? 0,
    );
  }
}

@immutable
class EventLinkedWishlistModel {
  final String id;
  final String name;
  final String? description;
  final EventWishlistPrivacy privacy;
  final EventLinkedWishlistOwnerModel? owner;
  final List<EventLinkedWishlistItemModel> items;

  const EventLinkedWishlistModel({
    required this.id,
    required this.name,
    this.description,
    required this.privacy,
    this.owner,
    this.items = const [],
  });

  factory EventLinkedWishlistModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['_id'] ?? json['id'];
    final ownerJson = json['owner'];
    final itemsJson = json['items'] as List<dynamic>? ?? const [];
    final items = itemsJson
        .whereType<Map>()
        .map((e) => EventLinkedWishlistItemModel.fromJson(
              e.cast<String, dynamic>(),
            ))
        .toList();

    return EventLinkedWishlistModel(
      id: rawId?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      privacy: eventWishlistPrivacyFromJson(json['privacy']),
      owner: ownerJson is Map<String, dynamic>
          ? EventLinkedWishlistOwnerModel.fromJson(ownerJson)
          : null,
      items: items,
    );
  }
}

