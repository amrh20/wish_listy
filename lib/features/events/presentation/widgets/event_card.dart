import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/features/events/data/models/event_model.dart';

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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface, // White background
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.border.withOpacity(0.8),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(24),
              child: Column(
                children: [
                  _buildHeader(event, isPast, daysUntil),
                  _buildContent(event, isPast),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(EventSummary event, bool isPast, int daysUntil) {
    final eventColor = _getEventTypeColor(event.type);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.06), // Soft Teal Tint
      ),
      child: Row(
        children: [
          // Event Icon - Squircle Style
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surface, // Surface background for contrast
              borderRadius: BorderRadius.circular(20), // Squircle
              boxShadow: [
                BoxShadow(
                  color: (isPast ? AppColors.textTertiary : eventColor)
                      .withOpacity(0.15),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(
              _getEventTypeIcon(event.type),
              color: isPast
                  ? AppColors.textTertiary
                  : eventColor,
              size: 32,
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

          // Date Badge - Pill-shaped
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isPast
                  ? AppColors.textTertiary.withOpacity(0.15)
                  : daysUntil <= 7
                  ? AppColors.warning.withOpacity(0.15)
                  : AppColors.info.withOpacity(0.15),
              borderRadius: BorderRadius.circular(30), // Pill-shaped
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
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
                const SizedBox(width: 4),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surface, // White background for body
      ),
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

          // Stats Row - Unified 3-column structure like Wishlist
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildEventStatColumn(
                icon: Icons.people_outline,
                label: 'Invited',
                value: '${event.invitedCount}',
                color: AppColors.secondary, // Match header theme (Teal)
              ),
              _buildEventStatColumn(
                icon: Icons.check_circle_outline,
                label: 'Accepted',
                value: '${event.acceptedCount}',
                color: AppColors.secondary, // Match header theme (Teal)
              ),
              if (event.wishlistId != null)
                _buildEventStatColumn(
                  icon: Icons.card_giftcard_outlined,
                  label: 'Wishlist',
                  value: '${event.wishlistItemCount}',
                  color: AppColors.secondary, // Match header theme (Teal)
                )
              else
                _buildEventStatColumn(
                  icon: Icons.warning_outlined,
                  label: 'No Wishlist',
                  value: '—',
                  color: AppColors.secondary, // Match header theme (Teal)
                ),
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
                      customColor: AppColors.primary, // Use primary color for all buttons
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
                      customColor: AppColors.primary, // Use primary color for all buttons
                    ),
                  ),
                ] else ...[
                  // Guest buttons
                  Expanded(
                    child: CustomButton(
                      text: 'View Details',
                      onPressed: onViewDetails,
                      variant: ButtonVariant.outline,
                      customColor: AppColors.primary, // Use primary color for all buttons
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (event.wishlistId != null) ...[
                    Expanded(
                      child: CustomButton(
                        text: localization.translate('ui.viewWishlist'),
                        onPressed: onViewWishlist,
                        variant: ButtonVariant.primary,
                        customColor: AppColors.primary, // Use primary color for all buttons
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

  Widget _buildEventStatColumn({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        // Icon Container with pastel background
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        // Bold number in middle
        Text(
          value,
          style: AppStyles.headingSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        // Small label at bottom
        Text(
          label,
          style: AppStyles.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
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
