import 'package:flutter/foundation.dart';

enum InvitationStatus { accepted, declined, maybe, pending, unknown }

InvitationStatus invitationStatusFromJson(dynamic value) {
  final v = value?.toString().toLowerCase();
  switch (v) {
    case 'accepted':
      return InvitationStatus.accepted;
    case 'declined':
    case 'rejected':
      return InvitationStatus.declined;
    case 'maybe':
      return InvitationStatus.maybe;
    case 'pending':
      return InvitationStatus.pending;
    default:
      return InvitationStatus.unknown;
  }
}

@immutable
class FriendEventCreatorModel {
  final String fullName;
  final String username;

  const FriendEventCreatorModel({
    required this.fullName,
    required this.username,
  });

  factory FriendEventCreatorModel.fromJson(Map<String, dynamic> json) {
    return FriendEventCreatorModel(
      fullName: json['fullName']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
    );
  }
}

@immutable
class FriendEventWishlistModel {
  final String id;
  final String name;
  final int? itemCount;

  const FriendEventWishlistModel({
    required this.id,
    required this.name,
    this.itemCount,
  });

  factory FriendEventWishlistModel.fromJson(Map<String, dynamic> json) {
    return FriendEventWishlistModel(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      itemCount: json['itemCount'] is num
          ? (json['itemCount'] as num).toInt()
          : json['item_count'] is num
              ? (json['item_count'] as num).toInt()
              : null,
    );
  }
}

@immutable
class FriendEventInvitedFriendModel {
  final String userId;
  final String fullName;
  final String? profileImage;
  final InvitationStatus status;

  const FriendEventInvitedFriendModel({
    required this.userId,
    required this.fullName,
    this.profileImage,
    required this.status,
  });

  factory FriendEventInvitedFriendModel.fromJson(Map<String, dynamic> json) {
    // Support both nested user object and flat structure
    final userJson = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : json;

    return FriendEventInvitedFriendModel(
      userId: (userJson['_id'] ?? userJson['id'])?.toString() ?? '',
      fullName: userJson['fullName']?.toString() ?? '',
      profileImage: userJson['profileImage']?.toString(),
      status: invitationStatusFromJson(json['status']),
    );
  }
}

@immutable
class FriendEventModel {
  final String id;
  final String name;
  final String? description;
  final DateTime? date;
  final String? time;
  final String? type;
  final String? privacy;
  final String? mode;
  final String? location;
  final String? status; // "upcoming", "past", etc.
  final FriendEventCreatorModel? creator;
  final FriendEventWishlistModel? wishlist;
  final InvitationStatus invitationStatus;
  final List<FriendEventInvitedFriendModel> invitedFriends;

  const FriendEventModel({
    required this.id,
    required this.name,
    this.description,
    this.date,
    this.time,
    this.type,
    this.privacy,
    this.mode,
    this.location,
    this.status,
    this.creator,
    this.wishlist,
    required this.invitationStatus,
    this.invitedFriends = const [],
  });

  factory FriendEventModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['_id'] ?? json['id'];
    DateTime? date;
    if (json['date'] != null) {
      try {
        date = DateTime.parse(json['date'].toString());
      } catch (_) {}
    }

    final creatorJson = json['creator'];
    final wishlistJson = json['wishlist'];
    final invitedFriendsJson = json['invited_friends'] ?? json['invitedFriends'];

    List<FriendEventInvitedFriendModel> invitedFriends = [];
    if (invitedFriendsJson is List) {
      invitedFriends = invitedFriendsJson
          .whereType<Map<String, dynamic>>()
          .map((item) => FriendEventInvitedFriendModel.fromJson(item))
          .toList();
    }

    return FriendEventModel(
      id: rawId?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      date: date,
      time: json['time']?.toString(),
      type: json['type']?.toString(),
      privacy: json['privacy']?.toString(),
      mode: json['mode']?.toString(),
      location: json['location']?.toString(),
      status: json['status']?.toString(),
      creator: creatorJson is Map<String, dynamic>
          ? FriendEventCreatorModel.fromJson(creatorJson)
          : null,
      wishlist: wishlistJson is Map<String, dynamic>
          ? FriendEventWishlistModel.fromJson(wishlistJson)
          : null,
      invitationStatus: invitationStatusFromJson(
        json['invitationStatus'] ?? json['invitation_status'],
      ),
      invitedFriends: invitedFriends,
    );
  }
}

