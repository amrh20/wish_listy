import 'package:wish_listy/features/friends/data/models/mutual_friends_data_model.dart';

/// Suggestion User model for "People You May Know" feature
/// Maps from API response structure: {_id, fullName, username, avatar, mutualFriendsCount, mutualFriendsData}
class SuggestionUser {
  final String id;
  final String fullName;
  final String username;
  final String? profileImage; // Mapped from 'avatar' field in API
  final int mutualFriendsCount;
  final MutualFriendsData? mutualFriendsData;

  const SuggestionUser({
    required this.id,
    required this.fullName,
    required this.username,
    this.profileImage,
    required this.mutualFriendsCount,
    this.mutualFriendsData,
  });

  factory SuggestionUser.fromJson(Map<String, dynamic> json) {
    final mutualDataRaw = json['mutualFriendsData'] ?? json['mutual_friends_data'];
    final mutualFriendsData = mutualDataRaw is Map<String, dynamic>
        ? MutualFriendsData.fromJson(mutualDataRaw)
        : null;

    return SuggestionUser(
      id: json['_id'] ?? json['id'] ?? '',
      fullName: json['fullName'] ?? json['name'] ?? '',
      username: json['username'] ?? '',
      profileImage: json['avatar'] ?? json['profileImage'] ?? json['profile_image'],
      mutualFriendsCount: json['mutualFriendsCount'] ?? json['mutual_friends_count'] ?? 0,
      mutualFriendsData: mutualFriendsData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fullName': fullName,
      'username': username,
      'avatar': profileImage,
      'mutualFriendsCount': mutualFriendsCount,
      if (mutualFriendsData != null) 'mutualFriendsData': mutualFriendsData!.toJson(),
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

