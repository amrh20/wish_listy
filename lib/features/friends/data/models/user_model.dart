import 'package:wish_listy/features/friends/data/models/mutual_friends_data_model.dart';

/// User model for friends/search results
/// Matches backend API response structure
class User {
  final String id;
  final String fullName;
  final String username; // Legacy field - kept for backward compatibility
  final String? handle; // Public handle (e.g., "@amr_hamdy_99")
  final String? profileImage;
  final int? mutualFriendsCount; // Only for suggestions
  final MutualFriendsData? mutualFriendsData;
  final bool? canSendRequest; // Whether user can send friend request
  final String? friendshipStatus; // Status: 'pending', 'received', 'accepted', etc.
  final String? requestId; // Friend request ID (if status is 'received' or 'pending')
  final bool? isFriend; // Whether user is already a friend

  User({
    required this.id,
    required this.fullName,
    required this.username,
    this.handle,
    this.profileImage,
    this.mutualFriendsCount,
    this.mutualFriendsData,
    this.canSendRequest,
    this.friendshipStatus,
    this.requestId,
    this.isFriend,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final mutualDataRaw = json['mutualFriendsData'] ?? json['mutual_friends_data'];
    final mutualFriendsData = mutualDataRaw is Map<String, dynamic>
        ? MutualFriendsData.fromJson(mutualDataRaw)
        : null;

    return User(
      id: json['_id'] ?? json['id'] ?? '',
      fullName: json['fullName'] ?? json['name'] ?? '',
      username: json['username'] ?? '',
      handle: json['handle'],
      profileImage: json['profileImage'] ?? json['profile_image'],
      mutualFriendsCount: json['mutualFriendsCount'] ?? json['mutual_friends_count'],
      mutualFriendsData: mutualFriendsData,
      canSendRequest: json['canSendRequest'] ?? true,
      friendshipStatus: json['friendshipStatus'] ?? json['friendship_status'],
      requestId: json['friendRequestId'] ?? json['friend_request_id'] ?? json['requestId'] ?? json['request_id'],
      isFriend: json['isFriend'] ?? json['is_friend'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fullName': fullName,
      'username': username,
      if (handle != null) 'handle': handle,
      'profileImage': profileImage,
      if (mutualFriendsCount != null) 'mutualFriendsCount': mutualFriendsCount,
      if (mutualFriendsData != null) 'mutualFriendsData': mutualFriendsData!.toJson(),
      if (canSendRequest != null) 'canSendRequest': canSendRequest,
      if (friendshipStatus != null) 'friendshipStatus': friendshipStatus,
      if (requestId != null) 'requestId': requestId,
      if (isFriend != null) 'isFriend': isFriend,
    };
  }

  User copyWith({
    String? id,
    String? fullName,
    String? username,
    String? handle,
    String? profileImage,
    int? mutualFriendsCount,
    MutualFriendsData? mutualFriendsData,
    bool? canSendRequest,
    String? friendshipStatus,
    String? requestId,
    bool? isFriend,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      handle: handle ?? this.handle,
      profileImage: profileImage ?? this.profileImage,
      mutualFriendsCount: mutualFriendsCount ?? this.mutualFriendsCount,
      mutualFriendsData: mutualFriendsData ?? this.mutualFriendsData,
      canSendRequest: canSendRequest ?? this.canSendRequest,
      friendshipStatus: friendshipStatus ?? this.friendshipStatus,
      requestId: requestId ?? this.requestId,
      isFriend: isFriend ?? this.isFriend,
    );
  }

  /// Get display handle for UI - returns @handle if available, otherwise "User #ID"
  String getDisplayHandle() {
    if (handle != null && handle!.isNotEmpty) {
      return handle!.startsWith('@') ? handle! : '@$handle';
    }
    return 'User #$id';
  }

  @override
  String toString() {
    return 'User(id: $id, fullName: $fullName, username: $username, handle: $handle)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

