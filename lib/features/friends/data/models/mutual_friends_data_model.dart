import 'package:flutter/foundation.dart';

/// Single mutual friend preview (avatar + name).
@immutable
class MutualFriendPreview {
  final String id;
  final String fullName;
  final String? profileImage;

  const MutualFriendPreview({
    required this.id,
    required this.fullName,
    this.profileImage,
  });

  factory MutualFriendPreview.fromJson(Map<String, dynamic> json) {
    return MutualFriendPreview(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      fullName: (json['fullName'] ?? json['full_name'] ?? json['name'])?.toString() ?? '',
      profileImage: (json['profileImage'] ?? json['profile_image'] ?? json['avatar'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fullName': fullName,
      if (profileImage != null) 'profileImage': profileImage,
    };
  }
}

/// Mutual friends summary: total count + preview list (e.g. up to 3).
@immutable
class MutualFriendsData {
  final int totalCount;
  final List<MutualFriendPreview> preview;

  const MutualFriendsData({
    required this.totalCount,
    this.preview = const [],
  });

  factory MutualFriendsData.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MutualFriendsData(totalCount: 0);

    int totalCount = 0;
    if (json['totalCount'] != null) {
      final v = json['totalCount'];
      totalCount = v is int ? v : (v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0);
    } else if (json['total_count'] != null) {
      final v = json['total_count'];
      totalCount = v is int ? v : (v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0);
    }

    List<MutualFriendPreview> preview = [];
    final previewRaw = json['preview'];
    if (previewRaw is List) {
      preview = previewRaw
          .whereType<Map<String, dynamic>>()
          .map((e) => MutualFriendPreview.fromJson(e))
          .toList();
    }

    return MutualFriendsData(totalCount: totalCount, preview: preview);
  }

  Map<String, dynamic> toJson() {
    return {
      'totalCount': totalCount,
      'preview': preview.map((e) => e.toJson()).toList(),
    };
  }
}
