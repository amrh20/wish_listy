import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wish_listy/core/utils/app_routes.dart';

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

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  Color _getStatusColor() {
    switch (notificationType) {
      case 'event_invitation_accepted':
        return Colors.green;
      case 'event_invitation_declined':
        return AppColors.error;
      case 'event_invitation_maybe':
        return Colors.amber;
      default:
        return AppColors.primary;
    }
  }

  IconData _getStatusIcon() {
    switch (notificationType) {
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

  String _getStatusText() {
    switch (notificationType) {
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
    final statusColor = _getStatusColor();
    final statusIcon = _getStatusIcon();
    final statusText = _getStatusText();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onProfileTap,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  backgroundImage: responderImage != null && responderImage!.isNotEmpty
                      ? CachedNetworkImageProvider(responderImage!)
                      : null,
                  child: responderImage == null || responderImage!.isEmpty
                      ? Text(
                          _getInitials(responderName),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: AppStyles.bodyMedium.copyWith(fontSize: 14),
                    children: [
                      TextSpan(
                        text: responderName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        recognizer: TapGestureRecognizer()..onTap = onProfileTap,
                      ),
                      const TextSpan(
                        text: ' ',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      TextSpan(
                        text: statusText,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      const TextSpan(
                        text: ' ',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      TextSpan(
                        text: eventName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                        recognizer: onEventTap != null
                            ? (TapGestureRecognizer()..onTap = onEventTap!)
                            : null,
                      ),
                      const TextSpan(
                        text: '.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
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
    );
  }
}

