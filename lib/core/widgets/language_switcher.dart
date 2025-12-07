import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localization, child) {
        if (!context.mounted) return const SizedBox.shrink();
        
        return PopupMenuButton<String>(
          onSelected: (languageCode) {
            debugPrint('LanguageSwitcher: Language selected: $languageCode');
            if (context.mounted) {
              localization.changeLanguage(languageCode);
              debugPrint('LanguageSwitcher: Language change initiated for: $languageCode');
            }
          },
          itemBuilder: (context) => localization.supportedLanguages.map((language) {
            return PopupMenuItem<String>(
              value: language['code']!,
              child: Row(
                children: [
                  Text(language['flag']!),
                  const SizedBox(width: 12),
                  Text(
                    language['nativeName']!,
                    style: AppStyles.bodyMedium.copyWith(
                      fontWeight: localization.currentLanguage == language['code']
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  if (localization.currentLanguage == language['code']) ...[
                    const Spacer(),
                    Icon(
                      Icons.check,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.surfaceVariant,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  localization.currentLanguageInfo?['flag'] ?? '🌐',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  localization.currentLanguageInfo?['code']?.toUpperCase() ?? 'EN',
                  style: AppStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.textTertiary,
                  size: 16,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Compact Language Switcher
class CompactLanguageSwitcher extends StatelessWidget {
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;

  const CompactLanguageSwitcher({
    super.key,
    this.size = 32,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localization, child) {
        final currentLang = localization.currentLanguageInfo;

        return GestureDetector(
          onTap: () => localization.toggleLanguage(),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: backgroundColor ?? const Color(0x80FFFFFF),
              borderRadius: BorderRadius.circular(size / 2),
              border: Border.all(
                color: AppColors.surfaceVariant,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textTertiary.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                currentLang?['flag'] ?? '🌐',
                style: TextStyle(fontSize: size * 0.6),
              ),
            ),
          ),
        );
      },
    );
  }
}

class LanguageSelectionDialog extends StatelessWidget {
  const LanguageSelectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localization, child) {
        if (!context.mounted) return const SizedBox.shrink();
        
        return AlertDialog(
          title: Text(
            localization.translate('app.selectLanguage'),
            style: AppStyles.headingMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: localization.supportedLanguages.map((language) {
              final isSelected = localization.currentLanguage == language['code'];
              return ListTile(
                leading: Text(
                  language['flag']!,
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(
                  language['nativeName']!,
                  style: AppStyles.bodyMedium.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  language['name']!,
                  style: AppStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                trailing: isSelected
                    ? Icon(
                        Icons.check_circle,
                        color: AppColors.primary,
                      )
                    : null,
                onTap: () {
                  if (context.mounted) {
                    localization.changeLanguage(language['code']!);
                    Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                localization.translate('app.cancel'),
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        );
      },
    );
  }
}
