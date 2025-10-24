import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_styles.dart';
import '../../../services/localization_service.dart';
import '../../custom_button.dart';

/// Widget for inviting guests to the event
class InviteGuestsWidget extends StatelessWidget {
  final List<String> invitedFriends;
  final VoidCallback onInvitePressed;

  const InviteGuestsWidget({
    super.key,
    required this.invitedFriends,
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

          // Invited friends count
          if (invitedFriends.isNotEmpty) ...[
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

          // Invite Friends Button
          CustomButton(
            text: localization.translate('events.inviteFriends'),
            onPressed: onInvitePressed,
            variant: ButtonVariant.outline,
            icon: Icons.person_add_outlined,
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}
