import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/utils/chat_date_formatter.dart';
import 'package:wish_listy/features/chat/data/models/chat_message_model.dart';
import 'package:wish_listy/features/chat/presentation/cubit/chat_cubit.dart';
import 'package:wish_listy/features/chat/presentation/cubit/chat_room_cubit.dart';
import 'package:wish_listy/features/chat/presentation/cubit/chat_room_state.dart';
import 'package:wish_listy/features/chat/presentation/widgets/chat_connection_banner.dart';
import 'package:wish_listy/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:wish_listy/features/chat/presentation/widgets/swipeable_message_bubble.dart';
import 'package:wish_listy/features/chat/presentation/widgets/typing_indicator.dart';

class ChatRoomScreen extends StatefulWidget {
  final String userId;
  final String? displayName;
  final String? avatarUrl;
  final String? chatRoomId;

  const ChatRoomScreen({
    super.key,
    required this.userId,
    this.displayName,
    this.avatarUrl,
    this.chatRoomId,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  ChatCubit? _chatCubit;

  ChatMessage? _replyToMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatCubit = context.read<ChatCubit>();
      _chatCubit?.setActiveChatRoom(
        userId: widget.userId,
        chatRoomId: widget.chatRoomId,
      );
      _chatCubit?.markConversationAsRead(widget.userId);
      context.read<ChatRoomCubit>().initialize();
    });
  }

  @override
  void dispose() {
    _chatCubit?.setActiveChatRoom(userId: null, chatRoomId: null);
    _chatCubit?.loadUnreadCount();
    _chatCubit?.loadConversations(forceRefresh: true);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 120;
    if (_scrollController.position.pixels >= threshold) {
      context.read<ChatRoomCubit>().loadOlderMessages();
    }
  }

  void _onReplyToMessage(ChatMessage message) {
    setState(() => _replyToMessage = message);
    _focusNode.requestFocus();
  }

  void _clearReply() {
    setState(() => _replyToMessage = null);
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    context.read<ChatRoomCubit>().sendMessage(
      text,
      replyToMessage: _replyToMessage,
    );
    _textController.clear();
    context.read<ChatRoomCubit>().onInputChanged('');
    if (_replyToMessage != null) _clearReply();
  }

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: BlocBuilder<ChatRoomCubit, ChatRoomState>(
          builder: (context, state) {
            final isTyping = switch (state) {
              ChatRoomLoaded(:final isTyping) => isTyping,
              ChatRoomRestricted(:final isTyping) => isTyping,
              _ => false,
            };
            final isPeerOnline = switch (state) {
              ChatRoomLoaded(:final isPeerOnline) => isPeerOnline,
              ChatRoomRestricted(:final isPeerOnline) => isPeerOnline,
              _ => null,
            };

            return Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.cardPurple,
                  backgroundImage:
                      widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty
                      ? NetworkImage(widget.avatarUrl!)
                      : null,
                  child: (widget.avatarUrl == null || widget.avatarUrl!.isEmpty)
                      ? Text(
                          (widget.displayName?.trim().isNotEmpty ?? false)
                              ? widget.displayName!
                                    .trim()
                                    .substring(0, 1)
                                    .toUpperCase()
                              : 'U',
                          style: AppStyles.bodyLargeWithContext(context)
                              .copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.displayName ??
                            localization.translate('chat.title'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppStyles.headingSmallWithContext(
                          context,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: _buildPresenceSubtitle(
                          context,
                          localization: localization,
                          isTyping: isTyping,
                          isPeerOnline: isPeerOnline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: BlocConsumer<ChatRoomCubit, ChatRoomState>(
        listenWhen: (previous, current) {
          if (current is ChatRoomLoaded && current.infoMessage != null) {
            return true;
          }
          if (current is ChatRoomError) return true;
          return false;
        },
        listener: (context, state) {
          final message = state is ChatRoomLoaded
              ? state.infoMessage
              : state is ChatRoomError
              ? state.message
              : null;
          if (message == null || message.isEmpty) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        },
        builder: (context, state) {
          if (state is ChatRoomLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state is ChatRoomError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: AppStyles.bodyMediumWithContext(context),
                ),
              ),
            );
          }

          final bool isRestricted;
          final List<ChatMessage> messages;
          final bool isConnected;
          final bool isSending;
          final String restrictedMessage;

          if (state is ChatRoomRestricted) {
            isRestricted = true;
            messages = state.messages;
            isConnected = state.isConnected;
            isSending = false;
            restrictedMessage = state.message;
          } else {
            final loadedState = state as ChatRoomLoaded;
            isRestricted = false;
            messages = loadedState.messages;
            isConnected = loadedState.isConnected;
            isSending = loadedState.isSending;
            restrictedMessage = '';
          }

          return Column(
            children: [
              if (!isConnected)
                ChatConnectionBanner(
                  message: localization.translate('chat.offline'),
                ),
              if (isRestricted)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    restrictedMessage,
                    style: AppStyles.bodySmallWithContext(context).copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Expanded(
                child: _buildMessagesList(
                  messages,
                  isRestricted,
                  !isRestricted && state is ChatRoomLoaded
                      ? state.isLoadingMore
                      : false,
                ),
              ),
              ChatInputBar(
                controller: _textController,
                focusNode: _focusNode,
                onChanged: (value) =>
                    context.read<ChatRoomCubit>().onInputChanged(value),
                onSend: _sendMessage,
                isEnabled: !isRestricted,
                isSending: isSending,
                maxLength: 4000,
                hintText: localization.translate('chat.inputHint'),
                disabledHintText: localization.translate('chat.restricted'),
                replyToMessage: _replyToMessage,
                replyToSenderLabel: _replyToMessage == null
                    ? null
                    : (_replyToMessage!.isMine
                          ? localization.translate('common.you')
                          : (widget.displayName ?? '')),
                onClearReply: _clearReply,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPresenceSubtitle(
    BuildContext context, {
    required LocalizationService localization,
    required bool isTyping,
    required bool? isPeerOnline,
  }) {
    if (isTyping) {
      return TypingIndicator(
        key: const ValueKey('typing'),
        text: localization.translate('chat.typing'),
      );
    }

    if (isPeerOnline == true) {
      return Row(
        key: const ValueKey('online'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            localization.translate('chat.online'),
            style: AppStyles.captionWithContext(
              context,
            ).copyWith(color: AppColors.textSecondary),
          ),
        ],
      );
    }

    if (isPeerOnline == false) {
      return Text(
        localization.translate('chat.offlineStatus'),
        key: const ValueKey('offline'),
        style: AppStyles.captionWithContext(
          context,
        ).copyWith(color: AppColors.textTertiary),
      );
    }

    return const SizedBox.shrink(key: ValueKey('presence-hidden'));
  }

  Widget _buildMessagesList(
    List<ChatMessage> messages,
    bool isRestricted,
    bool isLoadingMore,
  ) {
    if (messages.isEmpty) {
      return Center(
        child: Text(
          Provider.of<LocalizationService>(
            context,
          ).translate('chat.noMessages'),
          style: AppStyles.bodyMediumWithContext(
            context,
          ).copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    final newestFirst = messages.reversed.toList();
    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      itemCount: newestFirst.length + 1,
      itemBuilder: (context, index) {
        if (index == newestFirst.length) {
          if (!isRestricted && isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          return const SizedBox(height: 14);
        }

        final message = newestFirst[index];
        final olderMessage = index + 1 < newestFirst.length
            ? newestFirst[index + 1]
            : null;
        final showDateLabel = ChatDateFormatter.shouldShowDateSeparator(
          current: message.createdAt,
          previous: olderMessage?.createdAt,
        );

        return Column(
          children: [
            if (showDateLabel)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    ChatDateFormatter.formatMessageGroupDate(message.createdAt),
                    style: AppStyles.captionWithContext(context).copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            SwipeableMessageBubble(
              message: message,
              onReply: () => _onReplyToMessage(message),
              peerDisplayName: widget.displayName,
            ),
          ],
        );
      },
    );
  }
}
