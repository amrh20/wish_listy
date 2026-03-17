import 'package:flutter/material.dart';
import 'package:wish_listy/core/widgets/unified_snackbar.dart';

/// Centralized dialogs/snackbars facade for consistent UX.
class Dialogs {
  static void showErrorSnackbar(BuildContext context, String message) {
    UnifiedSnackbar.showError(
      context: context,
      message: message.trim().isEmpty ? 'Something went wrong. Please try again.' : message,
    );
  }
}

