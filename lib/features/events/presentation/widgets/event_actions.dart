import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'package:wish_listy/features/events/data/models/event_model.dart';

class EventActions extends StatelessWidget {
  final EventSummary event;
  final LocalizationService localization;
  final VoidCallback? onManageEvent;
  final VoidCallback? onViewWishlist;
  final VoidCallback? onAddWishlist;
  final VoidCallback? onViewDetails;

  const EventActions({
    super.key,
    required this.event,
    required this.localization,
    this.onManageEvent,
    this.onViewWishlist,
    this.onAddWishlist,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final isPast = event.status == EventStatus.completed;

    if (isPast) {
      return CustomButton(
        text: 'View Event Details',
        onPressed: onViewDetails,
        variant: ButtonVariant.outline,
        customColor: AppColors.textTertiary,
      );
    }

    return Row(
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
}
