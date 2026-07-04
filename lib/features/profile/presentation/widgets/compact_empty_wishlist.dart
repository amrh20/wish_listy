import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/theme/app_theme.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/features/profile/data/models/activity_model.dart';
import 'package:wish_listy/features/profile/presentation/widgets/activity_card.dart';

const double _emptyWishlistPatternSize = 120;
const double _emptyWishlistCenterGiftSize = 76;

/// Scattered light-purple icon pattern + centered gift / app logo. Flat, no shadows.
class _EmptyWishlistPatternStack extends StatelessWidget {
  const _EmptyWishlistPatternStack({required this.primaryColor});

  final Color primaryColor;

  static Color _patternTint(Color base) => base.withValues(alpha: 0.12);

  Widget _scatter(Widget child, {required double left, required double top}) {
    return Positioned(left: left, top: top, child: child);
  }

  @override
  Widget build(BuildContext context) {
    final tint = _patternTint(AppColors.primary);
    return SizedBox(
      width: _emptyWishlistPatternSize,
      height: _emptyWishlistPatternSize,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          _scatter(
            Transform.rotate(
              angle: -0.22,
              child: Icon(Icons.redeem_rounded, size: 22, color: tint),
            ),
            left: 5,
            top: 12,
          ),
          _scatter(
            Transform.rotate(
              angle: 0.28,
              child: Icon(Icons.auto_awesome_rounded, size: 19, color: tint),
            ),
            left: 70,
            top: 8,
          ),
          _scatter(
            Transform.rotate(
              angle: 0.14,
              child: Icon(Icons.card_giftcard_rounded, size: 20, color: tint),
            ),
            left: 8,
            top: 72,
          ),
          _scatter(
            Transform.rotate(
              angle: -0.18,
              child: Icon(Icons.star_rounded, size: 18, color: tint),
            ),
            left: 88,
            top: 62,
          ),
          _scatter(
            Transform.rotate(
              angle: 0.35,
              child: Icon(Icons.celebration_rounded, size: 21, color: tint),
            ),
            left: 42,
            top: 3,
          ),
          Center(
            child: Image.asset(
              'assets/images/app_logo.png',
              width: _emptyWishlistCenterGiftSize,
              height: _emptyWishlistCenterGiftSize,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.card_giftcard_rounded,
                  size: _emptyWishlistCenterGiftSize,
                  color: primaryColor,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// White card: horizontal patterned icon + title, subtitle, and CTA.
/// Used on Home when the user has no wishlists but other dashboard content exists,
/// and in [ActiveDashboard] when the wishlists section is empty.
class EmptyWishlistPromoCard extends StatelessWidget {
  const EmptyWishlistPromoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context, listen: true);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing16),
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _EmptyWishlistPatternStack(primaryColor: primaryColor),
              const SizedBox(width: AppTheme.spacing20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      localization.translate('cards.noWishlistsYet'),
                      style: AppStyles.headingSmallWithContext(context).copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing8),
                    Text(
                      localization.translate('cards.emptyWishlistSubtitle'),
                      style: AppStyles.bodyLargeWithContext(context).copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.35,
                        color: AppColors.primaryDark.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          Material(
            color: primaryColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall + 4),
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.createWishlist,
                  arguments: {
                    'previousRoute': AppRoutes.mainNavigation,
                  },
                );
              },
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall + 4),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing24,
                  vertical: 10,
                ),
                child: Text(
                  localization.translate('cards.createWishlist'),
                  textAlign: TextAlign.center,
                  style: AppStyles.buttonWithContext(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact Empty Wishlist Card - Used when wishlists are empty but activities exist
class CompactEmptyWishlistCard extends StatelessWidget {
  const CompactEmptyWishlistCard({super.key});

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context, listen: true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            '${localization.translate('cards.myWishlists')} 🎁',
            style: AppStyles.headingMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Alexandria',
            ),
          ),
        ),
        const SizedBox(height: 12),
        const EmptyWishlistPromoCard(),
      ],
    );
  }
}

/// Happening Now Section - Shows friend activities when user has no wishlists
/// This is a standalone section that can be used in the empty-wishlists-but-has-activities state
class HappeningNowSection extends StatelessWidget {
  final List<Activity> activities;

