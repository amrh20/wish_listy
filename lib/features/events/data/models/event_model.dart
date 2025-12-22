import 'package:flutter/foundation.dart';

class Event {
  final String id;
  final String creatorId;
  final String name;
  final DateTime date;
  final String? time; // HH:mm format (e.g., "18:00")
  final String? description;
  final String? location;
  final EventType type;
  final EventStatus status;
  final String? wishlistId;
  final String? wishlistName;
  final int? wishlistItemCount;
  final List<EventInvitation> invitations;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? privacy; // 'public', 'private', 'friends_only'
  final String? mode; // 'in_person', 'online', 'hybrid'
  final String? meetingLink; // For online/hybrid events
  final List<InvitedFriend> invitedFriends; // List of invited friends from API
  final String? creatorName; // Creator's full name from API
  final String? creatorImage; // Creator's profile image from API
  final InvitationStatus? invitationStatus; // User's RSVP status (from API invitation_status field)
  final int? statsAccepted; // Accepted count from API stats.accepted field

  Event({
    required this.id,
    required this.creatorId,
    required this.name,
    required this.date,
    this.time,
    this.description,
    this.location,
    required this.type,
    this.status = EventStatus.upcoming,
    this.wishlistId,
    this.wishlistName,
    this.wishlistItemCount,
    this.invitations = const [],
    required this.createdAt,
    required this.updatedAt,
    this.privacy,
    this.mode,
    this.meetingLink,
    this.invitedFriends = const [],
    this.creatorName,
    this.creatorImage,
    this.invitationStatus,
    this.statsAccepted,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    // Handle both API response formats:
    // 1. {_id: "...", creator: {_id: "..."}, ...} (MongoDB format)
    // 2. {id: "...", creator_id: "...", ...} (standard format)

    // Get ID - support both _id (MongoDB) and id
    final id = json['_id']?.toString() ?? json['id']?.toString() ?? '';

    // Get creator ID and info - support both creator object and creator_id
    String? creatorId;
    String? creatorName;
    String? creatorImage;
    if (json['creator'] != null && json['creator'] is Map) {
      final creator = json['creator'] as Map<String, dynamic>;
      creatorId =
          creator['_id']?.toString() ??
          creator['id']?.toString();
      creatorName = creator['fullName']?.toString() ?? creator['name']?.toString();
      creatorImage = creator['profileImage']?.toString() ?? creator['profile_image']?.toString();
    }
    creatorId ??=
        json['creator_id']?.toString() ?? json['creatorId']?.toString() ?? '';

    // Get wishlist ID - support both wishlist object and wishlist_id
    String? wishlistId;
    String? wishlistName;
    int? wishlistItemCount;
    if (json['wishlist'] != null) {
      if (json['wishlist'] is Map) {
        final wishlistMap = json['wishlist'] as Map<String, dynamic>;
        wishlistId =
            wishlistMap['_id']?.toString() ??
            wishlistMap['id']?.toString();
        wishlistName = wishlistMap['name']?.toString();
        if (wishlistMap['items'] != null && wishlistMap['items'] is List) {
          wishlistItemCount = (wishlistMap['items'] as List).length;
        }
      } else if (json['wishlist'] is String) {
        wishlistId = json['wishlist'];
      }
    }
    wishlistId ??=
        json['wishlist_id']?.toString() ?? json['wishlistId']?.toString();

    // Parse date and time fields separately
    DateTime? eventDate;
    String? eventTime;

    // Parse date field (ISO 8601 UTC format)
    if (json['date'] != null) {
      try {
        eventDate = DateTime.parse(json['date'].toString());
      } catch (e) {

      }
    }
    eventDate ??= DateTime.now();

    // Parse time field (HH:mm format)
    if (json['time'] != null) {
      eventTime = json['time'].toString();
    }

    // If time is provided, combine with date to create full DateTime
    // This maintains backward compatibility with existing code that uses event.date
    if (eventTime != null && eventTime.isNotEmpty) {
      try {
        final timeParts = eventTime.split(':');
        if (timeParts.length == 2) {
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);
          eventDate = DateTime(
            eventDate.year,
            eventDate.month,
            eventDate.day,
            hour,
            minute,
          );
        }
      } catch (e) {

      }
    }

    // Ensure eventDate is not null
    final finalEventDate = eventDate ?? DateTime.now();

    // Parse createdAt
    DateTime? createdAt;
    if (json['createdAt'] != null) {
      try {
        createdAt = DateTime.parse(json['createdAt'].toString());
      } catch (e) {

      }
    }
    createdAt ??= json['created_at'] != null
        ? DateTime.tryParse(json['created_at'].toString())
        : null;
    createdAt ??= DateTime.now();

    // Parse updatedAt
    DateTime? updatedAt;
    if (json['updatedAt'] != null) {
      try {
        updatedAt = DateTime.parse(json['updatedAt'].toString());
      } catch (e) {

      }
    }
    updatedAt ??= json['updated_at'] != null
        ? DateTime.tryParse(json['updated_at'].toString())
        : null;
    updatedAt ??= DateTime.now();

    // Parse invited_friends array from API response
    List<InvitedFriend> invitedFriendsList = [];
    if (json['invited_friends'] != null && json['invited_friends'] is List) {
      final invitedFriendsData = json['invited_friends'] as List<dynamic>;
      invitedFriendsList = invitedFriendsData
          .map((friendData) {
            try {
              if (friendData is Map<String, dynamic>) {
                return InvitedFriend.fromJson(friendData);
              } else if (friendData is String) {
                // If it's just an ID string, create InvitedFriend with ID only
                return InvitedFriend(id: friendData);
              }
              return null;
            } catch (e) {
              return null;
            }
          })
          .whereType<InvitedFriend>()
          .toList();
    }

    // Parse invitation_status directly from API (for invited events)
    InvitationStatus? invitationStatus;
    if (json['invitation_status'] != null) {
      final statusString = json['invitation_status'].toString().toLowerCase();
      invitationStatus = InvitationStatus.values.firstWhere(
        (e) => e.toString().split('.').last == statusString,
        orElse: () => InvitationStatus.pending,
      );
    }

    // Parse stats.accepted from API response
    int? statsAccepted;
    if (json['stats'] != null && json['stats'] is Map<String, dynamic>) {
      final stats = json['stats'] as Map<String, dynamic>;
      statsAccepted = stats['accepted'] as int?;
    }

    // Parse invitations - support both 'invitations' and 'invited'
    List<dynamic>? invitationsList;
    if (json['invitations'] != null && json['invitations'] is List) {
      invitationsList = json['invitations'] as List<dynamic>;
    } else if (json['invited'] != null && json['invited'] is List) {
      invitationsList = json['invited'] as List<dynamic>;
    }

    return Event(
      id: id,
      creatorId: creatorId,
      name: json['name']?.toString() ?? '',
      date: finalEventDate,
      time: eventTime,
      description: json['description']?.toString(),
      location: json['location']?.toString(),
      type: EventType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type']?.toString(),
        orElse: () => EventType.birthday,
      ),
      status: EventStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status']?.toString(),
        orElse: () => EventStatus.upcoming,
      ),
      wishlistId: wishlistId,
      wishlistName: wishlistName,
      wishlistItemCount: wishlistItemCount,
      invitations:
          invitationsList
              ?.map((invitation) {
                try {
                  return EventInvitation.fromJson(
                    invitation as Map<String, dynamic>,
                  );
                } catch (e) {

                  return null;
                }
              })
              .whereType<EventInvitation>()
              .toList() ??
          [],
      createdAt: createdAt,
      updatedAt: updatedAt,
      privacy: json['privacy']?.toString(),
      mode: json['mode']?.toString(),
      meetingLink:
          json['meeting_link']?.toString() ?? json['meetingLink']?.toString(),
      invitedFriends: invitedFriendsList,
      creatorName: creatorName,
      creatorImage: creatorImage,
      invitationStatus: invitationStatus,
      statsAccepted: statsAccepted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creator_id': creatorId,
      'name': name,
      'date': date.toIso8601String(),
      if (time != null) 'time': time,
      'description': description,
      'location': location,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'wishlist_id': wishlistId,
      'invitations': invitations
          .map((invitation) => invitation.toJson())
          .toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (privacy != null) 'privacy': privacy,
      if (mode != null) 'mode': mode,
      if (meetingLink != null) 'meeting_link': meetingLink,
      'invited_friends': invitedFriends.map((f) => f.id).toList(),
    };
  }

  Event copyWith({
    String? id,
    String? creatorId,
    String? name,
    DateTime? date,
    String? time,
    String? description,
    String? location,
    EventType? type,
    EventStatus? status,
    String? wishlistId,
    String? wishlistName,
    int? wishlistItemCount,
    List<EventInvitation>? invitations,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? privacy,
    String? mode,
    String? meetingLink,
    List<InvitedFriend>? invitedFriends,
    String? creatorName,
    String? creatorImage,
    InvitationStatus? invitationStatus,
    int? statsAccepted,
  }) {
    return Event(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      name: name ?? this.name,
      date: date ?? this.date,
      time: time ?? this.time,
      description: description ?? this.description,
      location: location ?? this.location,
      type: type ?? this.type,
      status: status ?? this.status,
      wishlistId: wishlistId ?? this.wishlistId,
      wishlistName: wishlistName ?? this.wishlistName,
      wishlistItemCount: wishlistItemCount ?? this.wishlistItemCount,
      invitations: invitations ?? this.invitations,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      privacy: privacy ?? this.privacy,
      mode: mode ?? this.mode,
      meetingLink: meetingLink ?? this.meetingLink,
      invitedFriends: invitedFriends ?? this.invitedFriends,
      creatorName: creatorName ?? this.creatorName,
      creatorImage: creatorImage ?? this.creatorImage,
      invitationStatus: invitationStatus ?? this.invitationStatus,
      statsAccepted: statsAccepted ?? this.statsAccepted,
    );
  }

  bool get isUpcoming => date.isAfter(DateTime.now());
  bool get isPast => date.isBefore(DateTime.now());
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  int get daysUntilEvent {
    final now = DateTime.now();
    final difference = date.difference(DateTime(now.year, now.month, now.day));
    return difference.inDays;
  }

  int get acceptedInvitations => invitations
      .where((invitation) => invitation.status == InvitationStatus.accepted)
      .length;

  int get pendingInvitations => invitations
      .where((invitation) => invitation.status == InvitationStatus.pending)
      .length;

  @override
  String toString() {
    return 'Event(id: $id, name: $name, date: $date, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Event && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class EventInvitation {
  final String id;
  final String eventId;
  final String inviterId;
  final String inviteeId;
  final InvitationStatus status;
  final DateTime sentAt;
  final DateTime? respondedAt;
  final String? message;

  EventInvitation({
    required this.id,
    required this.eventId,
    required this.inviterId,
    required this.inviteeId,
    this.status = InvitationStatus.pending,
    required this.sentAt,
    this.respondedAt,
    this.message,
  });

  factory EventInvitation.fromJson(Map<String, dynamic> json) {
    return EventInvitation(
      id: json['id'] ?? '',
      eventId: json['event_id'] ?? '',
      inviterId: json['inviter_id'] ?? '',
      inviteeId: json['invitee_id'] ?? '',
      status: InvitationStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => InvitationStatus.pending,
      ),
      sentAt: DateTime.parse(json['sent_at']),
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'])
          : null,
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'inviter_id': inviterId,
      'invitee_id': inviteeId,
      'status': status.toString().split('.').last,
      'sent_at': sentAt.toIso8601String(),
      'responded_at': respondedAt?.toIso8601String(),
      'message': message,
    };
  }

  EventInvitation copyWith({
    String? id,
    String? eventId,
    String? inviterId,
    String? inviteeId,
    InvitationStatus? status,
    DateTime? sentAt,
    DateTime? respondedAt,
    String? message,
  }) {
    return EventInvitation(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      inviterId: inviterId ?? this.inviterId,
      inviteeId: inviteeId ?? this.inviteeId,
      status: status ?? this.status,
      sentAt: sentAt ?? this.sentAt,
      respondedAt: respondedAt ?? this.respondedAt,
      message: message ?? this.message,
    );
  }

  @override
  String toString() {
    return 'EventInvitation(id: $id, eventId: $eventId, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventInvitation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum EventType {
  birthday,
  wedding,
  anniversary,
  graduation,
  holiday,
  vacation,
  babyShower,
  houseWarming,
  retirement,
  promotion,
  other,
}

