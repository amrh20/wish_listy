import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';

class TypingIndicator extends StatelessWidget {
  final String text;

  const TypingIndicator({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 8,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              3,
              (index) => Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: AppStyles.captionWithContext(context).copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
