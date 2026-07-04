import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/core/services/socket_service.dart';
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';
import 'package:wish_listy/features/chat/data/cache/chat_cache.dart';
import 'package:wish_listy/features/chat/data/models/chat_message_model.dart';
import 'package:wish_listy/features/chat/data/repository/chat_repository.dart';
import 'package:wish_listy/features/chat/presentation/cubit/chat_room_state.dart';

class ChatRoomCubit extends Cubit<ChatRoomState> {
  final ChatRepository _chatRepository;
  final ChatCache _chatCache;
  final SocketService _socketService;
  final AuthRepository _authRepository;

  final String userId;
  String? _chatRoomId;

  Timer? _typingDebounce;
  bool _typingSent = false;
  bool _isFetchingOlder = false;

  ChatRoomCubit({
    required this.userId,
    String? chatRoomId,
    ChatRepository? chatRepository,
    ChatCache? chatCache,
    SocketService? socketService,
    AuthRepository? authRepository,
  }) : _chatRepository = chatRepository ?? ChatRepository(),
       _chatCache = chatCache ?? ChatCache(),
       _socketService = socketService ?? SocketService(),
       _authRepository = authRepository ?? AuthRepository(),
       _chatRoomId = chatRoomId,
       super(const ChatRoomLoading());

  String get currentUserId => _authRepository.userId ?? '';

  Future<void> initialize() async {
    if (_authRepository.isGuest ||
        currentUserId.isEmpty ||
        userId.trim().isEmpty) {
      emit(const ChatRoomError('Unable to open this conversation right now.'));
      return;
    }

    _attachSocketListeners();
    _socketService.announceOnline();

    final cachedMessages = _chatCache.getMessages(userId);
    if (cachedMessages.isNotEmpty) {
      emit(
        ChatRoomLoaded(
          messages: cachedMessages,
          isConnected: _socketService.isConnected,
        ),
      );
    }

    await _loadInitialMessages();
    await markAsRead();

    if (_chatRoomId != null && _chatRoomId!.trim().isNotEmpty) {
      _socketService.joinRoom(_chatRoomId!.trim());
    }
  }