enum EventStatus { upcoming, ongoing, completed, cancelled }

enum InvitationStatus { pending, accepted, declined, maybe }

enum EventMode { inPerson, online, hybrid }

/// Model for invited friend data from API
class InvitedFriend {
  final String id;
  final String? fullName;
  final String? username;
  final String? profileImage;
  final InvitationStatus? status; // Response status: accepted, declined, pending, maybe

  InvitedFriend({
    required this.id,
    this.fullName,
    this.username,
    this.profileImage,
    this.status,
  });

  factory InvitedFriend.fromJson(Map<String, dynamic> json) {
    // Parse status from API response
    InvitationStatus? parsedStatus;
    if (json['status'] != null) {
      final statusString = json['status'].toString().toLowerCase();
      parsedStatus = InvitationStatus.values.firstWhere(
        (e) => e.toString().split('.').last == statusString,
        orElse: () => InvitationStatus.pending,
      );
    } else if (json['invitation_status'] != null) {
      final statusString = json['invitation_status'].toString().toLowerCase();
      parsedStatus = InvitationStatus.values.firstWhere(
        (e) => e.toString().split('.').last == statusString,
        orElse: () => InvitationStatus.pending,
      );
    }
    
    // Handle new API structure: { user: {...}, status: "...", updatedAt: "..." }
    // OR old structure: { _id: "...", fullName: "...", ... }
    String? id;
    String? fullName;
    String? username;
    String? profileImage;
    
    if (json['user'] != null && json['user'] is Map<String, dynamic>) {
      // New API structure: data is inside 'user' object
      final userData = json['user'] as Map<String, dynamic>;
      id = userData['_id']?.toString() ?? userData['id']?.toString() ?? '';
      fullName = userData['fullName']?.toString();
      username = userData['username']?.toString();
      profileImage = userData['profileImage']?.toString() ?? userData['profile_image']?.toString();
    } else {
      // Old API structure: data is directly in the object
      id = json['_id']?.toString() ?? json['id']?.toString() ?? '';
      fullName = json['fullName']?.toString();
      username = json['username']?.toString();
      profileImage = json['profileImage']?.toString() ?? json['profile_image']?.toString();
    }
    
    return InvitedFriend(
      id: id ?? '',
      fullName: fullName,
      username: username,
      profileImage: profileImage,
      status: parsedStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      if (fullName != null) 'fullName': fullName,
      if (username != null) 'username': username,
      if (profileImage != null) 'profileImage': profileImage,
      if (status != null) 'status': status.toString().split('.').last,
    };
  }

