import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';

class LegalInfoScreen extends StatelessWidget {
  final String title;
  final String content;

  const LegalInfoScreen({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localization, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: AppColors.textPrimary,
                size: 18,
              ),
              onPressed: () => Navigator.of(context).pop(),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(8),
                shape: const CircleBorder(),
              ),
            ),
            title: Text(
              title,
              style: AppStyles.heading3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textTertiary.withOpacity(0.1),
                    blurRadius: 25,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24.0),
              child: _buildContent(context, localization),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, LocalizationService localization) {
    // Split content by lines and process markdown-like formatting
    final lines = content.split('\n');
    final textSpans = <TextSpan>[];
    final isRTL = localization.isRTL;

    for (final line in lines) {
      if (line.trim().isEmpty) {
        textSpans.add(const TextSpan(text: '\n'));
        continue;
      }

      // Handle headings (lines that are entirely bold)
      if (line.trim().startsWith('**') && line.trim().endsWith('**') && line.trim().length > 4) {
        final boldText = line.trim().substring(2, line.trim().length - 2);
        textSpans.add(
          TextSpan(
            text: boldText,
            style: AppStyles.heading3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
        textSpans.add(const TextSpan(text: '\n\n'));
      } else if (line.startsWith('* ') && !line.startsWith('**')) {
        // Handle bullet points (must start with "* " not "**")
        final bulletContent = line.substring(2);
        final bulletSpans = _parseInlineFormatting(bulletContent);
        textSpans.add(
          const TextSpan(
            text: '• ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        );
        textSpans.addAll(bulletSpans);
        textSpans.add(const TextSpan(text: '\n'));
      } else {
        // Regular text or text with inline formatting
        final parsedSpans = _parseInlineFormatting(line);
        textSpans.addAll(parsedSpans);
        textSpans.add(const TextSpan(text: '\n'));
      }
    }

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: RichText(
        text: TextSpan(children: textSpans),
        textAlign: isRTL ? TextAlign.right : TextAlign.left,
      ),
    );
  }

  List<TextSpan> _parseInlineFormatting(String text) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int lastIndex = 0;

    for (final match in regex.allMatches(text)) {
      // Add text before the match
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(
            text: text.substring(lastIndex, match.start),
            style: AppStyles.bodyLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        );
      }
      // Add bold text
      spans.add(
        TextSpan(
          text: match.group(1) ?? '',
          style: AppStyles.bodyLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
      lastIndex = match.end;
    }

    // Add remaining text
    if (lastIndex < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastIndex),
          style: AppStyles.bodyLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      );
    }

    return spans.isEmpty
        ? [
            TextSpan(
              text: text,
              style: AppStyles.bodyLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            )
          ]
        : spans;
  }
}

