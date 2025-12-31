import 'package:flutter/foundation.dart';

@immutable
class FriendProfileUserModel {
  final String id;
  final String fullName;
  final String username; // Legacy field - kept for backward compatibility
  final String? handle; // Public handle (e.g., "@amr_hamdy_99")
  final String? profileImage;
  final DateTime? createdAt;

  const FriendProfileUserModel({
    required this.id,
    required this.fullName,
    required this.username,
    this.handle,
    this.profileImage,
    this.createdAt,
  });

  factory FriendProfileUserModel.fromJson(Map<String, dynamic> json) {
    DateTime? createdAt;
    final createdRaw = json['createdAt'] ?? json['created_at'];
    if (createdRaw != null) {
      try {
        createdAt = DateTime.parse(createdRaw.toString());
      } catch (_) {}
    }
    return FriendProfileUserModel(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      handle: json['handle']?.toString(),
      profileImage: json['profileImage']?.toString(),
      createdAt: createdAt,
    );
  }

  /// Get display handle for UI - returns @handle if available, otherwise "User #ID"
  String getDisplayHandle() {
    if (handle != null && handle!.isNotEmpty) {
      return handle!.startsWith('@') ? handle! : '@$handle';
    }
    return 'User #$id';
  }
}

@immutable
class FriendProfileCountsModel {
  final int wishlists;
  final int events;
  final int friends;

  const FriendProfileCountsModel({
    required this.wishlists,
    required this.events,
    required this.friends,
  });

  factory FriendProfileCountsModel.fromJson(Map<String, dynamic> json) {
    int readInt(List<String> keys) {
      for (final k in keys) {
        final v = json[k];
        if (v != null) {
          if (v is num) return v.toInt();
          if (v is String) {
            final parsed = int.tryParse(v);
            if (parsed != null) return parsed;
          }
        }
      }
      return 0;
    }

    return FriendProfileCountsModel(
      // Support both {counts:{wishlists/events/friends}} and flat API keys
      // Priority: camelCase keys first (wishlistCount, eventsCount, friendsCount)
      wishlists: readInt(const ['wishlistCount', 'wishlistsCount', 'wishlists']),
      events: readInt(const ['eventsCount', 'events']),
      friends: readInt(const ['friendsCount', 'friends']),
    );
  }
}

@immutable
class FriendProfileFriendshipStatusModel {
  final bool isFriend;
  final String? status;

  const FriendProfileFriendshipStatusModel({
    required this.isFriend,
    this.status,
  });

  factory FriendProfileFriendshipStatusModel.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['status'] ??
            json['friendshipStatus'] ??
            json['friendship_status'] ??
            json['state'])
        ?.toString()
        .toLowerCase();

    final boolFlag = json['isFriend'] == true ||
        json['is_friend'] == true ||
        json['friends'] == true ||
        json['isFriends'] == true;

    final statusImpliesFriend = rawStatus == 'accepted' ||
        rawStatus == 'friends' ||
        rawStatus == 'friend' ||
        rawStatus == 'connected';

    return FriendProfileFriendshipStatusModel(
      isFriend: boolFlag || statusImpliesFriend,
      status: rawStatus,
    );
  }
}

@immutable
class FriendProfileModel {
  final FriendProfileUserModel user;
  final FriendProfileCountsModel counts;
  final FriendProfileFriendshipStatusModel friendshipStatus;

  const FriendProfileModel({
    required this.user,
    required this.counts,
    required this.friendshipStatus,
  });

  factory FriendProfileModel.fromJson(Map<String, dynamic> json) {
    // Shape A (documented):
    // { user: {...}, counts: {...}, friendshipStatus: {isFriend:true} }
    // Shape B (seen in runtime):
    // { _id, fullName, username, profileImage, friendsCount, wishlistCount, eventsCount, ... }

    final hasNestedUser = json['user'] is Map<String, dynamic>;
    if (hasNestedUser) {
      final userJson = (json['user'] as Map<String, dynamic>?) ?? const {};
      final countsJson = (json['counts'] as Map<String, dynamic>?) ?? const {};
      final friendshipRaw = json['friendshipStatus'] ?? json['friendship_status'];
      final friendshipJson = friendshipRaw is Map<String, dynamic>
          ? friendshipRaw
          : (friendshipRaw is String
              ? <String, dynamic>{'status': friendshipRaw}
              : const <String, dynamic>{});
      return FriendProfileModel(
        user: FriendProfileUserModel.fromJson(userJson),
        counts: FriendProfileCountsModel.fromJson(countsJson),
        friendshipStatus:
            FriendProfileFriendshipStatusModel.fromJson(friendshipJson),
      );
    }

    final friendshipRaw = json['friendshipStatus'] ?? json['friendship_status'];
    final friendshipJson = friendshipRaw is Map<String, dynamic>
        ? friendshipRaw
        : (friendshipRaw is String
            ? <String, dynamic>{'status': friendshipRaw}
            : const <String, dynamic>{});
    return FriendProfileModel(
      user: FriendProfileUserModel.fromJson(json),
      // counts may be embedded as flat keys
      counts: FriendProfileCountsModel.fromJson(json),
      friendshipStatus: friendshipJson.isNotEmpty
          ? FriendProfileFriendshipStatusModel.fromJson(friendshipJson)
          : const FriendProfileFriendshipStatusModel(isFriend: false),
    );
  }
}


