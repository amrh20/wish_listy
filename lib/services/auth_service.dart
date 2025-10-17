import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UserState { guest, authenticated, loading }

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  UserState _userState = UserState.loading;
  String? _userId;
  String? _userEmail;
  String? _userName;

  // Getters
  UserState get userState => _userState;
  bool get isGuest => _userState == UserState.guest;
  bool get isAuthenticated => _userState == UserState.authenticated;
  bool get isLoading => _userState == UserState.loading;
  String? get userId => _userId;
  String? get userEmail => _userEmail;
  String? get userName => _userName;

  // Initialize auth state
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

      if (isLoggedIn) {
        _userId = prefs.getString('user_id');
        _userEmail = prefs.getString('user_email');
        _userName = prefs.getString('user_name');
        _userState = UserState.authenticated;
      } else {
        _userState = UserState.guest;
      }
    } catch (e) {
      _userState = UserState.guest;
    }
    notifyListeners();
  }

  // Login as guest (from "Get Started" button)
  Future<void> loginAsGuest() async {
    _userState = UserState.guest;
    _userId = null;
    _userEmail = null;
    _userName = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    await prefs.remove('user_id');
    await prefs.remove('user_email');
    await prefs.remove('user_name');

    notifyListeners();
  }

  // Login with credentials
  Future<bool> login(String email, String password) async {
    try {
      // Simulate API call - accept any credentials for now
      await Future.delayed(const Duration(seconds: 2));

      _userState = UserState.authenticated;
      _userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      _userEmail = email;
      _userName = email.split('@').first;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('user_id', _userId!);
      await prefs.setString('user_email', _userEmail!);
      await prefs.setString('user_name', _userName!);

      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _userState = UserState.guest;
    _userId = null;
    _userEmail = null;
    _userName = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    await prefs.remove('user_id');
    await prefs.remove('user_email');
    await prefs.remove('user_name');

    notifyListeners();
  }

  // Check if a feature is available for current user
  bool isFeatureAvailable(String feature) {
    if (isAuthenticated) return true;

    // Features available for guest users
    const guestFeatures = {
      'home_view',
      'browse_public_wishlists',
      'view_public_events',
      'language_switcher',
      'browse_friends_public_profiles',
    };

    return guestFeatures.contains(feature);
  }

  // Get restricted message for guests
  String getGuestRestrictionMessage() {
    return 'This feature requires login. Please sign in to continue.';
  }
}
