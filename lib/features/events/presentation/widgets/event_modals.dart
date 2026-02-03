import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/features/events/data/models/event_model.dart';
import 'package:wish_listy/features/events/data/repository/event_repository.dart';
import 'package:wish_listy/features/events/presentation/widgets/wishlist_options_bottom_sheet.dart';
import 'package:wish_listy/features/events/presentation/widgets/link_wishlist_bottom_sheet.dart';
import 'calendar_view.dart';
import 'filter_options.dart';

class EventModals {
  static void showCalendarView(
    BuildContext context,
    List<EventSummary> events,
    LocalizationService localization,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localization.translate('events.calendarView')),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: CalendarView(events: events, localization: localization),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localization.translate('common.close')),
          ),
        ],
      ),
    );
  }

  static void showFilterOptions(
    BuildContext context,
    String selectedSortOption,
    String? selectedEventType,
    Function(String) onSortChanged,
    Function(String?) onEventTypeChanged,
    VoidCallback onClearAll,
    VoidCallback onApply,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FilterOptions(
        selectedSortOption: selectedSortOption,
        selectedEventType: selectedEventType,
        onSortChanged: onSortChanged,
        onEventTypeChanged: onEventTypeChanged,
        onClearAll: onClearAll,
        onApply: onApply,
      ),
    );
  }

  static void showWishlistSelectionModal(
    BuildContext context,
    EventSummary event,
    List<Map<String, dynamic>> wishlists,
    LocalizationService localization,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              localization.translate('events.selectWishlist'),
              style: AppStyles.headingSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              localization
                  .translate('events.hasWishlists')
                  .replaceAll('{eventName}', event.name)
                  .replaceAll('{count}', wishlists.length.toString()),
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Wishlist List
            ...wishlists.map((wishlist) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                      context,
                      AppRoutes.wishlistItems,
                      arguments: {
                        'wishlistId': wishlist['id'],
                        'wishlistName': wishlist['name'],
                        'totalItems': wishlist['totalItems'],
                        'purchasedItems': wishlist['purchasedItems'],
                        'totalValue': wishlist['totalValue'],
                        'isFriendWishlist': false,
                      },
                    );
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: AppColors.surface,
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getEventTypeColor(event.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.favorite_rounded,
                      color: _getEventTypeColor(event.type),
                      size: 24,
                    ),
                  ),
                  title: Text(
                    wishlist['name'],
                    style: AppStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        '${wishlist['totalItems']} items • ${wishlist['purchasedItems']} purchased',
                        style: AppStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            _getPrivacyIcon(wishlist['privacy']),
                            size: 14,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getPrivacyLabel(wishlist['privacy']),
                            style: AppStyles.caption.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  static void showAddWishlistToEventModal(
    BuildContext context,
    EventSummary event,
    LocalizationService localization,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => WishlistOptionsBottomSheet(
        onCreateNew: () {
          Navigator.pop(context);
          Navigator.pushNamed(
            context,
            AppRoutes.createWishlist,
            arguments: {
              'eventId': event.id,
              'isForEvent': true,
              'previousRoute': AppRoutes.events,
            },
          ).then((result) {
            // Refresh events list if wishlist was created and linked
            if (result == true && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Wishlist created and linked successfully'),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          });
        },
        onLinkExisting: () {
          Navigator.pop(context);
          _showLinkExistingWishlistModal(
            context,
            event,
            localization,
          );
        },
      ),
    );
  }

  static void _showLinkExistingWishlistModal(
    BuildContext context,
    EventSummary event,
    LocalizationService localization,
  ) {
    final eventRepository = EventRepository();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => LinkWishlistBottomSheet(
        eventId: event.id,
        onLink: (wishlistId) async {
          try {
            // Link wishlist to event
            await eventRepository.linkWishlistToEvent(
              eventId: event.id,
              wishlistId: wishlistId,
            );

            // Use the bottom sheet context to close it
            if (!bottomSheetContext.mounted) return;
            Navigator.pop(bottomSheetContext);

            // Use the original context for showing snackbar (events screen context)
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(localization.translate('dialogs.wishlistLinkedSuccessfully') ?? 'Wishlist linked successfully'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } catch (e) {
            // Use the bottom sheet context to close it
            if (!bottomSheetContext.mounted) return;
            Navigator.pop(bottomSheetContext);

            // Use the original context for showing snackbar (events screen context)
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${localization.translate('dialogs.failedToLinkWishlist') ?? 'Failed to link wishlist'}: ${e.toString()}'),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  static Color _getEventTypeColor(EventType type) {
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

  static IconData _getPrivacyIcon(String privacy) {
    switch (privacy) {
      case 'public':
        return Icons.public;
      case 'private':
        return Icons.lock;
      case 'friends':
        return Icons.people;
      default:
        return Icons.help;
    }
  }

  static String _getPrivacyLabel(String privacy) {
    switch (privacy) {
      case 'public':
        return 'Public';
      case 'private':
        return 'Private';
      case 'friends':
        return 'Friends Only';
      default:
        return privacy;
    }
  }
}
