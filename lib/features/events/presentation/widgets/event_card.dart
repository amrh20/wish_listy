import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
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
    final localization = Provider.of<LocalizationService>(context, listen: false);
    final isPast = event.status == EventStatus.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Opacity(
            opacity: isPast ? 0.7 : 1.0,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Row: Date Badge + Content
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Badge (Left)
                    _buildDateBadge(),
                    const SizedBox(width: 12),
                    // Content (Expanded)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Row: Title + Spacer + more_vert
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  event.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (event.isCreatedByMe)
                                IconButton(
                                  icon: const Icon(
                                    Icons.more_vert,
                                    size: 20,
                                    color: AppColors.textSecondary,
                                  ),
                                  onPressed: () => _showContextMenu(context),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Location Row
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  event.location ?? '—',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Badges Row: Category + Status
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _buildCategoryBadge(localization),
                              _buildStatusBadge(isPast, localization),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Description (if exists)
                if (event.description != null &&
                    event.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    event.description!.trim(),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                // Wishlist Section
                if (event.wishlistId != null) ...[
                  const SizedBox(height: 12),
                  _buildWishlistStrip(true),
                ] else ...[
                  const SizedBox(height: 12),
                  _buildWishlistStrip(false),
                ],
                // Footer: Avatar Stack (Guests)
                if (event.invitedCount > 0) ...[
                  const SizedBox(height: 12),
                  _buildGuestsFooter(),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
          if (isPast) _buildEndedBadge(localization),
        ],
      ),
    );
  }

  /// "Ended" badge/ribbon overlaying the card for past events
  Widget _buildEndedBadge(LocalizationService localization) {
    return Positioned(
      top: -4,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.textTertiary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_busy,
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              localization.translate('events.statusEndedBadge'),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the Date Badge on the left side
  Widget _buildDateBadge() {
    final month = _getMonthNameShort(event.date.month);
    final day = event.date.day.toString();

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            month,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            day,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the Category Badge
  Widget _buildCategoryBadge(LocalizationService localization) {
    final style = _getEventTypeStyle(event.type, event.typeString, localization);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: style.color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 14, color: style.textColor),
          const SizedBox(width: 4),
          Text(
            style.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: style.textColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the Status Badge
  Widget _buildStatusBadge(bool isPast, LocalizationService localization) {
    String statusText = localization.translate('events.upcoming');
    if (isPast) {
      statusText = localization.translate('events.completed');
    } else {
      switch (event.status) {
        case EventStatus.upcoming:
          statusText = localization.translate('events.upcoming');
          break;
        case EventStatus.completed:
          statusText = localization.translate('events.completed');
          break;
        case EventStatus.cancelled:
          statusText = localization.translate('events.cancelled');
          break;
        case EventStatus.ongoing:
          statusText = localization.translate('events.ongoing');
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  /// Builds the Wishlist Strip (purple section)
  Widget _buildWishlistStrip(bool hasWishlist) {
    if (hasWishlist) {
      return InkWell(
        onTap: onViewWishlist,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.card_giftcard,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.wishlistName ?? localization.translate('events.wishlistCreatedLabel'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      localization.translate('cards.tapToView') ?? 'Tap to view',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      );
    } else {
      return InkWell(
        onTap: onAddWishlist,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.add_circle_outline,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                localization.translate('cards.addWishlist'),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  /// Builds the Guests Footer with Avatar Stack
  Widget _buildGuestsFooter() {
    // Use actual invited friends list if available
    final friendsList = event.invitedFriends.isNotEmpty
        ? event.invitedFriends
        : [];
    
    // If no friends list, use count as fallback
    final displayCount = friendsList.isNotEmpty
        ? friendsList.length
        : (event.acceptedCount > 0 ? event.acceptedCount : event.invitedCount);
    
    final maxAvatars = 3;
    final displayFriends = friendsList.take(maxAvatars).toList();
    final avatarCount = displayFriends.length > 0
        ? displayFriends.length
        : (displayCount > maxAvatars ? maxAvatars : displayCount);
    final overflowCount = friendsList.length > maxAvatars
        ? friendsList.length - maxAvatars
        : (displayCount > maxAvatars ? displayCount - maxAvatars : 0);

    // Helper to get initials from fullName
    String getInitials(String fullName) {
      if (fullName.isEmpty) return '?';
      final parts = fullName.trim().split(' ');
      if (parts.length >= 2) {
        return (parts[0][0] + parts[1][0]).toUpperCase();
      }
      return fullName[0].toUpperCase();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            localization.translate('cards.invitedGuests'),
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        // Avatars Row
        Row(
          children: [
            // Display actual friend avatars if available
            if (displayFriends.isNotEmpty)
              ...displayFriends.asMap().entries.map((entry) {
                final index = entry.key;
                final friend = entry.value;
                final hasImage = friend.profileImage != null &&
                    friend.profileImage!.isNotEmpty;
                final initials = getInitials(friend.fullName ?? friend.username ?? friend.id);
                
                return Transform.translate(
                  offset: Offset(index > 0 ? -6.0 : 0.0, 0.0),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 17,
                      backgroundImage: hasImage
                          ? NetworkImage(friend.profileImage!)
                          : null,
                      onBackgroundImageError: hasImage ? (_, __) {} : null,
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      child: !hasImage
                          ? Text(
                              initials,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            )
                          : null,
                    ),
                  ),
                );
              })
            else
              // Fallback: Placeholder avatars (if no friend data)
              ...List.generate(avatarCount, (index) {
                return Transform.translate(
                  offset: Offset(index > 0 ? -6.0 : 0.0, 0.0),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 17,
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      child: Icon(
                        Icons.person,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                );
              }),
            // Overflow Badge
            if (overflowCount > 0)
              Transform.translate(
                offset: const Offset(-6.0, 0.0),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey.shade400,
                  child: Text(
                    '+$overflowCount',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// Gets event type style (icon, color, textColor, label)
  /// If typeString is provided (custom type), use it for label
  ({IconData icon, Color color, Color textColor, String label})
      _getEventTypeStyle(EventType type, String? typeString, LocalizationService localization) {
    // If custom type string is provided, use it for label
    if (typeString != null && typeString.isNotEmpty) {
      switch (type) {
        case EventType.other:
          return (
            icon: Icons.event,
            color: Colors.purple.shade50,
            textColor: Colors.purple.shade700,
            label: typeString, // Use custom type string
          );
        default:
          // For predefined types with custom string, still show custom string but use appropriate styling
          break;
      }
    }
    
    switch (type) {
      case EventType.birthday:
        return (
          icon: Icons.cake,
          color: Colors.pink.shade100,
          textColor: Colors.pink.shade700,
          label: typeString ?? localization.translate('events.birthday'),
        );
      case EventType.anniversary:
        return (
          icon: Icons.favorite,
          color: Colors.red.shade100,
          textColor: Colors.red.shade700,
          label: typeString ?? localization.translate('events.anniversary'),
        );
      case EventType.graduation:
        return (
          icon: Icons.school,
          color: Colors.blue.shade100,
          textColor: Colors.blue.shade700,
          label: typeString ?? localization.translate('events.graduation'),
        );
      case EventType.wedding:
        return (
          icon: Icons.favorite,
          color: Colors.pink.shade100,
          textColor: Colors.pink.shade700,
          label: typeString ?? localization.translate('events.wedding'),
        );
      case EventType.holiday:
        return (
          icon: Icons.celebration,
          color: Colors.orange.shade100,
          textColor: Colors.orange.shade700,
          label: typeString ?? localization.translate('common.holiday'),
        );
      case EventType.babyShower:
        return (
          icon: Icons.child_care,
          color: Colors.purple.shade100,
          textColor: Colors.purple.shade700,
          label: typeString ?? localization.translate('events.babyShower'),
        );
      case EventType.houseWarming:
        return (
          icon: Icons.home,
          color: Colors.green.shade100,
          textColor: Colors.green.shade700,
          label: typeString ?? localization.translate('events.housewarming'),
        );
      default:
        return (
          icon: Icons.event,
          color: Colors.purple.shade50,
          textColor: Colors.purple.shade700,
          label: typeString ?? localization.translate('events.other'),
        );
    }
  }

  /// Gets short month name (JAN, FEB, etc.)
  String _getMonthNameShort(int month) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return months[month - 1];
  }

  /// Shows the context menu bottom sheet with event actions
  void _showContextMenu(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context, listen: false);
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
                label: localization.translate('events.shareEvent'),
                onTap: () {
                  Navigator.pop(context);
                  onShare?.call();
                },
              ),
              _buildMenuItem(
                icon: Icons.edit_outlined,
                label: localization.translate('events.editEvent'),
                onTap: () {
                  Navigator.pop(context);
                  onEdit?.call();
                },
              ),
              _buildMenuItem(
                icon: Icons.delete_outline,
                label: localization.translate('events.deleteEvent'),
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
