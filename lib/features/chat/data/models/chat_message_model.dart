import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  final String id;
  final String senderId;
  final String recipientId;
  final String text;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? chatRoomId;
  final bool isMine;
  final bool isPending;
  final bool isFailed;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.text,
    required this.createdAt,
    this.readAt,
    this.chatRoomId,
    this.isMine = false,
    this.isPending = false,
    this.isFailed = false,
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

  factory ChatMessage.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    final sender = (json['sender'] is Map<String, dynamic>)
        ? json['sender'] as Map<String, dynamic>
        : null;
    final recipient = (json['recipient'] is Map<String, dynamic>)
        ? json['recipient'] as Map<String, dynamic>
        : null;

    final senderId = _toStringValue(
      json['senderId'] ??
          json['sender_id'] ??
          sender?['_id'] ??
          sender?['id'] ??
          (json['sender'] is String ? json['sender'] : null),
    );
    final recipientId = _toStringValue(
      json['recipientId'] ??
          json['recipient_id'] ??
          recipient?['_id'] ??
          recipient?['id'] ??
          (json['recipient'] is String ? json['recipient'] : null),
    );
    final createdAt = _parseDate(
      json['createdAt'] ?? json['created_at'] ?? json['timestamp'],
    );
    final readAtValue = json['readAt'] ??
        json['read_at'] ??
        (json['isRead'] == true ? json['updatedAt'] ?? json['updated_at'] : null);

    final chatRoomId = _toStringValue(
      json['chatRoomId'] ??
          json['chat_room_id'] ??
          json['roomId'] ??
          json['conversationId'] ??
          json['conversation_id'] ??
          json['conversation'],
    );

    return ChatMessage(
      id: _toStringValue(
        json['_id'] ?? json['id'] ?? json['messageId'] ?? json['message_id'],
        fallback: DateTime.now().microsecondsSinceEpoch.toString(),
      ),
      senderId: senderId,
      recipientId: recipientId,
      text: _toStringValue(json['text'] ?? json['message']),
      createdAt: createdAt,
      readAt: readAtValue != null ? _parseDate(readAtValue) : null,
      chatRoomId: chatRoomId.isEmpty ? null : chatRoomId,
      isMine: currentUserId != null && senderId == currentUserId,
      isPending: json['isPending'] == true,
      isFailed: json['isFailed'] == true,
    );
  }

  factory ChatMessage.optimistic({
    required String senderId,
    required String recipientId,
    required String text,
    String? chatRoomId,
  }) {
    return ChatMessage(
      id: 'local_${DateTime.now().microsecondsSinceEpoch}',
      senderId: senderId,
      recipientId: recipientId,
      text: text,
      createdAt: DateTime.now(),
      chatRoomId: chatRoomId,
      isMine: true,
      isPending: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'senderId': senderId,
      'recipientId': recipientId,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      if (readAt != null) 'readAt': readAt!.toIso8601String(),
      if (chatRoomId != null) 'chatRoomId': chatRoomId,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? recipientId,
    String? text,
    DateTime? createdAt,
    DateTime? readAt,
    bool resetReadAt = false,
    String? chatRoomId,
    bool? isMine,
    bool? isPending,
    bool? isFailed,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      readAt: resetReadAt ? null : (readAt ?? this.readAt),
      chatRoomId: chatRoomId ?? this.chatRoomId,
      isMine: isMine ?? this.isMine,
      isPending: isPending ?? this.isPending,
      isFailed: isFailed ?? this.isFailed,
    );
  }

  bool get isRead => readAt != null;

  @override
  List<Object?> get props => [
    id,
    senderId,
    recipientId,
    text,
    createdAt,
    readAt,
    chatRoomId,
    isMine,
    isPending,
    isFailed,
  ];
}
