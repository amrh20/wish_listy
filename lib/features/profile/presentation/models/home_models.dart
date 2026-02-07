/// Data models for Home Screen dashboard
import 'package:wish_listy/features/wishlists/data/models/wishlist_model.dart';
import 'package:wish_listy/features/events/data/models/event_model.dart';
import 'package:wish_listy/features/profile/data/models/activity_model.dart';

/// Dashboard Model - Main model for Home Screen API response
class DashboardModel {
  final DashboardUser user;
  final DashboardStats stats;
  final List<Wishlist> myWishlists;
  final List<Event> upcomingOccasions;
  final List<Activity> latestActivityPreview; // Changed from friendActivity to latestActivityPreview

  DashboardModel({
    required this.user,
    required this.stats,
    required this.myWishlists,
    required this.upcomingOccasions,
    required this.latestActivityPreview,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    // Safely extract data object
    Map<String, dynamic> data;
    final dataRaw = json['data'];
    if (dataRaw != null && dataRaw is Map<String, dynamic>) {
      data = dataRaw;
    } else if (json is Map<String, dynamic>) {
      data = json;
    } else {
      // Fallback: create empty map
      data = {};
    }

    // Parse user
    final userData = data['user'] as Map<String, dynamic>? ?? {};
    final user = DashboardUser.fromJson(userData);

    // Parse stats
    final statsData = data['stats'] as Map<String, dynamic>? ?? {};
    final stats = DashboardStats.fromJson(statsData);

    // Parse wishlists - ensure it's a List before calling .map()
    List<dynamic> wishlistsData = [];
    final wishlistsRaw = data['myWishlists'];
    if (wishlistsRaw != null && wishlistsRaw is List) {
      wishlistsData = wishlistsRaw;
    }
    final wishlists = wishlistsData
        .map((item) {
          try {
            if (item is Map<String, dynamic>) {
              return Wishlist.fromJson(item);
            }
            return null;
          } catch (e) {
            return null;
          }
        })
        .whereType<Wishlist>()
        .toList();

    // Parse upcoming occasions (events) - ensure it's a List before calling .map()
    List<dynamic> occasionsData = [];
    final occasionsRaw = data['upcomingOccasions'];
    if (occasionsRaw != null && occasionsRaw is List) {
      occasionsData = occasionsRaw;
    }
    final occasions = occasionsData
        .map((item) {
          try {
            if (item is Map<String, dynamic>) {
              return Event.fromJson(item);
            }
            return null;
          } catch (e) {
            return null;
          }
        })
        .whereType<Event>()
        .toList();

    // Parse latest activity preview (max 3 items from /api/home) - ensure it's a List before calling .map()
    List<dynamic> activityData = [];
    final activityRaw = data['latestActivityPreview'] ?? data['friendActivity'];
    if (activityRaw != null && activityRaw is List) {
      activityData = activityRaw;
    } else if (activityRaw != null && activityRaw is! List) {
      // If it's not a List, log and use empty list
      activityData = [];
    }
    // Ensure activityData is never null before calling .map()
    final safeActivityData = activityData ?? [];
    final activityPreview = safeActivityData
        .where((item) => item != null) // Filter out null items first
        .map((item) {
          try {
            if (item is Map<String, dynamic>) {
              return Activity.fromJson(item);
            }
            return null;
          } catch (e) {
            // If parsing fails, return null
            return null;
          }
        })
        .whereType<Activity>()
        .toList();

    return DashboardModel(
      user: user,
      stats: stats,
      myWishlists: wishlists,
      upcomingOccasions: occasions,
      latestActivityPreview: activityPreview,
    );
  }

  /// Helper getter to determine if user is new (no wishlists and no occasions)
  bool get isNewUser => myWishlists.isEmpty && upcomingOccasions.isEmpty;
}

/// Dashboard User Model
class DashboardUser {
  final String firstName;
  final String? avatar;

  DashboardUser({
    required this.firstName,
    this.avatar,
  });

  factory DashboardUser.fromJson(Map<String, dynamic> json) {
    return DashboardUser(
      firstName: json['firstName']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
    );
  }
}

/// Dashboard Stats Model
class DashboardStats {
  final int wishlistsCount;
  final int unreadNotificationsCount;

  DashboardStats({
    required this.wishlistsCount,
    required this.unreadNotificationsCount,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      wishlistsCount: (json['wishlistsCount'] as num?)?.toInt() ?? 0,
      unreadNotificationsCount:
          (json['unreadNotificationsCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class UpcomingOccasion {
  final String id;
  final String name;
  final DateTime date;
  final String type; // Birthday, Anniversary, Graduation, etc.
  final String hostName;
  final String? hostId; // Creator/owner ID for navigation
  final String? imageUrl;
  final String? avatarUrl;
  final String? invitationStatus; // 'pending', 'accepted', 'declined', 'maybe', 'not_invited'

  UpcomingOccasion({
    required this.id,
    required this.name,
    required this.date,
    required this.type,
    required this.hostName,
    this.hostId,
    this.imageUrl,
    this.avatarUrl,
    this.invitationStatus,
  });

  int get daysUntil {
    final now = DateTime.now();
    final difference = date.difference(DateTime(now.year, now.month, now.day));
    return difference.inDays;
  }

  bool get isUpcoming => date.isAfter(DateTime.now());
}

class FriendActivity {
  final String id;
  final String friendName;
  final String? friendId; // Owner ID for navigation
  final String action; // e.g., "added 3 new items to her wishlist"
  final String timeAgo; // e.g., "2 hours ago"
  final String? imageUrl;
  final String? avatarUrl;

  FriendActivity({
    required this.id,
    required this.friendName,
    this.friendId,
    required this.action,
    required this.timeAgo,
    this.imageUrl,
    this.avatarUrl,
  });
}

