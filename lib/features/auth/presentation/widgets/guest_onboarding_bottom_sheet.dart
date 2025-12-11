import 'package:flutter/material.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/utils/app_routes.dart';
import 'package:wish_listy/core/widgets/custom_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GuestOnboardingBottomSheet extends StatelessWidget {
  const GuestOnboardingBottomSheet({super.key});

  static const String _keyHasSeenOnboarding = 'guest_has_seen_onboarding';

  /// Check if user has already seen the onboarding
  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasSeenOnboarding) ?? false;
  }

  /// Mark onboarding as seen
  static Future<void> markOnboardingAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasSeenOnboarding, true);
  }

  /// Show onboarding if user hasn't seen it
  static Future<void> showIfNeeded(BuildContext context) async {
    final hasSeen = await hasSeenOnboarding();
    if (!hasSeen && context.mounted) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const GuestOnboardingBottomSheet(),
      );
      await markOnboardingAsSeen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.75,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      'Welcome to WishListy!',
                      style: AppStyles.headingLargeWithContext(context),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // Subtitle
                    Text(
                      'Explore what you can do as a guest',
                      style: AppStyles.bodyLargeWithContext(context).copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Features list
                    _buildFeatureItem(
                      context,
                      Icons.favorite_outline,
                      'Browse Public Wishlists',
                      'Discover wishlists shared by others',
                    ),
                    const SizedBox(height: 20),
                    _buildFeatureItem(
                      context,
                      Icons.event_outlined,
                      'Explore Events',
                      'View public events and celebrations',
                    ),
                    const SizedBox(height: 20),
                    _buildFeatureItem(
                      context,
                      Icons.lock_outline,
                      'Sign Up for More',
                      'Create your own wishlists and manage events',
                    ),
                    const SizedBox(height: 32),

                    // Benefits section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.1),
                            AppColors.secondary.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.star_outline,
                                color: AppColors.primary,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Benefits of Signing Up',
                                style: AppStyles.headingSmallWithContext(context).copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildBenefitItem(
                            context,
                            'Create unlimited wishlists',
                          ),
                          _buildBenefitItem(
                            context,
                            'Organize events and invite friends',
                          ),
                          _buildBenefitItem(
                            context,
                            'Track gift purchases',
                          ),
                          _buildBenefitItem(
                            context,
                            'Connect with friends',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CustomButton(
                    text: 'Sign Up Now',
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.signup);
                    },
                    variant: ButtonVariant.gradient,
                    gradientColors: [AppColors.primary, AppColors.secondary],
                    size: ButtonSize.large,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Continue as Guest',
                      style: AppStyles.bodyMediumWithContext(context).copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppStyles.headingSmallWithContext(context).copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppStyles.bodyMediumWithContext(context).copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppStyles.bodyMediumWithContext(context).copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

