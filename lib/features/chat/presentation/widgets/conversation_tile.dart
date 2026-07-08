import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/utils/chat_date_formatter.dart';
import 'package:wish_listy/features/chat/data/models/conversation_model.dart';

class ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;
  final String emptyMessageText;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
    required this.emptyMessageText,
  });

  @override
  Widget build(BuildContext context) {
    final participant = conversation.participant;
    final avatar = participant.profileImage;
    final lastMessageText = conversation.lastMessage?.text.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.cardPurple,
                backgroundImage: avatar != null && avatar.isNotEmpty
                    ? NetworkImage(avatar)
                    : null,
                child: avatar == null || avatar.isEmpty
                    ? Text(
                        participant.displayName.substring(0, 1).toUpperCase(),
                        style: AppStyles.headingSmallWithContext(
                          context,
                        ).copyWith(color: AppColors.primary),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      participant.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyles.headingSmallWithContext(
                        context,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lastMessageText == null || lastMessageText.isEmpty
                          ? emptyMessageText
                          : lastMessageText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyles.bodyMediumWithContext(
                        context,
                      ).copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    ChatDateFormatter.formatConversationTime(
                      conversation.latestActivityAt,
                    ),
                    style: AppStyles.captionWithContext(context).copyWith(
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (conversation.unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      constraints: const BoxConstraints(minWidth: 24),
                      child: Text(
                        conversation.unreadCount > 99
                            ? '99+'
                            : '${conversation.unreadCount}',
                        textAlign: TextAlign.center,
                        style: AppStyles.captionWithContext(context).copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 24),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
