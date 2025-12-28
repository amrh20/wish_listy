/// Activity Model - Represents a single activity from the API
class Activity {
  final String id;
  final String type; // 'purchased', 'reserved', 'added', etc.
  final ActivityActor actor; // User who performed the action
  final ActivityTarget target; // Target of the activity (item, wishlist, etc.)
  final DateTime createdAt;
  final String? itemName;
  final String? itemImageUrl;
  final String? wishlistName;
  final String? wishlistId;

  Activity({
    required this.id,
    required this.type,
    required this.actor,
    required this.target,
    required this.createdAt,
    this.itemName,
    this.itemImageUrl,
    this.wishlistName,
    this.wishlistId,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    // Parse actor - handle missing or null actor
    ActivityActor actor;
    if (json['actor'] != null && json['actor'] is Map) {
      actor = ActivityActor.fromJson(json['actor'] as Map<String, dynamic>);
    } else {
      // Create default actor if missing
      actor = ActivityActor(
        id: json['actorId']?.toString() ?? 
            json['actor_id']?.toString() ?? 
            json['userId']?.toString() ?? 
            json['user_id']?.toString() ?? 
            '',
        fullName: json['actorName']?.toString() ?? 
                 json['actor_name']?.toString() ??
                 json['userName']?.toString() ??
                 json['user_name']?.toString(),
        username: json['actorUsername']?.toString() ?? 
                  json['actor_username']?.toString(),
        avatarUrl: json['actorAvatar']?.toString() ?? 
                  json['actor_avatar']?.toString(),
        profileImage: json['actorProfileImage']?.toString() ?? 
                     json['actor_profile_image']?.toString(),
      );
    }

    // Parse target - handle missing or null target
    ActivityTarget target;
    if (json['target'] != null && json['target'] is Map) {
      target = ActivityTarget.fromJson(json['target'] as Map<String, dynamic>);
    } else {
      // Create default target if missing
      target = ActivityTarget(
        type: json['targetType']?.toString() ?? 
              json['target_type']?.toString(),
        id: json['targetId']?.toString() ?? 
            json['target_id']?.toString(),
        itemName: json['itemName']?.toString() ?? 
                 json['item_name']?.toString(),
        itemImageUrl: json['itemImageUrl']?.toString() ?? 
                     json['item_image_url']?.toString(),
        wishlistName: json['wishlistName']?.toString() ?? 
                     json['wishlist_name']?.toString(),
        wishlistId: json['wishlistId']?.toString() ?? 
                   json['wishlist_id']?.toString(),
      );
    }

    // Parse dates
    DateTime createdAt;
    if (json['createdAt'] != null) {
      try {
        createdAt = DateTime.parse(json['createdAt'].toString());
      } catch (e) {
        createdAt = DateTime.now();
      }
    } else if (json['created_at'] != null) {
      try {
        createdAt = DateTime.parse(json['created_at'].toString());
      } catch (e) {
        createdAt = DateTime.now();
      }
    } else {
      createdAt = DateTime.now();
    }

    // Get ID
    final id = json['_id']?.toString() ?? 
               json['id']?.toString() ?? 
               '';

    // Get type
    final type = json['type']?.toString() ?? 'unknown';

    // Extract item/wishlist info from target or direct fields
    final itemName = target.itemName ?? 
                    json['itemName']?.toString() ?? 
                    json['item_name']?.toString();
    final itemImageUrl = target.itemImageUrl ?? 
                        json['itemImageUrl']?.toString() ?? 
                        json['item_image_url']?.toString();
    final wishlistName = target.wishlistName ?? 
                         json['wishlistName']?.toString() ?? 
                         json['wishlist_name']?.toString();
    final wishlistId = target.wishlistId ?? 
                       json['wishlistId']?.toString() ?? 
                       json['wishlist_id']?.toString();

    return Activity(
      id: id,
      type: type,
      actor: actor,
      target: target,
      createdAt: createdAt,
      itemName: itemName,
      itemImageUrl: itemImageUrl,
      wishlistName: wishlistName,
      wishlistId: wishlistId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'actor': actor.toJson(),
      'target': target.toJson(),
      'createdAt': createdAt.toIso8601String(),
      if (itemName != null) 'itemName': itemName,
      if (itemImageUrl != null) 'itemImageUrl': itemImageUrl,
      if (wishlistName != null) 'wishlistName': wishlistName,
      if (wishlistId != null) 'wishlistId': wishlistId,
    };
  }

  /// Get display text for the activity
  String getDisplayText() {
    final actorName = actor.fullName ?? actor.username ?? 'Someone';
    final typeLower = type.toLowerCase();
    
    switch (typeLower) {
      case 'wishlist_item_added':
        return '$actorName added ${itemName ?? 'an item'} to their wishlist ${wishlistName ?? ''}';
      case 'item_received':
        return '$actorName received their ${itemName ?? 'item'}!';
      case 'purchased':
        return '$actorName purchased ${itemName ?? 'an item'}';
      case 'reserved':
        return '$actorName reserved ${itemName ?? 'an item'}';
      case 'added':
        return '$actorName added ${itemName ?? 'an item'} to ${wishlistName ?? 'their wishlist'}';
      case 'event_invi':
      case 'event_invitation':
      case 'event_invitation_accepted':
        return '$actorName accepted an event invitation';
      case 'event_invitation_declined':
        return '$actorName declined an event invitation';
      case 'event_invitation_maybe':
        return '$actorName is interested in an event';
      default:
        // For unknown types, try to create a readable message
        final readableType = typeLower
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) => word.isEmpty 
                ? '' 
                : word[0].toUpperCase() + word.substring(1))
            .join(' ');
        return '$actorName $readableType ${itemName ?? ''}'.trim();
    }
  }

  /// Get time ago string
  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
}

