import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';

/// Model for wishlist privacy settings
enum WishlistPrivacy { public, private, onlyInvited }

/// Model for wishlist summary data
class WishlistSummary {
  final String id;
  final String name;
  final int itemCount;
  final int purchasedCount;
  final DateTime lastUpdated;
  final WishlistPrivacy privacy;
  final String? imageUrl;
  final String? eventName;
  final DateTime? eventDate;

  WishlistSummary({
    required this.id,
    required this.name,
    required this.itemCount,
    required this.purchasedCount,
    required this.lastUpdated,
    this.privacy = WishlistPrivacy.public,
    this.imageUrl,
    this.eventName,
    this.eventDate,
  });
}

/// Widget for displaying a wishlist card
class WishlistCardWidget extends StatelessWidget {
  final WishlistSummary wishlist;
  final bool isEvent;
  final VoidCallback onTap;
  final VoidCallback onAddItem;
  final Function(String) onMenuAction;

  const WishlistCardWidget({
    super.key,
    required this.wishlist,
    required this.isEvent,
    required this.onTap,
    required this.onAddItem,
    required this.onMenuAction,
  });

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context);
    final progress = wishlist.itemCount > 0
        ? wishlist.purchasedCount / wishlist.itemCount
        : 0.0;
    final daysAgo = DateTime.now().difference(wishlist.lastUpdated).inDays;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.textTertiary.withOpacity(0.08),
              offset: const Offset(0, 4),
              blurRadius: 12,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isEvent
                          ? Icons.celebration_rounded
                          : Icons.favorite_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title and event name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          wishlist.name,
                          style: AppStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isEvent && wishlist.eventName != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.event_rounded,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  wishlist.eventName!,
                                  style: AppStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Privacy badge
                  _buildPrivacyBadge(wishlist.privacy),

                  const SizedBox(width: 8),

                  // More options menu
                  PopupMenuButton<String>(
                    onSelected: onMenuAction,
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: AppColors.textPrimary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              localization.translate('common.edit'),
                              style: AppStyles.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(
                              Icons.share_outlined,
                              size: 18,
                              color: AppColors.textPrimary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              localization.translate('common.share'),
                              style: AppStyles.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              localization.translate('common.delete'),
                              style: AppStyles.bodyMedium.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildStatChip(
                    Icons.card_giftcard_rounded,
                    '${wishlist.itemCount} ${wishlist.itemCount == 1 ? "Wish" : "Wishes"}',
                    AppColors.primary,
                  ),
                  _buildStatChip(
                    Icons.check_circle_rounded,
                    '${wishlist.purchasedCount} Gifted',
                    AppColors.success,
                  ),
                  _buildStatChip(
                    Icons.access_time_rounded,
                    daysAgo == 0
                        ? localization.translate('wishlists.today')
                        : '$daysAgo ${localization.translate("wishlists.daysAgo")}',
                    AppColors.info,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        localization.translate('wishlists.progress'),
                        style: AppStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: AppStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: AppColors.textTertiary.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress < 0.3
                            ? AppColors.error
                            : progress < 0.7
                            ? AppColors.warning
                            : AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildActionButton(
                      label: 'View Wishes',
                      icon: Icons.visibility_rounded,
                      onPressed: onTap,
                      isPrimary: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      label: 'Add a Wish',
                      icon: Icons.add_rounded,
                      onPressed: onAddItem,
                      isPrimary: false,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyBadge(WishlistPrivacy privacy) {
    IconData icon;
    Color color;
    String label;

    switch (privacy) {
      case WishlistPrivacy.public:
        icon = Icons.public_rounded;
        color = AppColors.success;
        label = 'Public';
        break;
      case WishlistPrivacy.private:
        icon = Icons.lock_rounded;
        color = AppColors.error;
        label = 'Private';
        break;
      case WishlistPrivacy.onlyInvited:
        icon = Icons.group_rounded;
        color = AppColors.warning;
        label = 'Invited';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return Material(
      color: isPrimary ? AppColors.primary : AppColors.primary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isPrimary ? Colors.white : AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppStyles.bodyMedium.copyWith(
                  color: isPrimary ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
