import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/widgets/splash_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/new_password_screen.dart';
import '../../features/auth/presentation/screens/legal_info_screen.dart';
import '../../features/auth/presentation/screens/verification_screen.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/data/repository/auth_repository.dart';
import 'package:wish_listy/features/profile/presentation/screens/home_screen.dart';
import 'package:wish_listy/features/profile/presentation/screens/main_navigation.dart';
import '../../features/wishlists/presentation/screens/my_wishlists_screen.dart';
import '../../features/wishlists/presentation/screens/add_item_screen.dart';
import '../../features/wishlists/presentation/screens/wishlist_items_screen.dart';
import '../../features/wishlists/presentation/screens/item_details_screen.dart';
import '../../features/events/presentation/screens/events_screen.dart';
import '../../features/events/presentation/screens/create_event_screen.dart';
import '../../features/events/presentation/screens/event_details_screen.dart';
import '../../features/events/presentation/screens/event_management_screen.dart';
import '../../features/events/presentation/screens/event_wishlist_screen.dart';
import '../../features/events/presentation/screens/event_guest_list_screen.dart';
import '../../features/friends/presentation/screens/friends_screen.dart';
import '../../features/friends/presentation/screens/friend_profile_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/personal_information_screen.dart';
import '../../features/profile/presentation/screens/privacy_security_screen.dart';
import '../../features/profile/presentation/screens/change_password_screen.dart';
import '../../features/profile/presentation/screens/blocked_users_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/events/presentation/screens/guest_management_screen.dart';
import '../../features/events/presentation/screens/event_settings_screen.dart';
import '../../features/wishlists/presentation/screens/wishlist_item_details_screen.dart';
import '../../features/wishlists/presentation/screens/create_wishlist_screen.dart';
import '../../features/friends/presentation/screens/add_friend_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/activity_feed_screen.dart';
import '../../features/profile/presentation/screens/faq_screen.dart';
import '../../features/profile/presentation/screens/contact_us_screen.dart';
import '../../features/wishlists/data/models/wishlist_model.dart';
import '../../features/events/data/models/event_model.dart';

class AppRoutes {
  // Route Names
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String onboarding = '/welcome'; // Alias for welcome (OnboardingScreen)
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String verification = '/verification';
  static const String home = '/home';
  static const String mainNavigation = '/main';
  static const String myWishlists = '/my-wishlists';
  static const String addItem = '/add-item';
  static const String wishlistItems = '/wishlist-items';
  static const String itemDetails = '/item-details';
  static const String wishlistItemDetails = '/wishlist-item-details';
  static const String events = '/events';
  static const String createEvent = '/create-event';
  static const String eventDetails = '/event-details';
  static const String eventManagement = '/event-management';
  static const String eventWishlist = '/event-wishlist';
  static const String friends = '/friends';
  static const String friendProfile = '/friend-profile';
  static const String profile = '/profile';
  static const String notifications = '/notifications';
  static const String guestManagement = '/guest-management';
  static const String eventSettings = '/event-settings';
  static const String personalInformation = '/personal-information';
  static const String privacySecurity = '/privacy-security';
  static const String changePassword = '/change-password';
  static const String blockedUsers = '/blocked-users';
  static const String createWishlist = '/create-wishlist';
  static const String addFriend = '/add-friend';
  static const String editProfile = '/edit-profile';
  static const String friendActivityFeed = '/friend-activity-feed';
  static const String eventGuestList = '/event-guest-list';
  static const String legalInfo = '/legal-info';
  static const String faq = '/faq';
  static const String contactUs = '/contact-us';
  
  // Deep Link Routes (for Universal/App Links)
  static const String deepLinkWishlist = '/wishlist';
  static const String deepLinkEvent = '/event';

