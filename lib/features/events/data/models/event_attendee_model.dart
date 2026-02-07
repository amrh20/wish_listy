import 'package:flutter/foundation.dart';

enum AttendeeStatus { accepted, declined, maybe, pending, unknown }

AttendeeStatus attendeeStatusFromJson(dynamic value) {
  final v = value?.toString().toLowerCase();
  switch (v) {
    case 'accepted':
      return AttendeeStatus.accepted;
    case 'declined':
    case 'rejected':
      return AttendeeStatus.declined;
    case 'maybe':
      return AttendeeStatus.maybe;
    case 'pending':
      return AttendeeStatus.pending;
    default:
      return AttendeeStatus.unknown;
  }
}

@immutable
class EventAttendeeUserModel {
  final String fullName;
  final String username;
  final String? profileImage;

  const EventAttendeeUserModel({
    required this.fullName,
    required this.username,
    this.profileImage,
  });

  factory EventAttendeeUserModel.fromJson(Map<String, dynamic> json) {
    return EventAttendeeUserModel(
      fullName: json['fullName']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      profileImage: json['profileImage']?.toString(),
    );
  }
}

@immutable
class EventAttendeeInvitedByModel {
  final String fullName;
  final String username;

  const EventAttendeeInvitedByModel({
    required this.fullName,
    required this.username,
  });

  factory EventAttendeeInvitedByModel.fromJson(Map<String, dynamic> json) {
    return EventAttendeeInvitedByModel(
      fullName: json['fullName']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
    );
  }
}

@immutable
class EventAttendeeModel {
  final EventAttendeeUserModel user;
  final AttendeeStatus status;
  final EventAttendeeInvitedByModel? invitedBy;
  final DateTime? respondedAt;
  final DateTime? invitedAt;

  const EventAttendeeModel({
    required this.user,
    required this.status,
    this.invitedBy,
    this.respondedAt,
    this.invitedAt,
  });

  factory EventAttendeeModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    final userJson = json['user'] as Map<String, dynamic>? ?? const {};
    final invitedByJson = json['invitedBy'];

    return EventAttendeeModel(
      user: EventAttendeeUserModel.fromJson(userJson),
      status: attendeeStatusFromJson(json['status']),
      invitedBy: invitedByJson is Map<String, dynamic>
          ? EventAttendeeInvitedByModel.fromJson(invitedByJson)
          : null,
      respondedAt: parseDate(json['respondedAt']),
      invitedAt: parseDate(json['invitedAt']),
    );
  }
}

@immutable
class EventAttendeeStatsModel {
  final int totalCount;
  final int accepted;
  final int declined;
  final int maybe;
  final int pending;

  const EventAttendeeStatsModel({
    required this.totalCount,
    required this.accepted,
    required this.declined,
    required this.maybe,
    required this.pending,
  });

  factory EventAttendeeStatsModel.fromJson({
    required dynamic totalCount,
    required dynamic statusCounts,
  }) {
    final tc = (totalCount as num?)?.toInt() ?? 0;
    final counts = statusCounts is Map ? statusCounts as Map : const {};
    return EventAttendeeStatsModel(
      totalCount: tc,
      accepted: (counts['accepted'] as num?)?.toInt() ?? 0,
      declined: (counts['declined'] as num?)?.toInt() ?? 0,
      maybe: (counts['maybe'] as num?)?.toInt() ?? 0,
      pending: (counts['pending'] as num?)?.toInt() ?? 0,
    );
  }
}

