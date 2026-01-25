import 'package:flutter/material.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'package:wish_listy/core/widgets/confirmation_dialog.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/features/profile/presentation/screens/main_navigation.dart';

/// Helper class for showing success dialogs after wishlist creation/update
class WishlistSuccessDialogHelper {
  /// Show success dialog for editing mode
  static void showEditSuccessDialog(BuildContext context) {
    ConfirmationDialog.show(
      context: context,
      isSuccess: true,
      title: 'Wishlist Updated!',
      message: 'Your wishlist has been updated successfully.',
      primaryActionLabel: 'Done',
      onPrimaryAction: () {
        Navigator.of(context).pop(true);
      },
    );
  }

  /// Show success dialog for creation mode with multiple actions
  static void showCreateSuccessDialog({
    required BuildContext context,
    required LocalizationService localization,
    required String wishlistId,
    required String wishlistName,
    required VoidCallback onResetForm,
  }) {
    ConfirmationDialog.show(
      context: context,
      isSuccess: true,
      title: localization.translate('wishlists.wishlistCreatedTitle'),
      message: localization.translate('wishlists.wishlistCreatedMessage'),
      primaryActionLabel: localization.translate('wishlists.addItemsToWishlist'),
      onPrimaryAction: () {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.addItem,
          arguments: {
            'wishlistId': wishlistId,
            'wishlistName': wishlistName,
            'isNewWishlist': true,
          },
        );
      },
      additionalActions: [
        DialogAction(
          label: localization.translate('wishlists.viewwishlist'),
          onPressed: () {
            // Dialog is closed automatically by ConfirmationDialog
            // Close create wishlist screen first
            Navigator.of(context).pop();
            
            // Navigate to the created wishlist details
            if (context.mounted) {
              // Pop until we reach MainNavigation (first route)
              Navigator.popUntil(context, (route) => route.isFirst);
              
              // Navigate to wishlist details after navigation completes
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.wishlistItems,
                    arguments: {
                      'wishlistId': wishlistId,
                      'wishlistName': wishlistName,
                      'totalItems': 0,
                      'purchasedItems': 0,
                      'isFriendWishlist': false,
                    },
                  );
                }
              });
            }
          },
          variant: ButtonVariant.outline,
          icon: Icons.list_rounded,
        ),
        DialogAction(
          label: localization.translate('wishlists.createAnotherWishlist'),
          onPressed: onResetForm,
          variant: ButtonVariant.text,
          icon: Icons.add_circle_outline,
        ),
      ],
    );
  }
}
