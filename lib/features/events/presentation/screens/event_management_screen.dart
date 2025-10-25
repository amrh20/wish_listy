import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'package:wish_listy/core/widgets/decorative_background.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import '../widgets/event_card.dart';

class EventManagementScreen extends StatefulWidget {
  final EventSummary event;

  const EventManagementScreen({super.key, required this.event});

  @override
  _EventManagementScreenState createState() => _EventManagementScreenState();
}

class _EventManagementScreenState extends State<EventManagementScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
          ),
        );
  }

  void _startAnimations() {
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localization, child) {
        return Scaffold(
          body: DecorativeBackground(
            showGifts: true,
            child: Stack(
              children: [
                // Content
                SafeArea(
                  child: Column(
                    children: [
                      // Header
                      _buildHeader(localization),

                      // Content
                      Expanded(
                        child: AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return FadeTransition(
                              opacity: _fadeAnimation,
                              child: SlideTransition(
                                position: _slideAnimation,
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // Event Info Card
                                      _buildEventInfoCard(),

                                      const SizedBox(height: 24),

                                      // Management Options
                                      _buildManagementOptions(localization),

                                      const SizedBox(height: 24),

                                      // Quick Actions
                                      _buildQuickActions(),

                                      const SizedBox(
                                        height: 100,
                                      ), // Bottom padding
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(LocalizationService localization) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: AppColors.textTertiary.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceVariant,
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              localization.translate('ui.manageEvent'),
              style: AppStyles.headingSmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Edit Button
          IconButton(
            onPressed: _editEvent,
            icon: const Icon(Icons.edit_outlined),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceVariant,
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getEventTypeColor(widget.event.type).withOpacity(0.1),
            _getEventTypeColor(widget.event.type).withOpacity(0.05),
          ],
        ),
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getEventTypeColor(widget.event.type).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getEventTypeColor(widget.event.type),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getEventTypeIcon(widget.event.type),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.event.name,
                      style: AppStyles.headingSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(widget.event.date),
                      style: AppStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Event Stats
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.people_outline,
                  value: '${widget.event.invitedCount}',
                  label: 'Invited',
                  color: AppColors.info,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.check_circle_outline,
                  value: '${widget.event.acceptedCount}',
                  label: 'Accepted',
                  color: AppColors.success,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.card_giftcard_outlined,
                  value: '${widget.event.wishlistItemCount}',
                  label: 'Wishlist',
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppStyles.bodyMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: AppStyles.caption.copyWith(color: AppColors.textTertiary),
        ),
      ],
    );
  }

  Widget _buildManagementOptions(LocalizationService localization) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localization.translate('ui.eventManagement'),
            style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 16),

          // Guest Management
          _buildManagementOption(
            icon: Icons.people_outline,
            title: localization.translate('ui.guestManagement'),
            description: localization.translate('ui.manageInvitationsAndRsvps'),
            onTap: _navigateToGuestManagement,
          ),

          const SizedBox(height: 12),

          // Wishlist Management
          _buildManagementOption(
            icon: Icons.card_giftcard_outlined,
            title: localization.translate('ui.wishlistManagement'),
            description: localization.translate(
              'ui.addEditOrganizeWishlistItems',
            ),
            onTap: _navigateToWishlistManagement,
          ),

          const SizedBox(height: 12),

          // Event Settings
          _buildManagementOption(
            icon: Icons.settings_outlined,
            title: localization.translate('ui.eventSettings'),
            description: localization.translate(
              'ui.privacyNotificationsPreferences',
            ),
            onTap: _navigateToEventSettings,
          ),

          const SizedBox(height: 12),

          // Event Details
          _buildManagementOption(
            icon: Icons.edit_calendar_outlined,
            title: localization.translate('ui.editEventDetails'),
            description: localization.translate(
              'ui.changeDateLocationDescription',
            ),
            onTap: _navigateToEditEventDetails,
          ),
        ],
      ),
    );
  }

  Widget _buildManagementOption({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              offset: const Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textTertiary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: AppStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Share Event',
                  onPressed: _shareEvent,
                  variant: ButtonVariant.outline,
                  customColor: AppColors.secondary,
                  icon: Icons.share_outlined,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: CustomButton(
                  text: 'Cancel Event',
                  onPressed: _cancelEvent,
                  variant: ButtonVariant.outline,
                  customColor: AppColors.error,
                  icon: Icons.cancel_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper Methods
  Color _getEventTypeColor(EventType type) {
    switch (type) {
      case EventType.birthday:
        return AppColors.pink;
      case EventType.wedding:
        return AppColors.primary;
      case EventType.graduation:
        return AppColors.accent;
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
      case EventType.graduation:
        return Icons.school_outlined;
      case EventType.babyShower:
        return Icons.child_friendly_outlined;
      case EventType.houseWarming:
        return Icons.home_outlined;
      default:
        return Icons.event_outlined;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // Action Handlers
  void _navigateToGuestManagement() {
    Navigator.pushNamed(
      context,
      AppRoutes.guestManagement,
      arguments: widget.event,
    );
  }

  void _navigateToWishlistManagement() {
    Navigator.pushNamed(
      context,
      AppRoutes.eventWishlist,
      arguments: widget.event,
    );
  }

  void _navigateToEventSettings() {
    Navigator.pushNamed(
      context,
      AppRoutes.eventSettings,
      arguments: widget.event,
    );
  }

  void _navigateToEditEventDetails() {
    // Navigate to edit event details screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Edit event details coming soon!'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _editEvent() {
    // Edit event functionality
    _navigateToEditEventDetails();
  }

  void _shareEvent() {
    // Share event functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share functionality coming soon!'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  void _cancelEvent() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Event'),
        content: Text(
          'Are you sure you want to cancel "${widget.event.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('No, Keep Event'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Event cancelled successfully'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text('Yes, Cancel Event'),
          ),
        ],
      ),
    );
  }
}
