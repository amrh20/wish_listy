import 'package:flutter/material.dart';
import 'app_routes.dart';
import '../features/wishlists/presentation/screens/wishlist_items_screen.dart';
import '../features/events/presentation/screens/event_details_screen.dart';

/// Helper class to parse deep link URLs and convert them to app routes
class DeepLinkHelper {
  /// Parse a deep link URI and return RouteSettings
  /// 
  /// Supports:
  /// - https://wish-listy-self.vercel.app/wishlist/:id
  /// - https://wish-listy-self.vercel.app/event/:id
  static RouteSettings? parseDeepLinkUri(Uri uri) {
    // Only handle our domain
    if (uri.host != 'wish-listy-self.vercel.app') {
      return null;
    }

    final path = uri.path;
    
    // Handle /wishlist/:id pattern
    final wishlistRegex = RegExp(r'^/wishlist/([^/]+)');
    final wishlistMatch = wishlistRegex.firstMatch(path);
    if (wishlistMatch != null) {
      final wishlistId = wishlistMatch.group(1) ?? '';
      return RouteSettings(
        name: AppRoutes.wishlistItems,
        arguments: {
          'wishlistId': wishlistId,
          'wishlistName': 'Wishlist',
          'totalItems': 0,
          'purchasedItems': 0,
          'isFriendWishlist': false,
        },
      );
    }

    // Handle /event/:id pattern
    final eventRegex = RegExp(r'^/event/([^/]+)');
    final eventMatch = eventRegex.firstMatch(path);
    if (eventMatch != null) {
      final eventId = eventMatch.group(1) ?? '';
      return RouteSettings(
        name: AppRoutes.eventDetails,
        arguments: {
          'eventId': eventId,
        },
      );
    }

    return null;
  }

  /// Parse a deep link URL string and return RouteSettings
  static RouteSettings? parseDeepLinkUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return parseDeepLinkUri(uri);
    } catch (e) {
      return null;
    }
  }
}

