import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'package:wish_listy/core/widgets/confirmation_dialog.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/features/profile/presentation/screens/main_navigation.dart';

/// Helper class for showing success dialogs after wishlist creation/update
class WishlistSuccessDialogHelper {
  /// Show success dialog for editing mode
  static void showEditSuccessDialog(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    ConfirmationDialog.show(
      context: context,
      isSuccess: true,
      title: localization.translate('wishlists.wishlistUpdatedTitle'),
      message: localization.translate('wishlists.wishlistUpdatedMessage'),
      primaryActionLabel: localization.translate('app.done'),
      onPrimaryAction: () {
        Navigator.of(context).pop(true);
      },
    );
  }

  /// Show success dialog for creation mode with single action to view details
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
      primaryActionLabel: localization.translate('wishlists.viewDetails') ?? 
                          localization.translate('wishlists.viewwishlist') ?? 
                          localization.translate('app.viewDetails'),
      onPrimaryAction: () {
        // Close dialog and create wishlist screen
        Navigator.of(context).pop(); // Close dialog
        
        // Navigate to the created wishlist details
        if (context.mounted) {
          // Pop create wishlist screen if still in stack
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
          
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
    );
  }
}