  // Routes Map
  static Map<String, WidgetBuilder> routes = {
    splash: (context) => SplashScreen(),
    welcome: (context) => OnboardingScreen(),
    login: (context) => LoginScreen(),
    signup: (context) => SignupScreen(),
    // forgotPassword is handled in onGenerateRoute to provide BlocProvider
    // forgotPassword: (context) => ForgotPasswordScreen(),
    home: (context) => HomeScreen(),
    mainNavigation: (context) => MainNavigation(),
    myWishlists: (context) => MyWishlistsScreen(),
    addItem: (context) => AddItemScreen(),
    events: (context) => EventsScreen(),
    createEvent: (context) => CreateEventScreen(),
    friends: (context) => FriendsScreen(),
    profile: (context) => ProfileScreen(),
    notifications: (context) => NotificationsScreen(),
    // createWishlist is handled in onGenerateRoute to support editing with wishlistId
    addFriend: (context) => AddFriendScreen(),
    editProfile: (context) => EditProfileScreen(),
    faq: (context) => const FaqScreen(),
    contactUs: (context) => const ContactUsScreen(),
  };

  // Route Generator for dynamic routes
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    // Handle friends route with optional initialTabIndex
    if (settings.name == friends) {
      final args = settings.arguments as Map<String, dynamic>?;
      final initialTabIndex = args?['initialTabIndex'] as int?;
      return MaterialPageRoute(
        builder: (context) => FriendsScreen(initialTabIndex: initialTabIndex),
      );
    }
    
