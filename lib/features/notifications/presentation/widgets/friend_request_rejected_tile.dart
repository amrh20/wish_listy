import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';

/// Custom widget for displaying friend request rejected notifications
/// Features a clickable avatar, rich text with bold friend name, and no action buttons
class FriendRequestRejectedTile extends StatelessWidget {
  final String friendName;
  final String? friendImage;
  final String timeAgo;
  final VoidCallback onProfileTap;

  const FriendRequestRejectedTile({
    super.key,
    required this.friendName,
    this.friendImage,
    required this.timeAgo,
    required this.onProfileTap,
  });

  /// Get initials from friend name (first two letters, uppercase)
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
    final initials = _getInitials(friendName);

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
            // Leading: Avatar with cancel badge (clickable)
            GestureDetector(
              onTap: onProfileTap,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.purple.shade50,
                    backgroundImage: friendImage != null && friendImage!.isNotEmpty
                        ? NetworkImage(friendImage!)
                        : null,
                    child: friendImage == null || friendImage!.isEmpty
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
                  // Red cancel badge on bottom-right corner
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.error, // Red
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.close,
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
                  // RichText: "{friendName} declined your friend request"
                  RichText(
                    text: TextSpan(
                      style: AppStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary, // Grey for regular text
                        height: 1.5,
                        fontSize: 14,
                      ),
                      children: [
                        // Bold, black, clickable friend name
                        TextSpan(
                          text: friendName,
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
                          text: ' declined your friend request.',
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
      ),
    );
  }
}

