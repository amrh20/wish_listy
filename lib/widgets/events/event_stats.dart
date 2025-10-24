import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../services/localization_service.dart';

class EventStats extends StatelessWidget {
  final EventSummary event;
  final LocalizationService localization;

  const EventStats({
    super.key,
    required this.event,
    required this.localization,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildEventStat(
          icon: Icons.people_outline,
          label: 'Invited',
          value: '${event.invitedCount}',
          color: AppColors.primary,
        ),
        const SizedBox(width: 20),
        _buildEventStat(
          icon: Icons.check_circle_outline,
          label: 'Accepted',
          value: '${event.acceptedCount}',
          color: AppColors.success,
        ),
        const SizedBox(width: 20),
        // Dynamic wishlist stat based on whether wishlist exists
        if (event.wishlistId != null) ...[
          _buildEventStat(
            icon: Icons.card_giftcard_outlined,
            label: 'Wishlist',
            value: '${event.wishlistItemCount}',
            color: AppColors.secondary,
          ),
        ] else ...[
          _buildNoWishlistStat(),
        ],
      ],
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
        Text(
          label,
          style: AppStyles.caption.copyWith(color: AppColors.textTertiary),
        ),
      ],
    );
  }

  Widget _buildNoWishlistStat() {
    return Row(
      children: [
        Icon(Icons.warning_outlined, size: 16, color: AppColors.warning),
        const SizedBox(width: 4),
        Text(
          localization.translate('ui.noWishlistLinked'),
          style: AppStyles.caption.copyWith(
            color: AppColors.warning,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
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
