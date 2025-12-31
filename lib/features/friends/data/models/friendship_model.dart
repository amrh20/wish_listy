import 'package:wish_listy/features/friends/data/models/user_model.dart';

class Friendship {
  final String id;
  final String userId1;
  final String userId2;
  final FriendshipStatus status;
  final String requesterId; // Who sent the friend request
  final DateTime createdAt;
  final DateTime updatedAt;

  Friendship({
    required this.id,
    required this.userId1,
    required this.userId2,
    required this.status,
    required this.requesterId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Friendship.fromJson(Map<String, dynamic> json) {
    return Friendship(
      id: json['id'] ?? '',
      userId1: json['user_id1'] ?? '',
      userId2: json['user_id2'] ?? '',
      status: FriendshipStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => FriendshipStatus.pending,
      ),
      requesterId: json['requester_id'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id1': userId1,
      'user_id2': userId2,
      'status': status.toString().split('.').last,
      'requester_id': requesterId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Friendship copyWith({
    String? id,
    String? userId1,
    String? userId2,
    FriendshipStatus? status,
    String? requesterId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Friendship(
      id: id ?? this.id,
      userId1: userId1 ?? this.userId1,
      userId2: userId2 ?? this.userId2,
      status: status ?? this.status,
      requesterId: requesterId ?? this.requesterId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Get the other user's ID given the current user's ID
  String getOtherUserId(String currentUserId) {
    return currentUserId == userId1 ? userId2 : userId1;
  }

  // Check if the current user is the one who sent the request
  bool isRequester(String currentUserId) {
    return requesterId == currentUserId;
  }

  @override
  String toString() {
    return 'Friendship(id: $id, status: $status, requester: $requesterId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Friendship && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class FriendRequest {
  final String id;
  final User from; // User who sent the request
  final FriendRequestStatus status;
  final DateTime createdAt;

  FriendRequest({
    required this.id,
    required this.from,
    this.status = FriendRequestStatus.pending,
    required this.createdAt,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    // Parse the 'from' user object
    final fromJson = json['from'] as Map<String, dynamic>?;
    if (fromJson == null) {
      throw Exception('FriendRequest must have a "from" field');
    }

    return FriendRequest(
      id: json['_id'] ?? json['id'] ?? '',
      from: User.fromJson(fromJson),
      status: FriendRequestStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => FriendRequestStatus.pending,
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : (json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'from': from.toJson(),
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  FriendRequest copyWith({
    String? id,
    User? from,
    FriendRequestStatus? status,
    DateTime? createdAt,
  }) {
    return FriendRequest(
      id: id ?? this.id,
      from: from ?? this.from,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Convenience getters for backward compatibility with existing code
  String get senderId => from.id;
  String get senderName => from.fullName;
  String? get senderProfilePicture => from.profileImage;
  DateTime get sentAt => createdAt;

  @override
  String toString() {
    return 'FriendRequest(id: $id, from: ${from.fullName}, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FriendRequest && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Friend model for friends list
/// Matches API response structure
class Friend {
  final String id;
  final String fullName;
  final String username; // Legacy field - kept for backward compatibility
  final String? handle; // Public handle (e.g., "@amr_hamdy_99")
  final String? profileImage;
  final int wishlistCount;
  final String? email;
  final String? phone;

  Friend({
    required this.id,
    required this.fullName,
    required this.username,
    this.handle,
    this.profileImage,
    required this.wishlistCount,
    this.email,
    this.phone,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['_id'] ?? json['id'] ?? '',
      fullName: json['fullName'] ?? json['name'] ?? '',
      username: json['username'] ?? '',
      handle: json['handle']?.toString(),
      profileImage: json['profileImage'] ?? json['profile_image'],
      wishlistCount: json['wishlistCount'] ?? json['wishlist_count'] ?? 0,
      email: json['email']?.toString(),
      phone: json['phone']?.toString() ?? json['mobile']?.toString() ?? json['phoneNumber']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fullName': fullName,
      'username': username,
      if (handle != null) 'handle': handle,
      'profileImage': profileImage,
      'wishlistCount': wishlistCount,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
    };
  }

  Friend copyWith({
    String? id,
    String? fullName,
    String? username,
    String? handle,
    String? profileImage,
    int? wishlistCount,
    String? email,
    String? phone,
  }) {
    return Friend(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      handle: handle ?? this.handle,
      profileImage: profileImage ?? this.profileImage,
      wishlistCount: wishlistCount ?? this.wishlistCount,
      email: email ?? this.email,
      phone: phone ?? this.phone,
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
    return 'Friend(id: $id, fullName: $fullName, username: $username, handle: $handle)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Friend && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum FriendshipStatus {
  pending,
  accepted,
  blocked,
  declined,
}

enum FriendRequestStatus {
  pending,
  accepted,
  declined,
  cancelled,
}