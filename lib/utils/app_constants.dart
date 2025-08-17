class AppConstants {
  // App Info
  static const String appName = 'WishListy';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Connect through thoughtful gifting';

  // API Configuration
  static const String baseUrl = 'https://api.wishlink.com';
  static const String apiVersion = 'v1';
  static const Duration apiTimeout = Duration(seconds: 30);

  // Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String themeKey = 'app_theme';
  static const String languageKey = 'app_language';
  static const String notificationKey = 'notifications_enabled';

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 50;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int maxDescriptionLength = 500;
  static const int maxBioLength = 160;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultMargin = 8.0;
  static const double defaultBorderRadius = 12.0;
  static const double cardElevation = 2.0;
  static const double buttonHeight = 52.0;
  static const double iconSize = 24.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Image Constraints
  static const double maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1920;

  // Social Media
  static const String facebookUrl = 'https://facebook.com/wishlink';
  static const String twitterUrl = 'https://twitter.com/wishlink';
  static const String instagramUrl = 'https://instagram.com/wishlink';
  static const String supportEmail = 'support@wishlink.com';
  static const String privacyPolicyUrl = 'https://wishlink.com/privacy';
  static const String termsOfServiceUrl = 'https://wishlink.com/terms';

  // Feature Flags
  static const bool enablePushNotifications = true;
  static const bool enableSocialLogin = true;
  static const bool enableDarkMode = true;
  static const bool enableBiometricAuth = true;
  static const bool enableAnalytics = true;

  // Notification Types
  static const String friendRequestNotification = 'friend_request';
  static const String eventInviteNotification = 'event_invite';
  static const String itemPurchasedNotification = 'item_purchased';
  static const String eventReminderNotification = 'event_reminder';

  // Event Types
  static const Map<String, String> eventTypeEmojis = {
    'birthday': '🎂',
    'wedding': '💒',
    'anniversary': '💕',
    'graduation': '🎓',
    'holiday': '🎄',
    'baby_shower': '👶',
    'house_warming': '🏠',
    'retirement': '🎊',
    'promotion': '🎉',
    'other': '🎈',
  };

  // Currency Symbols
  static const Map<String, String> currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'EGP': 'E£',
    'SAR': 'SR',
    'AED': 'AED',
  };

  // Supported Languages
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'ar': 'العربية',
    'es': 'Español',
    'fr': 'Français',
    'de': 'Deutsch',
  };

  // Priority Levels
  static const Map<String, int> priorityLevels = {
    'low': 1,
    'medium': 2,
    'high': 3,
    'urgent': 4,
  };

  // Status Messages
  static const String networkErrorMessage =
      'Please check your internet connection and try again.';
  static const String serverErrorMessage =
      'Something went wrong. Please try again later.';
  static const String unauthorizedMessage = 'Please sign in to continue.';
  static const String forbiddenMessage =
      'You don\'t have permission to access this.';
  static const String notFoundMessage = 'The requested item was not found.';
  static const String validationErrorMessage =
      'Please check your input and try again.';

  // Success Messages
  static const String itemAddedMessage = 'Item added to wishlist successfully!';
  static const String eventCreatedMessage = 'Event created successfully!';
  static const String friendRequestSentMessage = 'Friend request sent!';
  static const String profileUpdatedMessage = 'Profile updated successfully!';
  static const String passwordChangedMessage = 'Password changed successfully!';

  // Confirmation Messages
  static const String deleteConfirmMessage =
      'Are you sure you want to delete this item?';
  static const String logoutConfirmMessage = 'Are you sure you want to logout?';
  static const String unfriendConfirmMessage =
      'Are you sure you want to remove this friend?';
  static const String cancelEventConfirmMessage =
      'Are you sure you want to cancel this event?';

  // Regular Expressions
  static const String emailRegex = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  static const String phoneRegex = r'^\+?[1-9]\d{1,14}$';
  static const String urlRegex =
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$';

  // Date Formats
  static const String shortDateFormat = 'MMM dd';
  static const String longDateFormat = 'MMMM dd, yyyy';
  static const String timeFormat = 'h:mm a';
  static const String dateTimeFormat = 'MMM dd, yyyy at h:mm a';

  // Image Assets
  static const String logoPath = 'assets/images/logo.png';
  static const String placeholderImagePath = 'assets/images/placeholder.png';
  static const String emptyStatePath = 'assets/images/empty_state.png';

  // Lottie Animations
  static const String loadingAnimationPath = 'assets/animations/loading.json';
  static const String successAnimationPath = 'assets/animations/success.json';
  static const String errorAnimationPath = 'assets/animations/error.json';

  // App Store Links
  static const String iosAppStoreUrl =
      'https://apps.apple.com/app/wishlink/id123456789';
  static const String androidPlayStoreUrl =
      'https://play.google.com/store/apps/details?id=com.wishlink.app';

  // Deep Links
  static const String appScheme = 'wishlink';
  static const String profileDeepLink = 'wishlink://profile';
  static const String wishlistDeepLink = 'wishlink://wishlist';
  static const String eventDeepLink = 'wishlink://event';
}