  InvitedFriend copyWith({
    String? id,
    String? fullName,
    String? username,
    String? profileImage,
    InvitationStatus? status,
  }) {
    return InvitedFriend(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      profileImage: profileImage ?? this.profileImage,
      status: status ?? this.status,
    );
  }

  @override
  String toString() {
    return 'InvitedFriend(id: $id, fullName: $fullName, username: $username)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InvitedFriend && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

extension EventTypeExtension on EventType {
  String get displayName {
    switch (this) {
      case EventType.birthday:
        return 'Birthday';
      case EventType.wedding:
        return 'Wedding';
      case EventType.anniversary:
        return 'Anniversary';
      case EventType.graduation:
        return 'Graduation';
      case EventType.holiday:
        return 'Holiday';
      case EventType.vacation:
        return 'Vacation';
      case EventType.babyShower:
        return 'Baby Shower';
      case EventType.houseWarming:
        return 'House Warming';
      case EventType.retirement:
        return 'Retirement';
      case EventType.promotion:
        return 'Promotion';
      case EventType.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case EventType.birthday:
        return '🎂';
      case EventType.wedding:
        return '💒';
      case EventType.anniversary:
        return '💕';
      case EventType.graduation:
        return '🎓';
      case EventType.holiday:
        return '🎄';
      case EventType.vacation:
        return '🏖️';
      case EventType.babyShower:
        return '👶';
      case EventType.houseWarming:
        return '🏠';
      case EventType.retirement:
        return '🎊';
      case EventType.promotion:
        return '🎉';
      case EventType.other:
        return '🎈';
    }
  }
}

extension EventModeExtension on EventMode {
  String get apiValue {
    switch (this) {
      case EventMode.inPerson:
        return 'in_person';
      case EventMode.online:
        return 'online';
      case EventMode.hybrid:
        return 'hybrid';
    }
  }
  
  static EventMode fromString(String value) {
    switch (value.toLowerCase()) {
      case 'online':
        return EventMode.online;
      case 'hybrid':
        return EventMode.hybrid;
      case 'in_person':
      default:
        return EventMode.inPerson;
    }
  }
}

// Summary class for displaying events in lists
class EventSummary {
  final String id;
  final String name;
  final DateTime date;
  final String? time; // HH:mm format
  final EventType type;
  final String? location;
  final String? description;
  final String? hostName;
  final int invitedCount;
  final int acceptedCount;
  final int wishlistItemCount;
  final String? wishlistId;
  final bool isCreatedByMe;
  final EventStatus status;
  final InvitationStatus? invitationStatus; // User's RSVP status for invited events
  final String? creatorName; // Creator's full name
  final String? creatorImage; // Creator's profile image
  final String? creatorId; // Creator's ID for navigation

  EventSummary({
    required this.id,
    required this.name,
    required this.date,
    this.time,
    required this.type,
    this.location,
    this.description,
    this.hostName,
    required this.invitedCount,
    required this.acceptedCount,
    required this.wishlistItemCount,
    this.wishlistId,
    required this.isCreatedByMe,
    required this.status,
    this.invitationStatus,
    this.creatorName,
    this.creatorImage,
    this.creatorId,
  });

  factory EventSummary.fromEvent(Event event, {String? currentUserId}) {
    // Determine if event is created by current user
    final isCreatedByMe =
        currentUserId != null && event.creatorId == currentUserId;

    // Find user's invitation status if not the creator
    // Priority: Use invitationStatus from Event (from API invitation_status field)
    // Fallback: Search in event.invitations array
    InvitationStatus? invitationStatus;
    if (!isCreatedByMe && currentUserId != null) {
      // First, try to use invitationStatus directly from Event (from API)
      if (event.invitationStatus != null) {
        invitationStatus = event.invitationStatus;
      } else {
        // Fallback: Search in invitations array
        final userInvitation = event.invitations.firstWhere(
          (inv) => inv.inviteeId == currentUserId,
          orElse: () => EventInvitation(
            id: '',
            eventId: event.id,
            inviterId: event.creatorId, // Use event creator as inviter
            inviteeId: currentUserId,
            status: InvitationStatus.pending,
            sentAt: DateTime.now(),
          ),
        );
        invitationStatus = userInvitation.status;
      }
    }

    final acceptedFromInvitedFriends = event.invitedFriends.isNotEmpty
        ? event.invitedFriends
            .where((friend) => friend.status == InvitationStatus.accepted)
            .length
        : null;

    return EventSummary(
      id: event.id,
      name: event.name,
      date: event.date,
      time: event.time,
      type: event.type,
      location: event.location,
      description: event.description,
      hostName: null, // Would be fetched from creator/user info
      invitedCount: event.invitedFriends.isNotEmpty
          ? event.invitedFriends.length
          : event.invitations.length, // Fallback to invitations if invitedFriends is empty
      acceptedCount: event.statsAccepted ??
          acceptedFromInvitedFriends ??
          event.acceptedInvitations, // Fallback: invited_friends status count, then invitations count
      wishlistItemCount: event.wishlistItemCount ?? 0,
      wishlistId: event.wishlistId,
      isCreatedByMe: isCreatedByMe,
      status: event.status,
      invitationStatus: invitationStatus,
      creatorName: event.creatorName,
      creatorImage: event.creatorImage,
      creatorId: event.creatorId,
    );
  }

  EventSummary copyWith({
    String? id,
    String? name,
    DateTime? date,
    String? time,
    EventType? type,
    String? location,
    String? description,
    String? hostName,
    int? invitedCount,
    int? acceptedCount,
    int? wishlistItemCount,
    String? wishlistId,
    bool? isCreatedByMe,
    EventStatus? status,
    InvitationStatus? invitationStatus,
    String? creatorName,
    String? creatorImage,
    String? creatorId,
  }) {
    return EventSummary(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
      time: time ?? this.time,
      type: type ?? this.type,
      location: location ?? this.location,
      description: description ?? this.description,
      hostName: hostName ?? this.hostName,
      invitedCount: invitedCount ?? this.invitedCount,
      acceptedCount: acceptedCount ?? this.acceptedCount,
      wishlistItemCount: wishlistItemCount ?? this.wishlistItemCount,
      wishlistId: wishlistId ?? this.wishlistId,
      isCreatedByMe: isCreatedByMe ?? this.isCreatedByMe,
      status: status ?? this.status,
      invitationStatus: invitationStatus ?? this.invitationStatus,
      creatorName: creatorName ?? this.creatorName,
      creatorImage: creatorImage ?? this.creatorImage,
      creatorId: creatorId ?? this.creatorId,
    );
  }

  int get daysUntilEvent {
    final now = DateTime.now();
    final difference = date.difference(DateTime(now.year, now.month, now.day));
    return difference.inDays;
  }

  bool get isUpcoming => date.isAfter(DateTime.now());
  bool get isPast => date.isBefore(DateTime.now());
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
