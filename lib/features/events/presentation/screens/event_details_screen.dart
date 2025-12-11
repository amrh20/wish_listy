import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/widgets/primary_gradient_button.dart';
import 'package:wish_listy/core/widgets/modern_wishlist_card.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/features/events/data/models/event_model.dart';
import 'package:wish_listy/features/events/data/repository/event_repository.dart';

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
    // Check if we can pop normally (if there's a route in the stack)
    if (Navigator.of(context).canPop()) {
      // Pop and return true to trigger refresh in EventsScreen
      Navigator.of(context).pop(true);
    } else {
      // If no route to pop, navigate to events list directly
      Navigator.of(context).pushReplacementNamed(AppRoutes.events);
    }
  }

  Future<void> _loadEventDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('📥 Loading event details for ID: ${widget.eventId}');
      final event = await _eventRepository.getEventById(widget.eventId);

      if (!mounted) return;

      setState(() {
        _event = event;
        _isLoading = false;
      });

      debugPrint('✅ Event details loaded successfully');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
      debugPrint('❌ API Error loading event: ${e.message}');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load event. Please try again.';
        _isLoading = false;
      });
      debugPrint('❌ Error loading event: $e');
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

  String _formatDateTime(DateTime date) {
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
    return '${months[date.month - 1]} ${date.day}, ${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}';
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

        return Scaffold(
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
                      if (widget.isOwner || _event!.wishlistId != null)
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
      actions: [_buildMoreOptionsMenu()],
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
          // Row 1: Meta Info (Date & Location)
          Row(
            children: [
              // Date
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatDateTime(_event!.date),
                        style: AppStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Location
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _event!.location ?? 'Location TBD',
                        style: AppStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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

          // Guests Section
          Text(
            'Who\'s Coming',
            style: AppStyles.headingSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (acceptedGuests.isEmpty)
            _buildQuickInviteWidget()
          else
            Row(
              children: [
                ...acceptedGuests.asMap().entries.map((entry) {
                  final index = entry.key;
                  final guest = entry.value;
                  return Container(
                    margin: EdgeInsets.only(left: index > 0 ? -12 : 0),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        guest.inviteeId.isNotEmpty
                            ? guest.inviteeId[0].toUpperCase()
                            : 'G',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }),
                if (remainingCount > 0)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.surfaceVariant,
                      child: Text(
                        '+$remainingCount',
                        style: AppStyles.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
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
              value: 'manage_guests',
              child: Row(
                children: [
                  Icon(
                    Icons.group_add_outlined,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Manage Guests',
                    style: AppStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
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
      case 'manage_guests':
        // Navigate to guest management
        if (widget.isOwner) {
          // TODO: Navigate to guest management screen
          Navigator.pushNamed(
            context,
            AppRoutes.eventManagement,
            arguments: _event,
          );
        }
        break;
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
      debugPrint('❌ Error deleting event: $e');
    }
  }

  /// Builds the Quick Invite Widget (for empty guests state)
  Widget _buildQuickInviteWidget() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Trigger same action as "Manage Guests"
          if (widget.isOwner) {
            // TODO: Navigate to guest management
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
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
            children: [
              Icon(Icons.person_add_alt_1, color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              Text(
                'Invite Friends to this Event',
                style: AppStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
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
    if (_event!.wishlistId == null && widget.isOwner) {
      // Create Event Wishlist placeholder
      return Container(
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
                  // TODO: Navigate to create wishlist for event
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
      );
    } else if (_event!.wishlistId != null) {
      // Show mini wishlist card with full width
      return Container(
        width: double.infinity, // Full width to match main sheet
        child: ModernWishlistCard(
          title: 'Event Wishlist', // TODO: Get wishlist name from API
          totalItems: 0, // TODO: Get from API
          giftedItems: 0, // TODO: Get from API
          completionPercentage: 0.0, // TODO: Calculate
          onView: () {
            Navigator.pushNamed(
              context,
              AppRoutes.wishlistItems,
              arguments: {
                'wishlistId': _event!.wishlistId,
                'wishlistName': 'Event Wishlist',
              },
            );
          },
          onAddItem: () {
            // TODO: Navigate to add item
          },
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
