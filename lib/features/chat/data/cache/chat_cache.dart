import 'package:wish_listy/features/chat/data/models/chat_message_model.dart';
import 'package:wish_listy/features/chat/data/models/conversation_model.dart';

class ChatCache {
  static final ChatCache _instance = ChatCache._internal();
  factory ChatCache() => _instance;
  ChatCache._internal();

  List<Conversation> _conversations = <Conversation>[];
  DateTime? _conversationsFetchedAt;
  final Map<String, List<ChatMessage>> _messagesByUserId =
      <String, List<ChatMessage>>{};

  List<Conversation> get conversations =>
      List<Conversation>.unmodifiable(_conversations);

  DateTime? get conversationsFetchedAt => _conversationsFetchedAt;

  bool get hasConversationsCache => _conversations.isNotEmpty;

  List<ChatMessage> getMessages(String userId) {
    return List<ChatMessage>.unmodifiable(
      _messagesByUserId[userId] ?? <ChatMessage>[],
    );
  }

  bool hasMessages(String userId) {
    return (_messagesByUserId[userId] ?? <ChatMessage>[]).isNotEmpty;
  }

  int _compareConversationsByActivity(Conversation a, Conversation b) {
    final byActivity = b.latestActivityAt.compareTo(a.latestActivityAt);
    if (byActivity != 0) return byActivity;
    return a.participantId.compareTo(b.participantId);
  }

  void setConversations(List<Conversation> conversations) {
    _conversations = List<Conversation>.from(conversations)
      ..sort(_compareConversationsByActivity);
    _conversationsFetchedAt = DateTime.now();
  }

  void upsertConversation(Conversation conversation) {
    final index = _conversations.indexWhere(
      (item) => item.participantId == conversation.participantId,
    );

    if (index == -1) {
      _conversations.insert(0, conversation);
    } else {
      _conversations[index] = conversation;
    }
    _conversations.sort(_compareConversationsByActivity);
    _conversationsFetchedAt = DateTime.now();
  }

  void removeConversation(String participantId) {
    _conversations.removeWhere((item) => item.participantId == participantId);
    _messagesByUserId.remove(participantId);
  }

  void setMessages(String userId, List<ChatMessage> messages) {
    _messagesByUserId[userId] = List<ChatMessage>.from(messages);
  }

  void appendMessage(String userId, ChatMessage message) {
    final list = _messagesByUserId.putIfAbsent(userId, () => <ChatMessage>[]);
    final exists = list.any((item) => item.id == message.id);
    if (!exists) {
      list.add(message);
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
  }

  void prependOlderMessages(String userId, List<ChatMessage> messages) {
    final list = _messagesByUserId.putIfAbsent(userId, () => <ChatMessage>[]);
    final existingIds = list.map((item) => item.id).toSet();
    final filtered = messages
        .where((item) => !existingIds.contains(item.id))
        .toList();
    list.insertAll(0, filtered);
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  void replaceMessage(String userId, String tempId, ChatMessage newMessage) {
    final list = _messagesByUserId[userId];
    if (list == null || list.isEmpty) return;
    final index = list.indexWhere((item) => item.id == tempId);
    if (index != -1) {
      list[index] = newMessage;
    }
    // Dedup by ID: the socket event may have already added the real message
    // before the HTTP response returned, leaving both local_xxx and abc123 then
    // abc123 twice after the replace above.
    final seen = <String>{};
    list.retainWhere((item) => seen.add(item.id));
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  void markAsReadByUser({required String userId, required DateTime readAt}) {
    final list = _messagesByUserId[userId];
    if (list == null || list.isEmpty) return;
    _messagesByUserId[userId] = list
        .map(
          (item) => item.isMine
              ? item.copyWith(readAt: readAt, isPending: false)
              : item,
        )
        .toList();
  }

  void invalidateConversation(String userId) {
    _messagesByUserId.remove(userId);
  }

  void clear() {
    _conversations = <Conversation>[];
    _conversationsFetchedAt = null;
    _messagesByUserId.clear();
  }
}