    // Handle createWishlist route with optional wishlistId for editing and eventId for event context
    if (settings.name == createWishlist) {
      final args = settings.arguments as Map<String, dynamic>?;
      final wishlistId = args?['wishlistId'] as String?;
      final eventId = args?['eventId'] as String?;
      final isForEvent = args?['isForEvent'] as bool? ?? false;
      final previousRoute = args?['previousRoute'] as String?;

      return MaterialPageRoute(
        builder: (context) => CreateWishlistScreen(
          wishlistId: wishlistId,
          eventId: eventId,
          isForEvent: isForEvent,
          previousRoute: previousRoute,
        ),
      );
    } else if (settings.name == wishlistItems) {
      final args = settings.arguments as Map<String, dynamic>?;
      final wishlistId = args?['wishlistId']?.toString().trim();
      if (args == null || wishlistId == null || wishlistId.isEmpty) {
        debugPrint('⚠️ [AppRoutes] wishlistItems: Invalid or missing wishlistId, redirecting to main');
        return MaterialPageRoute(
          builder: (context) => MainNavigation(),
        );
      }
      return MaterialPageRoute(
        builder: (context) => WishlistItemsScreen(
          wishlistName: args['wishlistName']?.toString() ?? 'My Wishlist',
          wishlistId: wishlistId,
          totalItems: (args['totalItems'] is int) ? args['totalItems'] as int : 0,
          purchasedItems: (args['purchasedItems'] is int) ? args['purchasedItems'] as int : 0,
          isFriendWishlist: args['isFriendWishlist'] == true,
          friendName: args['friendName']?.toString(),
        ),
      );
    } else if (settings.name == itemDetails) {
      // Support both Map and WishlistItem directly
      if (settings.arguments is WishlistItem) {
        return MaterialPageRoute(
          builder: (context) => ItemDetailsScreen(
            item: settings.arguments as WishlistItem,
          ),
        );
      } else {
        // Legacy support for Map arguments
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null) {
          debugPrint('⚠️ [AppRoutes] itemDetails: Null arguments, redirecting to main');
          return MaterialPageRoute(
            builder: (context) => MainNavigation(),
          );
        }
        
        // Deep link support: if only itemId is provided, create minimal WishlistItem
        // The screen will fetch full data in _fetchItemDetails
        if (args.containsKey('itemId') && args['fromDeepLink'] == true) {
          final itemId = args['itemId'] as String;
          return MaterialPageRoute(
            builder: (context) => ItemDetailsScreen(
              item: WishlistItem(
                id: itemId,
                wishlistId: '', // Will be fetched from API
                name: '', // Will be fetched from API
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            ),
          );
        }
        
        // Legacy support for full Map arguments
        return MaterialPageRoute(
          builder: (context) => ItemDetailsScreen(
            item: WishlistItem(
              id: args['id'] ?? '',
              wishlistId: args['wishlistId'] ?? '1',
              name: args['title'] ?? args['name'] ?? '',
              description: args['description'],
              imageUrl: args['imageUrl'],
              priority: ItemPriority.values.firstWhere(
                (e) => e.toString().split('.').last == args['priority'],
                orElse: () => ItemPriority.medium,
              ),
              status: ItemStatus.values.firstWhere(
                (e) => e.toString().split('.').last == args['status'],
                orElse: () => ItemStatus.desired,
              ),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ),
        );
      }
    } else if (settings.name == wishlistItemDetails) {
      final args = settings.arguments as WishlistItem;
      return MaterialPageRoute(
        builder: (context) => WishlistItemDetailsScreen(item: args),
      );
    } else if (settings.name == eventManagement) {
      final args = settings.arguments as EventSummary;
      return MaterialPageRoute(
        builder: (context) => EventManagementScreen(event: args),
      );
    } else if (settings.name == eventWishlist) {
      final args = settings.arguments as EventSummary;
      return MaterialPageRoute(
        builder: (context) => EventWishlistScreen(event: args),
      );
    } else if (settings.name == guestManagement) {
      final args = settings.arguments as EventSummary;
      return MaterialPageRoute(
        builder: (context) => GuestManagementScreen(event: args),
      );
    } else if (settings.name == eventSettings) {
      final args = settings.arguments as EventSummary;
      return MaterialPageRoute(
        builder: (context) => EventSettingsScreen(event: args),
      );
    } else if (settings.name == personalInformation) {
      final args = settings.arguments as Map<String, dynamic>;
      return MaterialPageRoute(
        builder: (context) => PersonalInformationScreen(userData: args),
      );
    } else if (settings.name == privacySecurity) {
      final args = settings.arguments as Map<String, dynamic>;
      return MaterialPageRoute(
        builder: (context) => PrivacySecurityScreen(privacySettings: args),
      );
    } else if (settings.name == changePassword) {
      return MaterialPageRoute(
        builder: (context) => const ChangePasswordScreen(),
      );
    } else if (settings.name == blockedUsers) {
      final args = settings.arguments as List<Map<String, dynamic>>;
      return MaterialPageRoute(
        builder: (context) => BlockedUsersScreen(blockedUsers: args),
      );
    } else if (settings.name == friendProfile) {
      final args = settings.arguments as Map<String, dynamic>;
      // Support both 'friendId' and 'userId' for backward compatibility
      final friendId = args['friendId'] ?? args['userId'] ?? '';
      return MaterialPageRoute(
        builder: (context) => FriendProfileScreen(friendId: friendId),
      );
    } else if (settings.name == eventDetails) {
      final args = settings.arguments as Map<String, dynamic>?;
      final eventId = args?['eventId']?.toString().trim();
      if (args == null || eventId == null || eventId.isEmpty) {
        debugPrint('⚠️ [AppRoutes] eventDetails: Invalid or missing eventId, redirecting to main');
        return MaterialPageRoute(
          builder: (context) => MainNavigation(),
        );
      }
      return MaterialPageRoute(
        builder: (context) => EventDetailsScreen(eventId: eventId),
      );
    } else if (settings.name == friendActivityFeed) {
      return MaterialPageRoute(
        builder: (context) => const ActivityFeedScreen(),
      );
    } else if (settings.name == eventGuestList) {
      final args = settings.arguments as Map<String, dynamic>;
      return MaterialPageRoute(
        builder: (context) => EventGuestListScreen(
          eventId: args['eventId'] ?? '',
          invitedFriends: args['invitedFriends'] as List<InvitedFriend>? ?? [],
        ),
      );
    } else if (settings.name == legalInfo) {
      final args = settings.arguments as Map<String, dynamic>?;
      // Support both 'type' (privacy/terms) and direct 'title'/'content' arguments
      final type = args?['type'] as String?;
      final title = args?['title'] as String?;
      final content = args?['content'] as String?;
      
      return MaterialPageRoute(
        builder: (context) => LegalInfoScreen(
          title: title ?? 'Legal Information',
          content: content ?? '',
          type: type, // Pass type to screen for localization lookup
        ),
      );
    } else if (settings.name == forgotPassword) {
      // Wrap ForgotPasswordScreen with BlocProvider to ensure AuthCubit is available
      return MaterialPageRoute(
        builder: (context) => BlocProvider<AuthCubit>(
          create: (context) => AuthCubit(),
          child: const ForgotPasswordScreen(),
        ),
      );
    } else if (settings.name == resetPassword) {
      final args = settings.arguments as Map<String, dynamic>?;
      final identifier = args?['identifier'] as String?;
      if (identifier != null && identifier.isNotEmpty) {
        return MaterialPageRoute(
          builder: (context) => BlocProvider<AuthCubit>(
            create: (context) => AuthCubit(),
            child: NewPasswordScreen(identifier: identifier),
          ),
        );
      }
      // If identifier is missing, redirect to forgot password or login
      return MaterialPageRoute(
        builder: (context) => BlocProvider<AuthCubit>(
          create: (context) => AuthCubit(),
          child: const ForgotPasswordScreen(),
        ),
      );
      } else if (settings.name == verification) {
        final args = settings.arguments as Map<String, dynamic>?;
        
        // Debug: Log route arguments for verification screen
        debugPrint('═══════════════════════════════════════════════════════');
        debugPrint('🛣️ [AppRoutes] Verification route called');
        debugPrint('🛣️ [AppRoutes] Username: ${args?['username']}');
        debugPrint('🛣️ [AppRoutes] Is Phone: ${args?['isPhone']}');
        debugPrint('🛣️ [AppRoutes] VerificationId: ${args?['verificationId']}');
        debugPrint('🛣️ [AppRoutes] VerificationId type: ${args?['verificationId'].runtimeType}');
        debugPrint('🛣️ [AppRoutes] VerificationId length: ${(args?['verificationId'] as String?)?.length ?? 0}');
        debugPrint('🛣️ [AppRoutes] UserId: ${args?['userId']}');
        debugPrint('═══════════════════════════════════════════════════════');
        
        return MaterialPageRoute(
          builder: (context) => BlocProvider<AuthCubit>(
            create: (context) => AuthCubit(repository: context.read<AuthRepository>()),
            child: VerificationScreen(
              username: args?['username'] ?? '',
              isPhone: args?['isPhone'] ?? false,
              verificationId: args?['verificationId'] as String?,
              userId: args?['userId'] as String?,
            ),
          ),
        );
      }

    return null;
  }

