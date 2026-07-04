import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/core/services/socket_service.dart';
import 'package:wish_listy/features/auth/data/repository/auth_repository.dart';
import 'package:wish_listy/features/chat/data/cache/chat_cache.dart';
import 'package:wish_listy/features/chat/data/models/chat_message_model.dart';
import 'package:wish_listy/features/chat/data/models/chat_participant_model.dart';
import 'package:wish_listy/features/chat/data/models/conversation_model.dart';
import 'package:wish_listy/features/chat/data/repository/chat_repository.dart';
import 'package:wish_listy/features/chat/presentation/cubit/chat_state.dart';
import 'package:wish_listy/features/friends/data/repository/friends_repository.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepository _chatRepository;
  final ChatCache _chatCache;
  final SocketService _socketService;
  final AuthRepository _authRepository;
  final FriendsRepository _friendsRepository;

  String? _activeRoomUserId;
  String? _activeChatRoomId;
  bool _listenersAttached = false;

  ChatCubit({
    ChatRepository? chatRepository,
    ChatCache? chatCache,
    SocketService? socketService,
    AuthRepository? authRepository,
    FriendsRepository? friendsRepository,
  }) : _chatRepository = chatRepository ?? ChatRepository(),
       _chatCache = chatCache ?? ChatCache(),
       _socketService = socketService ?? SocketService(),
       _authRepository = authRepository ?? AuthRepository(),
       _friendsRepository = friendsRepository ?? FriendsRepository(),
       super(const ChatInitial());

  String get _currentUserId => _authRepository.userId ?? '';

  Future<void> initialize() async {
    if (_authRepository.isGuest || _currentUserId.isEmpty) {
      return;
    }

    _attachSocketListeners();
    await loadUnreadCount();
    await loadConversations();
  }

  void setActiveRoomUserId(String? userId) {
    _activeRoomUserId = userId;
    if (userId == null) {
      _activeChatRoomId = null;
    }
  }

  void setActiveChatRoom({String? userId, String? chatRoomId}) {
    _activeRoomUserId = userId;
    _activeChatRoomId = chatRoomId;
  }

  /// Clears unread badge for a conversation in local state/cache.
  void markConversationAsRead(String userId) {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return;

    final cachedConversations = List<Conversation>.from(_chatCache.conversations);
    final cachedIndex = cachedConversations.indexWhere(
      (item) => item.participantId == normalizedUserId,
    );
    if (cachedIndex == -1) return;

    final cachedConversation = cachedConversations[cachedIndex];
    if (cachedConversation.unreadCount == 0) return;

    cachedConversations[cachedIndex] = cachedConversation.copyWith(
      unreadCount: 0,
    );
    _chatCache.setConversations(cachedConversations);

    if (state is! ChatLoaded) return;

    final current = state as ChatLoaded;
    final updatedUnreadCount = current.unreadCount > 0
        ? current.unreadCount - 1
        : 0;

    emit(
      current.copyWith(
        conversations: cachedConversations,
        filteredConversations: _applySearch(
          cachedConversations,
          current.searchQuery,
        ),
        unreadCount: updatedUnreadCount,
      ),
    );
  }

  bool isViewingChatRoom({String? senderId, String? chatRoomId}) {
    if (_activeRoomUserId == null && _activeChatRoomId == null) {
      return false;
    }

    final normalizedRoomId = chatRoomId?.trim() ?? '';
    if (normalizedRoomId.isNotEmpty &&
        _activeChatRoomId != null &&
        _activeChatRoomId!.isNotEmpty) {
      return _activeChatRoomId == normalizedRoomId;
    }

    final normalizedSenderId = senderId?.trim() ?? '';
    if (normalizedSenderId.isNotEmpty &&
        _activeRoomUserId != null &&
        _activeRoomUserId!.isNotEmpty) {
      return _activeRoomUserId == normalizedSenderId;
    }

    return false;
  }

  /// Refreshes chat badge/inbox when a chat push arrives while app is foreground.
  Future<void> onForegroundChatPush({
    required String senderId,
    required String chatRoomId,
  }) async {
    if (_authRepository.isGuest || _currentUserId.isEmpty) return;

    if (!isViewingChatRoom(senderId: senderId, chatRoomId: chatRoomId)) {
      await loadUnreadCount();
      if (state is ChatLoaded) {
        await loadConversations(forceRefresh: true);
      }
    }
  }

  Future<void> loadUnreadCount() async {
    if (_authRepository.isGuest || _currentUserId.isEmpty) {
      return;
    }

    try {
      final unreadCount = await _chatRepository.fetchUnreadCount();
      if (state is ChatLoaded) {
        final current = state as ChatLoaded;
        emit(current.copyWith(unreadCount: unreadCount));
      } else {
        emit(
          ChatLoaded(
            conversations: _chatCache.conversations,
            filteredConversations: _chatCache.conversations,
            unreadCount: unreadCount,
          ),
        );
      }
    } on ApiException catch (e) {
      if (state is! ChatLoaded) {
        emit(ChatError(e.message));
      }
    } catch (_) {
      if (state is! ChatLoaded) {
        emit(const ChatError('Failed to load unread messages.'));
      }
    }
  }

  Future<void> loadConversations({bool forceRefresh = false}) async {
    if (_authRepository.isGuest || _currentUserId.isEmpty) {
      return;
    }

    final currentState = state;
    if (currentState is! ChatLoaded) {
      emit(const ChatLoading());
    } else if (forceRefresh) {
      emit(currentState.copyWith(isRefreshing: true));
    }

    final cacheTime = _chatCache.conversationsFetchedAt;
    final hasFreshCache =
        !forceRefresh &&
        _chatCache.hasConversationsCache &&
        cacheTime != null &&
        DateTime.now().difference(cacheTime).inSeconds < 60;

    if (hasFreshCache) {
      final unreadCount = (state is ChatLoaded)
          ? (state as ChatLoaded).unreadCount
          : 0;
      final loaded = ChatLoaded(
        conversations: _chatCache.conversations,
        filteredConversations: _applySearch(
          _chatCache.conversations,
          (state is ChatLoaded) ? (state as ChatLoaded).searchQuery : '',
        ),
        unreadCount: unreadCount,
      );
      emit(loaded);
      return;
    }

    try {
      var conversations = await _chatRepository.fetchConversations(
        currentUserId: _currentUserId,
      );
      conversations = await _enrichConversationsWithMissingNames(conversations);
      conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      _chatCache.setConversations(conversations);

      final unreadCount = (state is ChatLoaded)
          ? (state as ChatLoaded).unreadCount
          : 0;
      final query = (state is ChatLoaded)
          ? (state as ChatLoaded).searchQuery
          : '';
      emit(
        ChatLoaded(
          conversations: conversations,
          filteredConversations: _applySearch(conversations, query),
          unreadCount: unreadCount,
          searchQuery: query,
        ),
      );
    } on ApiException catch (e) {
      if (state is ChatLoaded) {
        emit((state as ChatLoaded).copyWith(isRefreshing: false));
      } else {
        emit(ChatError(e.message));
      }
    } catch (_) {
      if (state is ChatLoaded) {
        emit((state as ChatLoaded).copyWith(isRefreshing: false));
      } else {
        emit(const ChatError('Failed to load conversations.'));
      }
    }
  }

  void filterConversations(String query) {
    if (state is! ChatLoaded) return;
    final current = state as ChatLoaded;
    emit(
      current.copyWith(
        searchQuery: query,
        filteredConversations: _applySearch(current.conversations, query),
      ),
    );
  }

  void _attachSocketListeners() {
    if (_listenersAttached) return;
    _listenersAttached = true;

    _socketService.addOnConnectListener(_onSocketConnected);
    _socketService.addChatMessageListener(_onSocketMessage);
    _socketService.addChatUnreadListener(_onSocketUnreadUpdate);
  }

  void _onSocketConnected() {
    loadUnreadCount();
    loadConversations(forceRefresh: true);
  }

  void _onSocketMessage(Map<String, dynamic> payload) {
    if (_authRepository.isGuest || _currentUserId.isEmpty) {
      return;
    }

    final messageJson = _extractMessagePayload(payload);
    if (messageJson == null) return;

    var message = ChatMessage.fromJson(
      messageJson,
      currentUserId: _currentUserId,
    );
    final conversationId =
        payload['conversationId']?.toString() ?? payload['chatRoomId']?.toString();
    if ((message.chatRoomId == null || message.chatRoomId!.isEmpty) &&
        conversationId != null &&
        conversationId.isNotEmpty) {
      message = message.copyWith(chatRoomId: conversationId);
    }
    final participantJson = _extractParticipantPayload(payload, message);
    final participant = ChatParticipant.fromJson(participantJson);

    final participantId = message.senderId == _currentUserId
        ? message.recipientId
        : message.senderId;
    final isIncoming = message.senderId != _currentUserId;
    final shouldIncreaseUnread =
        isIncoming && participantId != _activeRoomUserId;

    final current = state is ChatLoaded
        ? state as ChatLoaded
        : ChatLoaded(
            conversations: _chatCache.conversations,
            filteredConversations: _chatCache.conversations,
            unreadCount: 0,
          );

    final conversations = List<Conversation>.from(current.conversations);
    final existingIndex = conversations.indexWhere(
      (item) => item.participantId == participantId,
    );

    final existing = existingIndex == -1 ? null : conversations[existingIndex];
    final mergedParticipant = _mergeParticipant(
      incoming: participant,
      existing: existing?.participant,
      participantId: participantId,
    );
    final mergedConversation = Conversation(
      participantId: participantId,
      chatRoomId: message.chatRoomId ?? existing?.chatRoomId ?? '',
      participant: mergedParticipant,
      lastMessage: message,
      unreadCount: shouldIncreaseUnread
          ? (existing?.unreadCount ?? 0) + 1
          : (participantId == _activeRoomUserId
                ? 0
                : (existing?.unreadCount ?? 0)),
      updatedAt: message.createdAt,
    );

    if (existingIndex == -1) {
      conversations.insert(0, mergedConversation);
    } else {
      conversations[existingIndex] = mergedConversation;
      conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }

    _chatCache.setConversations(conversations);
    _chatCache.appendMessage(participantId, message);

    final unreadCount = shouldIncreaseUnread
        ? current.unreadCount + 1
        : current.unreadCount;
    emit(
      current.copyWith(
        conversations: conversations,
        filteredConversations: _applySearch(conversations, current.searchQuery),
        unreadCount: unreadCount,
      ),
    );
  }

  void _onSocketUnreadUpdate(Map<String, dynamic> payload) {
    if (state is! ChatLoaded) return;

    final participantId =
        payload['userId'] ??
            payload['participantId'] ??
            payload['otherUserId'] ??
            payload['other_user_id'] ??
            payload['data']?['userId'] ??
            payload['data']?['participantId'];
    if (participantId != null && participantId.toString().trim().isNotEmpty) {
      markConversationAsRead(participantId.toString());
    }

    if (state is! ChatLoaded) return;

    final unread = _parseInt(
      payload['unreadConversations'] ??
          payload['unread_conversations'] ??
          payload['unreadCount'] ??
          payload['unread_count'] ??
          payload['data']?['unreadConversations'] ??
          payload['data']?['unread_conversations'] ??
          payload['data']?['unreadCount'] ??
          payload['data']?['unread_count'],
    );
    emit((state as ChatLoaded).copyWith(unreadCount: unread));
  }

  List<Conversation> _applySearch(List<Conversation> source, String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return source;

    return source.where((item) {
      final name = item.participant.displayName.toLowerCase();
      final username = item.participant.username.toLowerCase();
      final text = item.lastMessage?.text.toLowerCase() ?? '';
      return name.contains(normalized) ||
          username.contains(normalized) ||
          text.contains(normalized);
    }).toList();
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

  Map<String, dynamic> _extractParticipantPayload(
    Map<String, dynamic> payload,
    ChatMessage message,
  ) {
    if (payload['participant'] is Map<String, dynamic>) {
      return payload['participant'] as Map<String, dynamic>;
    }
    if (payload['data'] is Map<String, dynamic> &&
        (payload['data'] as Map<String, dynamic>)['participant']
            is Map<String, dynamic>) {
      return (payload['data'] as Map<String, dynamic>)['participant']
          as Map<String, dynamic>;
    }

    final messageJson = _extractMessagePayload(payload) ?? const {};
    final sender = messageJson['sender'] is Map<String, dynamic>
        ? messageJson['sender'] as Map<String, dynamic>
        : payload['sender'] is Map<String, dynamic>
        ? payload['sender'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final recipient = messageJson['recipient'] is Map<String, dynamic>
        ? messageJson['recipient'] as Map<String, dynamic>
        : payload['recipient'] is Map<String, dynamic>
        ? payload['recipient'] as Map<String, dynamic>
        : const <String, dynamic>{};

    if (message.senderId == _currentUserId && recipient.isNotEmpty) {
      return recipient;
    }
    if (message.recipientId == _currentUserId && sender.isNotEmpty) {
      return sender;
    }
    if (payload['from'] is Map<String, dynamic>) {
      return payload['from'] as Map<String, dynamic>;
    }

    final fallbackId = message.senderId == _currentUserId
        ? message.recipientId
        : message.senderId;
    return {
      '_id': fallbackId,
      'fullName': payload['senderName'] ?? payload['name'] ?? '',
      'profileImage': payload['senderAvatar'] ?? payload['profileImage'],
    };
  }

  ChatParticipant _mergeParticipant({
    required ChatParticipant incoming,
    ChatParticipant? existing,
    required String participantId,
  }) {
    final resolvedName = _resolveParticipantFullName(
      incoming: incoming,
      existing: existing,
    );

    return (existing ?? incoming).copyWith(
      id: participantId.isEmpty ? (existing?.id ?? incoming.id) : participantId,
      fullName: resolvedName,
      username: incoming.username.isNotEmpty
          ? incoming.username
          : (existing?.username ?? ''),
      handle: incoming.handle ?? existing?.handle,
      profileImage: incoming.profileImage ?? existing?.profileImage,
      isOnline: incoming.isOnline,
    );
  }

  String _resolveParticipantFullName({
    required ChatParticipant incoming,
    ChatParticipant? existing,
  }) {
    if (incoming.hasResolvedName) return incoming.fullName;
    if (existing != null && existing.hasResolvedName) return existing.fullName;
    return incoming.fullName;
  }

  Future<List<Conversation>> _enrichConversationsWithMissingNames(
    List<Conversation> conversations,
  ) async {
    final missingNames = conversations.where(
      (conversation) =>
          conversation.participantId.isNotEmpty &&
          !conversation.participant.hasResolvedName,
    );
    if (missingNames.isEmpty) return conversations;

    final enrichedParticipants = <String, ChatParticipant>{};
    await Future.wait(
      missingNames.map((conversation) async {
        try {
          final profile = await _friendsRepository.getFriendProfile(
            conversation.participantId,
          );
          final user = profile.user;
          enrichedParticipants[conversation.participantId] = ChatParticipant(
            id: conversation.participantId,
            fullName: user.fullName,
            username: user.username,
            handle: user.handle,
            profileImage: user.profileImage,
          );
        } catch (_) {}
      }),
    );

    if (enrichedParticipants.isEmpty) return conversations;

    return conversations
        .map((conversation) {
          final enriched = enrichedParticipants[conversation.participantId];
          if (enriched == null) return conversation;

          return conversation.copyWith(
            participant: conversation.participant.copyWith(
              fullName: enriched.fullName,
              username: enriched.username,
              handle: enriched.handle,
              profileImage:
                  enriched.profileImage ?? conversation.participant.profileImage,
            ),
          );
        })
        .toList();
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  Future<void> close() {
    _socketService.removeOnConnectListener(_onSocketConnected);
    _socketService.removeChatMessageListener(_onSocketMessage);
    _socketService.removeChatUnreadListener(_onSocketUnreadUpdate);
    return super.close();
  }
}
