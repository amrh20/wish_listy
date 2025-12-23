import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'package:wish_listy/features/events/data/models/event_model.dart';

/// Widget for inviting guests to the event
class InviteGuestsWidget extends StatelessWidget {
  final List<String> invitedFriends;
  final List<InvitedFriend>? invitedFriendsData; // Full friend data for display
  final VoidCallback onInvitePressed;

  const InviteGuestsWidget({
    super.key,
    required this.invitedFriends,
    this.invitedFriendsData,
    required this.onInvitePressed,
  });

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.textTertiary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people_outline, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                localization.translate('events.inviteGuests'),
                style: AppStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Display invited friends with avatars and names
          if (invitedFriends.isNotEmpty) ...[
            if (invitedFriendsData != null && invitedFriendsData!.isNotEmpty) ...[
              // Display friends with avatars and names
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ...invitedFriendsData!.take(10).map((friend) {
                    return _buildFriendItem(friend);
                  }),
                  if (invitedFriendsData!.length > 10)
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '+${invitedFriendsData!.length - 10}',
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
                ],
              ),
              const SizedBox(height: 16),
            ] else ...[
              // Fallback: Show count only if friend data is not available
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: AppColors.primary, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    localization.translate(
                      'events.friendsInvited',
                      args: {'count': invitedFriends.length.toString()},
                    ),
                    style: AppStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ],
          ],

          // Invite Friends Button
          CustomButton(
            text: invitedFriends.isNotEmpty
                ? localization.translate('events.inviteMoreFriends')
                : localization.translate('events.inviteFriends'),
            onPressed: onInvitePressed,
            variant: ButtonVariant.outline,
            icon: Icons.person_add_outlined,
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  /// Build friend item with avatar and full name
  Widget _buildFriendItem(InvitedFriend friend) {
    final initials = _getInitials(friend.fullName ?? friend.username ?? friend.id);
    final displayName = friend.fullName ?? friend.username ?? '';
    
    return Column(
      mainAxisSize: MainAxisSize.min,
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
        const SizedBox(height: 4),
        SizedBox(
          width: 60,
          child: Text(
            displayName,
            style: AppStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
}
