import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/features/chat/data/models/chat_message_model.dart';
import 'package:wish_listy/features/chat/data/models/conversation_model.dart';

class ChatMessagesResult {
  final List<ChatMessage> messages;
  final String? conversationId;

  const ChatMessagesResult({
    required this.messages,
    this.conversationId,
  });
}

class ChatRepository {
  final ApiService _apiService = ApiService();

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static List<dynamic> _extractList(dynamic data, {String nestedKey = 'messages'}) {
    if (data is List) return data;
    if (data is Map) {
      final nested = data[nestedKey];
      if (nested is List) return nested;
    }
    return const [];
  }

  static String? _extractConversationId(dynamic data) {
    if (data is! Map) return null;
    final raw =
        data['conversationId'] ??
        data['conversation_id'] ??
        data['_id'] ??
        data['chatRoomId'];
    final value = raw?.toString().trim();
    return (value == null || value.isEmpty) ? null : value;
  }

  static Map<String, dynamic>? _asStringKeyedMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.map((key, val) => MapEntry(key.toString(), val));
    return null;
  }

  Future<List<Conversation>> fetchConversations({String? currentUserId}) async {
    try {
      final response = await _apiService.get('/chat/conversations');
      final list = _extractList(response['data']);

      return list
          .whereType<Map>()
          .map(
            (item) => Conversation.fromJson(
              item.cast<String, dynamic>(),
              currentUserId: currentUserId,
            ),
          )
          .toList();
    } on ApiException {
      rethrow;
    } catch (_) {
      throw Exception('Failed to load conversations. Please try again.');
    }
  }

  Future<int> fetchUnreadCount() async {
    try {
      final response = await _apiService.get('/chat/unread-count');
      final data = response['data'];
      final rawValue = (data is Map ? data['unreadConversations'] : null) ??
          (data is Map ? data['unreadCount'] : null) ??
          (data is Map ? data['count'] : null) ??
          response['unreadConversations'] ??
          response['unreadCount'] ??
          response['count'];
      return _toInt(rawValue);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw Exception(
        'Failed to load unread messages count. Please try again.',
      );
    }
  }

  Future<ChatMessagesResult> fetchMessages({
    required String userId,
    DateTime? before,
    String? currentUserId,
  }) async {
    try {
      final response = await _apiService.get(
        '/chat/conversations/$userId/messages',
        queryParameters: {
          if (before != null) 'before': before.toUtc().toIso8601String(),
        },
      );

      final data = response['data'];
      final conversationId = _extractConversationId(data);
      final list = _extractList(
        data,
        nestedKey: 'messages',
      );
      if (list.isEmpty && data is! Map) {
        final fallback = _extractList(response['messages']);
        return ChatMessagesResult(
          messages: _mapMessages(
            fallback,
            currentUserId: currentUserId,
            conversationId: conversationId,
          ),
          conversationId: conversationId,
        );
      }

      return ChatMessagesResult(
        messages: _mapMessages(
          list,
          currentUserId: currentUserId,
          conversationId: conversationId,
        ),
        conversationId: conversationId,
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw Exception('Failed to load chat history. Please try again.');
    }
  }

  Future<ChatMessage> sendMessage({
    required String recipientId,
    required String text,
    String? currentUserId,
    String? replyToMessageId,
  }) async {
    try {
      final response = await _apiService.post(
        '/chat/messages',
        data: {
          'recipientId': recipientId,
          'text': text,
          if (replyToMessageId != null && replyToMessageId.trim().isNotEmpty)
            'replyToMessageId': replyToMessageId.trim(),
        },
      );

      final data = _asStringKeyedMap(response['data']);
      final messageJson = _asStringKeyedMap(data?['message']) ??
          _asStringKeyedMap(response['message']);
      if (messageJson == null) {
        throw Exception('Invalid send message response.');
      }

      final conversationId = _extractConversationId(data);
      var message = ChatMessage.fromJson(messageJson, currentUserId: currentUserId);
      if ((message.chatRoomId == null || message.chatRoomId!.isEmpty) &&
          conversationId != null) {
        message = message.copyWith(chatRoomId: conversationId);
      }

      return message;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw Exception('Failed to send message. Please try again.');
    }
  }

  Future<void> markConversationRead({required String userId}) async {
    try {
      await _apiService.patch('/chat/conversations/$userId/read');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw Exception('Failed to mark messages as read.');
    }
  }

  List<ChatMessage> _mapMessages(
    List<dynamic> list, {
    String? currentUserId,
    String? conversationId,
  }) {
    return list
        .whereType<Map>()
        .map((item) {
          var message = ChatMessage.fromJson(
            item.cast<String, dynamic>(),
            currentUserId: currentUserId,
          );
          if ((message.chatRoomId == null || message.chatRoomId!.isEmpty) &&
              conversationId != null) {
            message = message.copyWith(chatRoomId: conversationId);
          }
          return message;
        })
        .toList();
  }
}
