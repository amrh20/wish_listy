/// User model for friends/search results
/// Matches backend API response structure
class User {
  final String id;
  final String fullName;
  final String username;
  final String? profileImage;
  final int? mutualFriendsCount; // Only for suggestions
  final bool? canSendRequest; // Whether user can send friend request
  final String? friendshipStatus; // Status: 'pending', 'received', 'accepted', etc.
  final String? requestId; // Friend request ID (if status is 'received' or 'pending')

  User({
    required this.id,
    required this.fullName,
    required this.username,
    this.profileImage,
    this.mutualFriendsCount,
    this.canSendRequest,
    this.friendshipStatus,
    this.requestId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      fullName: json['fullName'] ?? json['name'] ?? '',
      username: json['username'] ?? '',
      profileImage: json['profileImage'] ?? json['profile_image'],
      mutualFriendsCount: json['mutualFriendsCount'] ?? json['mutual_friends_count'],
      canSendRequest: json['canSendRequest'] ?? true, // Default to true if not provided
      friendshipStatus: json['friendshipStatus'] ?? json['friendship_status'],
      requestId: json['friendRequestId'] ?? json['friend_request_id'] ?? json['requestId'] ?? json['request_id'], // Extract friendRequestId if available
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fullName': fullName,
      'username': username,
      'profileImage': profileImage,
      if (mutualFriendsCount != null) 'mutualFriendsCount': mutualFriendsCount,
      if (canSendRequest != null) 'canSendRequest': canSendRequest,
      if (friendshipStatus != null) 'friendshipStatus': friendshipStatus,
      if (requestId != null) 'requestId': requestId,
    };
  }

  User copyWith({
    String? id,
    String? fullName,
    String? username,
    String? profileImage,
    int? mutualFriendsCount,
    bool? canSendRequest,
    String? friendshipStatus,
    String? requestId,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      profileImage: profileImage ?? this.profileImage,
      mutualFriendsCount: mutualFriendsCount ?? this.mutualFriendsCount,
      canSendRequest: canSendRequest ?? this.canSendRequest,
      friendshipStatus: friendshipStatus ?? this.friendshipStatus,
      requestId: requestId ?? this.requestId,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, fullName: $fullName, username: $username)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

