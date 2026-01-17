import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/widgets/unified_page_container.dart';
import 'package:wish_listy/core/widgets/decorative_background.dart';

/// Model for FAQ items
class FaqItem {
  final String questionKey;
  final String answerKey;

  const FaqItem({
    required this.questionKey,
    required this.answerKey,
  });
}

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  // FAQ items list with localization keys
  static final List<FaqItem> _faqs = [
    const FaqItem(questionKey: "data.faq_q1", answerKey: "data.faq_a1"),
    const FaqItem(questionKey: "data.faq_q2", answerKey: "data.faq_a2"),
    const FaqItem(questionKey: "data.faq_q3", answerKey: "data.faq_a3"),
    const FaqItem(questionKey: "data.faq_q4", answerKey: "data.faq_a4"),
    const FaqItem(questionKey: "data.faq_q5", answerKey: "data.faq_a5"),
    const FaqItem(questionKey: "data.faq_q6", answerKey: "data.faq_a6"),
    const FaqItem(questionKey: "data.faq_q7", answerKey: "data.faq_a7"),
    const FaqItem(questionKey: "data.faq_q8", answerKey: "data.faq_a8"),
    // --- New Items ---
    const FaqItem(questionKey: "data.faq_q9", answerKey: "data.faq_a9"),   // Create Wishlist
    const FaqItem(questionKey: "data.faq_q10", answerKey: "data.faq_a10"), // Create Event
    const FaqItem(questionKey: "data.faq_q11", answerKey: "data.faq_a11"), // Add Wishes
    const FaqItem(questionKey: "data.faq_q12", answerKey: "data.faq_a12"), // Reserve Gift
  ];

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          localization.translate('data.faq_title'),
          style: AppStyles.headingLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: UnifiedPageBackground(
        child: DecorativeBackground(
          showGifts: false,
          child: Column(
            children: [
              
              // Content
              Expanded(
                child: UnifiedPageContainer(
                  child: _faqs.isEmpty
                      ? _buildEmptyState(localization)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                          itemCount: _faqs.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final faq = _faqs[index];
                            return _buildFaqItem(context, faq, localization);
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build individual FAQ item as ExpansionTile
  Widget _buildFaqItem(
    BuildContext context,
    FaqItem faq,
    LocalizationService localization,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textTertiary.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          expansionTileTheme: ExpansionTileThemeData(
            backgroundColor: Colors.transparent,
            collapsedBackgroundColor: Colors.transparent,
            iconColor: AppColors.primary,
            collapsedIconColor: AppColors.textSecondary,
            textColor: AppColors.textPrimary,
            collapsedTextColor: AppColors.textPrimary,
          ),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.help_outline,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          title: Text(
            localization.translate(faq.questionKey),
            style: AppStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 52),
                child: Text(
                  localization.translate(faq.answerKey),
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty state if no FAQs
  Widget _buildEmptyState(LocalizationService localization) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.help_outline,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              localization.translate('profile.faqComingSoon'),
              style: AppStyles.headingSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              localization.translate('profile.faqComingSoonDescription'),
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
