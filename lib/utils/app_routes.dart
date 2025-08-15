


import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/main/home_screen.dart';
import '../screens/main/main_navigation.dart';
import '../screens/wishlists/my_wishlists_screen.dart';
import '../screens/wishlists/add_item_screen.dart';
import '../screens/wishlists/wishlist_items_screen.dart';
import '../screens/wishlists/item_details_screen.dart';
import '../screens/events/events_screen.dart';
import '../screens/events/create_event_screen.dart';
import '../screens/events/event_details_screen.dart';
import '../screens/events/event_management_screen.dart';
import '../screens/events/event_wishlist_screen.dart';
import '../screens/friends/friends_screen.dart';
import '../screens/friends/friend_profile_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/events/guest_management_screen.dart';
import '../screens/events/event_settings_screen.dart';
import '../screens/wishlists/wishlist_item_details_screen.dart';
import '../models/event.dart';
import '../models/event_model.dart';
import '../models/wishlist_model.dart';

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
  };

  // Route Generator for dynamic routes
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    if (settings.name == wishlistItems) {
      final args = settings.arguments as Map<String, dynamic>;
      return MaterialPageRoute(
        builder: (context) => WishlistItemsScreen(
          wishlistName: args['wishlistName'] ?? 'My Wishlist',
          wishlistId: args['wishlistId'] ?? '1',
          totalItems: args['totalItems'] ?? 0,
          purchasedItems: args['purchasedItems'] ?? 0,
          totalValue: args['totalValue'] ?? 0.0,
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
              status: ItemStatus.desired,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ),
      );
    } else if (settings.name == wishlistItemDetails) {
      final args = settings.arguments as WishlistItemPreview;
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
    } else if (settings.name == friendProfile) {
      final args = settings.arguments as Map<String, dynamic>;
      return MaterialPageRoute(
        builder: (context) => FriendProfileScreen(
          friendId: args['friendId'] ?? '',
        ),
      );
    } else if (settings.name == eventDetails) {
      final args = settings.arguments as Map<String, dynamic>;
      return MaterialPageRoute(
        builder: (context) => EventDetailsScreen(eventId: args['eventId'] ?? ''),
      );
    }
    
    return null;
  }

  // Navigation Helpers
  static void pushNamed(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  static void pushReplacementNamed(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushReplacementNamed(context, routeName, arguments: arguments);
  }

  static void pushNamedAndRemoveUntil(BuildContext context, String routeName, {Object? arguments}) {
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

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static Route<T> fadeTransition<T extends Object?>(Widget page, RouteSettings settings) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  static Route<T> scaleTransition<T extends Object?>(Widget page, RouteSettings settings) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeInOutCubic;
        var scaleTween = Tween(begin: 0.8, end: 1.0).chain(
          CurveTween(curve: curve),
        );
        var fadeTween = Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: curve),
        );

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