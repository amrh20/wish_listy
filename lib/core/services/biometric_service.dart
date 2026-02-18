import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:wish_listy/core/services/localization_service.dart';
import 'package:wish_listy/core/constants/app_colors.dart';

/// BiometricService - Bank-grade secure authentication service
///
/// Security Architecture:
/// - Uses biometrics to gate access to stored authentication tokens
/// - Tokens are stored in flutter_secure_storage (encrypted Keychain/Keystore)
/// - Token is ONLY retrieved after successful biometric verification
/// - No simple boolean flags - biometrics are required for token access
///
/// Flow:
/// 1. User logs in manually → Token is saved securely
/// 2. On next app launch → Biometric prompt appears
/// 3. If biometric succeeds → Token is retrieved and user is logged in
/// 4. If biometric fails/cancelled → User must login manually again
class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    // iOS: Use first unlock only for maximum security
    // Token is only accessible after device is unlocked
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // Storage key prefixes - MUST be consistent across save and read operations
  // Keys are now dynamic based on user identifier (email or phone)
  static const String _tokenKeyPrefix = 'biometric_token_';
  static const String _refreshTokenKeyPrefix = 'biometric_refresh_token_';
  static const String _enabledKeyPrefix = 'biometric_enabled_';
  static const String _userIdKeyPrefix = 'biometric_user_id_';
  static const String _userNameKeyPrefix = 'biometric_user_name_';

  /// Generate storage key for token based on identifier (email or phone)
  String _getTokenKey(String identifier) {
    final sanitized = _sanitizeIdentifier(identifier);
    return '$_tokenKeyPrefix$sanitized';
  }

  /// Generate storage key for refresh token based on identifier
  String _getRefreshTokenKey(String identifier) {
    final sanitized = _sanitizeIdentifier(identifier);
    return '$_refreshTokenKeyPrefix$sanitized';
  }

  /// Generate storage key for enabled flag based on identifier
  String _getEnabledKey(String identifier) {
    final sanitized = _sanitizeIdentifier(identifier);
    return '$_enabledKeyPrefix$sanitized';
  }

  /// Generate storage key for user ID based on identifier
  String _getUserIdKey(String identifier) {
    final sanitized = _sanitizeIdentifier(identifier);
    return '$_userIdKeyPrefix$sanitized';
  }

  /// Generate storage key for user name based on identifier
  String _getUserNameKey(String identifier) {
    final sanitized = _sanitizeIdentifier(identifier);
    return '$_userNameKeyPrefix$sanitized';
  }

  /// Sanitize identifier by trimming whitespace, converting to lowercase,
  /// and normalizing Arabic numbers (٠-٩) to English numbers (0-9)
  /// This ensures consistent key generation regardless of input format
  String _sanitizeIdentifier(String identifier) {
    String normalized = identifier.trim().toLowerCase();
    
    // Normalize Arabic numbers to English numbers
    normalized = normalized
        .replaceAll('٠', '0')
        .replaceAll('١', '1')
        .replaceAll('٢', '2')
        .replaceAll('٣', '3')
        .replaceAll('٤', '4')
        .replaceAll('٥', '5')
        .replaceAll('٦', '6')
        .replaceAll('٧', '7')
        .replaceAll('٨', '8')
        .replaceAll('٩', '9');
    
    return normalized;
  }

  /// Check if biometric authentication is available on the device
  /// Returns true if hardware supports it AND user has enrolled biometrics
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!isDeviceSupported || !canCheckBiometrics) {
        return false;
      }

      // Check if user has enrolled biometrics
      final List<BiometricType> availableBiometrics = await _localAuth
          .getAvailableBiometrics();

      return availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get the type of biometric available (Fingerprint, Face, etc.)
  Future<String> getBiometricType() async {
    try {
      final List<BiometricType> availableBiometrics = await _localAuth
          .getAvailableBiometrics();

      if (availableBiometrics.contains(BiometricType.face)) {
        return 'Face ID';
      } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
        return 'Fingerprint';
      } else if (availableBiometrics.contains(BiometricType.strong)) {
        return 'Biometric';
      } else if (availableBiometrics.contains(BiometricType.weak)) {
        return 'Biometric';
      }

      return 'Biometric';
    } catch (e) {
      return 'Biometric';
    }
  }

  /// Check if biometric login is enabled for a specific identifier (email or phone)
  /// This is the main method to use - checks for an exact match
  Future<bool> isEnabledForIdentifier(String identifier) async {
    try {
      if (identifier.trim().isEmpty) {
        return false;
      }

      final key = _getEnabledKey(identifier);
      final enabled = await _secureStorage.read(key: key);
      final result = enabled == 'true';

      return result;
    } catch (e) {
      return false;
    }
  }

  /// Legacy method - kept for backward compatibility
  /// Returns true if ANY biometric is enabled on this device
  @Deprecated('Use isEnabledForIdentifier instead')
  Future<bool> isBiometricEnabled() async {
    try {
      // Check for legacy keys
      final allKeys = await _secureStorage.readAll();
      final hasAnyEnabled = allKeys.entries.any(
        (entry) =>
            entry.key.startsWith(_enabledKeyPrefix) && entry.value == 'true',
      );
      return hasAnyEnabled;
    } catch (e) {
      return false;
    }
  }

  /// Check if stored token exists for a specific identifier
  Future<bool> hasStoredTokenForIdentifier(String identifier) async {
    try {
      if (identifier.trim().isEmpty) {
        return false;
      }

      final key = _getTokenKey(identifier);
      final token = await _secureStorage.read(key: key);
      final exists = token != null && token.isNotEmpty;

      return exists;
    } catch (e) {
      return false;
    }
  }

  /// Save authentication tokens securely after successful manual login
  /// This should be called ONLY after a successful API login
  /// Returns true if token, flag, and user data were saved successfully
  ///
  /// @param token The access token from the API
  /// @param identifier The user's email or phone number (will be sanitized)
  /// @param refreshToken Optional refresh token; if provided, stored for use after biometric login
  /// @param userId Optional user ID to store for biometric login
  /// @param userName Optional user name to store for biometric login
  Future<bool> saveTokenSecurely(
    String token, {
    required String identifier,
    String? refreshToken,
    String? userId,
    String? userName,
  }) async {
    try {
      if (token.isEmpty) {
        return false;
      }

      if (identifier.trim().isEmpty) {
        return false;
      }

      final tokenKey = _getTokenKey(identifier);
      final refreshTokenKey = _getRefreshTokenKey(identifier);
      final enabledKey = _getEnabledKey(identifier);
      final userIdKey = _getUserIdKey(identifier);
      final userNameKey = _getUserNameKey(identifier);

      // Save access token
      await _secureStorage.write(key: tokenKey, value: token);

      // Save refresh token if provided (required for 401 interceptor to refresh after biometric login)
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _secureStorage.write(key: refreshTokenKey, value: refreshToken);
      }

      // Save enabled flag
      await _secureStorage.write(key: enabledKey, value: 'true');

      // Save user ID if provided
      if (userId != null && userId.isNotEmpty) {
        await _secureStorage.write(key: userIdKey, value: userId);
      }

      // Save user name if provided
      if (userName != null && userName.isNotEmpty) {
        await _secureStorage.write(key: userNameKey, value: userName);
      }

      // Verify token and flag were saved
      final savedToken = await _secureStorage.read(key: tokenKey);
      final savedFlag = await _secureStorage.read(key: enabledKey);

      final success = savedToken == token && savedFlag == 'true';

      return success;
    } catch (e) {
      return false;
    }
  }

  /// @deprecated - Use getStoredTokenForIdentifier instead
  /// This is a legacy method kept for backward compatibility  
  Future<String?> getStoredToken({
    required BuildContext context,
    String? reason,
  }) async {
    return null;
  }
  
  /// Retrieve stored token for a specific identifier
  /// This method should be called AFTER authenticate() succeeds
  /// Returns null if token doesn't exist
  /// 
  /// @param identifier The user's email or phone number
  Future<String?> getStoredTokenForIdentifier(String identifier) async {
    try {
      if (identifier.trim().isEmpty) {
        return null;
      }
      
      final tokenKey = _getTokenKey(identifier);
      final sanitized = _sanitizeIdentifier(identifier);
      
      // Check if biometric is enabled for this identifier
      final isEnabled = await isEnabledForIdentifier(identifier);
      if (!isEnabled) {
        return null;
      }
      
      // Retrieve token
      final token = await _secureStorage.read(key: tokenKey);
      if (token == null || token.isEmpty) {
        
        // List all keys for debugging
        try {
          final allKeys = await _secureStorage.readAll();
          final biometricKeys = allKeys.keys
              .where((k) => k.startsWith(_tokenKeyPrefix) || k.startsWith(_enabledKeyPrefix))
              .toList();
        } catch (e) {
        }
        
        return null;
      }

      
      return token;
    } catch (e) {
      return null;
    }
  }

  /// Retrieve all stored credentials (token, refreshToken, userId, userName) for a specific identifier
  /// Returns a map with 'token', 'refreshToken' (if stored), 'userId', and 'userName' keys, or null if not found
  ///
  /// @param identifier The user's email or phone number
  Future<Map<String, String>?> getStoredCredentialsForIdentifier(String identifier) async {
    try {
      if (identifier.trim().isEmpty) {
        return null;
      }

      // Check if biometric is enabled for this identifier
      final isEnabled = await isEnabledForIdentifier(identifier);
      if (!isEnabled) {
        return null;
      }

      final tokenKey = _getTokenKey(identifier);
      final refreshTokenKey = _getRefreshTokenKey(identifier);
      final userIdKey = _getUserIdKey(identifier);
      final userNameKey = _getUserNameKey(identifier);

      // Retrieve all credentials
      final token = await _secureStorage.read(key: tokenKey);
      final refreshToken = await _secureStorage.read(key: refreshTokenKey);
      final userId = await _secureStorage.read(key: userIdKey);
      final userName = await _secureStorage.read(key: userNameKey);

      if (token == null || token.isEmpty) {
        return null;
      }

      return {
        'token': token,
        if (refreshToken != null && refreshToken.isNotEmpty) 'refreshToken': refreshToken,
        if (userId != null && userId.isNotEmpty) 'userId': userId,
        if (userName != null && userName.isNotEmpty) 'userName': userName,
      };
    } catch (e) {
      return null;
    }
  }

  /// Authenticate user with biometrics (without retrieving token)
  /// Useful for re-authentication during sensitive operations
  Future<bool> authenticate({
    required BuildContext context,
    String? reason,
  }) async {
    try {
      final localization = Provider.of<LocalizationService>(
        context,
        listen: false,
      );
      final isArabic = localization.currentLanguage == 'ar';

      final reasonText =
          reason ??
          (isArabic
              ? 'يرجى التحقق من هويتك للمتابعة'
              : 'Please verify your identity to continue');

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reasonText,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      return didAuthenticate;
    } catch (e) {
      return false;
    }
  }

  /// Delete stored token but KEEP biometric_enabled flag
  // These legacy methods are kept for backward compatibility but are deprecated
  // Use the identifier-specific methods instead

  /// @deprecated Use clearStoredTokenForIdentifier instead
  Future<void> clearStoredToken() async {
    // This is now a no-op - use clearStoredTokenForIdentifier
  }
  
  /// Clear stored token for a specific identifier (on logout)
  /// This preserves the enabled flag so user doesn't need to re-enable
  Future<void> clearStoredTokenForIdentifier(String identifier) async {
    try {
      if (identifier.trim().isEmpty) {
        return;
      }

      final tokenKey = _getTokenKey(identifier);
      final refreshTokenKey = _getRefreshTokenKey(identifier);

      await _secureStorage.delete(key: tokenKey);
      await _secureStorage.delete(key: refreshTokenKey);
    } catch (e) {
    }
  }
  
  /// Delete ALL biometric data for a specific identifier
  /// Use this when user explicitly disables biometric login
  Future<void> clearBiometricDataForIdentifier(String identifier) async {
    try {
      if (identifier.trim().isEmpty) {
        return;
      }

      final tokenKey = _getTokenKey(identifier);
      final refreshTokenKey = _getRefreshTokenKey(identifier);
      final enabledKey = _getEnabledKey(identifier);
      final userIdKey = _getUserIdKey(identifier);
      final userNameKey = _getUserNameKey(identifier);

      await _secureStorage.delete(key: tokenKey);
      await _secureStorage.delete(key: refreshTokenKey);
      await _secureStorage.delete(key: enabledKey);
      await _secureStorage.delete(key: userIdKey);
      await _secureStorage.delete(key: userNameKey);
    } catch (e) {
    }
  }

  /// Delete ALL biometric data for all identifiers
  /// Use this for account deletion or complete reset
  Future<void> clearAllBiometricData() async {
    try {
      final allKeys = await _secureStorage.readAll();
      final biometricKeys = allKeys.keys.where(
        (key) => key.startsWith(_tokenKeyPrefix) ||
                 key.startsWith(_refreshTokenKeyPrefix) ||
                 key.startsWith(_enabledKeyPrefix) ||
                 key.startsWith(_userIdKeyPrefix) ||
                 key.startsWith(_userNameKeyPrefix),
      ).toList();
      
      
      for (final key in biometricKeys) {
        await _secureStorage.delete(key: key);
      }
      
    } catch (e) {
    }
  }

  /// Get user-friendly error message for biometric failures
  String getErrorMessage(String errorCode, BuildContext context) {
    final localization = Provider.of<LocalizationService>(
      context,
      listen: false,
    );
    final isArabic = localization.currentLanguage == 'ar';

    switch (errorCode) {
      case 'NotAvailable':
        return isArabic
            ? 'المصادقة البيومترية غير متاحة على هذا الجهاز'
            : 'Biometric authentication is not available on this device';
      case 'NotEnrolled':
        return isArabic
            ? 'يرجى إعداد البصمة أو Face ID في إعدادات الجهاز'
            : 'Please set up fingerprint or Face ID in device settings';
      case 'LockedOut':
        return isArabic
            ? 'تم تعطيل المصادقة البيومترية مؤقتاً. حاول مرة أخرى لاحقاً'
            : 'Biometric authentication is temporarily disabled. Try again later';
      case 'PermanentlyLockedOut':
        return isArabic
            ? 'تم تعطيل المصادقة البيومترية بشكل دائم. يرجى استخدام كلمة المرور'
            : 'Biometric authentication is permanently disabled. Please use password';
      case 'UserCancel':
        return isArabic ? 'تم إلغاء المصادقة' : 'Authentication cancelled';
      default:
        return isArabic
            ? 'فشلت المصادقة البيومترية. يرجى المحاولة مرة أخرى'
            : 'Biometric authentication failed. Please try again';
    }
  }
}
