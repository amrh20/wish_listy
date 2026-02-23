import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/features/events/data/models/event_model.dart';

/// Invited Event Card - Displays events where the user was invited
/// Shows RSVP buttons for pending invitations or status banner for responded invitations
class InvitedEventCard extends StatelessWidget {
  final EventSummary event;
  final LocalizationService localization;
  final VoidCallback onTap;
  final Function(String status)? onRSVP;

  const InvitedEventCard({
    super.key,
    required this.event,
    required this.localization,
    required this.onTap,
    this.onRSVP,
  });

  @override
  Widget build(BuildContext context) {
    final hasResponded = event.invitationStatus != null &&
        event.invitationStatus != InvitationStatus.pending;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Invited By Row
            _buildInvitedByRow(),

            // Event Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Name
                  Text(
                    event.name,
                    style: AppStyles.headingSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 12),

                  // Event Details
                  _buildEventDetails(),

                  const SizedBox(height: 16),

                  // RSVP Section (with AnimatedSwitcher)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: hasResponded
                        ? _buildStatusBanner()
                        : _buildRSVPButtons(),
                  ),

                  // Wishlist Badge (if accepted)
                  if (event.invitationStatus == InvitationStatus.accepted &&
                      event.wishlistId != null)
                    _buildWishlistBadge(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvitedByRow() {
    return Builder(
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Row(
            children: [
              // Creator Avatar (clickable) - Larger size for better tap target
              GestureDetector(
                onTap: () => _navigateToProfile(context),
                child: CircleAvatar(
                  radius: 20, // Increased from 16 to 20
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  backgroundImage: event.creatorImage != null
                      ? NetworkImage(event.creatorImage!)
                      : null,
                  child: event.creatorImage == null
                      ? Text(
                          _getInitials(event.creatorName ?? ''),
                          style: AppStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14, // Increased font size
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              // Creator Name (clickable) - Larger font size
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: AppStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 14, // Increased from bodySmall to bodyMedium
                    ),
                    children: [
                      // Bold, clickable creator name
                      TextSpan(
                        text: event.creatorName ?? localization.translate('activity.someone'),
                        style: AppStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14, // Explicit font size
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => _navigateToProfile(context),
                      ),
                      // Regular text
                      TextSpan(
                        text: ' ${localization.translate('events.invitedYou')}',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Navigate to creator's profile
  void _navigateToProfile(BuildContext context) {
    if (event.creatorId == null || event.creatorId!.isEmpty) return;
    
    Navigator.pushNamed(
      context,
      AppRoutes.friendProfile,
      arguments: {'friendId': event.creatorId},
    );
  }

  Widget _buildEventDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date & Time
        if (event.date != null) ...[
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                _formatDate(event.date!),
                style: AppStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],

        // Location
        if (event.location != null) ...[
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  event.location!,
                  style: AppStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildRSVPButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildRSVPButton(
            text: localization.translate('events.accept'),
            onPressed: () => onRSVP?.call('accepted'),
            isPrimary: false,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildRSVPButton(
            text: localization.translate('events.maybe'),
            onPressed: () => onRSVP?.call('maybe'),
            isPrimary: false,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildRSVPButton(
            text: localization.translate('events.reject'),
            onPressed: () => onRSVP?.call('declined'),
            isPrimary: false,
            color: AppColors.error,
          ),
        ),
      ],
    );
  }

  Widget _buildRSVPButton({
    required String text,
    required VoidCallback? onPressed,
    required bool isPrimary,
    required Color color,
  }) {
    return SizedBox(
      height: 40,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: AppStyles.bodySmall.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    final status = event.invitationStatus!;
    final message = _getRSVPStatusMessage(status);
    final color = _getStatusColor(status);
    final icon = _getStatusIcon(status);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppStyles.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWishlistBadge() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.card_giftcard_outlined,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            localization.translate('events.wishlistLinked'),
            style: AppStyles.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getRSVPStatusMessage(InvitationStatus status) {
    switch (status) {
      case InvitationStatus.accepted:
        return localization.translate('events.youAreGoing');
      case InvitationStatus.declined:
        return localization.translate('events.youDeclined');
      case InvitationStatus.maybe:
        return localization.translate('events.youMarkedMaybe');
      case InvitationStatus.pending:
        return localization.translate('events.pendingResponse');
    }
  }

  Color _getStatusColor(InvitationStatus status) {
    switch (status) {
      case InvitationStatus.accepted:
        return AppColors.success;
      case InvitationStatus.declined:
        return AppColors.error;
      case InvitationStatus.maybe:
        return AppColors.warning;
      case InvitationStatus.pending:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon(InvitationStatus status) {
    switch (status) {
      case InvitationStatus.accepted:
        return Icons.check_circle_outline;
      case InvitationStatus.declined:
        return Icons.cancel_outlined;
      case InvitationStatus.maybe:
        return Icons.help_outline;
      case InvitationStatus.pending:
        return Icons.schedule;
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
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
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

