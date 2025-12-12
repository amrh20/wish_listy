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
  final List<EventInvitation> invitations;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? privacy; // 'public', 'private', 'friends_only'
  final String? mode; // 'in_person', 'online', 'hybrid'
  final String? meetingLink; // For online/hybrid events

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
    this.invitations = const [],
    required this.createdAt,
    required this.updatedAt,
    this.privacy,
    this.mode,
    this.meetingLink,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    // Handle both API response formats:
    // 1. {_id: "...", creator: {_id: "..."}, ...} (MongoDB format)
    // 2. {id: "...", creator_id: "...", ...} (standard format)

    // Get ID - support both _id (MongoDB) and id
    final id = json['_id']?.toString() ?? json['id']?.toString() ?? '';

    // Get creator ID - support both creator object and creator_id
    String? creatorId;
    if (json['creator'] != null && json['creator'] is Map) {
      creatorId =
          json['creator']['_id']?.toString() ??
          json['creator']['id']?.toString();
    }
    creatorId ??=
        json['creator_id']?.toString() ?? json['creatorId']?.toString() ?? '';

    // Get wishlist ID - support both wishlist object and wishlist_id
    String? wishlistId;
    if (json['wishlist'] != null) {
      if (json['wishlist'] is Map) {
        wishlistId =
            json['wishlist']['_id']?.toString() ??
            json['wishlist']['id']?.toString();
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
        debugPrint('⚠️ Failed to parse date: ${json['date']}');
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
        debugPrint('⚠️ Failed to parse time: ${json['time']}');
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
        debugPrint('⚠️ Failed to parse createdAt: ${json['createdAt']}');
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
        debugPrint('⚠️ Failed to parse updatedAt: ${json['updatedAt']}');
      }
    }
    updatedAt ??= json['updated_at'] != null
        ? DateTime.tryParse(json['updated_at'].toString())
        : null;
    updatedAt ??= DateTime.now();

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
      invitations:
          invitationsList
              ?.map((invitation) {
                try {
                  return EventInvitation.fromJson(
                    invitation as Map<String, dynamic>,
                  );
                } catch (e) {
                  debugPrint('⚠️ Failed to parse invitation: $e');
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
    List<EventInvitation>? invitations,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? privacy,
    String? mode,
    String? meetingLink,
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
      invitations: invitations ?? this.invitations,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      privacy: privacy ?? this.privacy,
      mode: mode ?? this.mode,
      meetingLink: meetingLink ?? this.meetingLink,
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

enum InvitationStatus { pending, accepted, declined }

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
  });

  factory EventSummary.fromEvent(Event event, {String? currentUserId}) {
    // Determine if event is created by current user
    final isCreatedByMe =
        currentUserId != null && event.creatorId == currentUserId;

    return EventSummary(
      id: event.id,
      name: event.name,
      date: event.date,
      time: event.time,
      type: event.type,
      location: event.location,
      description: event.description,
      hostName: null, // Would be fetched from creator/user info
      invitedCount: event.invitations.length,
      acceptedCount: event.acceptedInvitations,
      wishlistItemCount: 0, // Would be calculated from backend
      wishlistId: event.wishlistId,
      isCreatedByMe: isCreatedByMe,
      status: event.status,
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
