import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_styles.dart';
import '../../services/localization_service.dart';
import '../../widgets/custom_button.dart';
import '../../utils/app_routes.dart';

/// Friends wishlists tab widget
class FriendsWishlistsTabWidget extends StatelessWidget {
  const FriendsWishlistsTabWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline_rounded,
                size: 50,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              localization.translate('wishlists.noFriendsWishlistsYet'),
              style: AppStyles.headingMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              localization.translate('wishlists.addFriendsToSeeTheirWishlists'),
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: localization.translate('friends.addFriends'),
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.addFriend);
              },
              customColor: AppColors.secondary,
              icon: Icons.person_add_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
