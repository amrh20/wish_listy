class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? relatedId; // ID of Event, Item, or User
  final String? relatedWishlistId; // Crucial for navigating to WishlistDetails

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
    this.relatedId,
    this.relatedWishlistId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    // Handle both API response format and Socket.IO event format
    final notificationId = json['_id'] ?? json['id'] ?? '';
    final userId = json['userId'] ?? json['user_id'] ?? '';
    final typeStr = json['type'] ?? '';
    
    // Map backend notification types to our enum
    NotificationType type;
    try {
      // Try to find matching enum value
      final normalizedTypeStr = typeStr.toLowerCase().trim();
      
      // Direct mapping for common types
      switch (normalizedTypeStr) {
        case 'friendrequest':
        case 'friend_request':
          type = NotificationType.friendRequest;
          break;
        case 'friendrequestaccepted':
        case 'friend_request_accepted':
          type = NotificationType.friendRequestAccepted;
          break;
        case 'friendrequestrejected':
        case 'friend_request_rejected':
          type = NotificationType.friendRequestRejected;
          break;
        case 'eventinvitation':
        case 'event_invitation':
        case 'eventinvite':
        case 'event_invite':
          type = NotificationType.eventInvitation;
          break;
        case 'eventreminder':
        case 'event_reminder':
          type = NotificationType.eventReminder;
          break;
        case 'eventinvitationaccepted':
        case 'event_invitation_accepted':
          type = NotificationType.eventResponse;
          break;
        case 'eventinvitationmaybe':
        case 'event_invitation_maybe':
          type = NotificationType.eventResponse;
          break;
        case 'itempurchased':
        case 'item_purchased':
        case 'itemreceived':
        case 'item_received':
          type = NotificationType.itemPurchased;
          break;
        case 'itemreserved':
        case 'item_reserved':
          type = NotificationType.itemReserved;
          break;
        case 'itemunreserved':
        case 'item_unreserved':
          type = NotificationType.itemUnreserved;
          break;
        case 'eventupdate':
        case 'event_update':
          type = NotificationType.eventUpdate;
          break;
        case 'eventresponse':
        case 'event_response':
          type = NotificationType.eventResponse;
          break;
        case 'wishlistshared':
        case 'wishlist_shared':
          type = NotificationType.wishlistShared;
          break;
        default:
          // Fallback to enum search
          type = NotificationType.values.firstWhere(
            (e) => e.toString().split('.').last.toLowerCase() == normalizedTypeStr,
            orElse: () => NotificationType.general,
          );
      }
    } catch (e) {
      type = NotificationType.general;
    }

    // Parse dates
    DateTime createdAt;
    try {
      createdAt = json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now();
    } catch (e) {
      createdAt = DateTime.now();
    }

    DateTime? readAt;
    try {
      if (json['readAt'] != null) {
        readAt = DateTime.parse(json['readAt']);
      } else if (json['read_at'] != null) {
        readAt = DateTime.parse(json['read_at']);
      }
    } catch (e) {
      readAt = null;
    }

    // Parse relatedId and relatedWishlistId with fallback to data map
    String? relatedId;
    try {
      relatedId = json['relatedId'] as String? ??
          json['related_id'] as String? ??
          json['data']?['relatedId'] as String? ??
          json['data']?['related_id'] as String?;
    } catch (e) {
      relatedId = null;
    }

    String? relatedWishlistId;
    try {
      relatedWishlistId = json['relatedWishlistId'] as String? ??
          json['related_wishlist_id'] as String? ??
          json['data']?['relatedWishlistId'] as String? ??
          json['data']?['related_wishlist_id'] as String?;
    } catch (e) {
      relatedWishlistId = null;
    }

    return AppNotification(
      id: notificationId,
      userId: userId,
      type: type,
      title: json['title'] ?? json['message'] ?? '',
      message: json['message'] ?? json['body'] ?? '',
      data: json['data'] as Map<String, dynamic>? ?? json,
      isRead: json['isRead'] ?? json['is_read'] ?? false,
      createdAt: createdAt,
      readAt: readAt,
      relatedId: relatedId,
      relatedWishlistId: relatedWishlistId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.toString().split('.').last,
      'title': title,
      'message': message,
      'data': data,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'related_id': relatedId,
      'related_wishlist_id': relatedWishlistId,
    };
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
    String? relatedId,
    String? relatedWishlistId,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      relatedId: relatedId ?? this.relatedId,
      relatedWishlistId: relatedWishlistId ?? this.relatedWishlistId,
    );
  }

  AppNotification markAsRead() {
    return copyWith(
      isRead: true,
      readAt: DateTime.now(),
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  String toString() {
    return 'AppNotification(id: $id, type: $type, title: $title, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppNotification && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum NotificationType {
  friendRequest,
  friendRequestAccepted,
  friendRequestRejected, // Added to match backend
  eventInvitation,
  eventReminder,
  eventUpdate,
  eventResponse,
  itemPurchased,
  itemReserved,
  itemUnreserved,
  wishlistShared,
  general,
}

extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.friendRequest:
        return 'Friend Request';
      case NotificationType.friendRequestAccepted:
        return 'Friend Request Accepted';
      case NotificationType.friendRequestRejected:
        return 'Friend Request Rejected';
      case NotificationType.eventInvitation:
        return 'Event Invitation';
      case NotificationType.eventReminder:
        return 'Event Reminder';
      case NotificationType.eventUpdate:
        return 'Event Update';
      case NotificationType.eventResponse:
        return 'Event Response';
      case NotificationType.itemPurchased:
        return 'Item Purchased';
      case NotificationType.itemReserved:
        return 'Item Reserved';
      case NotificationType.itemUnreserved:
        return 'Item Unreserved';
      case NotificationType.wishlistShared:
        return 'Wishlist Shared';
      case NotificationType.general:
        return 'Notification';
    }
  }

  String get icon {
    switch (this) {
      case NotificationType.friendRequest:
        return '👥';
      case NotificationType.friendRequestAccepted:
        return '✅';
      case NotificationType.friendRequestRejected:
        return '❌';
      case NotificationType.eventInvitation:
        return '🎉';
      case NotificationType.eventReminder:
        return '⏰';
      case NotificationType.eventUpdate:
        return '📅';
      case NotificationType.eventResponse:
        return '💬';
      case NotificationType.itemPurchased:
        return '🛍️';
      case NotificationType.itemReserved:
        return '📌';
      case NotificationType.itemUnreserved:
        return '🔓';
      case NotificationType.wishlistShared:
        return '💝';
      case NotificationType.general:
        return '🔔';
    }
  }
}