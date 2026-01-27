import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'local_cache_service.dart';
import 'state_reset_service.dart';
import 'secure_storage_service.dart';
import '../views/logout_splash_screen.dart';
import '../widgets/auth_gate.dart';
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
    // Get NavigationModel for reliable navigation via global navigator key
    final navigationModel = Provider.of<NavigationModel>(context, listen: false);
    // Get AuthProvider reference early
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // We don't strictly need context mounted check for the initial logic if we use global keys,
    // but good to keep if we were using local context. 
    // Here we will shift to using navigationModel.navigatorKey for the Splash Screen too
    // to ensure it covers the whole app (including bottom tabs) and is on the root stack.

    try {
      debugPrint('Logout: Starting logout process');
      
      // Step 1: Immediately push LogoutSplashScreen to ROOT navigator
      // Using root navigator ensures it covers bottom navigation bar and everything else
      navigationModel.navigatorKey.currentState?.push(
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
          opaque: true, // Fully opaque to cover everything
          barrierDismissible: false, 
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

      // Step 5: Clear secure storage tokens (Remember Me)
      debugPrint('🗑️ [LogoutService] Clearing Keychain tokens and Remember Me flag...');
      await SecureStorageService.instance.deleteSessionTokens();
      debugPrint('✅ [LogoutService] Keychain tokens and Remember Me flag cleared');

      // Step 6: Sign out from Supabase
      await Supabase.instance.client.auth.signOut();
      
      debugPrint('Logout: Supabase signOut called');
      
      // Step 7: Wait a bit for the auth state change listener to process
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Step 8: Manually clear user state (using the reference we got earlier)
      authProvider.clearUserState();
      debugPrint('Logout: User state cleared');
      
      // Step 9: Stop all live listeners
      stopLiveListeners();
      
      // Step 10: Wait a moment for UI to update
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Step 11: Navigate to AuthGate (Root)
      // We use pushAndRemoveUntil to clear the entire stack (including the Splash Screen we just pushed)
      // and restart the app flow from AuthGate.
      debugPrint('Logout: Navigating to AuthGate (Root)');
      navigationModel.navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const AuthGate(),
        ),
        (route) => false, // Remove all routes
      );
      
      debugPrint('Logout: Logout complete');
    } catch (e) {
      debugPrint('Logout error: $e');
      // If error occurs, try to force navigate to AuthGate
      try {
        navigationModel.navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const AuthGate(),
          ),
          (route) => false,
        );
      } catch (_) {
        // Ignore navigation errors during error handling
      }
      throw Exception('Failed to logout: $e');
    }
  }
}

