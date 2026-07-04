import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';

class ChatEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const ChatEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.cardPurple,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppStyles.headingMediumWithContext(context),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppStyles.bodyMediumWithContext(
                context,
              ).copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