  // Navigation Helpers
  static void pushNamed(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  static void pushReplacementNamed(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    Navigator.pushReplacementNamed(context, routeName, arguments: arguments);
  }

  static void pushNamedAndRemoveUntil(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  static void pop(BuildContext context, [Object? result]) {
    Navigator.pop(context, result);
  }

  /// Safely pops the current route if possible, otherwise navigates to fallback route
  /// Returns true if popped, false if navigated to fallback
  static Future<bool> safePop(
    BuildContext context, {
    String? fallbackRoute,
  }) async {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return true;
    } else if (fallbackRoute != null) {
      pushNamedAndRemoveUntil(context, fallbackRoute);
      return false;
    }
    return false;
  }

  /// Safely pops with a specific fallback route
  /// Useful for screens that need to navigate to a specific screen when back is pressed
  static Future<bool> safePopWithFallback(
    BuildContext context,
    String fallbackRoute,
  ) async {
    return safePop(context, fallbackRoute: fallbackRoute);
  }

  // Custom page transitions
  static Route<T> slideTransition<T extends Object?>(
    Widget page,
    RouteSettings settings, {
    Offset begin = const Offset(1.0, 0.0),
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static Route<T> fadeTransition<T extends Object?>(
    Widget page,
    RouteSettings settings,
  ) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static Route<T> scaleTransition<T extends Object?>(
    Widget page,
    RouteSettings settings,
  ) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeInOutCubic;
        var scaleTween = Tween(
          begin: 0.8,
          end: 1.0,
        ).chain(CurveTween(curve: curve));
        var fadeTween = Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: curve));

        return ScaleTransition(
          scale: animation.drive(scaleTween),
          child: FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }
}
