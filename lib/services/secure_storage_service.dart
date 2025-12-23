import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service to handle secure storage of authentication tokens
/// Uses iOS Keychain on iOS and EncryptedSharedPreferences on Android
class SecureStorageService {
  static final SecureStorageService instance = SecureStorageService._init();

  SecureStorageService._init();

  /// Get platform-specific storage name for logging
  String get _storageName => Platform.isIOS ? 'Keychain' : 'EncryptedSharedPreferences';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Save session tokens to secure storage
  /// 
  /// Stores the user's email, access token, and refresh token
  /// for use in automatic re-authentication
  Future<void> saveSessionTokens({
    required String email,
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      debugPrint('🔐 [$_storageName] Saving tokens to secure storage...');
      debugPrint('🔐 [$_storageName] Email: $email');
      debugPrint('🔐 [$_storageName] Access token length: ${accessToken.length}');
      debugPrint('🔐 [$_storageName] Refresh token length: ${refreshToken.length}');
      
      await _storage.write(key: 'remember_me_email', value: email);
      await _storage.write(key: 'remember_me_access_token', value: accessToken);
      await _storage.write(key: 'remember_me_refresh_token', value: refreshToken);
      
      debugPrint('✅ [$_storageName] Session tokens successfully saved to secure storage for $email');
    } catch (e) {
      debugPrint('❌ [$_storageName] Error saving session tokens to secure storage: $e');
      // Silently fail - don't break login flow if secure storage fails
    }
  }

  /// Retrieve stored session tokens
  /// 
  /// Returns a map with email, accessToken, and refreshToken if they exist
  Future<Map<String, String>?> getSessionTokens() async {
    try {
      debugPrint('🔍 [$_storageName] Attempting to retrieve tokens from secure storage...');
      
      final email = await _storage.read(key: 'remember_me_email');
      final accessToken = await _storage.read(key: 'remember_me_access_token');
      final refreshToken = await _storage.read(key: 'remember_me_refresh_token');

      if (email != null && accessToken != null && refreshToken != null) {
        debugPrint('✅ [$_storageName] Tokens found in secure storage');
        debugPrint('🔍 [$_storageName] Email: $email');
        debugPrint('🔍 [$_storageName] Access token length: ${accessToken.length}');
        debugPrint('🔍 [$_storageName] Refresh token length: ${refreshToken.length}');
        return {
          'email': email,
          'accessToken': accessToken,
          'refreshToken': refreshToken,
        };
      } else {
        debugPrint('⚠️ [$_storageName] No tokens found in secure storage');
        debugPrint('🔍 [$_storageName] Email exists: ${email != null}');
        debugPrint('🔍 [$_storageName] Access token exists: ${accessToken != null}');
        debugPrint('🔍 [$_storageName] Refresh token exists: ${refreshToken != null}');
      }
      return null;
    } catch (e) {
      debugPrint('❌ [$_storageName] Error retrieving session tokens from secure storage: $e');
      return null;
    }
  }

  /// Check if session tokens exist in secure storage
  Future<bool> hasSessionTokens() async {
    try {
      debugPrint('🔍 [$_storageName] Checking if tokens exist in secure storage...');
      final email = await _storage.read(key: 'remember_me_email');
      final hasTokens = email != null && email.isNotEmpty;
      debugPrint('🔍 [$_storageName] Tokens exist in secure storage: $hasTokens');
      return hasTokens;
    } catch (e) {
      debugPrint('❌ [$_storageName] Error checking session tokens in secure storage: $e');
      return false;
    }
  }

  /// Delete all stored session tokens
  Future<void> deleteSessionTokens() async {
    try {
      debugPrint('🗑️ [$_storageName] Deleting all tokens from secure storage...');
      await _storage.delete(key: 'remember_me_email');
      await _storage.delete(key: 'remember_me_access_token');
      await _storage.delete(key: 'remember_me_refresh_token');
      await _storage.delete(key: 'remember_me_enabled');
      debugPrint('✅ [$_storageName] All session tokens and Remember Me flag deleted from secure storage');
    } catch (e) {
      debugPrint('❌ [$_storageName] Error deleting session tokens from secure storage: $e');
      // Silently fail - don't break logout flow if secure storage fails
    }
  }

  /// Set the "Remember Me" enabled flag
  /// This flag indicates whether the user wants to stay logged in across app restarts
  Future<void> setRememberMeEnabled(bool enabled) async {
    try {
      if (enabled) {
        await _storage.write(key: 'remember_me_enabled', value: 'true');
        debugPrint('✅ [$_storageName] Remember Me flag set to ENABLED in secure storage');
      } else {
        await _storage.delete(key: 'remember_me_enabled');
        debugPrint('✅ [$_storageName] Remember Me flag set to DISABLED (deleted from secure storage)');
      }
    } catch (e) {
      debugPrint('❌ [$_storageName] Error setting Remember Me flag in secure storage: $e');
      // Silently fail - don't break login flow if secure storage fails
    }
  }

  /// Check if "Remember Me" is enabled
  /// Returns true if the user previously checked "Remember Me" and tokens exist
  Future<bool> isRememberMeEnabled() async {
    try {
      debugPrint('🔍 [$_storageName] Checking Remember Me status in secure storage...');
      final enabled = await _storage.read(key: 'remember_me_enabled');
      final hasTokens = await hasSessionTokens();
      
      debugPrint('🔍 [$_storageName] Remember Me flag value: ${enabled ?? "null"}');
      debugPrint('🔍 [$_storageName] Tokens exist: $hasTokens');
      
      // Both flag and tokens must exist for Remember Me to be considered enabled
      final isEnabled = enabled == 'true' && hasTokens;
      debugPrint('🔍 [$_storageName] Remember Me is ${isEnabled ? "ENABLED" : "DISABLED"} (flag=${enabled == 'true'}, tokens=$hasTokens)');
      
      return isEnabled;
    } catch (e) {
      debugPrint('❌ [$_storageName] Error checking Remember Me flag in secure storage: $e');
      return false;
    }
  }
}

