import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';

/// A comprehensive, reusable error handling screen widget
/// Supports custom content, icons, illustrations, and action buttons
class GenericErrorScreen extends StatelessWidget {
  /// Main error title (bold, large text)
  final String title;

  /// Error description (grey, readable, centered text)
  final String description;

  /// Icon to display (optional, if illustrationPath is provided, this is ignored)
  final IconData? icon;

  /// Path to illustration image (optional, takes precedence over icon)
  final String? illustrationPath;

  /// Text for the primary action button (optional)
  final String? actionButtonText;

  /// Callback for primary action button (optional)
  final VoidCallback? onActionPressed;

  /// Text for secondary action button (optional)
  final String? secondaryButtonText;

  /// Callback for secondary action button (optional)
  final VoidCallback? onSecondaryPressed;

  /// If true, wraps content in a Scaffold. If false, returns only the body content.
  /// Useful when embedding inside an existing Scaffold (e.g., inside HomeScreen tabs).
  final bool withScaffold;

  const GenericErrorScreen({
    super.key,
    required this.title,
    required this.description,
    this.icon,
    this.illustrationPath,
    this.actionButtonText,
    this.onActionPressed,
    this.secondaryButtonText,
    this.onSecondaryPressed,
    this.withScaffold = true,
  }) : assert(
          icon != null || illustrationPath != null,
          'Either icon or illustrationPath must be provided',
        );

  /// Factory constructor for "No Internet Connection" error
  factory GenericErrorScreen.noInternet({
    required VoidCallback onRetry,
    bool withScaffold = true,
  }) {
    return GenericErrorScreen(
      title: 'No Internet Connection',
      description: 'Please check your network settings and try again.',
      icon: Icons.wifi_off_rounded,
      actionButtonText: 'Try Again',
      onActionPressed: onRetry,
      withScaffold: withScaffold,
    );
  }

  /// Factory constructor for "Server Error" error
  factory GenericErrorScreen.serverError({
    required VoidCallback onRetry,
    bool withScaffold = true,
  }) {
    return GenericErrorScreen(
      title: 'Something went wrong',
      description:
          'We\'re having trouble connecting to the server. Please try again later.',
      icon: Icons.dns_rounded,
      actionButtonText: 'Retry',
      onActionPressed: onRetry,
      withScaffold: withScaffold,
    );
  }

  /// Factory constructor for "Not Found (404)" error
  factory GenericErrorScreen.notFound({
    VoidCallback? onGoHome,
    bool withScaffold = true,
  }) {
    return GenericErrorScreen(
      title: 'Content Not Found',
      description:
          'The wishlist, gift, or page you are looking for has been removed or doesn\'t exist.',
      icon: Icons.search_off_rounded,
      actionButtonText: 'Go Home',
      onActionPressed: onGoHome,
      withScaffold: withScaffold,
    );
  }

  /// Factory constructor for "Maintenance" error
  factory GenericErrorScreen.maintenance({
    VoidCallback? onCheckStatus,
    bool withScaffold = true,
  }) {
    return GenericErrorScreen(
      title: 'Under Maintenance',
      description:
          'We are currently improving Wish Listy. We\'ll be back shortly!',
      icon: Icons.engineering_rounded,
      actionButtonText: onCheckStatus != null ? 'Check Status' : null,
      onActionPressed: onCheckStatus,
      withScaffold: withScaffold,
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Visual representation (Icon or Illustration)
              _buildVisual(context),

              const SizedBox(height: 32),

              // Title
              Text(
                title,
                style: AppStyles.headingLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Description
              Text(
                description,
                style: AppStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Primary Action Button
              if (actionButtonText != null && onActionPressed != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onActionPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      actionButtonText!,
                      style: AppStyles.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

              // Secondary Action Button
              if (secondaryButtonText != null && onSecondaryPressed != null) ...[
                if (actionButtonText != null && onActionPressed != null)
                  const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: onSecondaryPressed,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      secondaryButtonText!,
                      style: AppStyles.bodyLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (!withScaffold) return content;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: content,
    );
  }

  Widget _buildVisual(BuildContext context) {
    // If illustration path is provided, use it (takes precedence)
    if (illustrationPath != null) {
      return Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.05),
          shape: BoxShape.circle,
        ),
        child: Image.asset(
          illustrationPath!,
          width: 120,
          height: 120,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to icon if illustration fails to load
            return _buildIconVisual();
          },
        ),
      );
    }

    // Otherwise, use icon
    return _buildIconVisual();
  }

  Widget _buildIconVisual() {
    if (icon == null) {
      // Fallback if neither icon nor illustration is provided
      return const SizedBox.shrink();
    }

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 64,
        color: AppColors.primary,
      ),
    );
  }
}

/// Usage Examples:
///
/// 1. Using factory constructors (recommended):
/// 
///   // No Internet Error
///   GenericErrorScreen.noInternet(
///     onRetry: () {
///       // Retry logic here
///       Navigator.pop(context);
///       _loadData();
///     },
///   )
///
///   // Server Error
///   GenericErrorScreen.serverError(
///     onRetry: () => _fetchData(),
///   )
///
///   // Not Found (404)
///   GenericErrorScreen.notFound(
///     onGoHome: () => Navigator.pushNamed(context, AppRoutes.home),
///   )
///
///   // Maintenance
///   GenericErrorScreen.maintenance()
///
/// 2. Custom error screen:
///
///   GenericErrorScreen(
///     title: 'Custom Error Title',
///     description: 'Custom error description here.',
///     icon: Icons.error_outline_rounded,
///     actionButtonText: 'Retry',
///     onActionPressed: () => _retry(),
///     secondaryButtonText: 'Go Back',
///     onSecondaryPressed: () => Navigator.pop(context),
///   )
///
/// 3. Using with illustration image:
///
///   GenericErrorScreen(
///     title: 'Custom Error',
///     description: 'Error description',
///     illustrationPath: 'assets/images/error_illustration.png',
///     actionButtonText: 'Try Again',
///     onActionPressed: () => _retry(),
///   )
///
/// 4. In FutureBuilder:
///
///   FutureBuilder<Data>(
///     future: _fetchData(),
///     builder: (context, snapshot) {
///       if (snapshot.hasError) {
///         return GenericErrorScreen.serverError(
///           onRetry: () => setState(() {}),
///         );
///       }
///       if (snapshot.connectionState == ConnectionState.waiting) {
///         return const CircularProgressIndicator();
///       }
///       return YourDataWidget(data: snapshot.data!);
///     },
///   )
///
/// 5. Catching exceptions:
///
///   try {
///     await _apiCall();
///   } on SocketException {
///     Navigator.push(
///       context,
///       MaterialPageRoute(
///         builder: (_) => GenericErrorScreen.noInternet(
///           onRetry: () => Navigator.pop(context),
///         ),
///       ),
///     );
///   } catch (e) {
///     Navigator.push(
///       context,
///       MaterialPageRoute(
///         builder: (_) => GenericErrorScreen.serverError(
///           onRetry: () => Navigator.pop(context),
///         ),
///       ),
///     );
///   }

