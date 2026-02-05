import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';

/// Reusable confirmation dialog with Lottie animations
/// Supports both success and error states with customizable actions
class ConfirmationDialog {
  /// Show a confirmation dialog with Lottie animation or custom image
  ///
  /// [context] - BuildContext for showing the dialog
  /// [isSuccess] - Whether this is a success (true) or error (false) dialog
  /// [title] - Dialog title text
  /// [message] - Dialog message/description text
  /// [primaryActionLabel] - Text for the primary action button
  /// [onPrimaryAction] - Callback when primary action is pressed
  /// [secondaryActionLabel] - Optional text for secondary action button
  /// [onSecondaryAction] - Optional callback when secondary action is pressed
  /// [additionalActions] - Optional list of additional action buttons (label, callback, variant)
  /// [barrierDismissible] - Whether the dialog can be dismissed by tapping outside (default: false)
  /// [customImagePath] - Optional custom image path to replace Lottie animation
  /// [backgroundVectorPath] - Optional background vector image that appears behind and above dialog
  static Future<void> show({
    required BuildContext context,
    required bool isSuccess,
    required String title,
    required String message,
    String? primaryActionLabel,
    VoidCallback? onPrimaryAction,
    String? secondaryActionLabel,
    VoidCallback? onSecondaryAction,
    List<DialogAction>? additionalActions,
    bool barrierDismissible = false,
    String? customImagePath,
    String? backgroundVectorPath,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => _ConfirmationDialogWidget(
        isSuccess: isSuccess,
        title: title,
        message: message,
        primaryActionLabel: primaryActionLabel,
        onPrimaryAction: onPrimaryAction,
        secondaryActionLabel: secondaryActionLabel,
        onSecondaryAction: onSecondaryAction,
        additionalActions: additionalActions,
        customImagePath: customImagePath,
        backgroundVectorPath: backgroundVectorPath,
      ),
    );
  }
}

/// Model for additional dialog actions
class DialogAction {
  final String label;
  final VoidCallback onPressed;
  final ButtonVariant variant;
  final IconData? icon;

  const DialogAction({
    required this.label,
    required this.onPressed,
    this.variant = ButtonVariant.outline,
    this.icon,
  });
}

/// Internal widget for the confirmation dialog
class _ConfirmationDialogWidget extends StatelessWidget {
  final bool isSuccess;
  final String title;
  final String message;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final List<DialogAction>? additionalActions;
  final String? customImagePath;
  final String? backgroundVectorPath;

  const _ConfirmationDialogWidget({
    required this.isSuccess,
    required this.title,
    required this.message,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.additionalActions,
    this.customImagePath,
    this.backgroundVectorPath,
  });

  @override
  Widget build(BuildContext context) {
    // Determine colors based on success/error state
    final accentColor = isSuccess ? AppColors.success : AppColors.error;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Background vector image positioned behind and above dialog
        if (backgroundVectorPath != null)
          Positioned(
            top: -80, // Position above dialog (reduced from -120)
            child: Image.asset(
              backgroundVectorPath!,
              height: 180,
              width: 180,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox.shrink();
              },
            ),
          ),

        // Main Dialog
        AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Only show custom image or icon if NO background vector
              if (backgroundVectorPath == null) ...[
                SizedBox(
                  height: 80,
                  width: 80,
                  child: customImagePath != null
                      ? Image.asset(
                          customImagePath!,
                          height: 80,
                          width: 80,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback to icon if custom image fails
                            return Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isSuccess
                                    ? Icons.check_circle_outline
                                    : Icons.error_outline,
                                color: accentColor,
                                size: 40,
                              ),
                            );
                          },
                        )
                      : Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSuccess
                                ? Icons.check_circle_outline
                                : Icons.error_outline,
                            color: accentColor,
                            size: 40,
                          ),
                        ),
                ),
                const SizedBox(height: 24),
              ],

              // Title
              Text(
                title,
                style: AppStyles.headingSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              if (message.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                // Message
                Text(
                  message,
                  style: AppStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
              ] else ...[
                const SizedBox(height: 24),
              ],

              // Action Buttons
              Column(
                children: [
                  // Primary Action Button (if provided)
                  if (primaryActionLabel != null && onPrimaryAction != null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: primaryActionLabel!,
                        onPressed: () {
                          Navigator.of(context).pop();
                          onPrimaryAction!();
                        },
                        variant: isSuccess
                            ? ButtonVariant.gradient
                            : ButtonVariant.primary,
                        size: ButtonSize.small,
                        gradientColors: isSuccess
                            ? [AppColors.primary, AppColors.secondary]
                            : null,
                        customColor: isSuccess ? null : accentColor,
                        icon: isSuccess
                            ? Icons.check_rounded
                            : Icons.refresh_rounded,
                      ),
                    ),
                  ],

                  // Secondary Action Button (if provided)
                  if (secondaryActionLabel != null &&
                      onSecondaryAction != null) ...[
                    if (primaryActionLabel != null && onPrimaryAction != null)
                      const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: secondaryActionLabel!,
                        onPressed: () {
                          Navigator.of(context).pop();
                          onSecondaryAction!();
                        },
                        variant: ButtonVariant.outline,
                        size: ButtonSize.small,
                        customColor: accentColor,
                      ),
                    ),
                  ],

                  // Additional Actions (if provided)
                  if (additionalActions != null &&
                      additionalActions!.isNotEmpty) ...[
                    ...additionalActions!.map(
                      (action) => Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: CustomButton(
                            text: action.label,
                            onPressed: () {
                              Navigator.of(context).pop();
                              action.onPressed();
                            },
                            variant: action.variant,
                            size: ButtonSize.small,
                            icon: action.icon,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
