import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
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
  final VoidCallback? onShare;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;

  const EventCard({
    super.key,
    required this.event,
    required this.localization,
    this.onTap,
    this.onManageEvent,
    this.onViewWishlist,
    this.onAddWishlist,
    this.onViewDetails,
    this.onShare,
    this.onEdit,
    this.onDuplicate,
    this.onDelete,
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
                  _buildHeader(context, event, isPast, daysUntil),
                  _buildContent(event, isPast),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    EventSummary event,
    bool isPast,
    int daysUntil,
  ) {
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
              color: isPast ? AppColors.textTertiary : eventColor,
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

          // MoreVert Menu Button
          if (event.isCreatedByMe)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showContextMenu(context),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.more_vert,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ),
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

          const SizedBox(height: 16),

          // Single Sleek Primary Button
          if (!isPast) ...[
            if (event.isCreatedByMe)
              _buildSleekButton(
                text: event.wishlistId != null
                    ? localization.translate('ui.manageEvent')
                    : localization.translate('ui.addWishlist'),
                onPressed: event.wishlistId != null
                    ? onManageEvent
                    : onAddWishlist,
              )
            else
              _buildSleekButton(
                text: event.wishlistId != null
                    ? localization.translate('ui.viewWishlist')
                    : 'View Details',
                onPressed: event.wishlistId != null
                    ? onViewWishlist
                    : onViewDetails,
              ),
          ] else ...[
            // Past event actions
            _buildSleekButton(
              text: 'View Event Details',
              onPressed: onViewDetails,
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

  /// Builds a sleek, compact button with 44px height and 14px font
  Widget _buildSleekButton({
    required String text,
    required VoidCallback? onPressed,
  }) {
    final isEnabled = onPressed != null;

    return SizedBox(
      height: 44,
      width: double.infinity,
      child: Material(
        color: isEnabled
            ? AppColors.primary
            : AppColors.primary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.w600,
                color: isEnabled ? Colors.white : Colors.white.withOpacity(0.6),
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Shows the context menu bottom sheet with event actions
  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Menu Items
              _buildMenuItem(
                icon: Icons.share_outlined,
                label: 'Share Event',
                onTap: () {
                  Navigator.pop(context);
                  onShare?.call();
                },
              ),
              _buildMenuItem(
                icon: Icons.edit_outlined,
                label: 'Edit Event',
                onTap: () {
                  Navigator.pop(context);
                  onEdit?.call();
                },
              ),
              _buildMenuItem(
                icon: Icons.delete_outline,
                label: 'Delete Event',
                onTap: () {
                  Navigator.pop(context);
                  onDelete?.call();
                },
                isDestructive: true,
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a menu item for the bottom sheet
  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppColors.error : AppColors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
