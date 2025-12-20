import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';

/// Custom widget for displaying friend request notifications
/// Features a clickable avatar, rich text with bold sender name, and action buttons
class FriendRequestTile extends StatelessWidget {
  final String senderName;
  final String? senderImage;
  final String timeAgo;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onProfileTap;
  final bool compact; // For dropdown/compact mode

  const FriendRequestTile({
    super.key,
    required this.senderName,
    this.senderImage,
    required this.timeAgo,
    required this.onAccept,
    required this.onDecline,
    required this.onProfileTap,
    this.compact = false, // Default to false for full-size buttons
  });

  /// Get initials from sender name (first two letters, uppercase)
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

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(senderName);

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section: Avatar + Rich Text
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Leading: Avatar (clickable)
                GestureDetector(
                  onTap: onProfileTap,
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.purple.shade50,
                    backgroundImage: senderImage != null && senderImage!.isNotEmpty
                        ? NetworkImage(senderImage!)
                        : null,
                    child: senderImage == null || senderImage!.isEmpty
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
                ),

                const SizedBox(width: 16),

                // Middle: Rich Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // RichText: "{senderName} sent you a friend request"
                      RichText(
                        text: TextSpan(
                          style: AppStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary, // Grey for regular text
                            height: 1.5,
                            fontSize: 14,
                          ),
                          children: [
                            // Bold, black, clickable sender name
                            TextSpan(
                              text: senderName,
                              style: AppStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black, // Strictly black for name
                                fontSize: 14,
                                height: 1.5,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = onProfileTap,
                            ),
                            // Regular grey text (explicitly set to grey)
                            TextSpan(
                              text: ' sent you a friend request.',
                              style: AppStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary, // Explicit grey
                                fontWeight: FontWeight.normal,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
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

            const SizedBox(height: 16),

            // Bottom Section: Action Buttons
            Row(
              children: [
                // Decline Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: onDecline,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(
                        vertical: compact ? 8 : 12,
                        horizontal: compact ? 8 : 16,
                      ),
                      minimumSize: compact ? const Size(0, 32) : null,
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                    child: Text(
                      'Decline',
                      style: AppStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        fontSize: compact ? 12 : 14,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: compact ? 8 : 12),
                // Accept Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: compact ? 8 : 12,
                        horizontal: compact ? 8 : 16,
                      ),
                      minimumSize: compact ? const Size(0, 32) : null,
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                    child: Text(
                      'Accept',
                      style: AppStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: compact ? 12 : 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

