import 'package:equatable/equatable.dart';
import 'package:wish_listy/features/chat/data/models/chat_message_model.dart';
import 'package:wish_listy/features/chat/data/models/chat_participant_model.dart';

class Conversation extends Equatable {
  final String participantId;
  final String chatRoomId;
  final ChatParticipant participant;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final DateTime updatedAt;

  const Conversation({
    required this.participantId,
    required this.chatRoomId,
    required this.participant,
    required this.lastMessage,
    required this.unreadCount,
    required this.updatedAt,
  });

  static String _toStringValue(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    if (value is String) return value;
    return value.toString();
  }

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value)?.toLocal() ?? DateTime.now();
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value).toLocal();
    }
    return DateTime.now();
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.map((key, val) => MapEntry(key.toString(), val));
    return const {};
  }

  static Map<String, dynamic> _resolveParticipantJson(
    Map<String, dynamic> json, {
    String? currentUserId,
    Map<String, dynamic>? lastMessageJson,
  }) {
    for (final key in [
      'participant',
      'user',
      'otherUser',
      'other_user',
      'peer',
      'otherParticipant',
      'other_participant',
      'friend',
    ]) {
      final candidate = _asMap(json[key]);
      if (candidate.isNotEmpty) return candidate;
    }

    final participants = json['participants'];
    if (participants is List) {
      for (final entry in participants) {
        final participantEntry = _asMap(entry);
        if (participantEntry.isEmpty) continue;

        final userMap = _asMap(participantEntry['user']);
        final resolved = userMap.isNotEmpty ? userMap : participantEntry;
        final entryId = _toStringValue(
          resolved['_id'] ??
              resolved['id'] ??
              resolved['userId'] ??
              participantEntry['userId'] ??
              participantEntry['_id'],
        );
        if (entryId.isEmpty) continue;
        if (currentUserId == null ||
            currentUserId.isEmpty ||
            entryId != currentUserId) {
          return resolved;
        }
      }
    }

    if (lastMessageJson != null) {
      final sender = _asMap(lastMessageJson['sender']);
      final recipient = _asMap(lastMessageJson['recipient']);
      final senderId = _toStringValue(
        lastMessageJson['senderId'] ??
            lastMessageJson['sender_id'] ??
            sender['_id'] ??
            sender['id'],
      );
      final recipientId = _toStringValue(
        lastMessageJson['recipientId'] ??
            lastMessageJson['recipient_id'] ??
            recipient['_id'] ??
            recipient['id'],
      );

      if (currentUserId != null && currentUserId.isNotEmpty) {
        if (senderId == currentUserId && recipient.isNotEmpty) {
          return recipient;
        }
        if (recipientId == currentUserId && sender.isNotEmpty) {
          return sender;
        }
      }

      if (sender.isNotEmpty && senderId != currentUserId) return sender;
      if (recipient.isNotEmpty && recipientId != currentUserId) {
        return recipient;
      }
    }

    return const {};
  }

  factory Conversation.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    final lastMessageJson = (json['lastMessage'] is Map<String, dynamic>)
        ? json['lastMessage'] as Map<String, dynamic>
        : (json['message'] is Map<String, dynamic>)
        ? json['message'] as Map<String, dynamic>
        : null;

    final participantJson = _resolveParticipantJson(
      json,
      currentUserId: currentUserId,
      lastMessageJson: lastMessageJson,
    );

    final participant = ChatParticipant.fromJson(participantJson);
    final participantId = _toStringValue(
      json['participantId'] ??
          json['participant_id'] ??
          json['otherUserId'] ??
          json['other_user_id'] ??
          participantJson['_id'] ??
          participantJson['id'],
    );

    final updatedAt = _parseDate(
      json['updatedAt'] ??
          json['updated_at'] ??
          json['lastMessageAt'] ??
          json['last_message_at'] ??
          lastMessageJson?['createdAt'] ??
          lastMessageJson?['created_at'],
    );

    final chatRoomId = _toStringValue(
      json['chatRoomId'] ??
          json['chat_room_id'] ??
          json['conversationId'] ??
          json['conversation_id'] ??
          json['roomId'] ??
          json['room_id'] ??
          json['_id'] ??
          json['id'],
    );

    return Conversation(
      participantId: participantId,
      chatRoomId: chatRoomId,
      participant: participant.copyWith(
        id: participantId.isEmpty ? participant.id : participantId,
      ),
      lastMessage: lastMessageJson == null
          ? null
          : ChatMessage.fromJson(lastMessageJson, currentUserId: currentUserId),
      unreadCount: _parseInt(json['unreadCount'] ?? json['unread_count']),
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'participantId': participantId,
      'chatRoomId': chatRoomId,
      'participant': participant.toJson(),
      if (lastMessage != null) 'lastMessage': lastMessage!.toJson(),
      'unreadCount': unreadCount,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Conversation copyWith({
    String? participantId,
    String? chatRoomId,
    ChatParticipant? participant,
    ChatMessage? lastMessage,
    bool clearLastMessage = false,
    int? unreadCount,
    DateTime? updatedAt,
  }) {
    return Conversation(
      participantId: participantId ?? this.participantId,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      participant: participant ?? this.participant,
      lastMessage: clearLastMessage ? null : (lastMessage ?? this.lastMessage),
      unreadCount: unreadCount ?? this.unreadCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    participantId,
    chatRoomId,
    participant,
    lastMessage,
    unreadCount,
    updatedAt,
  ];
}