  Future<void> _loadInitialMessages() async {
    if (state is! ChatRoomLoading && _chatCache.hasMessages(userId)) return;

    try {
      final result = await _chatRepository.fetchMessages(
        userId: userId,
        currentUserId: currentUserId,
      );
      final messages = result.messages;
      final sorted = List<ChatMessage>.from(messages)
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      _chatCache.setMessages(userId, sorted);
      _chatRoomId ??=
          result.conversationId ?? _extractChatRoomId(sorted);
      emit(
        ChatRoomLoaded(
          messages: sorted,
          hasMoreMessages: messages.isNotEmpty,
          isConnected: _socketService.isConnected,
        ),
      );
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        emit(ChatRoomRestricted(message: e.message));
      } else {
        emit(ChatRoomError(e.message));
      }
    } catch (_) {
      emit(const ChatRoomError('Failed to load conversation.'));
    }
  }

  Future<void> loadOlderMessages() async {
    final current = state;
    if (current is! ChatRoomLoaded) return;
    if (_isFetchingOlder ||
        !current.hasMoreMessages ||
        current.messages.isEmpty)
      return;

    _isFetchingOlder = true;
    emit(current.copyWith(isLoadingMore: true));

    try {
      final oldest = current.messages.first.createdAt;
      final olderResult = await _chatRepository.fetchMessages(
        userId: userId,
        before: oldest,
        currentUserId: currentUserId,
      );
      final olderMessages = olderResult.messages;

      if (olderMessages.isEmpty) {
        emit(current.copyWith(isLoadingMore: false, hasMoreMessages: false));
        _isFetchingOlder = false;
        return;
      }

      final merged = <ChatMessage>[...olderMessages, ...current.messages]
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      _chatCache.prependOlderMessages(userId, olderMessages);
      emit(
        current.copyWith(
          messages: _dedupeMessages(merged),
          isLoadingMore: false,
          hasMoreMessages: true,
        ),
      );
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        emit(
          ChatRoomRestricted(
            message: e.message,
            messages: current.messages,
            isConnected: current.isConnected,
          ),
        );
      } else {
        emit(current.copyWith(isLoadingMore: false, infoMessage: e.message));
      }
    } catch (_) {
      emit(
        current.copyWith(
          isLoadingMore: false,
          infoMessage: 'Failed to load older messages.',
        ),
      );
    } finally {
      _isFetchingOlder = false;
    }
  }

  Future<void> sendMessage(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || text.length > 4000) return;

    final current = state;
    if (current is! ChatRoomLoaded || current.isRestricted) return;

    final optimistic = ChatMessage.optimistic(
      senderId: currentUserId,
      recipientId: userId,
      text: text,
      chatRoomId: _chatRoomId,
    );

    final optimisticMessages = <ChatMessage>[...current.messages, optimistic];
    _chatCache.appendMessage(userId, optimistic);
    emit(current.copyWith(messages: optimisticMessages, isSending: true));

    _emitStopTyping();

    try {
      final serverMessage = await _chatRepository.sendMessage(
        recipientId: userId,
        text: text,
        currentUserId: currentUserId,
      );

      _chatRoomId ??= serverMessage.chatRoomId;
      if (_chatRoomId != null && _chatRoomId!.isNotEmpty) {
        _socketService.joinRoom(_chatRoomId!);
      }

      final latestState = state is ChatRoomLoaded
          ? state as ChatRoomLoaded
          : current;
      final replaced =
          latestState.messages
              .map((item) => item.id == optimistic.id ? serverMessage : item)
              .toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      _chatCache.replaceMessage(userId, optimistic.id, serverMessage);
      emit(
        latestState.copyWith(
          messages: _dedupeMessages(replaced),
          isSending: false,
          clearInfoMessage: true,
        ),
      );
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        emit(
          ChatRoomRestricted(
            message: e.message,
            messages: current.messages,
            isConnected: current.isConnected,
          ),
        );
        return;
      }

      final latestState = state is ChatRoomLoaded
          ? state as ChatRoomLoaded
          : current;
      final failed = latestState.messages
          .map(
            (item) => item.id == optimistic.id
                ? item.copyWith(isPending: false, isFailed: true)
                : item,
          )
          .toList();
      _chatCache.setMessages(userId, failed);

      emit(
        latestState.copyWith(
          messages: failed,
          isSending: false,
          infoMessage: e.message,
        ),
      );
    } catch (_) {
      final latestState = state is ChatRoomLoaded
          ? state as ChatRoomLoaded
          : current;
      final failed = latestState.messages
          .map(
            (item) => item.id == optimistic.id
                ? item.copyWith(isPending: false, isFailed: true)
                : item,
          )
          .toList();
      _chatCache.setMessages(userId, failed);

      emit(
        latestState.copyWith(
          messages: failed,
          isSending: false,
          infoMessage: 'Failed to send message.',
        ),
      );
    }
  }

  Future<void> markAsRead() async {
    try {
      await _chatRepository.markConversationRead(userId: userId);
    } on ApiException {
      // Best-effort operation; no UI interruption.
    } catch (_) {
      // Best-effort operation; no UI interruption.
    }
  }

  void onInputChanged(String text) {
    if (state is! ChatRoomLoaded) return;
    if ((state as ChatRoomLoaded).isRestricted) return;

    if (text.trim().isEmpty) {
      _emitStopTyping();
      return;
    }

    if (!_typingSent) {
      _typingSent = true;
      _socketService.emitTyping(
        recipientId: userId,
        conversationId: _chatRoomId,
      );
    }

    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(milliseconds: 700), _emitStopTyping);
  }

  void _emitStopTyping() {
    _typingDebounce?.cancel();
    if (!_typingSent) return;
    _typingSent = false;
    _socketService.emitStopTyping(
      recipientId: userId,
      conversationId: _chatRoomId,
    );
  }

  void _attachSocketListeners() {
    _socketService.addOnConnectListener(_onSocketConnected);
    _socketService.addChatMessageListener(_onSocketMessageReceived);
    _socketService.addChatReadListener(_onMessagesRead);
    _socketService.addTypingListener(_onTypingEvent);
    _socketService.addUserStatusListener(_onUserStatusEvent);
  }

  void _onUserStatusEvent(Map<String, dynamic> payload) {
    final peerId = (payload['userId'] ?? payload['user_id'])?.toString();
    if (peerId != userId) return;

    final status = payload['status']?.toString().toLowerCase();
    final isOnline = status == 'online';

    final current = state;
    if (current is ChatRoomLoaded) {
      emit(current.copyWith(isPeerOnline: isOnline));
    } else if (current is ChatRoomRestricted) {
      emit(current.copyWith(isPeerOnline: isOnline));
    }
  }

  void _onSocketConnected() {
    _socketService.announceOnline();

    final current = state;
    if (current is ChatRoomLoaded) {
      emit(current.copyWith(isConnected: true));
    } else if (current is ChatRoomRestricted) {
      emit(current.copyWith(isConnected: true));
    }
    if (_chatRoomId != null && _chatRoomId!.trim().isNotEmpty) {
      _socketService.joinRoom(_chatRoomId!);
    }
  }

  void setConnectionStatus(bool isConnected) {
    final current = state;
    if (current is ChatRoomLoaded) {
      emit(current.copyWith(isConnected: isConnected));
    } else if (current is ChatRoomRestricted) {
      emit(current.copyWith(isConnected: isConnected));
    }
  }

  void _onSocketMessageReceived(Map<String, dynamic> payload) {
    if (state is! ChatRoomLoaded && state is! ChatRoomRestricted) return;

    final messageJson = _extractMessagePayload(payload);
    if (messageJson == null) return;

    var message = ChatMessage.fromJson(
      messageJson,
      currentUserId: currentUserId,
    );
    final conversationId =
        payload['conversationId']?.toString() ?? payload['chatRoomId']?.toString();
    if ((message.chatRoomId == null || message.chatRoomId!.isEmpty) &&
        conversationId != null &&
        conversationId.isNotEmpty) {
      message = message.copyWith(chatRoomId: conversationId);
    }
    final participantId = message.senderId == currentUserId
        ? message.recipientId
        : message.senderId;
    if (participantId != userId) return;

    _chatRoomId ??= message.chatRoomId;
    if (_chatRoomId != null && _chatRoomId!.isNotEmpty) {
      _socketService.joinRoom(_chatRoomId!);
    }

    final existingMessages = state is ChatRoomLoaded
        ? (state as ChatRoomLoaded).messages
        : (state as ChatRoomRestricted).messages;
    final merged = _dedupeMessages(<ChatMessage>[...existingMessages, message]);
    _chatCache.setMessages(userId, merged);

    if (state is ChatRoomRestricted) {
      final restricted = state as ChatRoomRestricted;
      emit(restricted.copyWith(messages: merged));
    } else {
      final loaded = state as ChatRoomLoaded;
      emit(loaded.copyWith(messages: merged, clearInfoMessage: true));
    }
  }

  void _onMessagesRead(Map<String, dynamic> payload) {
    final current = state;
    if (current is! ChatRoomLoaded && current is! ChatRoomRestricted) return;

    final participantId =
        (payload['userId'] ??
                payload['participantId'] ??
                payload['readerId'] ??
                payload['readBy'] ??
                payload['data']?['userId'])
            ?.toString();
    if (participantId != userId) return;

    final readAtRaw =
        payload['readAt'] ??
        payload['timestamp'] ??
        DateTime.now().toIso8601String();
    final readAt =
        DateTime.tryParse(readAtRaw.toString())?.toLocal() ?? DateTime.now();

    final sourceMessages = current is ChatRoomLoaded
        ? current.messages
        : (current as ChatRoomRestricted).messages;
    final updated = sourceMessages
        .map(
          (message) =>
              message.isMine ? message.copyWith(readAt: readAt) : message,
        )
        .toList();

    _chatCache.markAsReadByUser(userId: userId, readAt: readAt);

    if (state is ChatRoomLoaded) {
      emit((state as ChatRoomLoaded).copyWith(messages: updated));
    } else {
      final restricted = state as ChatRoomRestricted;
      emit(restricted.copyWith(messages: updated));
    }
  }

  void _onTypingEvent(Map<String, dynamic> payload) {
    final current = state;
    if (current is! ChatRoomLoaded && current is! ChatRoomRestricted) return;

    final actorId =
        (payload['userId'] ??
                payload['fromUserId'] ??
                payload['senderId'] ??
                payload['from']?['_id'])
            ?.toString();
    if (actorId != userId) return;

    final event = payload['event']?.toString();
    final isTyping = event == 'typing';

    if (current is ChatRoomLoaded) {
      emit(current.copyWith(isTyping: isTyping));
    } else {
      emit((current as ChatRoomRestricted).copyWith(isTyping: isTyping));
    }
  }

  Map<String, dynamic>? _extractMessagePayload(Map<String, dynamic> payload) {
    if (payload['message'] is Map<String, dynamic>) {
      return payload['message'] as Map<String, dynamic>;
    }
    if (payload['data'] is Map<String, dynamic>) {
      final data = payload['data'] as Map<String, dynamic>;
      if (data['message'] is Map<String, dynamic>) {
        return data['message'] as Map<String, dynamic>;
      }
      return data;
    }
    return payload;
  }

  String? _extractChatRoomId(List<ChatMessage> messages) {
    for (final message in messages.reversed) {
      if (message.chatRoomId != null && message.chatRoomId!.isNotEmpty) {
        return message.chatRoomId;
      }
    }
    return _chatRoomId;
  }

  List<ChatMessage> _dedupeMessages(List<ChatMessage> messages) {
    final map = <String, ChatMessage>{};
    for (final message in messages) {
      map[message.id] = message;
    }
    final deduped = map.values.toList();
    deduped.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return deduped;
  }

  @override
  Future<void> close() {
    _emitStopTyping();
    if (_chatRoomId != null && _chatRoomId!.trim().isNotEmpty) {
      _socketService.leaveRoom(_chatRoomId!);
    }

    _socketService.removeOnConnectListener(_onSocketConnected);
    _socketService.removeChatMessageListener(_onSocketMessageReceived);
    _socketService.removeChatReadListener(_onMessagesRead);
    _socketService.removeTypingListener(_onTypingEvent);
    _socketService.removeUserStatusListener(_onUserStatusEvent);

    return super.close();
  }
}
