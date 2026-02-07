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

enum FriendRelationshipStatus {
  friends,
  incomingRequest,
  outgoingRequest,
  none,
}

@immutable
class FriendProfileRelationshipModel {
  final FriendRelationshipStatus status;
  final bool isFriend;
  final String? incomingRequestId;
  final String? outgoingRequestId;
  final bool isBlockedByMe;

  const FriendProfileRelationshipModel({
    required this.status,
    required this.isFriend,
    this.incomingRequestId,
    this.outgoingRequestId,
    this.isBlockedByMe = false,
  });

  factory FriendProfileRelationshipModel.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status']?.toString().toLowerCase().trim();
    final status = switch (rawStatus) {
      'friends' => FriendRelationshipStatus.friends,
      'incoming_request' => FriendRelationshipStatus.incomingRequest,
      'outgoing_request' => FriendRelationshipStatus.outgoingRequest,
      'none' => FriendRelationshipStatus.none,
      _ => FriendRelationshipStatus.none,
    };

    String? readRequestId(dynamic obj) {
      if (obj is Map) {
        final v = obj['requestId'] ?? obj['request_id'] ?? obj['_id'] ?? obj['id'];
        final s = v?.toString();
        return (s != null && s.isNotEmpty) ? s : null;
      }
      return null;
    }

    final incomingObj = json['incomingRequest'] ?? json['incoming_request'];
    final outgoingObj = json['outgoingRequest'] ?? json['outgoing_request'];

    final incomingExists = (incomingObj is Map)
        ? (incomingObj['exists'] == true || incomingObj['exist'] == true)
        : false;
    final outgoingExists = (outgoingObj is Map)
        ? (outgoingObj['exists'] == true || outgoingObj['exist'] == true)
        : false;

    final incomingRequestId = incomingExists ? readRequestId(incomingObj) : null;
    final outgoingRequestId = outgoingExists ? readRequestId(outgoingObj) : null;

    final isFriend = json['isFriend'] == true ||
        json['is_friend'] == true ||
        status == FriendRelationshipStatus.friends;

    final isBlockedByMe = json['isBlockedByMe'] == true ||
        json['is_blocked_by_me'] == true;

    return FriendProfileRelationshipModel(
      status: status,
      isFriend: isFriend,
      incomingRequestId: incomingRequestId,
      outgoingRequestId: outgoingRequestId,
      isBlockedByMe: isBlockedByMe,
    );
  }
}

@immutable
class FriendProfileModel {
  final FriendProfileUserModel user;
  final FriendProfileCountsModel counts;
  final FriendProfileFriendshipStatusModel friendshipStatus;
  final FriendProfileRelationshipModel? relationship;
  final bool isBlockedByMe;

  const FriendProfileModel({
    required this.user,
    required this.counts,
    required this.friendshipStatus,
    this.relationship,
    this.isBlockedByMe = false,
  });

  factory FriendProfileModel.fromJson(Map<String, dynamic> json) {
    // Shape A (documented):
    // { user: {...}, counts: {...}, friendshipStatus: {isFriend:true} }
    // Shape B (seen in runtime):
    // { _id, fullName, username, profileImage, friendsCount, wishlistCount, eventsCount, ... }

    Map<String, dynamic> _extractFriendshipJson(Map<String, dynamic> source) {
      // Backends can return this field in multiple shapes/keys.
      final raw = source['friendshipStatus'] ??
          source['friendship_status'] ??
          source['friendship'] ??
          source['friendshipState'] ??
          source['friendship_state'];

      if (raw is Map<String, dynamic>) return raw;
      if (raw is String) return <String, dynamic>{'status': raw};

      // If not present as an object, some APIs return flags at the root level.
      // We allow parsing from root by passing the whole json to the model later.
      return const <String, dynamic>{};
    }

    final hasNestedUser = json['user'] is Map<String, dynamic>;
    if (hasNestedUser) {
      final userJson = (json['user'] as Map<String, dynamic>?) ?? const {};
      final countsJson = (json['counts'] as Map<String, dynamic>?) ?? const {};
      final friendshipJson = _extractFriendshipJson(json);
      final relationshipRaw = json['relationship'];
      final relationshipJson =
          relationshipRaw is Map<String, dynamic> ? relationshipRaw : null;
      final rel = relationshipJson != null
          ? FriendProfileRelationshipModel.fromJson(relationshipJson)
          : null;
      final isBlockedByMe = (rel?.isBlockedByMe ?? false) ||
          json['isBlockedByMe'] == true ||
          json['is_blocked_by_me'] == true;
      return FriendProfileModel(
        user: FriendProfileUserModel.fromJson(userJson),
        counts: FriendProfileCountsModel.fromJson(countsJson),
        friendshipStatus: friendshipJson.isNotEmpty
            ? FriendProfileFriendshipStatusModel.fromJson(friendshipJson)
            : FriendProfileFriendshipStatusModel.fromJson(json),
        relationship: rel,
        isBlockedByMe: isBlockedByMe,
      );
    }

    final friendshipJson = _extractFriendshipJson(json);
    final relationshipRaw = json['relationship'];
    final relationshipJson =
        relationshipRaw is Map<String, dynamic> ? relationshipRaw : null;
    final rel = relationshipJson != null
        ? FriendProfileRelationshipModel.fromJson(relationshipJson)
        : null;
    final isBlockedByMe = (rel?.isBlockedByMe ?? false) ||
        json['isBlockedByMe'] == true ||
        json['is_blocked_by_me'] == true;
    return FriendProfileModel(
      user: FriendProfileUserModel.fromJson(json),
      // counts may be embedded as flat keys
      counts: FriendProfileCountsModel.fromJson(json),
      // If backend returns friendship flags at root (e.g., {isFriend:true}),
      // parse from root as a safe fallback instead of defaulting to false.
      friendshipStatus: friendshipJson.isNotEmpty
          ? FriendProfileFriendshipStatusModel.fromJson(friendshipJson)
          : FriendProfileFriendshipStatusModel.fromJson(json),
      relationship: rel,
      isBlockedByMe: isBlockedByMe,
    );
  }
}


