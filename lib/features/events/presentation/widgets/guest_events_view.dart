import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'package:wish_listy/features/auth/presentation/widgets/guest_restriction_dialog.dart';
import 'package:wish_listy/features/events/data/models/event_model.dart';

class GuestEventsView extends StatefulWidget {
  final List<EventSummary> publicEvents;
  final LocalizationService localization;

  const GuestEventsView({
    super.key,
    required this.publicEvents,
    required this.localization,
  });

  @override
  State<GuestEventsView> createState() => _GuestEventsViewState();
}

class _GuestEventsViewState extends State<GuestEventsView> {
  @override
  Widget build(BuildContext context) {
    if (widget.publicEvents.isEmpty) {
      return _buildEmptyState();
    }

    return _buildEventsList();
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 60),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_outlined,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Public Events Yet',
            style: AppStyles.headingMediumWithContext(context).copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Be the first to create an event! Sign up to organize events and invite friends.',
            style: AppStyles.bodyMediumWithContext(context).copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          CustomButton(
            text: 'Sign Up to Create Events',
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.signup);
            },
            variant: ButtonVariant.gradient,
            gradientColors: [AppColors.primary, AppColors.secondary],
            size: ButtonSize.large,
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.publicEvents.length,
      itemBuilder: (context, index) {
        return _buildGuestEventCard(widget.publicEvents[index]);
      },
    );
  }

  Widget _buildGuestEventCard(EventSummary event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getEventTypeColor(event.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getEventTypeIcon(event.type),
                  color: _getEventTypeColor(event.type),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name,
                      style: AppStyles.bodyLargeWithContext(context).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (event.hostName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${widget.localization.translate('common.by')} ${event.hostName}',
                        style: AppStyles.bodySmallWithContext(context).copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                children: [
                  Text(
                    '${event.date.day}',
                    style: AppStyles.heading4WithContext(context).copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _getMonthName(event.date.month),
                    style: AppStyles.captionWithContext(context).copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (event.description != null) ...[
            Text(
              event.description!,
              style: AppStyles.bodyMediumWithContext(context).copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
          ],
          if (event.location != null) ...[
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  event.location!,
                  style: AppStyles.bodySmallWithContext(context).copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              _buildGuestEventStat(
                icon: Icons.people_outline,
                value: '${event.acceptedCount}/${event.invitedCount}',
                label: widget.localization.translate(
                  'guest.events.card.attendees',
                ),
              ),
              const SizedBox(width: 16),
              _buildGuestEventStat(
                icon: Icons.card_giftcard,
                value: '${event.wishlistItemCount}',
                label: 'Wishes',
              ),
              const Spacer(),
              CustomButton(
                text: widget.localization.translate(
                  'guest.events.card.viewDetails',
                ),
                onPressed: () => _showGuestEventDetails(event),
                variant: ButtonVariant.outline,
                size: ButtonSize.small,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuestEventStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppStyles.bodySmallWithContext(context).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              label,
              style: AppStyles.captionWithContext(context).copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }


  void _showGuestEventDetails(EventSummary event) {
    GuestRestrictionDialog.show(context, 'Event Details');
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
