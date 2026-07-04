import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/utils/chat_date_formatter.dart';
import 'package:wish_listy/features/chat/data/models/chat_message_model.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    final bubbleColor = isMine ? null : AppColors.surfaceVariant;
    final textColor = isMine ? Colors.white : AppColors.textPrimary;

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
