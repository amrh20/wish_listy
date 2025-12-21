import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';

/// Custom widget for displaying event invitation response notifications
/// Features a clickable avatar with status badge, rich text with clickable name and event, and time ago
class EventResponseTile extends StatelessWidget {
  final String notificationType; // 'event_invitation_accepted', 'event_invitation_declined', 'event_invitation_maybe'
  final String responderName;
  final String? responderImage;
  final String eventName;
  final String timeAgo;
  final VoidCallback onProfileTap;
  final VoidCallback? onEventTap;

  const EventResponseTile({
    super.key,
    required this.notificationType,
    required this.responderName,
    this.responderImage,
    required this.eventName,
    required this.timeAgo,
    required this.onProfileTap,
    this.onEventTap,
  });

  /// Get initials from responder name (first two letters, uppercase)
  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final trimmed = name.trim();
    final parts = trimmed.split(' ');
    
    if (parts.length >= 2) {
      // Two or more words: take first letter of first two words
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (trimmed.length >= 2) {
      // Single word with 2+ characters: take first two letters
      return trimmed.substring(0, 2).toUpperCase();
    } else {
      // Single character: return it uppercase
      return trimmed[0].toUpperCase();
    }
  }

  /// Get status color based on notification type
  Color _getStatusColor() {
    switch (notificationType.toLowerCase()) {
      case 'event_invitation_accepted':
        return AppColors.success; // Green
      case 'event_invitation_declined':
        return AppColors.error; // Red
      case 'event_invitation_maybe':
        return AppColors.warning; // Amber/Orange
      default:
        return AppColors.textSecondary;
    }
  }

  /// Get status icon based on notification type
  IconData _getStatusIcon() {
    switch (notificationType.toLowerCase()) {
      case 'event_invitation_accepted':
        return Icons.check;
      case 'event_invitation_declined':
        return Icons.close;
      case 'event_invitation_maybe':
        return Icons.help_outline;
      default:
        return Icons.info_outline;
    }
  }

  /// Get status text based on notification type
  String _getStatusText() {
    switch (notificationType.toLowerCase()) {
      case 'event_invitation_accepted':
        return 'is going to';
      case 'event_invitation_declined':
        return 'declined invitation to';
      case 'event_invitation_maybe':
        return 'is interested in';
      default:
        return 'responded to';
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(responderName);
    final statusColor = _getStatusColor();
    final statusIcon = _getStatusIcon();
    final statusText = _getStatusText();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Leading: Avatar with status badge (clickable)
            GestureDetector(
              onTap: onProfileTap,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.purple.shade50,
                    backgroundImage: responderImage != null && responderImage!.isNotEmpty
                        ? NetworkImage(responderImage!)
                        : null,
                    child: responderImage == null || responderImage!.isEmpty
                        ? Text(
                            initials,
                            style: AppStyles.bodyMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          )
                        : null,
                  ),
                  // Status badge on bottom-right corner
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        statusIcon,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Middle: Rich Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // RichText: "{Name} {statusText} {Event}"
                  RichText(
                    text: TextSpan(
                      style: AppStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary, // Grey for regular text
                        height: 1.5,
                        fontSize: 14,
                      ),
                      children: [
                        // Bold, black, clickable responder name
                        TextSpan(
                          text: responderName,
                          style: AppStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black, // Strictly black for name
                            fontSize: 14,
                            height: 1.5,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = onProfileTap,
                        ),
                        // Regular grey text
                        TextSpan(
                          text: ' $statusText ',
                          style: AppStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary, // Explicit grey
                            fontWeight: FontWeight.normal,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        // Bold, primary color, clickable event name
                        TextSpan(
                          text: eventName,
                          style: AppStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary, // Purple for event name
                            fontSize: 14,
                            height: 1.5,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = onEventTap ?? () {},
                        ),
                        // Period
                        const TextSpan(text: '.'),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 6),

                  // Time ago (smaller grey font)
                  Text(
                    timeAgo,
                    style: AppStyles.caption.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

