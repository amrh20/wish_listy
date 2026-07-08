import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/features/chat/data/models/chat_message_model.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;
  final bool isEnabled;
  final bool isSending;
  final int maxLength;
  final String hintText;
  final String disabledHintText;
  final ChatMessage? replyToMessage;
  final String? replyToSenderLabel;
  final VoidCallback? onClearReply;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSend,
    required this.isEnabled,
    required this.isSending,
    required this.maxLength,
    required this.hintText,
    required this.disabledHintText,
    this.replyToMessage,
    this.replyToSenderLabel,
    this.onClearReply,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.border.withValues(alpha: 0.85)),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (replyToMessage != null) _buildReplyPreview(context),
            ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                final textLength = controller.text.trim().length;
                final canSend = isEnabled &&
                    !isSending &&
                    textLength > 0 &&
                    textLength <= maxLength;

                return Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                  child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      enabled: isEnabled,
                      onChanged: onChanged,
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      style: AppStyles.bodyMediumWithContext(context).copyWith(
                        color: AppColors.textPrimary,
                        height: 1.35,
                      ),
                      decoration: InputDecoration(
                        hintText: isEnabled ? hintText : disabledHintText,
                        hintStyle: AppStyles.bodyMediumWithContext(
                          context,
                        ).copyWith(color: AppColors.textTertiary),
                        filled: true,
                        fillColor: AppColors.surfaceVariant,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: AppColors.border.withValues(alpha: 0.55),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.45),
                            width: 1.5,
                          ),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: AppColors.border.withValues(alpha: 0.35),
                          ),
                        ),
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: AnimatedScale(
                      scale: canSend ? 1 : 0.94,
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOut,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: canSend ? onSend : null,
                          customBorder: const CircleBorder(),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              gradient: canSend ? AppColors.primaryGradient : null,
                              color: canSend
                                  ? null
                                  : AppColors.border.withValues(alpha: 0.65),
                              shape: BoxShape.circle,
                              boxShadow: canSend
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.28,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: isSending
                                ? const Padding(
                                    padding: EdgeInsets.all(11),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.send_rounded,
                                    color: canSend
                                        ? Colors.white
                                        : AppColors.textTertiary,
                                    size: 21,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview(BuildContext context) {
    final msg = replyToMessage!;
    final label = replyToSenderLabel ?? 'User';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
          left: BorderSide(color: AppColors.primary, width: 3),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppStyles.captionWithContext(context).copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  msg.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.captionWithContext(context).copyWith(
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClearReply,
            icon: Icon(
              Icons.close_rounded,
              size: 18,
              color: AppColors.textTertiary,
            ),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
