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
  final String senderId;
  final String receiverId;
  final String? message;
  final FriendRequestStatus status;
  final DateTime sentAt;
  final DateTime? respondedAt;

  FriendRequest({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.message,
    this.status = FriendRequestStatus.pending,
    required this.sentAt,
    this.respondedAt,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'] ?? '',
      senderId: json['sender_id'] ?? '',
      receiverId: json['receiver_id'] ?? '',
      message: json['message'],
      status: FriendRequestStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => FriendRequestStatus.pending,
      ),
      sentAt: DateTime.parse(json['sent_at']),
      respondedAt: json['responded_at'] != null ? DateTime.parse(json['responded_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'status': status.toString().split('.').last,
      'sent_at': sentAt.toIso8601String(),
      'responded_at': respondedAt?.toIso8601String(),
    };
  }

  FriendRequest copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? message,
    FriendRequestStatus? status,
    DateTime? sentAt,
    DateTime? respondedAt,
  }) {
    return FriendRequest(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      message: message ?? this.message,
      status: status ?? this.status,
      sentAt: sentAt ?? this.sentAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }

  @override
  String toString() {
    return 'FriendRequest(id: $id, sender: $senderId, receiver: $receiverId, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FriendRequest && other.id == id;
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