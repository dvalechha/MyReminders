import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'local_cache_service.dart';
import 'state_reset_service.dart';
import '../views/logout_splash_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/navigation_model.dart';

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
  /// 3. Clear in-memory state
  /// 4. Clear local cache
  /// 5. Sign out from Supabase
  /// 6. Clear user state in AuthProvider
  /// 7. Stop live listeners
  /// 8. Navigate to root (AuthGate shows LoginScreen)
  Future<void> logout(BuildContext context) async {
    // Store references before async operations
    final navigator = Navigator.of(context);
    // Get NavigationModel for reliable navigation via global navigator key
    final navigationModel = Provider.of<NavigationModel>(context, listen: false);
    // Get AuthProvider reference early
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (!context.mounted) {
      debugPrint('Logout: Context not mounted');
      return;
    }

    try {
      debugPrint('Logout: Starting logout process');
      
      // Step 1: Immediately push LogoutSplashScreen (on top of current screen)
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

      // Step 3: Clear in-memory state
      if (context.mounted) {
        await StateResetService.instance.clearInMemoryState(context);
      }

      // Step 4: Clear local cache (database, notifications)
      await LocalCacheService.instance.clearAll();

      // Step 5: Sign out from Supabase
      await Supabase.instance.client.auth.signOut();
      
      debugPrint('Logout: Supabase signOut called');
      
      // Step 6: Wait a bit for the auth state change listener to process
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Step 7: Manually clear user state (using the reference we got earlier)
      // This ensures state is cleared even if the original context is no longer mounted
      authProvider.clearUserState();
      debugPrint('Logout: User state cleared');
      
      // Step 8: Stop all live listeners
      stopLiveListeners();
      
      // Step 9: Wait a moment for UI to update
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Step 10: Navigate to root using the global navigator key
      // This clears the entire navigation stack and returns to AuthGate
      // AuthGate will detect null session and show LoginScreen
      debugPrint('Logout: Navigating to root');
      navigationModel.popToRoot();
      
      debugPrint('Logout: Logout complete');
    } catch (e) {
      debugPrint('Logout error: $e');
      // If error occurs, try to pop the splash screen
      try {
        navigationModel.popToRoot();
      } catch (_) {
        // Ignore navigation errors during error handling
      }
      throw Exception('Failed to logout: $e');
    }
  }
}

