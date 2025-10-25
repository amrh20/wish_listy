import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'package:wish_listy/core/services/localization_service.dart';

class EventCard extends StatelessWidget {
  final EventSummary event;
  final LocalizationService localization;
  final VoidCallback? onTap;
  final VoidCallback? onManageEvent;
  final VoidCallback? onViewWishlist;
  final VoidCallback? onAddWishlist;
  final VoidCallback? onViewDetails;

  const EventCard({
    super.key,
    required this.event,
    required this.localization,
    this.onTap,
    this.onManageEvent,
    this.onViewWishlist,
    this.onAddWishlist,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final isPast = event.status == EventStatus.completed;
    final daysUntil = event.date.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: isPast
            ? Border.all(color: AppColors.textTertiary.withOpacity(0.3))
            : Border.all(
                color: _getEventTypeColor(event.type).withOpacity(0.3),
              ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textTertiary.withOpacity(0.1),
            offset: const Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              _buildHeader(event, isPast, daysUntil),
              _buildContent(event, isPast),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(EventSummary event, bool isPast, int daysUntil) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPast
              ? [
                  AppColors.textTertiary.withOpacity(0.1),
                  AppColors.textTertiary.withOpacity(0.05),
                ]
              : [
                  _getEventTypeColor(event.type).withOpacity(0.1),
                  _getEventTypeColor(event.type).withOpacity(0.05),
                ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          // Event Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isPast
                  ? AppColors.textTertiary
                  : _getEventTypeColor(event.type),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _getEventTypeIcon(event.type),
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(width: 16),

          // Event Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.name,
                  style: AppStyles.headingSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isPast
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                if (event.hostName != null)
                  Text(
                    'by ${event.hostName}',
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.location ?? 'Location TBD',
                        style: AppStyles.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Date Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isPast
                  ? AppColors.textTertiary.withOpacity(0.1)
                  : daysUntil <= 7
                  ? AppColors.warning.withOpacity(0.1)
                  : AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '${event.date.day}',
                  style: AppStyles.headingSmall.copyWith(
                    color: isPast
                        ? AppColors.textTertiary
                        : daysUntil <= 7
                        ? AppColors.warning
                        : AppColors.info,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getMonthName(event.date.month),
                  style: AppStyles.caption.copyWith(
                    color: isPast
                        ? AppColors.textTertiary
                        : daysUntil <= 7
                        ? AppColors.warning
                        : AppColors.info,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(EventSummary event, bool isPast) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          if (event.description != null)
            Text(
              event.description!,
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

          const SizedBox(height: 16),

          // Stats Row
          Row(
            children: [
              Expanded(
                child: _buildEventStat(
                  icon: Icons.people_outline,
                  label: 'Invited',
                  value: '${event.invitedCount}',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEventStat(
                  icon: Icons.check_circle_outline,
                  label: 'Accepted',
                  value: '${event.acceptedCount}',
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              // Dynamic wishlist stat based on whether wishlist exists
              if (event.wishlistId != null) ...[
                Expanded(
                  child: _buildEventStat(
                    icon: Icons.card_giftcard_outlined,
                    label: 'Wishlist',
                    value: '${event.wishlistItemCount}',
                    color: AppColors.secondary,
                  ),
                ),
              ] else ...[
                Expanded(child: _buildNoWishlistStat()),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // Action Buttons
          if (!isPast) ...[
            Row(
              children: [
                if (event.isCreatedByMe) ...[
                  // Event creator buttons
                  Expanded(
                    child: CustomButton(
                      text: localization.translate('ui.manageEvent'),
                      onPressed: onManageEvent,
                      variant: ButtonVariant.outline,
                      customColor: _getEventTypeColor(event.type),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: event.wishlistId != null
                          ? localization.translate('ui.viewWishlist')
                          : localization.translate('ui.addWishlist'),
                      onPressed: event.wishlistId != null
                          ? onViewWishlist
                          : onAddWishlist,
                      variant: ButtonVariant.primary,
                      customColor: _getEventTypeColor(event.type),
                    ),
                  ),
                ] else ...[
                  // Guest buttons
                  Expanded(
                    child: CustomButton(
                      text: 'View Details',
                      onPressed: onViewDetails,
                      variant: ButtonVariant.outline,
                      customColor: _getEventTypeColor(event.type),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (event.wishlistId != null) ...[
                    Expanded(
                      child: CustomButton(
                        text: localization.translate('ui.viewWishlist'),
                        onPressed: onViewWishlist,
                        variant: ButtonVariant.primary,
                        customColor: _getEventTypeColor(event.type),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: CustomButton(
                        text: localization.translate('ui.noWishlist'),
                        onPressed: null, // Disabled button
                        variant: ButtonVariant.outline,
                        customColor: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ] else ...[
            // Past event actions
            CustomButton(
              text: 'View Event Details',
              onPressed: onViewDetails,
              variant: ButtonVariant.outline,
              customColor: AppColors.textTertiary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEventStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: AppStyles.bodySmall.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            style: AppStyles.caption.copyWith(color: AppColors.textTertiary),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildNoWishlistStat() {
    return Row(
      children: [
        Icon(Icons.warning_outlined, size: 16, color: AppColors.warning),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            localization.translate('ui.noWishlistLinked'),
            style: AppStyles.caption.copyWith(
              color: AppColors.warning,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Color _getEventTypeColor(EventType type) {
    switch (type) {
      case EventType.birthday:
        return AppColors.secondary;
      case EventType.wedding:
        return AppColors.primary;
      case EventType.anniversary:
        return AppColors.error;
      case EventType.graduation:
        return AppColors.accent;
      case EventType.holiday:
        return AppColors.success;
      case EventType.babyShower:
        return AppColors.info;
      case EventType.houseWarming:
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  IconData _getEventTypeIcon(EventType type) {
    switch (type) {
      case EventType.birthday:
        return Icons.cake_outlined;
      case EventType.wedding:
        return Icons.favorite_outline;
      case EventType.anniversary:
        return Icons.favorite_border;
      case EventType.graduation:
        return Icons.school_outlined;
      case EventType.holiday:
        return Icons.celebration_outlined;
      case EventType.babyShower:
        return Icons.child_friendly_outlined;
      case EventType.houseWarming:
        return Icons.home_outlined;
      default:
        return Icons.event_outlined;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}

// Event models
class EventSummary {
  final String id;
  final String name;
  final DateTime date;
  final EventType type;
  final String? location;
  final String? description;
  final String? hostName;
  final int invitedCount;
  final int acceptedCount;
  final int wishlistItemCount;
  final String? wishlistId;
  final bool isCreatedByMe;
  final EventStatus status;

  EventSummary({
    required this.id,
    required this.name,
    required this.date,
    required this.type,
    this.location,
    this.description,
    this.hostName,
    required this.invitedCount,
    required this.acceptedCount,
    required this.wishlistItemCount,
    this.wishlistId,
    required this.isCreatedByMe,
    required this.status,
  });
}

enum EventType {
  birthday,
  wedding,
  anniversary,
  graduation,
  holiday,
  vacation,
  babyShower,
  houseWarming,
  retirement,
  promotion,
  other,
}

enum EventStatus { upcoming, ongoing, completed, cancelled }
