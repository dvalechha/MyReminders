import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = true;

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

    // Listen to auth state changes
    supabase.auth.onAuthStateChange.listen((event) {
      debugPrint('Auth state changed: ${event.event}, Session: ${event.session != null}');
      _user = event.session?.user;
      _isLoading = false;
      notifyListeners();
    });
  }

  /// Refresh the current session - useful after OAuth callback
  Future<void> refreshSession() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final supabase = Supabase.instance.client;
      // Use currentSession property instead of getSession() method
      final session = supabase.auth.currentSession;
      debugPrint('Refreshing session: ${session != null}, User: ${session?.user?.email}');
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
      // Auth state change will be handled by the listener
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
      // Note: Supabase handles opening the browser automatically with authScreenLaunchMode
    } catch (e) {
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  Future<void> signUp(String email, String password) async {
    try {
      await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: _getRedirectUrl(),
      );
      // Auth state change will be handled by the listener
      // Note: User will need to verify email before full access
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      // Auth state change will be handled by the listener
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