import 'package:equatable/equatable.dart';
import 'package:wish_listy/features/chat/data/models/chat_message_model.dart';

abstract class ChatRoomState extends Equatable {
  const ChatRoomState();

  @override
  List<Object?> get props => [];
}

class ChatRoomLoading extends ChatRoomState {
  const ChatRoomLoading();
}

class ChatRoomLoaded extends ChatRoomState {
  final List<ChatMessage> messages;
  final bool isLoadingMore;
  final bool hasMoreMessages;
  final bool isConnected;
  final bool isTyping;
  final bool? isPeerOnline;
  final bool isRestricted;
  final bool isSending;
  final String? infoMessage;

  const ChatRoomLoaded({
    required this.messages,
    this.isLoadingMore = false,
    this.hasMoreMessages = true,
    this.isConnected = true,
    this.isTyping = false,
    this.isPeerOnline,
    this.isRestricted = false,
    this.isSending = false,
    this.infoMessage,
  });

  ChatRoomLoaded copyWith({
    List<ChatMessage>? messages,
    bool? isLoadingMore,
    bool? hasMoreMessages,
    bool? isConnected,
    bool? isTyping,
    bool? isPeerOnline,
    bool resetPeerOnline = false,
    bool? isRestricted,
    bool? isSending,
    String? infoMessage,
    bool clearInfoMessage = false,
  }) {
    return ChatRoomLoaded(
      messages: messages ?? this.messages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      isConnected: isConnected ?? this.isConnected,
      isTyping: isTyping ?? this.isTyping,
      isPeerOnline:
          resetPeerOnline ? null : (isPeerOnline ?? this.isPeerOnline),
      isRestricted: isRestricted ?? this.isRestricted,
      isSending: isSending ?? this.isSending,
      infoMessage: clearInfoMessage ? null : (infoMessage ?? this.infoMessage),
    );
  }

  @override
  List<Object?> get props => [
    messages,
    isLoadingMore,
    hasMoreMessages,
    isConnected,
    isTyping,
    isPeerOnline,
    isRestricted,
    isSending,
    infoMessage,
  ];
}

class ChatRoomError extends ChatRoomState {
  final String message;

  const ChatRoomError(this.message);

  @override
  List<Object?> get props => [message];
}

class ChatRoomRestricted extends ChatRoomState {
  final String message;
  final List<ChatMessage> messages;
  final bool isConnected;
  final bool isTyping;
  final bool? isPeerOnline;

  const ChatRoomRestricted({
    required this.message,
    this.messages = const <ChatMessage>[],
    this.isConnected = true,
    this.isTyping = false,
    this.isPeerOnline,
  });

  ChatRoomRestricted copyWith({
    String? message,
    List<ChatMessage>? messages,
    bool? isConnected,
    bool? isTyping,
    bool? isPeerOnline,
  }) {
    return ChatRoomRestricted(
      message: message ?? this.message,
      messages: messages ?? this.messages,
      isConnected: isConnected ?? this.isConnected,
      isTyping: isTyping ?? this.isTyping,
      isPeerOnline: isPeerOnline ?? this.isPeerOnline,
    );
  }

  @override
  List<Object?> get props => [
    message,
    messages,
    isConnected,
    isTyping,
    isPeerOnline,
  ];
}
