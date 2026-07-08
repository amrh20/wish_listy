import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/utils/chat_date_formatter.dart';
import 'package:wish_listy/features/chat/data/models/chat_message_model.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final String? peerDisplayName;

  const MessageBubble({super.key, required this.message, this.peerDisplayName});

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    final bubbleColor = isMine ? null : AppColors.surfaceVariant;
    final textColor = isMine ? Colors.white : AppColors.textPrimary;
    final replyTo = message.replyTo;
    final localization = Provider.of<LocalizationService>(
      context,
      listen: false,
    );

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.76,
        ),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          gradient: isMine ? AppColors.primaryGradient : null,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          border: isMine
              ? null
              : Border.all(color: AppColors.border.withOpacity(0.35)),
        ),
        child: Column(
          crossAxisAlignment: isMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (replyTo != null) ...[
              _ReplyQuoteBox(
                replyTo: replyTo,
                isMine: isMine,
                currentUserId: message.isMine
                    ? message.senderId
                    : message.recipientId,
                peerDisplayName: peerDisplayName,
                youLabel: localization.translate('common.you'),
              ),
            ],
            Text(
              message.text,
              style: AppStyles.bodyMediumWithContext(context).copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ChatDateFormatter.formatTime(message.createdAt),
                  style: AppStyles.captionWithContext(context).copyWith(
                    color: isMine
                        ? Colors.white.withOpacity(0.9)
                        : AppColors.textTertiary,
                  ),
                ),
                if (isMine) ...[
                  const SizedBox(width: 6),
                  Icon(
                    message.isFailed
                        ? Icons.error_outline_rounded
                        : message.isPending
                        ? Icons.schedule_rounded
                        : message.isRead
                        ? Icons.done_all_rounded
                        : Icons.done_rounded,
                    size: 14,
                    color: message.isFailed
                        ? Colors.white
                        : message.isRead
                        ? AppColors.secondaryLight
                        : Colors.white.withOpacity(0.9),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplyQuoteBox extends StatelessWidget {
  final ChatMessageReply replyTo;
  final bool isMine;
  final String currentUserId;
  final String? peerDisplayName;
  final String youLabel;

  const _ReplyQuoteBox({
    required this.replyTo,
    required this.isMine,
    required this.currentUserId,
    required this.peerDisplayName,
    required this.youLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isReplyToCurrentUser = replyTo.senderId == currentUserId;
    final senderLabel = isReplyToCurrentUser
        ? youLabel
        : ((peerDisplayName?.trim().isNotEmpty ?? false)
              ? peerDisplayName!.trim()
              : 'User');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(8, 8, 10, 8),
      decoration: BoxDecoration(
        color: isMine
            ? Colors.white.withOpacity(0.16)
            : AppColors.border.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  senderLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.captionWithContext(context).copyWith(
                    color: isReplyToCurrentUser
                        ? AppColors.primary
                        : AppColors.secondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  replyTo.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.captionWithContext(context).copyWith(
                    color: isMine
                        ? Colors.white.withOpacity(0.92)
                        : AppColors.textSecondary,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
