import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';

class ItemWhereToBuyCardWidget extends StatelessWidget {
  final String? url;
  final String? storeName;
  final String? storeLocation;
  final VoidCallback? onTap;

  const ItemWhereToBuyCardWidget({
    super.key,
    this.url,
    this.storeName,
    this.storeLocation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    
    // Don't show if no URL and no store info
    if (url == null && 
        (storeName == null || storeName!.isEmpty) && 
        (storeLocation == null || storeLocation!.isEmpty)) {
      return const SizedBox.shrink();
    }

    // Determine what to display
    final hasStoreName = storeName != null && storeName!.isNotEmpty;
    final hasUrl = url != null && url!.isNotEmpty;
    final hasLocation = storeLocation != null && storeLocation!.isNotEmpty;

    Widget cardContent = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.language_rounded,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localization.translate('details.whereToBuy'),
                style: AppStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              // Store Name (if available) - separate line
              if (hasStoreName) ...[
                Text(
                  storeName!,
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              // URL or Location - clickable, separate line
              if (hasUrl) ...[
                GestureDetector(
                  onTap: onTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.link_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _extractDomain(url!) ?? url!,
                          style: AppStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.primary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (hasLocation) ...[
                GestureDetector(
                  onTap: () => _openLocation(storeLocation!),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          storeLocation!,
                          style: AppStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.primary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: cardContent,
    );
  }

  Future<void> _openLocation(String location) async {
    // Check if location is a URL (starts with http:// or https://)
    if (location.startsWith('http://') || location.startsWith('https://')) {
      try {
        final uri = Uri.parse(location);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        // If URL parsing fails, try to open as map search
        final mapUri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(location)}',
        );
        await launchUrl(mapUri, mode: LaunchMode.externalApplication);
      }
    } else {
      // If it's not a URL, open as map search
      final mapUri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(location)}',
      );
      await launchUrl(mapUri, mode: LaunchMode.externalApplication);
    }
  }

  String? _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.replaceFirst('www.', '');
    } catch (e) {
      return null;
    }
  }
}