  const HappeningNowSection({
    super.key,
    required this.activities,
  });

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context, listen: true);
    
    // Limit to 3 activities for preview
    final displayActivities = activities.take(3).toList();
    
    if (displayActivities.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: 1.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          // Header with "Happening Now" title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${localization.translate('cards.happeningNow')} ⚡',
                  style: AppStyles.headingMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontFamily: 'Alexandria',
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.friendActivityFeed,
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    localization.translate('home.viewAll'),
                    style: AppStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      fontFamily: 'Alexandria',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Activity List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: displayActivities
                  .map((activity) => ActivityCard(activity: activity))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact Activity Card - A smaller version for inline display
/// Shows activity in a more compact horizontal format
class CompactActivityCard extends StatelessWidget {
  final Activity activity;

  const CompactActivityCard({
    super.key,
    required this.activity,
  });

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  IconData _getActivityIcon(String type) {
    final typeLower = type.toLowerCase();
    switch (typeLower) {
      case 'wishlist_item_added':
        return Icons.card_giftcard;
      case 'item_received':
        return Icons.celebration;
      case 'purchased':
        return Icons.shopping_bag;
      case 'reserved':
        return Icons.bookmark;
      default:
        return Icons.card_giftcard;
    }
  }

  Color _getActivityColor(String type) {
    final typeLower = type.toLowerCase();
    switch (typeLower) {
      case 'wishlist_item_added':
        return AppColors.primary;
      case 'item_received':
        return AppColors.success;
      case 'purchased':
        return AppColors.success;
      case 'reserved':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  String _getTimeAgoLocalized(LocalizationService loc, DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      if (years == 1) return loc.translate('activity.oneYearAgo');
      return loc.translate('activity.yearsAgo', args: {'count': years});
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      if (months == 1) return loc.translate('activity.oneMonthAgo');
      return loc.translate('activity.monthsAgo', args: {'count': months});
    } else if (difference.inDays > 0) {
      if (difference.inDays == 1) return loc.translate('activity.oneDayAgo');
      return loc.translate('activity.daysAgo', args: {'count': difference.inDays});
    } else if (difference.inHours > 0) {
      if (difference.inHours == 1) return loc.translate('activity.oneHourAgo');
      return loc.translate('activity.hoursAgo', args: {'count': difference.inHours});
    } else if (difference.inMinutes > 0) {
      if (difference.inMinutes == 1) return loc.translate('activity.oneMinuteAgo');
      return loc.translate('activity.minutesAgo', args: {'count': difference.inMinutes});
    } else {
      return loc.translate('activity.justNow');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context);
    final actorName = activity.actor.displayName ?? loc.translate('activity.someone');
    final actorImage = activity.actor.imageUrl;
    final activityIcon = _getActivityIcon(activity.type);
    final activityColor = _getActivityColor(activity.type);
    final timeAgo = _getTimeAgoLocalized(loc, activity.createdAt);
    final friendId = activity.actor.id;

    final typeLower = activity.type.toLowerCase();
    final itemName = activity.itemName ?? loc.translate('activity.anItem');
    final wishlistName = activity.wishlistName ?? '';
    String displayText;
    if (typeLower == 'wishlist_item_added') {
      displayText = loc.translate('activity.addedToWishlist', args: {
        'actor': actorName,
        'item': itemName,
        'wishlist': wishlistName,
      });
      if (displayText == 'activity.addedToWishlist') {
        displayText = '$actorName added $itemName to their wishlist $wishlistName';
      }
    } else if (typeLower == 'item_received') {
      displayText = loc.translate('activity.receivedTheir', args: {'actor': actorName, 'item': itemName});
      if (displayText == 'activity.receivedTheir') {
        displayText = '$actorName received their $itemName!';
      }
    } else {
      displayText = activity.getDisplayText();
    }

    return GestureDetector(
      onTap: friendId.isNotEmpty
          ? () {
              Navigator.pushNamed(
                context,
                AppRoutes.friendProfile,
                arguments: {'friendId': friendId},
              );
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: actorImage != null
                  ? NetworkImage(actorImage)
                  : null,
              child: actorImage == null
                  ? Text(
                      _getInitials(actorName),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        fontFamily: 'Alexandria',
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayText,
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontFamily: 'Alexandria',
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeAgo,
                    style: AppStyles.caption.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 10,
                      fontFamily: 'Alexandria',
                    ),
                  ),
                ],
              ),
            ),
            // Activity Icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: activityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                activityIcon,
                color: activityColor,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
