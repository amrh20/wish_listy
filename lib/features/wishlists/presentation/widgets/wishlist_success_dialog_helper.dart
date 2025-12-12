import 'package:flutter/material.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'package:wish_listy/core/widgets/confirmation_dialog.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/utils/app_routes.dart';

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
          label: localization.translate('wishlists.viewWishlists'),
          onPressed: () {
            Navigator.of(context).pop(); // Close dialog
            if (context.mounted) {
              // Close create wishlist screen
              Navigator.of(context).pop(); // Close create wishlist screen
              
              // Navigate to MainNavigation which includes the bottom nav
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.mainNavigation,
                  (route) => route.isFirst, // Keep only the initial route (splash/home)
                );
              }
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

