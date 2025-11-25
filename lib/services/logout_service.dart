import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'local_cache_service.dart';
import 'state_reset_service.dart';
import '../views/logout_splash_screen.dart';
import '../providers/auth_provider.dart';

/// Service to handle complete logout process
class LogoutService {
  static final LogoutService instance = LogoutService._init();

  LogoutService._init();

  /// Stream subscription for auth state changes (to be cancelled on logout)
  StreamSubscription<AuthState>? _authStateSubscription;

  /// Set the auth state subscription (called from AuthProvider)
  void setAuthStateSubscription(StreamSubscription<AuthState>? subscription) {
    _authStateSubscription = subscription;
  }

  /// Stop all live listeners/streams
  void stopLiveListeners() {
    // Cancel auth state change listener
    _authStateSubscription?.cancel();
    _authStateSubscription = null;
  }

  /// Complete logout process following the required order:
  /// 1. Immediately push LogoutSplashScreen
  /// 2. Wait for next frame to ensure splash screen is visible
  /// 3. stopLiveListeners()
  /// 4. await clearInMemoryState()
  /// 5. await LocalCacheService.clearAll()
  /// 6. await Supabase.instance.client.auth.signOut()
  /// 7. LogoutSplashScreen auto-finishes after 1 second
  /// 8. AuthGate detects null session and routes to LoginScreen
  Future<void> logout(BuildContext context) async {
    // Store navigator reference before async operations
    final navigator = Navigator.of(context);
    if (!context.mounted) {
      debugPrint('Logout: Context not mounted');
      return;
    }

    try {
      debugPrint('Logout: Starting logout process');
      
      // Step 1: Immediately push LogoutSplashScreen (on top of current screen)
      // Use push instead of pushReplacement so we can pop back to AuthGate
      navigator.push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            debugPrint('Logout: LogoutSplashScreen pageBuilder called');
            return const LogoutSplashScreen();
          },
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          opaque: true, // Fully opaque to cover the welcome view
          barrierDismissible: false, // Prevent dismissing by tapping outside
        ),
      );

      debugPrint('Logout: Splash screen pushed, waiting for frame');
      
      // Step 2: Wait for next frame to ensure splash screen is fully rendered
      await SchedulerBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 200));
      
      debugPrint('Logout: Frame rendered, starting cleanup');

      // Step 3: Clear in-memory state (check context is still mounted)
      if (context.mounted) {
        await StateResetService.instance.clearInMemoryState(context);
      }

      // Step 4: Clear local cache (database, notifications)
      await LocalCacheService.instance.clearAll();

      // Step 5: Sign out from Supabase FIRST (before cancelling listener)
      // This will trigger the auth state change event
      await Supabase.instance.client.auth.signOut();
      
      debugPrint('Logout: Supabase signOut called, waiting for auth state change');
      
      // Step 6: Wait a bit for the auth state change listener to process
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Step 7: Manually update AuthProvider to ensure state is cleared
      // (in case listener was already cancelled or didn't process)
      if (context.mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        // Manually clear the user state
        authProvider.clearUserState();
      }
      
      // Step 8: Now stop all live listeners (after state is updated)
      stopLiveListeners();
      
      debugPrint('Logout: Logout complete, waiting for splash screen to finish');

      // Step 7: LogoutSplashScreen will automatically pop after 1 second
      // Step 8: AuthGate will detect null session and route to LoginScreen
    } catch (e) {
      debugPrint('Logout error: $e');
      // If error occurs, pop the splash screen and show error
      if (context.mounted) {
        navigator.pop();
      }
      throw Exception('Failed to logout: $e');
    }
  }
}

