import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/services/api_service.dart';
import 'package:wish_listy/core/widgets/confirmation_dialog.dart';

/// Error Handler Widget
/// This widget provides a consistent way to display API errors
/// and handle different types of error states
class ErrorHandler {
  /// Show error dialog with retry option (using Lottie animation)
  static void showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onRetry,
    String? retryText,
  }) {
    ConfirmationDialog.show(
      context: context,
      isSuccess: false,
      title: title,
      message: message,
      primaryActionLabel: retryText ?? 'Try Again',
      onPrimaryAction: () {
        if (onRetry != null) {
          onRetry();
        }
      },
      secondaryActionLabel: 'Close',
      onSecondaryAction: () {},
      barrierDismissible: true,
    );
  }

  /// Show error dialog with Lottie animation (replaces SnackBar)
  static void showErrorSnackBar(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onAction,
    String? actionText,
  }) {
    ConfirmationDialog.show(
      context: context,
      isSuccess: false,
      title: 'Error',
      message: message,
      primaryActionLabel: actionText ?? 'Try Again',
      onPrimaryAction: () {
        if (onAction != null) {
          onAction();
        }
      },
      secondaryActionLabel: 'Close',
      onSecondaryAction: () {},
      barrierDismissible: true,
    );
  }

  /// Show success dialog with Lottie animation (replaces SnackBar)
  static void showSuccessSnackBar(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    ConfirmationDialog.show(
      context: context,
      isSuccess: true,
      title: 'Success',
      message: message,
      primaryActionLabel: 'OK',
      onPrimaryAction: () {},
      barrierDismissible: true,
    );
  }

  /// Show warning snackbar
  static void showWarningSnackBar(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.warning,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        width: 320,
        margin: const EdgeInsets.only(
          top: 60,
          right: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Handle API exception and show appropriate error message
  static void handleApiException(
    BuildContext context,
    ApiException exception, {
    VoidCallback? onRetry,
  }) {
    // Determine error type and show appropriate message
    // For 400, 404, 422: Show the actual API error message
    // For 500: Show generic server error message
    // For others: Show the actual API error message
    if (exception.statusCode == 400) {
      // Show actual API error message for 400 (Bad Request)
      showErrorDialog(
        context,
        title: 'Error',
        message: exception.message.isNotEmpty 
            ? exception.message 
            : 'Invalid request. Please check your input.',
        onRetry: onRetry,
      );
    } else if (exception.statusCode == 401) {
      showErrorDialog(
        context,
        title: 'Authentication Error',
        message: 'Please login again to continue.',
        onRetry: onRetry,
        retryText: 'Login',
      );
    } else if (exception.statusCode == 403) {
      showErrorDialog(
        context,
        title: 'Access Denied',
        message: 'You don\'t have permission to perform this action.',
      );
    } else if (exception.statusCode == 404) {
      // Show actual API error message for 404
      showErrorDialog(
        context,
        title: 'Not Found',
        message: exception.message.isNotEmpty 
            ? exception.message 
            : 'The requested resource was not found.',
        onRetry: onRetry,
      );
    } else if (exception.statusCode == 422) {
      // Show actual API error message for 422 (Validation Error)
      showErrorDialog(
        context,
        title: 'Validation Error',
        message: exception.message.isNotEmpty 
            ? exception.message 
            : 'Please check your input and try again.',
        onRetry: onRetry,
      );
    } else if (exception.statusCode == 500) {
      // For 500, show generic server error message (not the actual API message)
      showErrorDialog(
        context,
        title: 'Server Error',
        message: 'Something went wrong on our end. Please try again later.',
        onRetry: onRetry,
      );
    } else {
      // For other status codes, show the actual API error message
      showErrorDialog(
        context,
        title: 'Error',
        message: exception.message.isNotEmpty 
            ? exception.message 
            : 'An error occurred. Please try again.',
        onRetry: onRetry,
      );
    }
  }

  /// Show loading dialog
  static void showLoadingDialog(
    BuildContext context, {
    String message = 'Loading...',
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Hide loading dialog
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  /// Show confirmation dialog
  static Future<bool> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          title,
          style: AppStyles.headingMedium,
        ),
        content: Text(
          message,
          style: AppStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              cancelText,
              style: AppStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor ?? AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
