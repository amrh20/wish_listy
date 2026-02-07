import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wish_listy/core/utils/app_routes.dart';

/// Service for handling deep link sharing and URL generation
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  GlobalKey<NavigatorState>? _navigatorKey;
  RouteSettings? _pendingRoute;
  String? _pendingUriString;

  // Prevent double-handling the same link (initialLink + stream can both fire)
  String? _lastHandledUriString;
  DateTime? _lastHandledAt;
  static const Duration _dedupeWindow = Duration(seconds: 3);

  /// Base domain for deep links
  static const String baseDomain = 'wish-listy-self.vercel.app';

  /// Base URL for deep links
  static const String baseUrl = 'https://$baseDomain';

  /// Generates a deep link URL for a wishlist or event
  /// 
  /// [type] should be 'wishlist' or 'event'
  /// [id] is the unique identifier for the wishlist or event
  static String generateDeepLinkUrl(String type, String id) {
    return '$baseUrl/$type/$id';
  }

  /// Initialize deep link receiving (cold start + warm start stream)
  /// Must be called once (we call it from main.dart).
  void initialize(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    _handleInitialLink();
    _handleIncomingLinks();
  }

  Future<void> _handleInitialLink() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri == null) return;

      // Debug log (Cold Start)
      // ignore: avoid_print

      // Store pending route for cold start to avoid being overridden by SplashScreen pushReplacement.
      _pendingRoute = _routeSettingsFromUri(initialUri);
      _pendingUriString = initialUri.toString();
    } catch (e) {
    }
  }

  void _handleIncomingLinks() {
    _linkSubscription?.cancel();
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        // Debug log (Warm Start / Foreground / Background)
        // ignore: avoid_print
        if (_shouldIgnoreUri(uri)) {
          return;
        }
        // Safety: give the UI a tiny moment to resume/rebuild before navigating.
        Future.delayed(const Duration(milliseconds: 200), () {
          handleDeepLink(uri);
        });
      },
      onError: (Object err) {
      },
    );
  }

  /// Call after SplashScreen completes navigation to MainNavigation/Onboarding.
  void navigatePendingIfAny() {
    final pending = _pendingRoute;
    if (pending == null) return;

    final navigator = _navigatorKey?.currentState;
    if (navigator == null) {
      return;
    }

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

  /// Unified navigation logic for warm start (stream) and any manual calls.
  void handleDeepLink(Uri uri) {
    if (!_isSupportedUri(uri)) {
      return;
    }

    final navigator = _navigatorKey?.currentState;
    if (navigator == null) {
      _pendingRoute = _routeSettingsFromUri(uri);
      _pendingUriString = uri.toString();
      return;
    }

    final path = _normalizedPath(uri);

    // /wishlist/:id
    final wishlistMatch = RegExp(r'^/wishlist/([^/]+)').firstMatch(path);
    if (wishlistMatch != null) {
      final wishlistId = wishlistMatch.group(1) ?? '';
      if (wishlistId.isEmpty) return;
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

    // /event/:id
    final eventMatch = RegExp(r'^/event/([^/]+)').firstMatch(path);
    if (eventMatch != null) {
      final eventId = eventMatch.group(1) ?? '';
      if (eventId.isEmpty) return;
      _markHandled(uri.toString());
      navigator.pushNamed(
        AppRoutes.eventDetails,
        arguments: {'eventId': eventId},
      );
      return;
    }

    // /item/:id
    final itemMatch = RegExp(r'^/item/([^/]+)').firstMatch(path);
    if (itemMatch != null) {
      final itemId = itemMatch.group(1) ?? '';
      if (itemId.isEmpty) return;
      _markHandled(uri.toString());
      navigator.pushNamed(
        AppRoutes.itemDetails,
        arguments: {'itemId': itemId, 'fromDeepLink': true},
      );
      return;
    }

    // /reset-password?token=...
    if (path == '/reset-password') {
      final token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        _markHandled(uri.toString());
        navigator.pushNamed(
          AppRoutes.resetPassword,
          arguments: {'token': token},
        );
        return;
      } else {
        return;
      }
    }

  }

  RouteSettings? _routeSettingsFromUri(Uri uri) {
    if (!_isSupportedUri(uri)) return null;

    final path = _normalizedPath(uri);

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

    final eventMatch = RegExp(r'^/event/([^/]+)').firstMatch(path);
    if (eventMatch != null) {
      final eventId = eventMatch.group(1) ?? '';
      if (eventId.isEmpty) return null;
      return RouteSettings(name: AppRoutes.eventDetails, arguments: {'eventId': eventId});
    }

    final itemMatch = RegExp(r'^/item/([^/]+)').firstMatch(path);
    if (itemMatch != null) {
      final itemId = itemMatch.group(1) ?? '';
      if (itemId.isEmpty) return null;
      return RouteSettings(
        name: AppRoutes.itemDetails,
        arguments: {'itemId': itemId, 'fromDeepLink': true},
      );
    }

    // /reset-password?token=...
    if (path == '/reset-password') {
      final token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        return RouteSettings(
          name: AppRoutes.resetPassword,
          arguments: {'token': token},
        );
      }
      return null;
    }

    return null;
  }

  bool _shouldIgnoreUri(Uri uri) {
    final uriString = uri.toString();

    // If we have a pending link from cold start, ignore the same link coming from stream
    if (_pendingUriString != null && _pendingUriString == uriString) return true;

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

  bool _isSupportedUri(Uri uri) {
    if (uri.scheme == 'https' || uri.scheme == 'http') {
      return uri.host == baseDomain;
    }
    if (uri.scheme == 'wishlink' || uri.scheme == 'wishlisty') {
      return true;
    }
    return false;
  }

  String _normalizedPath(Uri uri) {
    final rawPath = uri.path;

    // Custom scheme may use host as first segment (wishlink://wishlist/123)
    if ((uri.scheme == 'wishlink' || uri.scheme == 'wishlisty') &&
        (rawPath.isEmpty || rawPath == '/')) {
      final host = uri.host;
      if (host.isNotEmpty) return '/$host';
      return '/';
    }

    if (uri.scheme == 'wishlink' || uri.scheme == 'wishlisty') {
      final host = uri.host;
      if (host.isNotEmpty && rawPath.isNotEmpty && rawPath != '/') {
        return '/$host$rawPath';
      }
      return rawPath.isNotEmpty ? rawPath : '/';
    }

    return rawPath.isNotEmpty ? rawPath : '/';
  }

  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    _navigatorKey = null;
    _pendingRoute = null;
    _pendingUriString = null;
    _lastHandledUriString = null;
    _lastHandledAt = null;
  }

  /// Shares a wishlist or event via deep link
  /// 
  /// [type] should be 'wishlist' or 'event'
  /// [id] is the unique identifier for the wishlist or event
  /// [entityName] is the display name (e.g., "Birthday Wishlist" or "Summer Party")
  /// 
  /// Returns a Future that completes when the share dialog is shown
  static Future<void> shareEntity({
    required String type,
    required String id,
    String? entityName,
  }) async {
    final url = generateDeepLinkUrl(type, id);
    
    // Create share message
    final entityDisplayName = entityName ?? type.capitalize();
    final message = 'Check out my $entityDisplayName on Wish Listy: $url';
    
    // Share the link
    await Share.share(
      message,
      subject: 'Wish Listy - $entityDisplayName',
    );
  }

  /// Shares a wishlist via deep link
  static Future<void> shareWishlist({
    required String wishlistId,
    String? wishlistName,
  }) async {
    return shareEntity(
      type: 'wishlist',
      id: wishlistId,
      entityName: wishlistName,
    );
  }

  /// Shares an event via deep link
  static Future<void> shareEvent({
    required String eventId,
    String? eventName,
  }) async {
    return shareEntity(
      type: 'event',
      id: eventId,
      entityName: eventName,
    );
  }

  /// Shares an item via deep link
  static Future<void> shareItem({
    required String itemId,
    String? itemName,
  }) async {
    return shareEntity(
      type: 'item',
      id: itemId,
      entityName: itemName,
    );
  }
}

/// Extension to capitalize first letter of a string
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

