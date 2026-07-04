import 'package:wish_listy/features/friends/data/models/mutual_friends_data_model.dart';

double? _parseOptionalDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// Suggestion User model for "People You May Know" feature
/// Maps from API response structure including Discovery V2 metadata.
class SuggestionUser {
  final String id;
  final String fullName;
  final String username;
  final String? profileImage; // Mapped from 'avatar' field in API
  final int mutualFriendsCount;
  final MutualFriendsData? mutualFriendsData;
  final double? discoveryScore;
  final double? interestOverlap;
  final double? categoryOverlap;

  const SuggestionUser({
    required this.id,
    required this.fullName,
    required this.username,
    this.profileImage,
    required this.mutualFriendsCount,
    this.mutualFriendsData,
    this.discoveryScore,
    this.interestOverlap,
    this.categoryOverlap,
  });

  factory SuggestionUser.fromJson(Map<String, dynamic> json) {
    final mutualDataRaw = json['mutualFriendsData'] ?? json['mutual_friends_data'];
    final mutualFriendsData = mutualDataRaw is Map<String, dynamic>
        ? MutualFriendsData.fromJson(mutualDataRaw)
        : null;

    final mfc = json['mutualFriendsCount'] ?? json['mutual_friends_count'];
    final mutualCount = mfc is int
        ? mfc
        : (mfc is num ? mfc.toInt() : int.tryParse('$mfc') ?? 0);

    return SuggestionUser(
      id: json['_id'] ?? json['id'] ?? '',
      fullName: json['fullName'] ?? json['name'] ?? '',
      username: json['username'] ?? '',
      profileImage: json['avatar'] ?? json['profileImage'] ?? json['profile_image'],
      mutualFriendsCount: mutualCount,
      mutualFriendsData: mutualFriendsData,
      discoveryScore: _parseOptionalDouble(json['discoveryScore'] ?? json['discovery_score']),
      interestOverlap: _parseOptionalDouble(json['interestOverlap'] ?? json['interest_overlap']),
      categoryOverlap: _parseOptionalDouble(json['categoryOverlap'] ?? json['category_overlap']),
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
      if (discoveryScore != null) 'discoveryScore': discoveryScore,
      if (interestOverlap != null) 'interestOverlap': interestOverlap,
      if (categoryOverlap != null) 'categoryOverlap': categoryOverlap,
    };
  }

  SuggestionUser copyWith({
    String? id,
    String? fullName,
    String? username,
    String? profileImage,
    int? mutualFriendsCount,
    MutualFriendsData? mutualFriendsData,
    double? discoveryScore,
    double? interestOverlap,
    double? categoryOverlap,
  }) {
    return SuggestionUser(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      profileImage: profileImage ?? this.profileImage,
      mutualFriendsCount: mutualFriendsCount ?? this.mutualFriendsCount,
      mutualFriendsData: mutualFriendsData ?? this.mutualFriendsData,
      discoveryScore: discoveryScore ?? this.discoveryScore,
      interestOverlap: interestOverlap ?? this.interestOverlap,
      categoryOverlap: categoryOverlap ?? this.categoryOverlap,
    );
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
