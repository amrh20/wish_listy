import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/features/chat/presentation/cubit/chat_cubit.dart';
import 'package:wish_listy/features/chat/presentation/cubit/chat_state.dart';
import 'package:wish_listy/features/chat/presentation/widgets/chat_empty_state.dart';
import 'package:wish_listy/features/chat/presentation/widgets/conversation_tile.dart';

class ChatInboxScreen extends StatefulWidget {
  const ChatInboxScreen({super.key});

  @override
  State<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends State<ChatInboxScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatCubit>().initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        titleSpacing: 4,
        title: Text(
          localization.translate('chat.title'),
          style: AppStyles.headingMediumWithContext(
            context,
          ).copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
          child: Column(
            children: [
              _buildSearchField(localization),
              const SizedBox(height: 12),
              Expanded(
                child: BlocBuilder<ChatCubit, ChatState>(
                  builder: (context, state) {
                    if (state is ChatLoading || state is ChatInitial) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    }

                    if (state is ChatError) {
                      return Center(
                        child: Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: AppStyles.bodyMediumWithContext(context),
                        ),
                      );
                    }

                    if (state is! ChatLoaded) {
                      return const SizedBox.shrink();
                    }

                    if (state.filteredConversations.isEmpty) {
                      return ChatEmptyState(
                        title: localization.translate('chat.emptyTitle'),
                        subtitle: localization.translate('chat.emptySubtitle'),
                      );
                    }

                    return RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () => context
                          .read<ChatCubit>()
                          .loadConversations(forceRefresh: true),
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: state.filteredConversations.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = state.filteredConversations[index];
                          return ConversationTile(
                            conversation: item,
                            emptyMessageText: localization.translate(
                              'chat.noMessages',
                            ),
                            onTap: () {
                              context.read<ChatCubit>().setActiveChatRoom(
                                userId: item.participantId,
                                chatRoomId: item.chatRoomId,
                              );
                              Navigator.of(context).pushNamed(
                                AppRoutes.chatRoom,
                                arguments: {
                                  'userId': item.participantId,
                                  'displayName': item.participant.displayName,
                                  'avatarUrl': item.participant.profileImage,
                                  'chatRoomId': item.chatRoomId,
                                },
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(LocalizationService localization) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) =>
            context.read<ChatCubit>().filterConversations(value),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: localization.translate('chat.searchHint'),
          hintStyle: AppStyles.bodyMediumWithContext(
            context,
          ).copyWith(color: AppColors.textTertiary),
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
