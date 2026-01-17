import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

    String displayText;
    VoidCallback? cardOnTap;
    
    if (url != null && url!.isNotEmpty) {
      displayText = _extractDomain(url!) ?? url!;
      cardOnTap = onTap;
    } else if (storeName != null && storeName!.isNotEmpty) {
      displayText = storeName!;
      if (storeLocation != null && storeLocation!.isNotEmpty) {
        displayText += ' • $storeLocation';
      }
      cardOnTap = null;
    } else {
      displayText = storeLocation ?? '';
      cardOnTap = null;
    }

    Widget cardContent = Row(
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
              const SizedBox(height: 4),
              Text(
                displayText,
                style: AppStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (cardOnTap != null) ...[
          const SizedBox(width: 12),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: AppColors.primary,
            size: 16,
          ),
        ],
      ],
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: cardOnTap != null
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: cardOnTap,
                borderRadius: BorderRadius.circular(20),
                child: cardContent,
              ),
            )
          : cardContent,
    );
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