/// Activity Actor - User who performed the action
class ActivityActor {
  final String id;
  final String? fullName;
  final String? username;
  final String? avatarUrl;
  final String? profileImage;

  ActivityActor({
    required this.id,
    this.fullName,
    this.username,
    this.avatarUrl,
    this.profileImage,
  });

  factory ActivityActor.fromJson(Map<String, dynamic> json) {
    final id = json['_id']?.toString() ?? 
               json['id']?.toString() ?? 
               '';
    
    return ActivityActor(
      id: id,
      fullName: json['fullName']?.toString() ?? 
                json['full_name']?.toString() ??
                json['name']?.toString(),
      username: json['username']?.toString(),
      avatarUrl: json['avatarUrl']?.toString() ?? 
                 json['avatar_url']?.toString(),
      profileImage: json['profileImage']?.toString() ?? 
                    json['profile_image']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (fullName != null) 'fullName': fullName,
      if (username != null) 'username': username,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (profileImage != null) 'profileImage': profileImage,
    };
  }

  String? get displayName => fullName ?? username;
  String? get imageUrl => avatarUrl ?? profileImage;
}

/// Activity Target - Target of the activity (item, wishlist, etc.)
class ActivityTarget {
  final String? type; // 'item', 'wishlist', etc.
  final String? id;
  final String? itemName;
  final String? itemImageUrl;
  final String? wishlistName;
  final String? wishlistId;

  ActivityTarget({
    this.type,
    this.id,
    this.itemName,
    this.itemImageUrl,
    this.wishlistName,
    this.wishlistId,
  });

  factory ActivityTarget.fromJson(Map<String, dynamic> json) {
    return ActivityTarget(
      type: json['type']?.toString(),
      id: json['_id']?.toString() ?? json['id']?.toString(),
      itemName: json['itemName']?.toString() ?? 
                json['item_name']?.toString() ??
                json['name']?.toString(),
      itemImageUrl: json['itemImageUrl']?.toString() ?? 
                    json['item_image_url']?.toString() ??
                    json['imageUrl']?.toString() ??
                    json['image_url']?.toString(),
      wishlistName: json['wishlistName']?.toString() ?? 
                    json['wishlist_name']?.toString(),
      wishlistId: json['wishlistId']?.toString() ?? 
                  json['wishlist_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (type != null) 'type': type,
      if (id != null) 'id': id,
      if (itemName != null) 'itemName': itemName,
      if (itemImageUrl != null) 'itemImageUrl': itemImageUrl,
      if (wishlistName != null) 'wishlistName': wishlistName,
      if (wishlistId != null) 'wishlistId': wishlistId,
    };
  }
}

