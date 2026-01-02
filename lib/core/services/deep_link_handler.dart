import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:wish_listy/core/utils/app_routes.dart';

/// Service to handle deep links for the app
class DeepLinkHandler {
  static final DeepLinkHandler _instance = DeepLinkHandler._internal();
  factory DeepLinkHandler() => _instance;
  DeepLinkHandler._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  GlobalKey<NavigatorState>? _navigatorKey;
  RouteSettings? _pendingRoute;
  String? _pendingUriString;

  // Prevent double-handling the same link (common on Android/iOS where initialLink + stream fire)
  String? _lastHandledUriString;
  DateTime? _lastHandledAt;
  static const Duration _dedupeWindow = Duration(seconds: 3);

  /// Initialize deep link handling
  /// 
  /// [navigatorKey] is required to perform navigation without BuildContext
  void initialize(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    _handleInitialLink(navigatorKey);
    _handleIncomingLinks(navigatorKey);
  }

  /// Handle initial link (when app is opened from a deep link - cold start)
  Future<void> _handleInitialLink(GlobalKey<NavigatorState> navigatorKey) async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('🔗 Deep Link Handler: Initial link received: $initialUri');
        // IMPORTANT:
        // Don't navigate immediately here, because SplashScreen does a pushReplacement
        // after ~3s which would override any earlier navigation.
        // Instead, store the deep link and navigate AFTER the splash finishes.
        _pendingRoute = _routeSettingsFromUri(initialUri);
        _pendingUriString = initialUri.toString();
      }
    } catch (e) {
      debugPrint('❌ Deep Link Handler: Error getting initial link: $e');
    }
  }

  /// Handle incoming links (when app is already running - warm/hot start)
  void _handleIncomingLinks(GlobalKey<NavigatorState> navigatorKey) {
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        debugPrint('🔗 Deep Link Handler: Incoming link received: $uri');
        if (_shouldIgnoreUri(uri)) {
          debugPrint('🟡 Deep Link Handler: Ignoring duplicate incoming link: $uri');
          return;
        }
        _navigateFromDeepLink(uri, navigatorKey);
      },
      onError: (Object err) {
        debugPrint('❌ Deep Link Handler: Error in link stream: $err');
      },
    );
  }

  /// Call this after SplashScreen completes navigation to MainNavigation/Onboarding.
  /// If there is a pending deep link from cold start, it will be pushed now.
  void navigatePendingIfAny() {
    final pending = _pendingRoute;
    if (pending == null) return;

    final navigator = _navigatorKey?.currentState;
    if (navigator == null) {
      debugPrint('⚠️ Deep Link Handler: Cannot navigate pending link - navigator not ready');
      return;
    }

    debugPrint('🔗 Deep Link Handler: Navigating pending deep link to ${pending.name}');
    final pendingUriString = _pendingUriString;
    _pendingRoute = null; // consume
    _pendingUriString = null;
    if (pendingUriString != null) {
      _markHandled(pendingUriString);
    }
    navigator.pushNamed(
      pending.name ?? AppRoutes.mainNavigation,
      arguments: pending.arguments,
    );
  }

  /// Navigate based on deep link URI
  void _navigateFromDeepLink(Uri uri, GlobalKey<NavigatorState> navigatorKey) {
    // Accept:
    // - App Links / Universal Links: https://wish-listy-self.vercel.app/...
    // - Custom schemes (some browsers redirect to scheme when app is installed): wishlink://... or wishlisty://...
    if (!_isSupportedUri(uri)) {
      debugPrint('⚠️ Deep Link Handler: Ignoring unsupported URI: $uri');
      return;
    }

    // Wait for navigator to be ready (with retry logic)
    _navigateWhenReady(uri, navigatorKey, retries: 5);
  }

  /// Navigate when navigator is ready (with retry logic)
  void _navigateWhenReady(
    Uri uri,
    GlobalKey<NavigatorState> navigatorKey, {
    int retries = 5,
    int currentRetry = 0,
  }) {
    final navigator = navigatorKey.currentState;
    
    if (navigator == null) {
      if (currentRetry < retries) {
        debugPrint('⚠️ Deep Link Handler: Navigator not ready, retrying... (${currentRetry + 1}/$retries)');
        Future.delayed(Duration(milliseconds: 500), () {
          _navigateWhenReady(uri, navigatorKey, retries: retries, currentRetry: currentRetry + 1);
        });
      } else {
        debugPrint('❌ Deep Link Handler: Navigator not available after $retries retries');
      }
      return;
    }

    final path = _normalizedPath(uri);

    // Handle /wishlist/:id pattern
    final wishlistRegex = RegExp(r'^/wishlist/([^/]+)');
    final wishlistMatch = wishlistRegex.firstMatch(path);
    if (wishlistMatch != null) {
      final wishlistId = wishlistMatch.group(1) ?? '';
      if (wishlistId.isNotEmpty) {
        debugPrint('🔗 Deep Link Handler: Navigating to wishlist: $wishlistId');
        _markHandled(uri.toString());
        navigator.pushNamed(
          AppRoutes.wishlistItems,
          arguments: {
            'wishlistId': wishlistId,
            'wishlistName': 'Wishlist',
            'totalItems': 0,
            'purchasedItems': 0,
            'isFriendWishlist': false,
          },
        );
        return;
      }
    }

    // Handle /event/:id pattern
    final eventRegex = RegExp(r'^/event/([^/]+)');
    final eventMatch = eventRegex.firstMatch(path);
    if (eventMatch != null) {
      final eventId = eventMatch.group(1) ?? '';
      if (eventId.isNotEmpty) {
        debugPrint('🔗 Deep Link Handler: Navigating to event: $eventId');
        _markHandled(uri.toString());
        navigator.pushNamed(
          AppRoutes.eventDetails,
          arguments: {
            'eventId': eventId,
          },
        );
        return;
      }
    }

    // Handle /item/:id pattern
    final itemRegex = RegExp(r'^/item/([^/]+)');
    final itemMatch = itemRegex.firstMatch(path);
    if (itemMatch != null) {
      final itemId = itemMatch.group(1) ?? '';
      if (itemId.isNotEmpty) {
        debugPrint('🔗 Deep Link Handler: Navigating to item: $itemId');
        _markHandled(uri.toString());
        navigator.pushNamed(
          AppRoutes.itemDetails,
          arguments: {
            'itemId': itemId,
            'fromDeepLink': true,
          },
        );
        return;
      }
    }

    debugPrint('⚠️ Deep Link Handler: Unknown deep link path: $path');
  }

  RouteSettings? _routeSettingsFromUri(Uri uri) {
    if (!_isSupportedUri(uri)) return null;

    final path = _normalizedPath(uri);

    // /wishlist/:id -> WishlistItemsScreen (existing route)
    final wishlistMatch = RegExp(r'^/wishlist/([^/]+)').firstMatch(path);
    if (wishlistMatch != null) {
      final wishlistId = wishlistMatch.group(1) ?? '';
      if (wishlistId.isEmpty) return null;
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

    // /event/:id -> EventDetailsScreen (existing route)
    final eventMatch = RegExp(r'^/event/([^/]+)').firstMatch(path);
    if (eventMatch != null) {
      final eventId = eventMatch.group(1) ?? '';
      if (eventId.isEmpty) return null;
      return RouteSettings(
        name: AppRoutes.eventDetails,
        arguments: {'eventId': eventId},
      );
    }

    // /item/:id -> ItemDetailsScreen (existing route)
    final itemMatch = RegExp(r'^/item/([^/]+)').firstMatch(path);
    if (itemMatch != null) {
      final itemId = itemMatch.group(1) ?? '';
      if (itemId.isEmpty) return null;
      return RouteSettings(
        name: AppRoutes.itemDetails,
        arguments: {
          'itemId': itemId,
          'fromDeepLink': true,
        },
      );
    }

    return null;
  }

  bool _isSupportedUri(Uri uri) {
    // HTTPS/HTTP app links
    if (uri.scheme == 'https' || uri.scheme == 'http') {
      return uri.host == 'wish-listy-self.vercel.app';
    }

    // Custom schemes (landing page redirect, etc.)
    if (uri.scheme == 'wishlink' || uri.scheme == 'wishlisty') {
      return true;
    }

    return false;
  }

  /// Normalize paths across:
  /// - https://wish-listy-self.vercel.app/wishlist/123  -> /wishlist/123
  /// - wishlink://wishlist/123                         -> host=wishlist, path=/123 => /wishlist/123
  /// - wishlink:///wishlist/123                        -> host='', path=/wishlist/123 => /wishlist/123
  String _normalizedPath(Uri uri) {
    final rawPath = uri.path;

    // Custom scheme often uses the "host" as first segment.
    if ((uri.scheme == 'wishlink' || uri.scheme == 'wishlisty') &&
        (rawPath.isEmpty || rawPath == '/')) {
      final host = uri.host;
      if (host.isNotEmpty) return '/$host';
      return '/';
    }

    if (uri.scheme == 'wishlink' || uri.scheme == 'wishlisty') {
      final host = uri.host;
      // wishlink://wishlist/123  => host=wishlist, path=/123
      if (host.isNotEmpty && rawPath.isNotEmpty && rawPath != '/') {
        return '/$host$rawPath';
      }
      // wishlink:///wishlist/123 => host empty, path already has segments
      return rawPath.isNotEmpty ? rawPath : '/';
    }

    // http/https
    return rawPath.isNotEmpty ? rawPath : '/';
  }

  bool _shouldIgnoreUri(Uri uri) {
    final uriString = uri.toString();

    // If we have a pending link from cold start, ignore the same link coming from stream
    if (_pendingUriString != null && _pendingUriString == uriString) {
      return true;
    }

    // Dedupe any repeat link within the window
    if (_lastHandledUriString == uriString && _lastHandledAt != null) {
      final diff = DateTime.now().difference(_lastHandledAt!);
      if (diff <= _dedupeWindow) return true;
    }

    return false;
  }

  void _markHandled(String uriString) {
    _lastHandledUriString = uriString;
    _lastHandledAt = DateTime.now();
  }

  /// Dispose resources
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    _pendingRoute = null;
    _pendingUriString = null;
    _navigatorKey = null;
    _lastHandledUriString = null;
    _lastHandledAt = null;
  }
}

