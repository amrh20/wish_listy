import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/widgets/primary_gradient_button.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/core/services/deep_link_service.dart';
import 'package:wish_listy/features/events/data/models/event_model.dart';
import 'package:wish_listy/features/events/data/repository/event_repository.dart';
import 'package:wish_listy/features/events/presentation/widgets/invite_friends_bottom_sheet.dart';
import 'package:wish_listy/features/events/presentation/widgets/wishlist_options_bottom_sheet.dart';
import 'package:wish_listy/features/events/presentation/widgets/link_wishlist_bottom_sheet.dart';
import 'package:wish_listy/features/events/presentation/widgets/event_wishlist_tile.dart';
import 'package:wish_listy/core/widgets/top_overlay_toast.dart';
import 'package:wish_listy/features/profile/presentation/screens/main_navigation.dart';
import 'package:wish_listy/features/notifications/presentation/cubit/notifications_cubit.dart';

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
  
  // Stream subscription for event updates from notifications
  StreamSubscription<String>? _eventUpdateSubscription;

  @override
  void initState() {
    super.initState();
    _loadEventDetails();
    _setupEventUpdateListener();
  }

  /// Setup listener for event updates from notifications
  void _setupEventUpdateListener() {
    try {
      final notificationsCubit = context.read<NotificationsCubit>();
      _eventUpdateSubscription = notificationsCubit.eventUpdateStream.listen(
        (updatedEventId) {
          // Only refresh if this is the current event
          if (updatedEventId == widget.eventId && mounted) {
            debugPrint('🔄 EventDetailsScreen: Received update signal for event: $updatedEventId');
            _refreshEventDetails();
          }
        },
        onError: (error) {
          debugPrint('⚠️ EventDetailsScreen: Error in event update stream: $error');
        },
      );
    } catch (e) {
      debugPrint('⚠️ EventDetailsScreen: Could not setup event update listener: $e');
    }
  }

  @override
  void dispose() {
    _eventUpdateSubscription?.cancel();
    super.dispose();
  }

  /// Handles back navigation - always navigates to Events tab in MainNavigation
  void _handleBackNavigation() {
    if (!mounted) return;

    // Close current screen
    Navigator.of(context).pop();

    // Navigate to Events tab in MainNavigation
    if (mounted) {
      // Use post-frame callback to ensure navigation is safe
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        // Navigate to MainNavigation and switch to Events tab (index 2)
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.mainNavigation,
          (route) => route.isFirst,
        );
        // Use another post frame callback to ensure MainNavigation is built before switching tabs
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            MainNavigation.switchToTab(context, 2); // Events tab is index 2
          }
        });
      });
    }
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

  Future<void> _refreshEventDetails() async {
    await _loadEventDetails();
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
                  size: 18,
                ),
                onPressed: _handleBackNavigation,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.all(8),
                  shape: const CircleBorder(),
                ),
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
            body: RefreshIndicator(
              onRefresh: _refreshEventDetails,
              color: AppColors.primary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                        _buildUnifiedInfoSheet(acceptedGuests, remainingCount, localization),

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

    // Calculate dynamic expanded height based on whether host info is shown
    final hasHostInfo = !_event!.isCreator && _event!.creatorName != null;
    final expandedHeight = hasHostInfo ? 320.0 : 280.0;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 18),
        onPressed: () => _handleBackNavigation(),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.all(8),
          shape: const CircleBorder(),
        ),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 32),
                  // Event Icon
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
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
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Event Name
                  Flexible(
                    child: Text(
                      _event!.name,
                      style: AppStyles.headingLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Host Name with Avatar (for Guest View)
                  if (hasHostInfo)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            backgroundImage: _event!.creatorImage != null &&
                                    _event!.creatorImage!.isNotEmpty
                                ? NetworkImage(_event!.creatorImage!)
                                : null,
                            child: _event!.creatorImage == null ||
                                    _event!.creatorImage!.isEmpty
                                ? Text(
                                    _getInitials(_event!.creatorName ?? ''),
                                    style: AppStyles.bodySmall.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${localization.translate('dialogs.hostedBy')} ${_event!.creatorName}',
                              style: AppStyles.bodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (hasHostInfo) const SizedBox(height: 8),
                  // Date Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            isPast
                                ? localization.translate('dialogs.pastEvent')
                                : daysUntil == 0
                                ? localization.translate('dialogs.today')
                                : daysUntil == 1
                                ? localization.translate('dialogs.tomorrow')
                                : localization.translate('dialogs.inDays').replaceAll('{days}', daysUntil.toString()),
                            style: AppStyles.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
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
    LocalizationService localization,
  ) {
    final hasDescription =
        _event!.description != null && _event!.description!.isNotEmpty;
    // Invitation/Response section:
    // Hide if user is not invited OR the event is in the past.
    final showInvitationSection = _event!.isCreator == false &&
        _event!.myInvitationStatus != 'not_invited' &&
        _event!.isPast == false;

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
          
          // Combined Date & Location Row (Compact)
          _buildCompactInfoRow(),

          // Divider (only if About section exists)
          if (hasDescription) const Divider(height: 30),

          // Description Section (only show if not empty)
          if (hasDescription) ...[
            Text(
              localization.translate('dialogs.about'),
              style: AppStyles.headingSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _event!.description!,
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const Divider(height: 30),
          ],

          // Add spacing before Invitation Card / Status Card
          if (showInvitationSection) const SizedBox(height: 8),

          // Invitation Card (pending) OR Status Card (responded)
          if (showInvitationSection) ...[
            // Show invitation card only if status is pending
            if (_event!.myInvitationStatus == 'pending')
              _buildInvitationCard(localization)
            // Show status card if user has responded (accepted, declined, maybe)
            else ...[
              Text(
                'Your Response',
                style: AppStyles.headingSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildGuestActionsArea(),
            ],
            const SizedBox(height: 16),
          ],

          // Add spacing before "Who's Coming" section
          const SizedBox(height: 16),

          // Guests Section
          Text(
            localization.translate('dialogs.whosComing'),
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

  /// Builds compact info row combining Date and Location
  Widget _buildCompactInfoRow() {
    return Column(
      children: [
        // Date & Time Row
        Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              color: AppColors.primary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${_formatDate(_event!.date)}${_event!.time != null && _event!.time!.isNotEmpty ? ' • ${_formatTime(_event!.time)}' : ''}',
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
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
                    size: 18,
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
      ],
    );
  }

  /// Builds the prominent Invitation Card for Guest View
  Widget _buildInvitationCard(LocalizationService localization) {
    final currentStatus = _event?.myInvitationStatus ?? 'pending';
    
    // Don't show invitation card if not invited OR if user already responded (not pending)
    if (currentStatus == 'not_invited' || currentStatus != 'pending') {
      return const SizedBox.shrink();
    }

    // Show invitation card with premium gradient design (only for pending status)
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFF3E5F5), // Very light purple
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.deepPurple.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title
          Text(
            localization.translate('dialogs.youreOnGuestList'),
            style: AppStyles.headingSmall.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.deepPurple.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Subtitle
          Text(
            localization.translate('dialogs.letHostKnow'),
            style: AppStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Hybrid Button Layout (Column with two rows)
          Column(
            children: [
              // Row 1: Accept Button (Full Width - Primary Action)
              SizedBox(
                width: double.infinity,
                child: _buildRSVPButton(
                  label: localization.translate('dialogs.accept'),
                  icon: Icons.check_circle_outline,
                  status: 'accepted',
                  currentStatus: currentStatus,
                  isPrimary: true,
                ),
              ),
              const SizedBox(height: 12),
              // Row 2: Maybe and Decline Buttons (Side by Side)
              Row(
                children: [
                    // Maybe Button (Orange Outlined)
                    Expanded(
                      child: _buildRSVPButton(
                        label: localization.translate('dialogs.maybe'),
                        icon: Icons.help_outline,
                        status: 'maybe',
                        currentStatus: currentStatus,
                        isMaybe: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Decline Button (The Minimalist - Grey TextButton)
                    Expanded(
                      child: _buildRSVPButton(
                        label: localization.translate('dialogs.decline'),
                        icon: Icons.close,
                        status: 'declined',
                        currentStatus: currentStatus,
                        isDecline: true,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds a single RSVP button with highlight/dim logic (Stadium style)
  Widget _buildRSVPButton({
    required String label,
    required IconData icon,
    required String status,
    required String currentStatus,
    bool isPrimary = false,
    bool isMaybe = false,
    bool isDecline = false,
  }) {
    final isSelected = currentStatus == status;
    final isDimmed = currentStatus != 'pending' && currentStatus != 'not_invited' && !isSelected;

    if (isPrimary) {
      // Accept Button - ElevatedButton with Green (The Hero)
      return ElevatedButton.icon(
        onPressed: () => _handleRSVP(status),
        icon: Icon(
          icon,
          size: 18,
          color: Colors.white,
        ),
        label: Text(
          label,
          style: AppStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? const Color(0xFF4CAF50) // Soft Green
              : (isDimmed
                  ? Colors.grey.shade300
                  : const Color(0xFF4CAF50)),
          foregroundColor: isSelected ? Colors.white : Colors.grey.shade600,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          shape: const StadiumBorder(), // Fully rounded ends
          elevation: isSelected ? 4 : 0, // Pop out when selected
        ),
      );
    } else if (isMaybe) {
      // Maybe Button - OutlinedButton with Orange
      return OutlinedButton.icon(
        onPressed: () => _handleRSVP(status),
        icon: Icon(
          icon,
          size: 18,
          color: isSelected
              ? Colors.orange.shade700
              : (isDimmed ? Colors.grey.shade400 : Colors.orange.shade700),
        ),
        label: Text(
          label,
          style: AppStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.orange.shade700
                : (isDimmed ? Colors.grey.shade400 : Colors.orange.shade700),
            fontSize: 14,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: isSelected
              ? Colors.orange.shade700
              : (isDimmed ? Colors.grey.shade400 : Colors.orange.shade700),
          backgroundColor: isSelected
              ? Colors.orange.withOpacity(0.1)
              : Colors.transparent,
          side: BorderSide(
            color: isSelected
                ? Colors.orange.shade700
                : (isDimmed ? Colors.grey.shade300 : Colors.orange.shade400),
            width: 1,
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          shape: const StadiumBorder(), // Fully rounded ends
        ),
      );
    } else {
      // Decline Button - OutlinedButton with Grey border and color
      return OutlinedButton.icon(
        onPressed: () => _handleRSVP(status),
        icon: Icon(
          icon,
          size: 18,
          color: isSelected
              ? Colors.grey.shade700
              : (isDimmed ? Colors.grey.shade400 : Colors.grey.shade600),
        ),
        label: Text(
          label,
          style: AppStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.grey.shade700
                : (isDimmed ? Colors.grey.shade400 : Colors.grey.shade600),
            fontSize: 14,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: isSelected
              ? Colors.grey.shade700
              : (isDimmed ? Colors.grey.shade400 : Colors.grey.shade600),
          backgroundColor: isSelected
              ? Colors.grey.withOpacity(0.1)
              : Colors.transparent,
          side: BorderSide(
            color: isSelected
                ? Colors.grey.shade600
                : (isDimmed ? Colors.grey.shade300 : Colors.grey.shade400),
            width: 1,
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          shape: const StadiumBorder(), // Fully rounded ends
        ),
      );
    }
  }

  /// Helper methods for status card styling
  Color _getStatusCardColor(String status) {
    switch (status) {
      case 'accepted':
        return AppColors.success.withOpacity(0.1);
      case 'declined':
        return AppColors.error.withOpacity(0.1);
      case 'maybe':
        return AppColors.warning.withOpacity(0.1);
      default:
        return AppColors.primary.withOpacity(0.1);
    }
  }

  Color _getStatusCardBorderColor(String status) {
    switch (status) {
      case 'accepted':
        return AppColors.success.withOpacity(0.3);
      case 'declined':
        return AppColors.error.withOpacity(0.3);
      case 'maybe':
        return AppColors.warning.withOpacity(0.3);
      default:
        return AppColors.primary.withOpacity(0.3);
    }
  }

  Color _getStatusCardIconColor(String status) {
    switch (status) {
      case 'accepted':
        return AppColors.success;
      case 'declined':
        return AppColors.error;
      case 'maybe':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  IconData _getStatusCardIcon(String status) {
    switch (status) {
      case 'accepted':
        return Icons.check;
      case 'declined':
        return Icons.close;
      case 'maybe':
        return Icons.help_outline;
      default:
        return Icons.access_time;
    }
  }

  String _getStatusCardTitle(String status) {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    switch (status) {
      case 'accepted':
        return localization.translate('events.youAreGoing') ?? 'You are going';
      case 'declined':
        return localization.translate('events.youDeclined') ?? 'You declined';
      case 'maybe':
        return localization.translate('events.maybe') ?? 'Maybe';
      default:
        return localization.translate('events.pending') ?? 'Pending';
    }
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
        if (_event != null) {
          DeepLinkService.shareEvent(
            eventId: _event!.id,
            eventName: _event!.name,
          );
        }
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
        final localization = Provider.of<LocalizationService>(context, listen: false);
        // Show success message
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(localization.translate('dialogs.eventDeletedSuccessfully')),
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
        final localization = Provider.of<LocalizationService>(context, listen: false);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localization.translate('dialogs.failedToDeleteEvent')}: ${e.toString()}'),
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
                    icon: const Icon(Icons.check_circle, size: 14),
                    label: Text(
                      Provider.of<LocalizationService>(context, listen: false).translate('dialogs.accept'),
                      style: AppStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleRSVP('maybe'),
                    icon: const Icon(Icons.help_outline, size: 14),
                    label: Text(
                      Provider.of<LocalizationService>(context, listen: false).translate('dialogs.maybe'),
                      style: AppStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 10),
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
                    icon: const Icon(Icons.close, size: 14),
                    label: Text(
                      Provider.of<LocalizationService>(context, listen: false).translate('dialogs.decline'),
                      style: AppStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 10),
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
        final localizationAccepted = Provider.of<LocalizationService>(context, listen: false);
        return _buildStatusCard(
          backgroundColor: AppColors.success.withOpacity(0.1),
          borderColor: AppColors.success.withOpacity(0.3),
          iconColor: AppColors.success,
          icon: Icons.check,
          title: localizationAccepted.translate('events.youAreGoing'),
          subtitle: localizationAccepted.translate('events.tapToChangeResponse'),
          onTap: () => _handleRSVP('pending'),
        );

      case 'declined':
        final localizationDeclined = Provider.of<LocalizationService>(context, listen: false);
        return _buildStatusCard(
          backgroundColor: AppColors.error.withOpacity(0.1),
          borderColor: AppColors.error.withOpacity(0.3),
          iconColor: AppColors.error,
          icon: Icons.close,
          title: localizationDeclined.translate('events.youDeclined'),
          subtitle: localizationDeclined.translate('events.tapToChangeResponse'),
          onTap: () => _handleRSVP('pending'),
        );

      case 'maybe':
        final localizationMaybe = Provider.of<LocalizationService>(context, listen: false);
        return _buildStatusCard(
          backgroundColor: AppColors.warning.withOpacity(0.1),
          borderColor: AppColors.warning.withOpacity(0.3),
          iconColor: AppColors.warning,
          icon: Icons.help_outline,
          title: localizationMaybe.translate('events.maybe'),
          subtitle: localizationMaybe.translate('events.tapToChangeResponse'),
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
          margin: EdgeInsets.zero,
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

      // Reload event details to get the latest data from server
      await _loadEventDetails();

      if (!mounted) return;

      // Show success snackbar
      if (status == 'accepted') {
        final localization = Provider.of<LocalizationService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(localization.translate('dialogs.youAreGoing')),
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
      final localization = Provider.of<LocalizationService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${localization.translate('dialogs.failedToUpdateResponse')}: ${e.toString()}'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Handles location tap - opens Maps or meeting link
  Future<void> _handleLocationTap() async {
    if (_event == null) return;

    final localization = Provider.of<LocalizationService>(context, listen: false);
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
                content: Text(localization.translate('dialogs.couldNotOpenMaps')),
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
                content: Text(localization.translate('dialogs.couldNotOpenMeetingLink')),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localization.translate('dialogs.meetingLinkNotAvailable')),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }
    }
  }

  /// Builds the Who's Coming section with invited friends
  Widget _buildWhosComingSection() {
    // Get all invited friends (not just accepted ones)
    final allInvitedFriends = _event?.invitedFriends ?? [];
    
    // If no invited friends and user is creator, show invite widget
    if (allInvitedFriends.isEmpty) {
      if (_event?.isCreator == true) {
        return _buildQuickInviteWidget();
      }
      // For guests, show empty state
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            Provider.of<LocalizationService>(context, listen: false).translate('events.noOneInvitedYet'),
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    // Group friends by status for better organization
    final acceptedFriends = allInvitedFriends
        .where((f) => f.status == InvitationStatus.accepted)
        .toList();
    final pendingFriends = allInvitedFriends
        .where((f) => f.status == InvitationStatus.pending || f.status == null)
        .toList();
    final declinedFriends = allInvitedFriends
        .where((f) => f.status == InvitationStatus.declined)
        .toList();
    final maybeFriends = allInvitedFriends
        .where((f) => f.status == InvitationStatus.maybe)
        .toList();

    // Show "See All" button if there are more than 6 friends
    final shouldShowSeeAll = allInvitedFriends.length > 6;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display all invited friends in a vertical list grouped by status
        Builder(
          builder: (context) {
            final localization = Provider.of<LocalizationService>(context, listen: false);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._buildStatusGroup(localization.translate('events.accepted'), acceptedFriends, Icons.check_circle, AppColors.success),
                if (acceptedFriends.isNotEmpty && (pendingFriends.isNotEmpty || maybeFriends.isNotEmpty || declinedFriends.isNotEmpty))
                  const SizedBox(height: 16),
                ..._buildStatusGroup(localization.translate('events.pending'), pendingFriends, Icons.schedule, AppColors.warning),
                if (pendingFriends.isNotEmpty && (maybeFriends.isNotEmpty || declinedFriends.isNotEmpty))
                  const SizedBox(height: 16),
                ..._buildStatusGroup(localization.translate('events.maybe'), maybeFriends, Icons.help_outline, AppColors.info),
                if (maybeFriends.isNotEmpty && declinedFriends.isNotEmpty)
                  const SizedBox(height: 16),
                ..._buildStatusGroup(localization.translate('events.declined'), declinedFriends, Icons.cancel, AppColors.error),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        // See All button (if there are many friends)
        if (shouldShowSeeAll)
          Center(
            child: TextButton.icon(
              onPressed: () => _navigateToGuestList(),
              icon: Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppColors.primary,
              ),
              label: Text(
                Provider.of<LocalizationService>(context, listen: false).translate('events.seeAll'),
                style: AppStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        if (shouldShowSeeAll) const SizedBox(height: 8),
        // Invite Friends button (only for creator)
        if (_event?.isCreator == true) _buildQuickInviteWidget(),
      ],
    );
  }

  /// Builds a status group section
  List<Widget> _buildStatusGroup(
    String title,
    List<InvitedFriend> friends,
    IconData icon,
    Color color,
  ) {
    if (friends.isEmpty) return [];
    
    return [
      Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            '$title (${friends.length})',
            style: AppStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      // Display friends in a horizontal scrollable list
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ...friends.map((friend) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _buildFriendItem(friend),
              );
            }),
          ],
        ),
      ),
    ];
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
                    ? Provider.of<LocalizationService>(context, listen: false).translate('events.inviteFriends')
                    : Provider.of<LocalizationService>(context, listen: false).translate('events.inviteMoreFriends'),
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

  /// Navigate to Guest List screen
  void _navigateToGuestList() {
    if (_event == null) return;
    
    Navigator.pushNamed(
      context,
      AppRoutes.eventGuestList,
      arguments: {
        'eventId': _event!.id,
        'invitedFriends': _event!.invitedFriends,
      },
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
          Navigator.pop(context); // Close the modal bottom sheet first
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
              Builder(
                builder: (context) {
                  final localization = Provider.of<LocalizationService>(context, listen: false);
                  return ListTile(
                    leading: Icon(Icons.link_off_rounded, color: AppColors.error),
                    title: Text(
                      localization.translate('events.unlinkWishlist'),
                      style: AppStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _handleUnlinkWishlist();
                    },
                  );
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
    final localization = Provider.of<LocalizationService>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          localization.translate('events.unlinkWishlist'),
          style: AppStyles.headingSmall.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          localization.translate('events.unlinkWishlistMessage'),
          style: AppStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              localization.translate('common.cancel'),
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              localization.translate('events.unlink'),
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

      final localization = Provider.of<LocalizationService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localization.translate('dialogs.wishlistUnlinkedSuccessfully')),
          backgroundColor: AppColors.success,
        ),
      );

      // Refresh event details
      _loadEventDetails();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      final localization = Provider.of<LocalizationService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${localization.translate('dialogs.failedToUnlinkWishlist')}: ${e.toString()}'),
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
            final localization = Provider.of<LocalizationService>(context, listen: false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(localization.translate('dialogs.wishlistLinkedSuccessfully')),
                backgroundColor: AppColors.success,
              ),
            );

            // Refresh event details
            _loadEventDetails();
          } catch (e) {
            if (!mounted) return;
            Navigator.pop(context);
            final localization = Provider.of<LocalizationService>(context, listen: false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${localization.translate('dialogs.failedToLinkWishlist')}: ${e.toString()}'),
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

    // Type Tag - use typeString if available (custom type), otherwise use enum
    final typeIcon = _getEventTypeIcon(_event!.type);
    final typeText = _event!.typeString != null 
        ? _event!.typeString! 
        : _getEventTypeText(_event!.type);
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
    final localization = Provider.of<LocalizationService>(context, listen: false);
    switch (privacy.toLowerCase()) {
      case 'public':
        return localization.translate('events.public');
      case 'private':
        return localization.translate('events.private');
      case 'friends_only':
        return localization.translate('events.friendsOnly');
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
    final localization = Provider.of<LocalizationService>(context, listen: false);
    switch (status) {
      case EventStatus.upcoming:
        return localization.translate('events.upcoming');
      case EventStatus.ongoing:
        return localization.translate('events.ongoing');
      case EventStatus.completed:
        return localization.translate('events.completed');
      case EventStatus.cancelled:
        return localization.translate('events.cancelled');
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
          localization.translate('events.giftRegistry'),
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
              Provider.of<LocalizationService>(context, listen: false).translate('events.createEventWishlist'),
              style: AppStyles.headingSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              Provider.of<LocalizationService>(context, listen: false).translate('events.linkWishlistDescription'),
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
                      Provider.of<LocalizationService>(context, listen: false).translate('events.createWishlist'),
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
                  Provider.of<LocalizationService>(context, listen: false).translate('events.noWishlistYet'),
                  style: AppStyles.headingSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  Provider.of<LocalizationService>(context, listen: false).translate('details.noWishlistLinkedToEvent'),
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
