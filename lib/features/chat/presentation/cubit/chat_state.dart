import 'package:equatable/equatable.dart';
import 'package:wish_listy/features/chat/data/models/conversation_model.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatLoading extends ChatState {
  const ChatLoading();
}

class ChatLoaded extends ChatState {
  final List<Conversation> conversations;
  final List<Conversation> filteredConversations;
  final int unreadCount;
  final String searchQuery;
  final bool isRefreshing;

  const ChatLoaded({
    required this.conversations,
    required this.filteredConversations,
    required this.unreadCount,
    this.searchQuery = '',
    this.isRefreshing = false,
  });

  ChatLoaded copyWith({
    List<Conversation>? conversations,
    List<Conversation>? filteredConversations,
    int? unreadCount,
    String? searchQuery,
    bool? isRefreshing,
  }) {
    return ChatLoaded(
      conversations: conversations ?? this.conversations,
      filteredConversations:
          filteredConversations ?? this.filteredConversations,
      unreadCount: unreadCount ?? this.unreadCount,
      searchQuery: searchQuery ?? this.searchQuery,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [
    conversations,
    filteredConversations,
    unreadCount,
    searchQuery,
    isRefreshing,
  ];
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}
