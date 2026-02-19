import 'dart:convert';

import 'package:wish_listy/core/services/localization_service.dart';

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

  /// Safely convert any value to String, handling null, int, and other types.
  static String? _safeToString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    return value.toString();
  }

  /// Safely parse relatedUser field which can be:
  /// - A Map<String, dynamic> (from Socket.io/API) - use directly
  /// - A String (from FCM data payload) - needs JSON parsing
  static Map<String, dynamic>? _parseRelatedUser(dynamic relatedUser) {
    if (relatedUser == null) return null;
    
    // Already a Map - use directly (Socket.io/API format)
    if (relatedUser is Map<String, dynamic>) {
      return relatedUser;
    }
    
    // String that needs parsing (FCM format)
    if (relatedUser is String) {
      try {
        final decoded = jsonDecode(relatedUser) as Map<String, dynamic>?;
        return decoded;
      } catch (e) {
        // If JSON parsing fails, return null
        return null;
      }
    }
    
    return null;
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    // Handle both API response format and Socket.IO event format
    // Type-safe ID extraction - can be String, int, or other types
    final notificationId = _safeToString(json['_id'] ?? json['id']) ?? '';
    final userId = _safeToString(json['userId'] ?? json['user_id']) ?? '';
    final typeStr = json['type']?.toString() ?? '';
    
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
        case 'reservation_expired':
          type = NotificationType.reservationExpired;
          break;
        case 'reservation_reminder':
          type = NotificationType.reservationReminder;
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

    // Parse relatedId and relatedWishlistId with type-safe conversion
    // These fields can come as String, int, or other types from different sources
    String? relatedId = _safeToString(
      json['relatedId'] ??
          json['related_id'] ??
          json['data']?['relatedId'] ??
          json['data']?['related_id'] ??
          json['eventId'] ??
          json['itemId'],
    );

    String? relatedWishlistId = _safeToString(
      json['relatedWishlistId'] ??
          json['related_wishlist_id'] ??
          json['data']?['relatedWishlistId'] ??
          json['data']?['related_wishlist_id'] ??
          json['wishlistId'],
    );

    // Prepare data map, handling relatedUser parsing and cleaning bonus fields
    Map<String, dynamic>? dataMap;
    if (json['data'] != null && json['data'] is Map<String, dynamic>) {
      // Clone the data map to avoid mutating the original
      dataMap = Map<String, dynamic>.from(json['data'] as Map<String, dynamic>);
      
      // Parse relatedUser if it exists (can be String from FCM or Map from Socket.io/API)
      if (dataMap.containsKey('relatedUser')) {
        final parsedRelatedUser = _parseRelatedUser(dataMap['relatedUser']);
        if (parsedRelatedUser != null) {
          dataMap['relatedUser'] = parsedRelatedUser;
        } else {
          // Remove invalid relatedUser to avoid confusion
          dataMap.remove('relatedUser');
        }
      }
      
      // Remove bonus fields that shouldn't be part of the notification data
      // These fields are used for UI state but not part of the notification model
      dataMap.remove('unreadCount');
      dataMap.remove('unread_count');
      dataMap.remove('fcmMessageId');
      dataMap.remove('notificationTitle');
      dataMap.remove('notificationBody');
    } else {
      // If no data map exists, use the entire json as data (backward compatibility)
      // but exclude model fields and bonus fields
      dataMap = Map<String, dynamic>.from(json);
      dataMap.remove('_id');
      dataMap.remove('id');
      dataMap.remove('userId');
      dataMap.remove('user_id');
      dataMap.remove('type');
      dataMap.remove('title');
      dataMap.remove('message');
      dataMap.remove('body');
      dataMap.remove('isRead');
      dataMap.remove('is_read');
      dataMap.remove('createdAt');
      dataMap.remove('created_at');
      dataMap.remove('readAt');
      dataMap.remove('read_at');
      dataMap.remove('relatedId');
      dataMap.remove('related_id');
      dataMap.remove('relatedWishlistId');
      dataMap.remove('related_wishlist_id');
      dataMap.remove('unreadCount');
      dataMap.remove('unread_count');
      dataMap.remove('fcmMessageId');
      dataMap.remove('notificationTitle');
      dataMap.remove('notificationBody');
      
      // Parse relatedUser if it exists in the root json
      if (dataMap.containsKey('relatedUser')) {
        final parsedRelatedUser = _parseRelatedUser(dataMap['relatedUser']);
        if (parsedRelatedUser != null) {
          dataMap['relatedUser'] = parsedRelatedUser;
        } else {
          dataMap.remove('relatedUser');
        }
      }
    }

    return AppNotification(
      id: notificationId,
      userId: userId,
      type: type,
      title: json['title']?.toString() ?? json['message']?.toString() ?? '',
      message: json['message']?.toString() ?? json['body']?.toString() ?? '',
      data: dataMap.isEmpty ? null : dataMap,
      isRead: json['isRead'] == true || json['is_read'] == true,
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
  reservationExpired,
  reservationReminder,
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
      case NotificationType.reservationExpired:
        return 'Reservation Expired';
      case NotificationType.reservationReminder:
        return 'Reservation Reminder';
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
      case NotificationType.reservationExpired:
        return '⏱️';
      case NotificationType.reservationReminder:
        return '🔔';
      case NotificationType.general:
        return '🔔';
    }
  }
}

/// Extension to get localized notification titles based on [NotificationType].
/// Do not use the backend title for display; use this instead.
extension AppNotificationLocalization on AppNotification {
  /// Returns a localized title for this notification based on [type].
  /// Uses [LocalizationService] for translations. Falls back to backend title if key is missing.
  String getLocalizedTitle(LocalizationService localization) {
    // Distinguish item_received and item_not_received when type is itemPurchased
    if (type == NotificationType.itemPurchased) {
      final dataType = (data?['type'] ?? data?['notificationType'])
          ?.toString()
          .toLowerCase();
      if (dataType == 'item_received') {
        return localization.translate('notifications.item_received');
      }
      if (dataType == 'item_not_received') {
        return localization.translate('notifications.item_not_received');
      }
    }

    final key = _typeToTranslationKey(type);
    final translated = localization.translate(key);
    return translated != key ? translated : title;
  }

  static String _typeToTranslationKey(NotificationType type) {
    switch (type) {
      case NotificationType.friendRequest:
        return 'notifications.friend_request';
      case NotificationType.friendRequestAccepted:
        return 'notifications.friend_request_accepted';
      case NotificationType.friendRequestRejected:
        return 'notifications.friend_request_rejected';
      case NotificationType.eventInvitation:
        return 'notifications.event_invite';
      case NotificationType.eventReminder:
        return 'notifications.event_reminder';
      case NotificationType.eventUpdate:
        return 'notifications.event_update';
      case NotificationType.eventResponse:
        return 'notifications.event_response';
      case NotificationType.itemPurchased:
        return 'notifications.item_purchased';
      case NotificationType.itemReserved:
        return 'notifications.item_reserved';
      case NotificationType.itemUnreserved:
        return 'notifications.item_unreserved';
      case NotificationType.wishlistShared:
        return 'notifications.wishlist_shared';
      case NotificationType.reservationExpired:
        return 'notifications.reservation_expired';
      case NotificationType.reservationReminder:
        return 'notifications.reservation_reminder';
      case NotificationType.general:
        return 'notifications.general';
    }
  }
}