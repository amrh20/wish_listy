import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FriendRequestTile extends StatelessWidget {
  final String senderName;
  final String? senderImage;
  final String timeAgo;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onProfileTap;
  final bool compact;

  const FriendRequestTile({
    super.key,
    required this.senderName,
    this.senderImage,
    required this.timeAgo,
    required this.onAccept,
    required this.onDecline,
    required this.onProfileTap,
    this.compact = false,
  });

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onProfileTap,
                child: CircleAvatar(
                  radius: compact ? 20 : 28,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  backgroundImage: senderImage != null && senderImage!.isNotEmpty
                      ? CachedNetworkImageProvider(senderImage!)
                      : null,
                  child: senderImage == null || senderImage!.isEmpty
                      ? Text(
                          _getInitials(senderName),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: compact ? 12 : 16,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: AppStyles.bodyMedium.copyWith(fontSize: compact ? 13 : 14),
                        children: [
                          TextSpan(
                            text: senderName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            recognizer: TapGestureRecognizer()..onTap = onProfileTap,
                          ),
                          const TextSpan(
                            text: ' sent you a friend request.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeAgo,
                      style: AppStyles.caption.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: compact ? 10 : 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 8 : 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onDecline,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: AppColors.textPrimary,
                    padding: EdgeInsets.symmetric(vertical: compact ? 8 : 12),
                    minimumSize: Size(0, compact ? 32 : 40),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    'Decline',
                    style: TextStyle(fontSize: compact ? 12 : 14),
                  ),
                ),
              ),
              SizedBox(width: compact ? 8 : 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: compact ? 8 : 12),
                    minimumSize: Size(0, compact ? 32 : 40),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    'Accept',
                    style: TextStyle(fontSize: compact ? 12 : 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

