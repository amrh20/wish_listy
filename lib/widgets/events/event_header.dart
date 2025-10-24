import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import 'event_card.dart';

class EventHeader extends StatelessWidget {
  final EventSummary event;
  final bool isPast;
  final int daysUntil;

  const EventHeader({
    super.key,
    required this.event,
    required this.isPast,
    required this.daysUntil,
  });

  @override
  Widget build(BuildContext context) {
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
