class Event {
  final String id;
  final String creatorId;
  final String name;
  final DateTime date;
  final String? description;
  final String? location;
  final EventType type;
  final EventStatus status;
  final String? wishlistId;
  final List<EventInvitation> invitations;
  final DateTime createdAt;
  final DateTime updatedAt;

  Event({
    required this.id,
    required this.creatorId,
    required this.name,
    required this.date,
    this.description,
    this.location,
    required this.type,
    this.status = EventStatus.upcoming,
    this.wishlistId,
    this.invitations = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] ?? '',
      creatorId: json['creator_id'] ?? '',
      name: json['name'] ?? '',
      date: DateTime.parse(json['date']),
      description: json['description'],
      location: json['location'],
      type: EventType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => EventType.birthday,
      ),
      status: EventStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => EventStatus.upcoming,
      ),
      wishlistId: json['wishlist_id'],
      invitations:
          (json['invitations'] as List<dynamic>?)
              ?.map((invitation) => EventInvitation.fromJson(invitation))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creator_id': creatorId,
      'name': name,
      'date': date.toIso8601String(),
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
    };
  }

  Event copyWith({
    String? id,
    String? creatorId,
    String? name,
    DateTime? date,
    String? description,
    String? location,
    EventType? type,
    EventStatus? status,
    String? wishlistId,
    List<EventInvitation>? invitations,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      name: name ?? this.name,
      date: date ?? this.date,
      description: description ?? this.description,
      location: location ?? this.location,
      type: type ?? this.type,
      status: status ?? this.status,
      wishlistId: wishlistId ?? this.wishlistId,
      invitations: invitations ?? this.invitations,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
  final EventType type;
  final String? location;
  final int invitedCount;
  final int acceptedCount;
  final int wishlistItemCount;
  final bool isCreatedByMe;
  final EventStatus status;

  EventSummary({
    required this.id,
    required this.name,
    required this.date,
    required this.type,
    this.location,
    required this.invitedCount,
    required this.acceptedCount,
    required this.wishlistItemCount,
    required this.isCreatedByMe,
    required this.status,
  });

  factory EventSummary.fromEvent(Event event) {
    return EventSummary(
      id: event.id,
      name: event.name,
      date: event.date,
      type: event.type,
      location: event.location,
      invitedCount: event.invitations.length,
      acceptedCount: event.acceptedInvitations,
      wishlistItemCount: 0, // Would be calculated from backend
      isCreatedByMe:
          false, // Would be determined by comparing with current user
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
