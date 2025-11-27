import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/logout_service.dart';
import '../repositories/user_profile_repository.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = true;
  StreamSubscription<AuthState>? _authStateSubscription;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  bool get isEmailVerified => _user?.emailConfirmedAt != null;

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    final supabase = Supabase.instance.client;

    // Get initial session
    _user = supabase.auth.currentUser;
    _isLoading = false;
    notifyListeners();

    // Listen to auth state changes and store subscription
    _authStateSubscription = supabase.auth.onAuthStateChange.listen((event) {
      debugPrint('Auth state changed: ${event.event}, Session: ${event.session != null}');
      _user = event.session?.user;
      _isLoading = false;
      notifyListeners();
      
      // Handle Google auth callback - create/update profile if needed
      if (event.session != null) {
        final user = event.session!.user;
        // Check if this is a Google OAuth user (has provider metadata)
        if (user.appMetadata['provider'] == 'google') {
          _handleGoogleAuthCallback();
        }
      }
    });

    // Register subscription with LogoutService so it can be cancelled on logout
    LogoutService.instance.setAuthStateSubscription(_authStateSubscription);
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
    notifyListeners();
    debugPrint('AuthProvider: User state cleared');
  }

  /// Refresh the current session - useful after OAuth callback
  Future<void> refreshSession() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final supabase = Supabase.instance.client;
      // Use currentSession property instead of getSession() method
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
      // Session refresh failed, but don't throw - let the listener handle it
    }
  }

  Future<void> signInWithPassword(String email, String password) async {
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      // Immediately update the user state from the current session
      // This ensures AuthGate reacts immediately without waiting for the listener
      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;
      if (session != null) {
        _user = session.user;
        _isLoading = false;
        notifyListeners();
        debugPrint('Sign in successful: User ${_user?.email}');
        
        // Ensure user profile exists (for existing users who might not have profile)
        if (_user != null && _user!.email != null) {
          try {
            final repository = UserProfileRepository();
            final existingProfile = await repository.getById(_user!.id);
            if (existingProfile == null) {
              // Create profile with email as fallback display name
              await repository.getOrCreateForCurrentUser(
                email: _user!.email!,
                displayName: _user!.email!.split('@')[0],
              );
            }
          } catch (e) {
            // Silently ignore profile creation errors if table doesn't exist
            // This is expected if the user_profile table hasn't been created in Supabase
          }
        }
      } else {
        // If session is null, wait a bit for the auth state change event
        await Future.delayed(const Duration(milliseconds: 200));
        await refreshSession();
      }
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final redirectUrl = _getRedirectUrl();
      
      // Use Supabase's signInWithOAuth which handles the OAuth flow
      // The method will return a bool indicating if the OAuth flow was initiated
      // We need to let Supabase handle the URL construction with proper PKCE and state
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      // Auth state change will be handled by the listener when user returns to app
      // Profile creation will be handled in _handleGoogleAuthCallback
      // Note: Supabase handles opening the browser automatically with authScreenLaunchMode
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

      // Derive display name from Google profile metadata
      String displayName = _deriveDisplayNameFromGoogle(user);

      // Create or update user profile
      final repository = UserProfileRepository();
      await repository.getOrCreateForCurrentUser(
        email: user.email!,
        displayName: displayName,
      );
      // Profile created/updated successfully
    } catch (e) {
      // Silently ignore profile creation errors if table doesn't exist
      // This is expected if the user_profile table hasn't been created in Supabase
      // Don't throw - profile can be created later
    }
  }

  /// Derive display name from Google user metadata
  String _deriveDisplayNameFromGoogle(User user) {
    final metadata = user.userMetadata;
    
    // Try full_name first
    if (metadata != null && metadata['full_name'] != null) {
      final fullName = metadata['full_name'] as String;
      if (fullName.isNotEmpty) {
        return fullName;
      }
    }
    
    // Try name
    if (metadata != null && metadata['name'] != null) {
      final name = metadata['name'] as String;
      if (name.isNotEmpty) {
        return name;
      }
    }
    
    // Fallback: email without domain part
    if (user.email != null) {
      final emailParts = user.email!.split('@');
      if (emailParts.isNotEmpty) {
        return emailParts[0];
      }
    }
    
    // Last resort: return "User"
    return 'User';
  }

  Future<void> signUp(String email, String password, {String? displayName}) async {
    try {
      await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: _getRedirectUrl(),
      );
      
      // After successful signup, create user profile if displayName is provided
      if (displayName != null && displayName.isNotEmpty) {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null && user.email != null) {
          try {
            final repository = UserProfileRepository();
            await repository.getOrCreateForCurrentUser(
              email: user.email!,
              displayName: displayName,
            );
            // Profile created successfully
          } catch (e) {
            // Silently ignore profile creation errors if table doesn't exist
            // This is expected if the user_profile table hasn't been created in Supabase
            // Don't throw - profile can be created later
          }
        }
      }
      
      // Auth state change will be handled by the listener
      // Note: User will need to verify email before full access
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }

  /// Sign out using the complete logout service
  /// This handles all cleanup: listeners, state, cache, and Supabase session
  Future<void> signOut(BuildContext context) async {
    try {
      await LogoutService.instance.logout(context);
      // Auth state change will be handled by AuthGate after logout completes
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

  String _getRedirectUrl() {
    // Read redirect URL from .env file
    final redirectUrl = dotenv.env['SUPABASE_REDIRECT_URL'];
    if (redirectUrl != null && redirectUrl.isNotEmpty) {
      return redirectUrl;
    }
    // Fallback to default if not set in .env
    return 'myreminders://auth-callback';
  }
}