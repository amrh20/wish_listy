import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wish_listy/core/constants/app_colors.dart';
import 'package:wish_listy/core/constants/app_styles.dart';
import 'package:wish_listy/core/utils/app_constants.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/widgets/unified_page_container.dart';
import 'package:wish_listy/core/widgets/decorative_background.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localization = Provider.of<LocalizationService>(context, listen: false);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          localization.translate('profile.contactUs'),
          style: AppStyles.headingLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: UnifiedPageBackground(
        child: DecorativeBackground(
          showGifts: false,
          child: Column(
            children: [
              Expanded(
                child: UnifiedPageContainer(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Header Icon
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.headset_mic,
                            size: 40,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Title
                        Text(
                          localization.translate('profile.weAreHereToHelp'),
                          style: AppStyles.headingLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        // Subtitle
                        Text(
                          localization.translate('profile.haveQuestionsDropUsEmail'),
                          style: AppStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),

                        // Email Card
                        _buildEmailCard(localization),
                        const SizedBox(height: 32),
                        // Follow Us label
                        Text(
                          localization.translate('profile.followUs') ?? 'Follow Us',
                          style: AppStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        // Social Links (same as profile screen)
                        _buildSocialMediaLinksRow(context),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build Email Card
  Widget _buildEmailCard(LocalizationService localization) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        onTap: _sendEmail,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.email_outlined,
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
                      localization.translate('profile.email'),
                      style: AppStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'wishlistyapp@gmail.com',
                      style: AppStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textTertiary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Social media links row (Facebook, Instagram, Snapchat, TikTok, X)
  Widget _buildSocialMediaLinksRow(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SocialCircleIconButton(
            icon: FontAwesomeIcons.facebookF,
            onTap: () => _launchExternalUrl(context, AppConstants.facebookUrl),
          ),
          const SizedBox(width: 16),
          _SocialCircleIconButton(
            icon: FontAwesomeIcons.instagram,
            onTap: () => _launchExternalUrl(context, AppConstants.instagramUrl),
          ),
          const SizedBox(width: 16),
          _SocialCircleIconButton(
            icon: FontAwesomeIcons.snapchatGhost,
            onTap: () => _launchExternalUrl(context, AppConstants.snapchatUrl),
          ),
          const SizedBox(width: 16),
          _SocialCircleIconButton(
            icon: FontAwesomeIcons.tiktok,
            onTap: () => _launchExternalUrl(context, AppConstants.tiktokUrl),
          ),
          const SizedBox(width: 16),
          _SocialCircleIconButton(
            icon: FontAwesomeIcons.xTwitter,
            onTap: () => _launchExternalUrl(context, AppConstants.xUrl),
          ),
        ],
      ),
    );
  }

  /// Generic URL launcher for external links
  static Future<void> _launchExternalUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Provider.of<LocalizationService>(context, listen: false)
                  .translate('profile.couldNotLaunchUrl'),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Open email client to send email (works on mobile and desktop).
  Future<void> _sendEmail() async {
    final uri = Uri.parse('mailto:wishlistyapp@gmail.com');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('Failed to send email: $e');
    }
  }
}

class _SocialCircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SocialCircleIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: FaIcon(
              icon,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

