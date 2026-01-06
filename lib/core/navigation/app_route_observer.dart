import 'package:flutter/material.dart';

/// Global route observer used to listen for route visibility changes.
///
/// We use this to refresh IndexedStack tabs (Wishlists/Events/Friends/etc.)
/// when the user navigates back from a pushed screen (e.g., details/create).
final RouteObserver<PageRoute<dynamic>> appRouteObserver =
    RouteObserver<PageRoute<dynamic>>();


