/// Suggestion User model for "People You May Know" feature
/// Maps from API response structure: {_id, fullName, username, avatar, mutualFriendsCount}
class SuggestionUser {
  final String id;
  final String fullName;
  final String username;
  final String? profileImage; // Mapped from 'avatar' field in API
  final int mutualFriendsCount;

  const SuggestionUser({
    required this.id,
    required this.fullName,
    required this.username,
    this.profileImage,
    required this.mutualFriendsCount,
  });

  factory SuggestionUser.fromJson(Map<String, dynamic> json) {
    return SuggestionUser(
      id: json['_id'] ?? json['id'] ?? '',
      fullName: json['fullName'] ?? json['name'] ?? '',
      username: json['username'] ?? '',
      // Map 'avatar' field from API to 'profileImage' internally
      profileImage: json['avatar'] ?? json['profileImage'] ?? json['profile_image'],
      mutualFriendsCount: json['mutualFriendsCount'] ?? json['mutual_friends_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fullName': fullName,
      'username': username,
      'avatar': profileImage, // Map back to 'avatar' for API compatibility
      'mutualFriendsCount': mutualFriendsCount,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SuggestionUser && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'SuggestionUser(id: $id, fullName: $fullName, mutualFriendsCount: $mutualFriendsCount)';
  }
}

