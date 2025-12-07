import 'package:flutter/material.dart';
import 'package:wish_listy/core/widgets/splash_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
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
import '../../features/friends/presentation/screens/friends_screen.dart';
import '../../features/friends/presentation/screens/friend_profile_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/personal_information_screen.dart';
import '../../features/profile/presentation/screens/privacy_security_screen.dart';
import '../../features/profile/presentation/screens/blocked_users_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/events/presentation/screens/guest_management_screen.dart';
import '../../features/events/presentation/screens/event_settings_screen.dart';
import '../../features/wishlists/presentation/screens/wishlist_item_details_screen.dart';
import '../../features/wishlists/presentation/screens/create_wishlist_screen.dart';
import '../../features/friends/presentation/screens/add_friend_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/wishlists/data/models/wishlist_model.dart';
import '../../features/events/data/models/event_model.dart';

class AppRoutes {
  // Route Names
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
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
  static const String blockedUsers = '/blocked-users';
  static const String createWishlist = '/create-wishlist';
  static const String addFriend = '/add-friend';
  static const String editProfile = '/edit-profile';

  // Routes Map
  static Map<String, WidgetBuilder> routes = {
    splash: (context) => SplashScreen(),
    welcome: (context) => WelcomeScreen(),
    login: (context) => LoginScreen(),
    signup: (context) => SignupScreen(),
    forgotPassword: (context) => ForgotPasswordScreen(),
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
  };

  // Route Generator for dynamic routes
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    // Handle createWishlist route with optional wishlistId for editing
    if (settings.name == createWishlist) {
      final args = settings.arguments as Map<String, dynamic>?;
      final wishlistId = args?['wishlistId'] as String?;
      debugPrint('🔍 AppRoutes: createWishlist route');
      debugPrint('   Arguments: $args');
      debugPrint('   WishlistId: $wishlistId');
      return MaterialPageRoute(
        builder: (context) => CreateWishlistScreen(wishlistId: wishlistId),
      );
    } else if (settings.name == wishlistItems) {
      final args = settings.arguments as Map<String, dynamic>;
      return MaterialPageRoute(
        builder: (context) => WishlistItemsScreen(
          wishlistName: args['wishlistName'] ?? 'My Wishlist',
          wishlistId: args['wishlistId'] ?? '1',
          totalItems: args['totalItems'] ?? 0,
          purchasedItems: args['purchasedItems'] ?? 0,
          isFriendWishlist: args['isFriendWishlist'] ?? false,
          friendName: args['friendName'],
        ),
      );
    } else if (settings.name == itemDetails) {
      final args = settings.arguments as Map<String, dynamic>;
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
    } else if (settings.name == blockedUsers) {
      final args = settings.arguments as List<Map<String, dynamic>>;
      return MaterialPageRoute(
        builder: (context) => BlockedUsersScreen(blockedUsers: args),
      );
    } else if (settings.name == friendProfile) {
      final args = settings.arguments as Map<String, dynamic>;
      return MaterialPageRoute(
        builder: (context) =>
            FriendProfileScreen(friendId: args['friendId'] ?? ''),
      );
    } else if (settings.name == eventDetails) {
      final args = settings.arguments as Map<String, dynamic>;
      return MaterialPageRoute(
        builder: (context) =>
            EventDetailsScreen(eventId: args['eventId'] ?? ''),
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
