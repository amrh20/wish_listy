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
  static const String _enabledKeyPrefix = 'biometric_enabled_';
  static const String _userIdKeyPrefix = 'biometric_user_id_';
  static const String _userNameKeyPrefix = 'biometric_user_name_';

  /// Generate storage key for token based on identifier (email or phone)
  String _getTokenKey(String identifier) {
    final sanitized = _sanitizeIdentifier(identifier);
    return '$_tokenKeyPrefix$sanitized';
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

  /// Sanitize identifier by trimming whitespace and converting to lowercase
  /// This ensures consistent key generation
  String _sanitizeIdentifier(String identifier) {
    return identifier.trim().toLowerCase();
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
      debugPrint('❌ [BiometricService] Error checking availability: $e');
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
      debugPrint('❌ [BiometricService] Error getting biometric type: $e');
      return 'Biometric';
    }
  }

  /// Check if biometric login is enabled for a specific identifier (email or phone)
  /// This is the main method to use - checks for an exact match
  Future<bool> isEnabledForIdentifier(String identifier) async {
    try {
      if (identifier.trim().isEmpty) {
        debugPrint('⚠️ [BiometricService] Empty identifier provided');
        return false;
      }

      final key = _getEnabledKey(identifier);
      final enabled = await _secureStorage.read(key: key);
      final result = enabled == 'true';

      debugPrint('🔍 [BiometricService] isEnabledForIdentifier: $result');
      debugPrint('   📧 Identifier: ${_sanitizeIdentifier(identifier)}');
      debugPrint('   🔑 Key: $key');
      debugPrint('   ✅ Stored value: $enabled');

      return result;
    } catch (e) {
      debugPrint('❌ [BiometricService] Error checking if enabled: $e');
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
      debugPrint('❌ [BiometricService] Error checking legacy enabled: $e');
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

      debugPrint('🔍 [BiometricService] hasStoredTokenForIdentifier: $exists');
      debugPrint('   📧 Identifier: ${_sanitizeIdentifier(identifier)}');
      debugPrint('   🔑 Key: $key');

      return exists;
    } catch (e) {
      debugPrint('❌ [BiometricService] Error checking stored token: $e');
      return false;
    }
  }

  /// Save authentication token securely after successful manual login
  /// This should be called ONLY after a successful API login
  /// Returns true if token, flag, and user data were saved successfully
  ///
  /// @param token The authentication token from the API
  /// @param identifier The user's email or phone number (will be sanitized)
  /// @param userId Optional user ID to store for biometric login
  /// @param userName Optional user name to store for biometric login
  Future<bool> saveTokenSecurely(
    String token, {
    required String identifier,
    String? userId,
    String? userName,
  }) async {
    try {
      if (token.isEmpty) {
        debugPrint('❌ [BiometricService] Cannot save empty token');
        return false;
      }

      if (identifier.trim().isEmpty) {
        debugPrint('❌ [BiometricService] Cannot save without identifier');
        return false;
      }

      final tokenKey = _getTokenKey(identifier);
      final enabledKey = _getEnabledKey(identifier);
      final userIdKey = _getUserIdKey(identifier);
      final userNameKey = _getUserNameKey(identifier);
      final sanitized = _sanitizeIdentifier(identifier);

      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('🔐 [BiometricService] Saving biometric credentials');
      debugPrint('   📧 Identifier: $sanitized');
      debugPrint('   🔑 Token key: $tokenKey');
      debugPrint('   🔑 Enabled key: $enabledKey');
      debugPrint('   🔑 User ID key: $userIdKey');
      debugPrint('   🔑 User Name key: $userNameKey');
      debugPrint('   📏 Token length: ${token.length}');
      debugPrint('   👤 User ID: ${userId ?? "not provided"}');
      debugPrint('   👤 User Name: ${userName ?? "not provided"}');
      debugPrint('═══════════════════════════════════════════════════════');

      // Save token
      await _secureStorage.write(key: tokenKey, value: token);

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

      if (success) {
        debugPrint('✅ [BiometricService] Token and flag saved successfully');
        if (userId != null && userId.isNotEmpty) {
          debugPrint('✅ [BiometricService] User ID saved successfully');
        }
        if (userName != null && userName.isNotEmpty) {
          debugPrint('✅ [BiometricService] User Name saved successfully');
        }
      } else {
        debugPrint('❌ [BiometricService] Verification failed');
        debugPrint('   Token match: ${savedToken == token}');
        debugPrint('   Flag match: ${savedFlag == 'true'}');
      }

      return success;
    } catch (e) {
      debugPrint('❌ [BiometricService] Error saving token: $e');
      return false;
    }
  }

  /// @deprecated - Use getStoredTokenForIdentifier instead
  /// This is a legacy method kept for backward compatibility  
  Future<String?> getStoredToken({
    required BuildContext context,
    String? reason,
  }) async {
    debugPrint('⚠️ [BiometricService] getStoredToken() is deprecated - use getStoredTokenForIdentifier');
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
        debugPrint('❌ [BiometricService] Cannot retrieve token without identifier');
        return null;
      }
      
      final tokenKey = _getTokenKey(identifier);
      final sanitized = _sanitizeIdentifier(identifier);
      
      // Check if biometric is enabled for this identifier
      final isEnabled = await isEnabledForIdentifier(identifier);
      if (!isEnabled) {
        debugPrint('⚠️ [BiometricService] Biometric not enabled for: $sanitized');
        return null;
      }
      
      // Retrieve token
      final token = await _secureStorage.read(key: tokenKey);
      if (token == null || token.isEmpty) {
        debugPrint('⚠️ [BiometricService] No stored token found');
        debugPrint('   📧 Identifier: $sanitized');
        debugPrint('   🔑 Token key: $tokenKey');
        
        // List all keys for debugging
        try {
          final allKeys = await _secureStorage.readAll();
          final biometricKeys = allKeys.keys
              .where((k) => k.startsWith(_tokenKeyPrefix) || k.startsWith(_enabledKeyPrefix))
              .toList();
          debugPrint('   🔍 Available biometric keys: $biometricKeys');
        } catch (e) {
          debugPrint('   ⚠️ Could not list keys: $e');
        }
        
        return null;
      }

      debugPrint('✅ [BiometricService] Token retrieved successfully');
      debugPrint('   📧 Identifier: $sanitized');
      debugPrint('   📏 Token length: ${token.length}');
      
      return token;
    } catch (e) {
      debugPrint('❌ [BiometricService] Error retrieving token: $e');
      return null;
    }
  }

  /// Retrieve all stored credentials (token, userId, userName) for a specific identifier
  /// Returns a map with 'token', 'userId', and 'userName' keys, or null if not found
  /// 
  /// @param identifier The user's email or phone number
  Future<Map<String, String>?> getStoredCredentialsForIdentifier(String identifier) async {
    try {
      if (identifier.trim().isEmpty) {
        debugPrint('❌ [BiometricService] Cannot retrieve credentials without identifier');
        return null;
      }
      
      final sanitized = _sanitizeIdentifier(identifier);
      
      // Check if biometric is enabled for this identifier
      final isEnabled = await isEnabledForIdentifier(identifier);
      if (!isEnabled) {
        debugPrint('⚠️ [BiometricService] Biometric not enabled for: $sanitized');
        return null;
      }
      
      final tokenKey = _getTokenKey(identifier);
      final userIdKey = _getUserIdKey(identifier);
      final userNameKey = _getUserNameKey(identifier);
      
      // Retrieve all credentials
      final token = await _secureStorage.read(key: tokenKey);
      final userId = await _secureStorage.read(key: userIdKey);
      final userName = await _secureStorage.read(key: userNameKey);
      
      if (token == null || token.isEmpty) {
        debugPrint('⚠️ [BiometricService] No stored token found for: $sanitized');
        return null;
      }
      
      debugPrint('✅ [BiometricService] Credentials retrieved successfully');
      debugPrint('   📧 Identifier: $sanitized');
      debugPrint('   📏 Token length: ${token.length}');
      debugPrint('   👤 User ID: ${userId ?? "not stored"}');
      debugPrint('   👤 User Name: ${userName ?? "not stored"}');
      
      return {
        'token': token,
        if (userId != null && userId.isNotEmpty) 'userId': userId,
        if (userName != null && userName.isNotEmpty) 'userName': userName,
      };
    } catch (e) {
      debugPrint('❌ [BiometricService] Error retrieving credentials: $e');
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
      debugPrint('❌ [BiometricService] Authentication error: $e');
      return false;
    }
  }

  /// Delete stored token but KEEP biometric_enabled flag
  // These legacy methods are kept for backward compatibility but are deprecated
  // Use the identifier-specific methods instead

  /// @deprecated Use clearStoredTokenForIdentifier instead
  Future<void> clearStoredToken() async {
    debugPrint('⚠️ [BiometricService] clearStoredToken() is deprecated');
    // This is now a no-op - use clearStoredTokenForIdentifier
  }
  
  /// Clear stored token for a specific identifier (on logout)
  /// This preserves the enabled flag so user doesn't need to re-enable
  Future<void> clearStoredTokenForIdentifier(String identifier) async {
    try {
      if (identifier.trim().isEmpty) {
        debugPrint('⚠️ [BiometricService] Cannot clear token without identifier');
        return;
      }
      
      final tokenKey = _getTokenKey(identifier);
      final sanitized = _sanitizeIdentifier(identifier);
      
      await _secureStorage.delete(key: tokenKey);
      
      debugPrint('✅ [BiometricService] Token cleared (keeping enabled flag)');
      debugPrint('   📧 Identifier: $sanitized');
      debugPrint('   🔑 Cleared key: $tokenKey');
    } catch (e) {
      debugPrint('❌ [BiometricService] Error clearing token: $e');
    }
  }
  
  /// Delete ALL biometric data for a specific identifier
  /// Use this when user explicitly disables biometric login
  Future<void> clearBiometricDataForIdentifier(String identifier) async {
    try {
      if (identifier.trim().isEmpty) {
        debugPrint('⚠️ [BiometricService] Cannot clear data without identifier');
        return;
      }
      
      final tokenKey = _getTokenKey(identifier);
      final enabledKey = _getEnabledKey(identifier);
      final userIdKey = _getUserIdKey(identifier);
      final userNameKey = _getUserNameKey(identifier);
      final sanitized = _sanitizeIdentifier(identifier);
      
      await _secureStorage.delete(key: tokenKey);
      await _secureStorage.delete(key: enabledKey);
      await _secureStorage.delete(key: userIdKey);
      await _secureStorage.delete(key: userNameKey);
      
      debugPrint('✅ [BiometricService] All biometric data cleared');
      debugPrint('   📧 Identifier: $sanitized');
      debugPrint('   🔑 Cleared keys: $tokenKey, $enabledKey, $userIdKey, $userNameKey');
    } catch (e) {
      debugPrint('❌ [BiometricService] Error clearing biometric data: $e');
    }
  }
  
  /// Delete ALL biometric data for all identifiers
  /// Use this for account deletion or complete reset
  Future<void> clearAllBiometricData() async {
    try {
      final allKeys = await _secureStorage.readAll();
      final biometricKeys = allKeys.keys.where(
        (key) => key.startsWith(_tokenKeyPrefix) || 
                 key.startsWith(_enabledKeyPrefix) ||
                 key.startsWith(_userIdKeyPrefix) ||
                 key.startsWith(_userNameKeyPrefix),
      ).toList();
      
      debugPrint('🗑️ [BiometricService] Clearing all biometric data');
      debugPrint('   📊 Found ${biometricKeys.length} keys to delete');
      
      for (final key in biometricKeys) {
        await _secureStorage.delete(key: key);
      }
      
      debugPrint('✅ [BiometricService] All biometric data cleared');
    } catch (e) {
      debugPrint('❌ [BiometricService] Error clearing all biometric data: $e');
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
