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
          label: localization.translate('wishlists.myWishlists'),
          onPressed: () {
            Navigator.of(context).pop(); // Close dialog
            if (context.mounted) {
              // Close create wishlist screen
              Navigator.of(context).pop(); // Close create wishlist screen
              
              // Navigate to Wishlists tab in MainNavigation
              if (context.mounted) {
                // Navigate to MainNavigation and switch to Wishlists tab (index 1)
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.mainNavigation,
                  (route) => route.isFirst,
                );
                // Use post frame callback to ensure MainNavigation is built before switching tabs
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    MainNavigation.switchToTab(context, 1);
                  }
                });
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

