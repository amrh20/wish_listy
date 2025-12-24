import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/widgets/primary_gradient_button.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/features/events/data/models/event_model.dart';
import 'package:wish_listy/features/events/data/repository/event_repository.dart';
import 'package:wish_listy/features/events/presentation/widgets/invite_friends_bottom_sheet.dart';
import 'package:wish_listy/features/events/presentation/widgets/wishlist_options_bottom_sheet.dart';
import 'package:wish_listy/features/events/presentation/widgets/link_wishlist_bottom_sheet.dart';
import 'package:wish_listy/features/events/presentation/widgets/event_wishlist_tile.dart';
import 'package:wish_listy/core/widgets/top_overlay_toast.dart';

class EventDetailsScreen extends StatefulWidget {
  final String eventId;
  final bool isOwner;

  const EventDetailsScreen({
    super.key,
    required this.eventId,
    this.isOwner = true, // Default to true since only Owner API is ready
  });

  @override
  _EventDetailsScreenState createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  // Event data
  Event? _event;

  // Loading and error states
  bool _isLoading = true;
  String? _errorMessage;

  // Repository
  final EventRepository _eventRepository = EventRepository();

  @override
  void initState() {
    super.initState();
    _loadEventDetails();
  }

  /// Handles back navigation - returns to events list
  void _handleBackNavigation() {
    if (!mounted) return;

    // Use post-frame callback to ensure Navigator is not locked
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final navigator = Navigator.of(context);

      // Simple approach: just pop if possible, otherwise navigate
      // Return true to indicate that events list should be refreshed
      if (navigator.canPop()) {
        try {
          navigator.pop(true); // Return true to trigger refresh
        } catch (e) {

          // If pop fails, navigate to events screen
          if (mounted) {
            try {
              navigator.pushReplacementNamed(AppRoutes.events);
            } catch (e2) {

            }
          }
        }
      } else {
        // If no route to pop, navigate to events list directly
        try {
          navigator.pushReplacementNamed(AppRoutes.events);
        } catch (e) {

        }
      }
    });
  }

  Future<void> _loadEventDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {

      final event = await _eventRepository.getEventById(widget.eventId);

      if (!mounted) return;

      setState(() {
        _event = event;
        _isLoading = false;
      });

    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load event. Please try again.';
        _isLoading = false;
      });

    }
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
      case EventType.vacation:
        return Icons.beach_access_outlined;
      case EventType.babyShower:
        return Icons.child_friendly_outlined;
      case EventType.houseWarming:
        return Icons.home_outlined;
      case EventType.retirement:
        return Icons.work_off_outlined;
      case EventType.promotion:
        return Icons.trending_up_outlined;
      default:
        return Icons.event_outlined;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(String? time) {
    if (time != null && time.isNotEmpty) {
      return time; // Already in HH:mm format
    }
    // Fallback: extract time from event.date
    if (_event != null) {
      final hour = _event!.date.hour.toString().padLeft(2, '0');
      final minute = _event!.date.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localization, child) {
        // Error State
        if (_errorMessage != null && _event == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: AppColors.textPrimary,
                ),
                onPressed: _handleBackNavigation,
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(
                      'Error Loading Event',
                      style: AppStyles.headingMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: AppStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    PrimaryGradientButton(
                      text: 'Retry',
                      icon: Icons.refresh,
                      onPressed: _loadEventDetails,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Loading State
        if (_isLoading || _event == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final eventColor = _getEventTypeColor(_event!.type);
        final acceptedGuests = _event!.invitations
            .where((inv) => inv.status == InvitationStatus.accepted)
            .take(5)
            .toList();
        final remainingCount =
            _event!.invitations
                .where((inv) => inv.status == InvitationStatus.accepted)
                .length -
            acceptedGuests.length;

        return PopScope(
          canPop: false,
          onPopInvoked: (didPop) {
            if (!didPop) {
              _handleBackNavigation();
            }
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: CustomScrollView(
              slivers: [
                // SliverAppBar (The Header)
                _buildSliverAppBar(eventColor, localization),

                // Content Body
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Unified Info Sheet (Merged Date, Location, Description, Guests)
                        _buildUnifiedInfoSheet(acceptedGuests, remainingCount),

                        const SizedBox(height: 16),

                        // Linked Wishlist (Kept Separate)
                        if (_event!.isCreator || _event!.wishlistId != null)
                          _buildWishlistCard(localization),

                        SizedBox(
                          height: 20 + MediaQuery.of(context).padding.bottom,
                        ), // Bottom padding
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Bottom Navigation Bar removed - actions moved to More Options menu
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar(
    Color eventColor,
    LocalizationService localization,
  ) {
    final daysUntil = _event!.date.difference(DateTime.now()).inDays;
    final isPast = _event!.status == EventStatus.completed;

    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => _handleBackNavigation(),
      ),
      actions: _event?.isCreator == true ? [_buildMoreOptionsMenu()] : [],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: AppColors
                .primaryGradient, // Use Purple Gradient (Unified Identity)
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  // Event Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          offset: const Offset(0, 4),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Icon(
                      _getEventTypeIcon(_event!.type),
                      color: AppColors.primary,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Event Name
                  Text(
                    _event!.name,
                    style: AppStyles.headingLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // Date Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isPast
                              ? 'Past Event'
                              : daysUntil == 0
                              ? 'Today'
                              : daysUntil == 1
                              ? 'Tomorrow'
                              : 'In $daysUntil days',
                          style: AppStyles.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the unified info sheet (merged Date, Location, Description, Guests)
  Widget _buildUnifiedInfoSheet(
    List<EventInvitation> acceptedGuests,
    int remainingCount,
  ) {
    final hasDescription =
        _event!.description != null && _event!.description!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meta-Tags Row (Type, Privacy, Status)
          _buildMetaTagsRow(),
          const SizedBox(height: 16),
          // Date & Time Row
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      _formatDate(_event!.date),
                      style: AppStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (_event!.time != null && _event!.time!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(_event!.time),
                        style: AppStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Location Row (Clickable)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleLocationTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      _event!.mode == 'online' || _event!.mode == 'hybrid'
                          ? Icons.video_camera_front_outlined
                          : Icons.location_on_outlined,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _event!.mode == 'online' || _event!.mode == 'hybrid'
                            ? (_event!.meetingLink ?? 'Online Event')
                            : (_event!.location ?? 'Location TBD'),
                        style: AppStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Divider
          const Divider(height: 30),

          // Description Section
          Text(
            'About',
            style: AppStyles.headingSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            hasDescription
                ? _event!.description!
                : 'No description provided for this event.',
            style: AppStyles.bodyMedium.copyWith(
              color: hasDescription
                  ? AppColors.textSecondary
                  : AppColors.textTertiary,
              height: 1.5,
              fontStyle: hasDescription ? FontStyle.normal : FontStyle.italic,
            ),
          ),

          // Divider
          const Divider(height: 30),

          // Guest Actions Area (RSVP buttons/badges)
          if (_event!.isCreator == false) ...[
            _buildGuestActionsArea(),
            const Divider(height: 30),
          ],

          // Guests Section
          Text(
            'Who\'s Coming',
            style: AppStyles.headingSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildWhosComingSection(),
        ],
      ),
    );
  }

  /// Builds the More Options Menu (PopupMenuButton)
  Widget _buildMoreOptionsMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColors.surface,
      elevation: 8,
      onSelected: (value) {
        _handleMenuAction(value);
      },
      itemBuilder: (BuildContext context) {
        final items = <PopupMenuEntry<String>>[];

        if (widget.isOwner) {
          // Owner Actions
          items.add(
            PopupMenuItem<String>(
              value: 'edit_event',
              child: Row(
                children: [
                  Icon(
                    Icons.edit_outlined,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Edit Event',
                    style: AppStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Share Event (available for both owner and guest)
        items.add(
          PopupMenuItem<String>(
            value: 'share_event',
            child: Row(
              children: [
                Icon(
                  Icons.share_outlined,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Share Event',
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );

        // Divider before delete (only for owner)
        if (widget.isOwner) {
          items.add(const PopupMenuDivider());
          items.add(
            PopupMenuItem<String>(
              value: 'delete_event',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'Delete Event',
                    style: AppStyles.bodyMedium.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return items;
      },
    );
  }

  /// Handles menu action selection
  void _handleMenuAction(String value) {
    switch (value) {
      case 'edit_event':
        // Navigate to edit event screen
        Navigator.pushNamed(
          context,
          AppRoutes.createEvent,
          arguments: {'eventId': _event!.id, 'event': _event},
        );
        break;
      case 'share_event':
        // Share event
        // TODO: Implement share functionality
        break;
      case 'delete_event':
        // Show delete confirmation dialog
        _showDeleteConfirmationDialog();
        break;
    }
  }

  /// Shows delete confirmation dialog
  Future<void> _showDeleteConfirmationDialog() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: AppColors.surface,
          title: Text(
            'Delete Event',
            style: AppStyles.headingSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${_event!.name}"? This action cannot be undone.',
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: AppStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Delete',
                style: AppStyles.bodyMedium.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    // Show loading indicator with event name
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Deleting Event',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '"${_event!.name}"',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.warning,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    try {
      // Delete event via API
      await _eventRepository.deleteEvent(_event!.id);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Event deleted successfully'),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate back to events list
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete event: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }

    }
  }

  /// Builds the Guest Actions Area (RSVP buttons/badges)
  Widget _buildGuestActionsArea() {
    final status = _event?.myInvitationStatus ?? 'not_invited';

    switch (status) {
      case 'pending':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Your Response',
              style: AppStyles.headingSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleRSVP('accepted'),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _handleRSVP('maybe'),
                    icon: const Icon(Icons.help_outline, size: 18),
                    label: const Text('Maybe'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleRSVP('declined'),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Decline'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );

      case 'accepted':
        return _buildStatusCard(
          backgroundColor: AppColors.success.withOpacity(0.1),
          borderColor: AppColors.success.withOpacity(0.3),
          iconColor: AppColors.success,
          icon: Icons.check,
          title: 'You are going',
          subtitle: 'Tap to change response',
          onTap: () => _handleRSVP('pending'),
        );

      case 'declined':
        return _buildStatusCard(
          backgroundColor: AppColors.error.withOpacity(0.1),
          borderColor: AppColors.error.withOpacity(0.3),
          iconColor: AppColors.error,
          icon: Icons.close,
          title: 'You declined',
          subtitle: 'Tap to change response',
          onTap: () => _handleRSVP('pending'),
        );

      case 'maybe':
        return _buildStatusCard(
          backgroundColor: AppColors.warning.withOpacity(0.1),
          borderColor: AppColors.warning.withOpacity(0.3),
          iconColor: AppColors.warning,
          icon: Icons.help_outline,
          title: 'Maybe',
          subtitle: 'Tap to change response',
          onTap: () => _handleRSVP('pending'),
        );

      case 'not_invited':
      default:
        return const SizedBox.shrink();
    }
  }

  /// Builds a smart status card for RSVP status
  Widget _buildStatusCard({
    required Color backgroundColor,
    required Color borderColor,
    required Color iconColor,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Leading Icon (Circle with icon inside)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Middle Text (Expanded)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: iconColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: iconColor.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Trailing Action Icon
              Icon(
                Icons.edit_outlined,
                color: iconColor,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Handles RSVP response
  Future<void> _handleRSVP(String status) async {
    if (_event == null) return;

    // Optimistic update
    final previousStatus = _event!.myInvitationStatus;
    setState(() {
      _event = _event!.copyWith(myInvitationStatus: status);
    });

    try {
      // Call API
      final updatedEvent = await _eventRepository.respondToEventInvitation(
        eventId: _event!.id,
        status: status,
      );

      if (!mounted) return;

      // Update with server response
      setState(() {
        _event = updatedEvent;
      });

      // Show success snackbar
      if (status == 'accepted') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('You are going! Don\'t forget a gift 🎁'),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      // Revert optimistic update on error
      setState(() {
        _event = _event!.copyWith(myInvitationStatus: previousStatus);
      });

      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update response: ${e.toString()}'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Handles location tap - opens Maps or meeting link
  Future<void> _handleLocationTap() async {
    if (_event == null) return;

    final mode = _event!.mode ?? 'in_person';
    final myStatus = _event!.myInvitationStatus ?? 'not_invited';

    if (mode == 'in_person') {
      // Open Maps with location
      final location = _event!.location;
      if (location != null && location.isNotEmpty) {
        final encodedLocation = Uri.encodeComponent(location);
        final mapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedLocation');
        if (await canLaunchUrl(mapsUrl)) {
          await launchUrl(mapsUrl, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Could not open maps'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      }
    } else if ((mode == 'online' || mode == 'hybrid') && myStatus == 'accepted') {
      // Open meeting link
      final meetingLink = _event!.meetingLink;
      if (meetingLink != null && meetingLink.isNotEmpty) {
        final url = Uri.parse(meetingLink);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Could not open meeting link'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Meeting link not available'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }
    }
  }

  /// Builds the Who's Coming section with invited friends
  Widget _buildWhosComingSection() {
    // Use attendees list if available, otherwise filter invitedFriends for accepted
    final attendeesList = _event?.attendees.isNotEmpty == true
        ? _event!.attendees
        : (_event?.invitedFriends ?? [])
            .where((friend) => friend.status == InvitationStatus.accepted)
            .toList();
    
    // If no attendees and user is creator, show invite widget
    if (attendeesList.isEmpty) {
      if (_event?.isCreator == true) {
        return _buildQuickInviteWidget();
      }
      // For guests, show empty state
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'No one has accepted yet',
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display attendees with avatars (horizontal list)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...attendeesList.take(10).map((friend) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildFriendItem(friend),
                );
              }),
              if (attendeesList.length > 10)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '+${attendeesList.length - 10}',
                          style: AppStyles.bodySmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'more',
                        style: AppStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Invite Friends button (only for creator)
        if (_event?.isCreator == true) _buildQuickInviteWidget(),
      ],
    );
  }

  /// Build friend item with avatar, status indicator, and full name
  Widget _buildFriendItem(InvitedFriend friend) {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    final initials = _getInitials(friend.fullName ?? friend.username ?? friend.id);
    final displayName = friend.fullName ?? friend.username ?? '';
    final status = friend.status ?? InvitationStatus.pending;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar with status indicator
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: friend.profileImage != null && friend.profileImage!.isNotEmpty
                  ? NetworkImage(friend.profileImage!)
                  : null,
              child: friend.profileImage == null || friend.profileImage!.isEmpty
                  ? Text(
                      initials,
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            // Status indicator (small dot/icon at bottom-right)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _getInvitationStatusColor(status),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.surface,
                    width: 2,
                  ),
                ),
                child: Icon(
                  _getInvitationStatusIcon(status),
                  size: 10,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Name + status badge (more room so text doesn't truncate badly)
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 96),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayName,
                style: AppStyles.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _getInvitationStatusColor(status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getInvitationStatusIcon(status),
                      size: 12,
                      color: _getInvitationStatusColor(status),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _getInvitationStatusText(status, localization),
                        style: AppStyles.caption.copyWith(
                          color: _getInvitationStatusColor(status),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Get invitation status color based on invitation status
  Color _getInvitationStatusColor(InvitationStatus status) {
    switch (status) {
      case InvitationStatus.accepted:
        return AppColors.success; // Green
      case InvitationStatus.declined:
        return AppColors.error; // Red
      case InvitationStatus.maybe:
        return AppColors.warning; // Orange/Yellow
      case InvitationStatus.pending:
      default:
        return AppColors.textSecondary; // Grey
    }
  }

  /// Get invitation status icon based on invitation status
  IconData _getInvitationStatusIcon(InvitationStatus status) {
    switch (status) {
      case InvitationStatus.accepted:
        return Icons.check;
      case InvitationStatus.declined:
        return Icons.close;
      case InvitationStatus.maybe:
        return Icons.help_outline;
      case InvitationStatus.pending:
      default:
        return Icons.access_time;
    }
  }

  /// Get invitation status text based on invitation status
  String _getInvitationStatusText(InvitationStatus status, LocalizationService localization) {
    switch (status) {
      case InvitationStatus.accepted:
        return localization.translate('events.accepted') ?? 'Accepted';
      case InvitationStatus.declined:
        return localization.translate('events.declined') ?? 'Declined';
      case InvitationStatus.maybe:
        return localization.translate('events.maybe') ?? 'Maybe';
      case InvitationStatus.pending:
      default:
        return localization.translate('events.pending') ?? 'Pending';
    }
  }

  /// Build friend avatar widget (kept for backward compatibility if needed)
  Widget _buildFriendAvatar(InvitedFriend friend) {
    final initials = _getInitials(friend.fullName ?? friend.username ?? friend.id);
    
    return Tooltip(
      message: friend.fullName ?? friend.username ?? '',
      child: CircleAvatar(
        radius: 20,
        backgroundColor: AppColors.primary.withOpacity(0.1),
        backgroundImage: friend.profileImage != null && friend.profileImage!.isNotEmpty
            ? NetworkImage(friend.profileImage!)
            : null,
        child: friend.profileImage == null || friend.profileImage!.isEmpty
            ? Text(
                initials,
                style: AppStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
    );
  }

  /// Get initials from name
  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  /// Builds the Quick Invite Widget (for empty guests state or to add more)
  Widget _buildQuickInviteWidget() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (widget.isOwner) {
            _showInviteFriendsBottomSheet();
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
              width: 1.5,
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_add_alt_1, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                _event?.invitedFriends.isEmpty ?? true
                    ? 'Invite Friends'
                    : 'Invite More Friends',
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows bottom sheet for inviting friends
  void _showInviteFriendsBottomSheet() async {
    // Get currently invited friend IDs from event
    final currentlyInvitedIds = _event?.invitedFriends.map((f) => f.id).toList() ?? [];
    
    // Create map of friend ID to their response status
    final friendStatuses = <String, InvitationStatus>{};
    if (_event?.invitedFriends != null) {
      for (final friend in _event!.invitedFriends) {
        if (friend.status != null) {
          friendStatuses[friend.id] = friend.status!;
        }
      }
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InviteFriendsBottomSheet(
        initiallySelectedIds: currentlyInvitedIds,
        friendStatuses: friendStatuses.isNotEmpty ? friendStatuses : null,
        onInvite: (List<String> friendIds) async {
          // Close bottom sheet first
          Navigator.pop(context);
          
          // Show loading indicator
          if (!mounted) return;
          
          try {
            // Call PATCH API to update invited friends
            await _updateInvitedFriends(friendIds);
            
            // Refresh event details to get updated data
            await _loadEventDetails();
            
            // Show success toast
            if (mounted) {
              final localization = Provider.of<LocalizationService>(context, listen: false);
              TopOverlayToast.showSuccess(
                context,
                localization.translate('events.invitationsUpdatedSuccessfully') != 'events.invitationsUpdatedSuccessfully'
                    ? localization.translate('events.invitationsUpdatedSuccessfully')
                    : 'Invitations updated successfully',
                duration: const Duration(seconds: 2),
              );
            }
          } catch (e) {
            // Show error toast
            if (mounted) {
              TopOverlayToast.showError(
                context,
                e.toString().replaceAll('Exception: ', ''),
                duration: const Duration(seconds: 3),
          );
            }
          }
        },
      ),
    );
  }

  /// Update invited friends via PUT API (edit event)
  /// Sends all event data with updated invited_friends list
  Future<void> _updateInvitedFriends(List<String> friendIds) async {
    if (_event == null) {
      throw Exception('Event not loaded');
    }

    final event = _event!;

    // Format date for API (ISO 8601 UTC format)
    // Extract date part only (without time) and create UTC date at midnight
    final eventDate = DateTime.utc(
      event.date.year,
      event.date.month,
      event.date.day,
    ).toIso8601String();
    
    // Format time (HH:mm format)
    // Extract time from event.date if time field is not available
    String eventTime;
    if (event.time != null && event.time!.isNotEmpty) {
      eventTime = event.time!;
    } else {
      // Extract time from event.date DateTime
      final hour = event.date.hour.toString().padLeft(2, '0');
      final minute = event.date.minute.toString().padLeft(2, '0');
      eventTime = '$hour:$minute';
    }

    // Call PUT /api/events/:eventId with all event data
    await _eventRepository.updateEvent(
      eventId: widget.eventId,
      name: event.name,
      description: event.description,
      date: eventDate,
      time: eventTime,
      type: event.type.toString().split('.').last,
      privacy: event.privacy ?? 'friends_only',
      mode: event.mode ?? 'in_person',
      location: event.location,
      meetingLink: event.meetingLink,
      wishlistId: event.wishlistId,
      invitedFriends: friendIds, // Updated invited friends list
    );
  }

  /// Shows bottom sheet for wishlist options (Create New or Link Existing)
  void _showWishlistOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => WishlistOptionsBottomSheet(
        onCreateNew: () {
          Navigator.pushNamed(
            context,
            AppRoutes.createWishlist,
            arguments: {
              'eventId': widget.eventId,
              'isForEvent': true,
              'previousRoute': AppRoutes.eventDetails,
            },
          ).then((result) {
            // Refresh event details if wishlist was created and linked
            if (result == true) {
              _loadEventDetails();
            }
          });
        },
        onLinkExisting: () {
          _showLinkExistingWishlistBottomSheet();
        },
      ),
    );
  }

  /// Shows wishlist menu with unlink option
  void _showWishlistMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // Unlink option
              ListTile(
                leading: Icon(Icons.link_off_rounded, color: AppColors.error),
                title: Text(
                  'Unlink Wishlist',
                  style: AppStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _handleUnlinkWishlist();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// Handles unlinking wishlist from event
  Future<void> _handleUnlinkWishlist() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Unlink Wishlist',
          style: AppStyles.headingSmall.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to unlink this wishlist from the event? The wishlist will not be deleted, but it will no longer be associated with this event.',
          style: AppStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Unlink',
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Show loading indicator
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Unlink wishlist from event
      await _eventRepository.unlinkWishlistFromEvent(eventId: widget.eventId);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Wishlist unlinked successfully'),
          backgroundColor: AppColors.success,
        ),
      );

      // Refresh event details
      _loadEventDetails();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to unlink wishlist: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// Shows bottom sheet for linking existing wishlist
  void _showLinkExistingWishlistBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LinkWishlistBottomSheet(
        eventId: widget.eventId,
        onLink: (wishlistId) async {
          try {
            // Link wishlist to event
            await _eventRepository.linkWishlistToEvent(
              eventId: widget.eventId,
              wishlistId: wishlistId,
            );

            if (!mounted) return;

            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Wishlist linked successfully'),
                backgroundColor: AppColors.success,
              ),
            );

            // Refresh event details
            _loadEventDetails();
          } catch (e) {
            if (!mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to link wishlist: ${e.toString()}'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
      ),
    );
  }

  /// Builds the Meta-Tags Row (Type, Privacy, Status)
  Widget _buildMetaTagsRow() {
    final tags = <Widget>[];

    // Type Tag
    final typeIcon = _getEventTypeIcon(_event!.type);
    final typeText = _getEventTypeText(_event!.type);
    tags.add(_buildTag(typeText, typeIcon, AppColors.accent));

    // Privacy Tag
    if (_event!.privacy != null) {
      final privacyIcon = _getPrivacyIcon(_event!.privacy!);
      final privacyText = _getPrivacyText(_event!.privacy!);
      tags.add(_buildTag(privacyText, privacyIcon, AppColors.info));
    }

    // Status Tag
    final statusIcon = _getStatusIcon(_event!.status);
    final statusText = _getStatusText(_event!.status);
    final statusColor = _getStatusColor(_event!.status);
    tags.add(_buildTag(statusText, statusIcon, statusColor));

    return Wrap(spacing: 8, runSpacing: 8, children: tags);
  }

  /// Builds a single tag widget
  Widget _buildTag(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20), // StadiumBorder (pill shape)
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Gets display text for EventType
  String _getEventTypeText(EventType type) {
    final typeString = type.toString().split('.').last;
    // Convert camelCase to Title Case
    return typeString
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? ''
              : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join(' ')
        .trim();
  }

  /// Gets icon for Privacy
  IconData _getPrivacyIcon(String privacy) {
    switch (privacy.toLowerCase()) {
      case 'public':
        return Icons.public;
      case 'private':
        return Icons.lock;
      case 'friends_only':
        return Icons.group;
      default:
        return Icons.info;
    }
  }

  /// Gets display text for Privacy
  String _getPrivacyText(String privacy) {
    switch (privacy.toLowerCase()) {
      case 'public':
        return 'Public';
      case 'private':
        return 'Private';
      case 'friends_only':
        return 'Friends Only';
      default:
        return privacy;
    }
  }

  /// Gets icon for Status
  IconData _getStatusIcon(EventStatus status) {
    switch (status) {
      case EventStatus.upcoming:
        return Icons.access_time_filled;
      case EventStatus.ongoing:
        return Icons.play_circle_filled;
      case EventStatus.completed:
        return Icons.check_circle;
      case EventStatus.cancelled:
        return Icons.cancel;
    }
  }

  /// Gets display text for Status
  String _getStatusText(EventStatus status) {
    switch (status) {
      case EventStatus.upcoming:
        return 'Upcoming';
      case EventStatus.ongoing:
        return 'Ongoing';
      case EventStatus.completed:
        return 'Completed';
      case EventStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Gets color for Status
  Color _getStatusColor(EventStatus status) {
    switch (status) {
      case EventStatus.upcoming:
        return AppColors.success; // Green
      case EventStatus.ongoing:
        return AppColors.info; // Blue
      case EventStatus.completed:
        return AppColors.textTertiary; // Grey
      case EventStatus.cancelled:
        return AppColors.error; // Red
    }
  }

  Widget _buildWishlistCard(LocalizationService localization) {
    final isAccepted = _event?.myInvitationStatus == 'accepted';
    final isCreator = _event?.isCreator ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Text(
          '🎁 Gift Registry',
          style: AppStyles.headingSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        // Wishlist Content
        if (_event!.wishlistId == null && isCreator)
      // Create Event Wishlist placeholder
          Container(
        width: double.infinity, // Full width to match main sheet
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.secondary.withOpacity(0.3), // Teal border
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.card_giftcard_outlined,
              color: AppColors.secondary, // Teal icon
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'Create Event Wishlist',
              style: AppStyles.headingSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Link a wishlist to this event so guests can see what to gift',
              style: AppStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _showWishlistOptionsBottomSheet();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary, // Teal background
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Create Wishlist',
                      style: AppStyles.button.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
          )
        else if (_event!.wishlistId == null && !isCreator)
          // Guest view: No wishlist message
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.border.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.card_giftcard_outlined,
                  color: AppColors.textTertiary,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'No Wishlist Yet',
                  style: AppStyles.headingSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No wishlist or wishes are linked to this event yet.',
                  style: AppStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else if (_event!.wishlistId != null)
          // Show compact wishlist tile (clickable)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.wishlistItems,
                  arguments: {
                    'wishlistId': _event!.wishlistId,
                    'wishlistName': _event!.wishlistName ?? 'Event Wishlist',
                    'isFriendWishlist': !isCreator,
                  },
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  border: isAccepted
                      ? Border.all(
                          color: AppColors.primary,
                          width: 2,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: EventWishlistTile(
                  wishlistName: _event!.wishlistName ?? 'Event Wishlist',
                  itemCount: _event!.wishlistItemCount ?? 0,
                  reservedCount: 0, // TODO: Get from API if available
                  showUnlinkAction: isCreator, // Only show unlink for event creator
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.wishlistItems,
                      arguments: {
                        'wishlistId': _event!.wishlistId,
                        'wishlistName': _event!.wishlistName ?? 'Event Wishlist',
                        'isFriendWishlist': !isCreator,
                      },
                    );
                  },
                  onUnlink: isCreator ? _handleUnlinkWishlist : null,
                ),
              ),
            ),
          )
        else
          const SizedBox.shrink(),
      ],
    );
  }
}
