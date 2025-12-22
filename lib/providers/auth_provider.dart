import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/logout_service.dart';
import '../services/secure_storage_service.dart';
import '../repositories/user_profile_repository.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = true;
  StreamSubscription<AuthState>? _authStateSubscription;
  bool _isPasswordResetFlow = false;
  bool _isCheckingPasswordReset = false;
  DateTime? _sessionCreatedAt;
  bool? _previousEmailVerified;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  bool get isEmailVerified => _user?.emailConfirmedAt != null;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    final supabase = Supabase.instance.client;

    debugPrint('🚀 [AuthProvider] Initializing authentication...');
    _user = supabase.auth.currentUser;
    _previousEmailVerified = _user?.emailConfirmedAt != null;
    
    if (_user != null) {
      debugPrint('👤 [AuthProvider] Supabase session found on startup');
      debugPrint('👤 [AuthProvider] User email: ${_user?.email}');
      debugPrint('👤 [AuthProvider] Session restored by Supabase (built-in persistence)');
      
      // Check if "Remember Me" is enabled
      // If user exists but Remember Me is not enabled, clear the session
      debugPrint('🔍 [AuthProvider] Checking Remember Me status in Keychain...');
      final rememberMeEnabled = await SecureStorageService.instance.isRememberMeEnabled();
      
      if (!rememberMeEnabled) {
        debugPrint('⚠️ [AuthProvider] Remember Me NOT enabled in Keychain');
        debugPrint('⚠️ [AuthProvider] Clearing Supabase session (user did not check Remember Me)');
        // Clear Supabase session if Remember Me is not enabled
        await supabase.auth.signOut();
        _user = null;
        _previousEmailVerified = null;
        _sessionCreatedAt = null;
        debugPrint('✅ [AuthProvider] Session cleared - user will see login screen');
      } else {
        debugPrint('✅ [AuthProvider] Remember Me ENABLED in Keychain');
        debugPrint('✅ [AuthProvider] Session will be kept - user stays logged in');
        debugPrint('ℹ️ [AuthProvider] Note: Supabase restored session automatically, Keychain tokens are available for future use');
        _sessionCreatedAt = DateTime.now();
        // Await the email verification check to ensure sign out happens before listener setup
        await _checkEmailVerificationOnInit();
      }
    } else {
      debugPrint('👤 [AuthProvider] No Supabase session found on startup');
      debugPrint('🔍 [AuthProvider] Checking if Keychain tokens exist...');
      final hasTokens = await SecureStorageService.instance.hasSessionTokens();
      if (hasTokens) {
        debugPrint('⚠️ [AuthProvider] Keychain tokens exist but no Supabase session');
        debugPrint('⚠️ [AuthProvider] This means Supabase session expired or was cleared');
        debugPrint('ℹ️ [AuthProvider] User will need to log in again');
      } else {
        debugPrint('ℹ️ [AuthProvider] No Keychain tokens found - user needs to log in');
      }
    }

    _isLoading = false;
    notifyListeners();

    _authStateSubscription = supabase.auth.onAuthStateChange.listen((event) async {
      debugPrint('Auth state changed: ${event.event}, Session: ${event.session != null}');
      debugPrint('Event type: ${event.event}, Previous user: ${_user?.email}, Previous email verified: $_previousEmailVerified');

      final hadSession = _user != null;
      final previousEmailVerified = _previousEmailVerified;
      _user = event.session?.user;
      final currentEmailVerified = _user?.emailConfirmedAt != null;
      _isLoading = false;

      debugPrint('Current user: ${_user?.email}, Current email verified: $currentEmailVerified');

      if (event.session != null) {
        _sessionCreatedAt = DateTime.now();
        final user = event.session!.user;

        if (user.appMetadata['provider'] == 'google') {
          _handleGoogleAuthCallback();
          _isPasswordResetFlow = false;
          clearPasswordResetFlag();
          _previousEmailVerified = currentEmailVerified;
        } else {
          final prefs = await SharedPreferences.getInstance();
          final justSignedUp = prefs.getBool('just_signed_up') ?? false;
          final signupEmail = prefs.getString('signup_email');

          debugPrint('Email verification check - justSignedUp: $justSignedUp, signupEmail: $signupEmail');
          debugPrint('Email verification check - previous: $previousEmailVerified, current: $currentEmailVerified');
          debugPrint('Email verification check - hadSession: $hadSession, userEmail: ${user.email}');
          debugPrint('Email verification check - event: ${event.event}');

          if (justSignedUp &&
              signupEmail != null &&
              signupEmail == user.email &&
              currentEmailVerified == true) {
            if (!hadSession || previousEmailVerified == false || event.event == AuthChangeEvent.tokenRefreshed) {
              debugPrint('*** Email verification detected after signup - signing out user ***');

              await prefs.remove('just_signed_up');
              await prefs.remove('signup_email');
              await prefs.setBool('email_verified_success', true);

              final supabase = Supabase.instance.client;
              await supabase.auth.signOut();

              _user = null;
              _previousEmailVerified = null;
              _isLoading = false;
              notifyListeners();

              debugPrint('User signed out after email verification - will need to log in');
              return;
            }
          }

          _previousEmailVerified = currentEmailVerified;
          _isCheckingPasswordReset = true;
          notifyListeners();

          checkPasswordResetFlow().then((isReset) {
            _isPasswordResetFlow = isReset;
            _isCheckingPasswordReset = false;
            if (isReset) {
              debugPrint('Password reset flow detected in auth listener - showing reset screen');
            } else {
              debugPrint('Password reset flow check completed - not a reset flow');
              clearPasswordResetFlag();
            }
            notifyListeners();
          }).catchError((e) {
            debugPrint('Error checking password reset in listener: $e');
            _isCheckingPasswordReset = false;
            _isPasswordResetFlow = false;
            clearPasswordResetFlag();
            notifyListeners();
          });
        }
      } else {
        _isPasswordResetFlow = false;
        _sessionCreatedAt = null;
        _previousEmailVerified = null;
      }

      notifyListeners();
    });

    // Register subscription with LogoutService so it can be cancelled on logout
    LogoutService.instance.setAuthStateSubscription(_authStateSubscription);

    _checkPasswordResetOnInit();
  }

  Future<void> _checkEmailVerificationOnInit() async {
    await checkAndHandleEmailVerification(source: 'init');
  }

  /// Check if user just verified email after signup and sign them out to require re-login.
  /// Returns true if user was signed out, false otherwise.
  /// This can be called from anywhere (init, app resume, etc.)
  Future<bool> checkAndHandleEmailVerification({String source = 'unknown'}) async {
    // Refresh user state first to get latest emailConfirmedAt
    final supabase = Supabase.instance.client;
    _user = supabase.auth.currentUser;
    
    if (_user == null) {
      debugPrint('[$source] No user to check for email verification');
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final justSignedUp = prefs.getBool('just_signed_up') ?? false;
      final signupEmail = prefs.getString('signup_email');
      final currentEmailVerified = _user?.emailConfirmedAt != null;

      debugPrint('[$source] Email verification check - justSignedUp: $justSignedUp, signupEmail: $signupEmail');
      debugPrint('[$source] Email verification check - userEmail: ${_user?.email}, emailVerified: $currentEmailVerified');

      if (justSignedUp &&
          signupEmail != null &&
          signupEmail == _user?.email &&
          currentEmailVerified == true) {
        debugPrint('*** [$source] Email verification detected - signing out user ***');

        await prefs.remove('just_signed_up');
        await prefs.remove('signup_email');
        await prefs.setBool('email_verified_success', true);

        await supabase.auth.signOut();

        _user = null;
        _previousEmailVerified = null;
        _isLoading = false;
        notifyListeners();

        debugPrint('[$source] User signed out after email verification - will need to log in');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[$source] Error checking email verification: $e');
      return false;
    }
  }

  /// Check if we're in a password reset flow
  bool get isPasswordResetFlow => _isPasswordResetFlow;

  /// Check if we're currently checking for password reset
  bool get isCheckingPasswordReset => _isCheckingPasswordReset;

  /// Get when the current session was created
  DateTime? get sessionCreatedAt => _sessionCreatedAt;

  /// Set password reset flow flag
  void setPasswordResetFlow(bool value) {
    _isPasswordResetFlow = value;
    notifyListeners();
  }

  /// Check for password reset token on app initialization
  Future<void> _checkPasswordResetOnInit() async {
    try {
      final shouldShowReset = await checkPasswordResetFlow();
      _isPasswordResetFlow = shouldShowReset;
      notifyListeners();
    } catch (e) {
      debugPrint('Error checking password reset: $e');
      _isPasswordResetFlow = false;
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  /// Clear user state (used during logout)
  void clearUserState() {
    _user = null;
    _isLoading = false;
    _isPasswordResetFlow = false;
    _isCheckingPasswordReset = false;
    _sessionCreatedAt = null;
    _previousEmailVerified = null;
    notifyListeners();
    debugPrint('AuthProvider: User state cleared');
  }

  /// Refresh the current session
  Future<void> refreshSession() async {
    try {
      _isLoading = true;
      notifyListeners();

      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;
      final userEmail = session != null ? (session.user.email ?? 'null') : 'null';
      debugPrint('Refreshing session: ${session != null}, User: $userEmail');
      _user = session?.user;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing session: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithPassword(String email, String password) async {
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;
      if (session != null) {
        _user = session.user;
        _isLoading = false;

        await clearPasswordResetFlag();

        notifyListeners();
        debugPrint('Sign in successful: User ${_user?.email}');

        if (_user != null && _user!.email != null) {
          try {
            final repository = UserProfileRepository();
            final existingProfile = await repository.getById(_user!.id);
            if (existingProfile == null) {
              await repository.getOrCreateForCurrentUser(
                email: _user!.email!,
                displayName: _user!.email!.split('@')[0],
              );
            }
          } catch (e) {
            // Silently ignore profile creation errors
          }
        }
      } else {
        await Future.delayed(const Duration(milliseconds: 200));
        await refreshSession();
        await clearPasswordResetFlag();
      }
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final redirectUrl = _getRedirectUrl();

      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } catch (e) {
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  /// Handle Google auth callback and create/update user profile
  Future<void> _handleGoogleAuthCallback() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null || user.email == null) {
        return;
      }

      String displayName = _deriveDisplayNameFromGoogle(user);

      final repository = UserProfileRepository();
      await repository.getOrCreateForCurrentUser(
        email: user.email!,
        displayName: displayName,
      );
    } catch (e) {
      // Silently ignore profile creation errors
    }
  }

  /// Derive display name from Google user metadata
  String _deriveDisplayNameFromGoogle(User user) {
    final metadata = user.userMetadata;

    if (metadata != null && metadata['full_name'] != null) {
      final fullName = metadata['full_name'] as String;
      if (fullName.isNotEmpty) {
        return fullName;
      }
    }

    if (metadata != null && metadata['name'] != null) {
      final name = metadata['name'] as String;
      if (name.isNotEmpty) {
        return name;
      }
    }

    if (user.email != null) {
      final emailParts = user.email!.split('@');
      if (emailParts.isNotEmpty) {
        return emailParts[0];
      }
    }

    return 'User';
  }

  Future<void> signUp(String email, String password, {String? displayName}) async {
    try {
      await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: _getRedirectUrl(),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('just_signed_up', true);
      await prefs.setString('signup_email', email);

      final currentUser = Supabase.instance.client.auth.currentUser;
      _previousEmailVerified = currentUser?.emailConfirmedAt != null;

      debugPrint('Signup successful - flag set for email verification detection');
      debugPrint('Signup email: $email, Email verified: $_previousEmailVerified');

      if (displayName != null && displayName.isNotEmpty) {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null && user.email != null) {
          try {
            final repository = UserProfileRepository();
            await repository.getOrCreateForCurrentUser(
              email: user.email!,
              displayName: displayName,
            );
          } catch (e) {
            // Silently ignore profile creation errors
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }

  /// Sign out using the complete logout service
  Future<void> signOut(BuildContext context) async {
    try {
      await LogoutService.instance.logout(context);
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      if (_user?.email != null) {
        await Supabase.instance.client.auth.resend(
          type: OtpType.signup,
          email: _user!.email!,
        );
      }
    } catch (e) {
      throw Exception('Failed to resend verification email: $e');
    }
  }

  /// Send password reset email to the specified email address
  Future<void> resetPassword(String email) async {
    try {
      final supabase = Supabase.instance.client;
      final redirectUrl = _getRedirectUrl();

      await supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: redirectUrl,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('password_reset_initiated', true);
      await prefs.setString('password_reset_email', email);
      await prefs.setInt('password_reset_timestamp', DateTime.now().millisecondsSinceEpoch);

      debugPrint('Password reset email sent. Flag set for detection.');
    } catch (e) {
      throw Exception('Failed to send password reset email: $e');
    }
  }

  Future<bool> checkPasswordResetFlow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isInitiated = prefs.getBool('password_reset_initiated') ?? false;
      final resetEmail = prefs.getString('password_reset_email');
      final timestamp = prefs.getInt('password_reset_timestamp');

      debugPrint('Checking password reset flow - initiated: $isInitiated, email: $resetEmail, timestamp: $timestamp');

      if (!isInitiated) {
        debugPrint('Password reset not initiated - returning false');
        return false;
      }

      if (timestamp != null) {
        final resetTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final now = DateTime.now();
        final difference = now.difference(resetTime);

        debugPrint('Time since password reset initiated: ${difference.inMinutes} minutes');

        if (difference.inHours > 1) {
          debugPrint('Password reset flag expired - clearing');
          await prefs.remove('password_reset_initiated');
          await prefs.remove('password_reset_email');
          await prefs.remove('password_reset_timestamp');
          return false;
        }
      }

      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;

      debugPrint('Current session exists: ${session != null}');

      if (session != null) {
        final userEmail = session.user.email;
        debugPrint('Session user email: $userEmail, reset email: $resetEmail');

        if (resetEmail != null && userEmail != null && userEmail == resetEmail) {
          debugPrint('Password reset flow confirmed - email matches');
          return true;
        } else if (resetEmail == null || userEmail == null) {
          debugPrint('Password reset flow confirmed - flag set and session exists');
          return true;
        } else {
          debugPrint('Email mismatch - treating as normal login, not password reset');
          return false;
        }
      }

      debugPrint('Password reset flow check returning false');
      return false;
    } catch (e) {
      debugPrint('Error checking password reset flow: $e');
      return false;
    }
  }

  /// Clear password reset flag (called after password is successfully reset)
  Future<void> clearPasswordResetFlag() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('password_reset_initiated');
      await prefs.remove('password_reset_email');
      await prefs.remove('password_reset_timestamp');
      _isPasswordResetFlow = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing password reset flag: $e');
    }
  }

  /// Returns true when the user signed up directly with email/password
  bool get isDirectSignIn {
    try {
      final provider = _user?.appMetadata['provider'];
      return provider != null && provider == 'email';
    } catch (_) {
      return false;
    }
  }

  /// Update the current user's password
  Future<void> updatePassword(String newPassword) async {
    try {
      debugPrint('🔐 [AuthProvider] Starting password update...');
      final supabase = Supabase.instance.client;
      
      debugPrint('📝 [AuthProvider] Updating password in Supabase...');
      await supabase.auth.updateUser(UserAttributes(password: newPassword));
      debugPrint('✅ [AuthProvider] Password updated successfully in Supabase');
      
      debugPrint('🔄 [AuthProvider] Refreshing session...');
      await refreshSession();
      debugPrint('✅ [AuthProvider] Session refreshed');
      
      debugPrint('🧹 [AuthProvider] Clearing password reset flag...');
      await clearPasswordResetFlag();
      debugPrint('✅ [AuthProvider] Password reset flag cleared');
      
      // Clear keychain tokens when password is changed
      // Old tokens become invalid, user needs to log in again with new password
      debugPrint('🔐 [AuthProvider] Password changed - clearing Keychain tokens...');
      debugPrint('🔐 [AuthProvider] Old tokens are now invalid, user must log in again with new password');
      await SecureStorageService.instance.deleteSessionTokens();
      debugPrint('✅ [AuthProvider] Keychain tokens cleared after password change');
      debugPrint('✅ [AuthProvider] Password update complete - user must re-authenticate with new password');
    } catch (e) {
      debugPrint('❌ [AuthProvider] Error updating password: $e');
      throw Exception('Failed to update password: $e');
    }
  }

  /// Delete the current user's account
  Future<void> deleteAccount(BuildContext context) async {
    try {
      debugPrint('🗑️ [AuthProvider] Starting account deletion process...');
      final supabase = Supabase.instance.client;

      debugPrint('🔄 [AuthProvider] Refreshing session before deletion...');
      try {
        await supabase.auth.refreshSession();
        debugPrint('✅ [AuthProvider] Session refreshed');
      } catch (e) {
        debugPrint('⚠️ [AuthProvider] Warning: Could not refresh session: $e');
      }

      final session = supabase.auth.currentSession;
      if (session == null) {
        throw Exception('No active session. Please sign in again.');
      }

      final accessToken = session.accessToken;
      if (accessToken.isEmpty) {
        throw Exception('Invalid session token. Please sign in again.');
      }

      debugPrint('📞 [AuthProvider] Calling delete-account function with token (length: ${accessToken.length})');

      try {
        final response = await supabase.functions.invoke(
          'delete-account',
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        );

        if (response.status != 200) {
          final errorData = response.data;
          final errorMessage = errorData is Map
              ? (errorData['error'] ?? errorData['details'] ?? 'Failed to delete account')
              : 'Failed to delete account';
          throw Exception(errorMessage);
        }

        debugPrint('✅ [AuthProvider] Account deletion successful: ${response.data}');
      } catch (e) {
        debugPrint('❌ [AuthProvider] Error calling delete-account function: $e');
        rethrow;
      }

      // LogoutService will clear keychain tokens as part of the logout process
      debugPrint('🔐 [AuthProvider] Account deleted - initiating logout (Keychain will be cleared)...');
      // ignore: use_build_context_synchronously
      await LogoutService.instance.logout(context);
      debugPrint('✅ [AuthProvider] Account deletion complete - Keychain cleared via LogoutService');
    } catch (e) {
      debugPrint('❌ [AuthProvider] Error in deleteAccount: $e');
      rethrow;
    }
  }

  String _getRedirectUrl() {
    final redirectUrl = dotenv.env['SUPABASE_REDIRECT_URL'];
    if (redirectUrl != null && redirectUrl.isNotEmpty) {
      return redirectUrl;
    }
    return 'myreminders://auth-callback';
  }
}