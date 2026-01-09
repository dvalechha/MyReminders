import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_profile_provider.dart';
import '../providers/navigation_model.dart';
import '../views/login_screen.dart';
import '../views/email_verification_view.dart';
import '../views/reset_password_screen.dart';
import '../views/main_navigation_view.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  bool _isCheckingPasswordReset = false;
  bool _shouldShowPasswordReset = false;
  bool _hasCheckedPasswordReset = false; // Track if we've already checked to prevent infinite loop
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPasswordResetOnInit();
  }
  
  /// Check for password reset on initialization
  Future<void> _checkPasswordResetOnInit() async {
    // Prevent multiple simultaneous checks
    if (_isCheckingPasswordReset) {
      return;
    }
    
    setState(() {
      _isCheckingPasswordReset = true;
      _hasCheckedPasswordReset = true; // Mark as checked
    });
    
    try {
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        // Small delay to allow Supabase to process the deep link
        // Reduced delay to improve startup performance
        await Future.delayed(const Duration(milliseconds: 300));
        
        // Check if password reset was initiated
        final shouldShow = await authProvider.checkPasswordResetFlow();
        
        debugPrint('Initial password reset check - shouldShow: $shouldShow, authenticated: ${authProvider.isAuthenticated}');
        
        debugPrint('Password reset check result: $shouldShow');
        
        if (mounted) {
          setState(() {
            _shouldShowPasswordReset = shouldShow;
            _isCheckingPasswordReset = false;
          });
          
          // Also update the provider's flag
          if (shouldShow) {
            authProvider.setPasswordResetFlow(true);
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking password reset: $e');
      if (mounted) {
        setState(() {
          _isCheckingPasswordReset = false;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // When app resumes, refresh the session to catch OAuth callbacks
    // Add a small delay to allow Supabase to process the deep link
    if (state == AppLifecycleState.resumed) {
      Future.delayed(const Duration(milliseconds: 500), () async {
        if (mounted) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          
          // First check for email verification (this handles signup confirmation links)
          // If user was signed out, we don't need to do anything else
          final wasSignedOut = await authProvider.checkAndHandleEmailVerification(source: 'app_resume');
          if (wasSignedOut) {
            debugPrint('User was signed out after email verification on app resume');
            return;
          }
          
          // Refresh session for OAuth callbacks
          authProvider.refreshSession();
          // Check for password reset when app resumes (in case it opened from reset link)
          _checkPasswordResetOnInit();
          // Also refresh profile (fails silently if table doesn't exist)
          final profileProvider = Provider.of<UserProfileProvider>(context, listen: false);
          profileProvider.loadProfile().catchError((_) {
            // Silently ignore profile loading errors
          });
        }
      });
    }
  }

  void _loadProfileIfAuthenticated() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.isAuthenticated) {
          final profileProvider = Provider.of<UserProfileProvider>(context, listen: false);
          profileProvider.loadProfile().catchError((_) {
            // Silently ignore profile loading errors
          });
        }
      }
    });
  }
  
  /// Re-check password reset when auth state changes
  /// This is called when a new session is created (e.g., from password reset link)
  Future<void> _recheckPasswordReset() async {
    // Prevent multiple simultaneous checks
    if (_isCheckingPasswordReset) {
      return;
    }
    
    setState(() {
      _isCheckingPasswordReset = true;
    });
    
    try {
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        // Small delay to ensure SharedPreferences is accessible
        await Future.delayed(const Duration(milliseconds: 300));
        final shouldShow = await authProvider.checkPasswordResetFlow();
        if (mounted) {
          setState(() {
            _shouldShowPasswordReset = shouldShow;
            _isCheckingPasswordReset = false;
          });
          if (shouldShow) {
            authProvider.setPasswordResetFlow(true);
          }
        }
      }
    } catch (e) {
      debugPrint('Error rechecking password reset: $e');
      if (mounted) {
        setState(() {
          _isCheckingPasswordReset = false;
        });
      }
    }
  }
  

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading while checking auth state or password reset
        if (authProvider.isLoading || _isCheckingPasswordReset || authProvider.isCheckingPasswordReset) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Check if user is authenticated
        // BUT: If we're checking for password reset, don't show login screen yet
        // The password reset link creates a session, so we need to wait for it
        if (!authProvider.isAuthenticated && !_isCheckingPasswordReset && !authProvider.isCheckingPasswordReset) {
          return const LoginScreen();
        }
        
        // If not authenticated but we're checking password reset, show loading
        // This handles the case when app opens from reset link and session is being created
        if (!authProvider.isAuthenticated && (_isCheckingPasswordReset || authProvider.isCheckingPasswordReset)) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // IMPORTANT: Check for password reset BEFORE checking email verification
        // This ensures reset screen is shown even if user is already verified
        
        debugPrint('=== AuthGate Build ===');
        debugPrint('Authenticated: ${authProvider.isAuthenticated}');
        debugPrint('Local flag: $_shouldShowPasswordReset');
        debugPrint('Provider flag: ${authProvider.isPasswordResetFlow}');
        debugPrint('Checking reset: $_isCheckingPasswordReset / ${authProvider.isCheckingPasswordReset}');
        
        // Provider flag is the source of truth
        // Only clear local flag if provider flag is false AND we're not currently checking
        // This prevents clearing the flag while the async check is still in progress
        if (!authProvider.isPasswordResetFlow && _shouldShowPasswordReset && 
            !_isCheckingPasswordReset && !authProvider.isCheckingPasswordReset) {
          debugPrint('Provider flag is false but local flag is true - clearing local flag (normal login detected)');
          // Clear local flag after build completes (cannot call setState during build)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _shouldShowPasswordReset = false;
              });
            }
          });
        }
        
        // Use provider flag as the primary source of truth
        // But also check local flag if we're still checking (to show reset screen during async check)
        // This ensures reset screen is shown immediately when app opens from reset link
        final shouldShowReset = authProvider.isPasswordResetFlow || 
            (_shouldShowPasswordReset && (_isCheckingPasswordReset || authProvider.isCheckingPasswordReset));
        
        debugPrint('Should show reset: $shouldShowReset (provider: ${authProvider.isPasswordResetFlow}, local: $_shouldShowPasswordReset, checking: $_isCheckingPasswordReset/${authProvider.isCheckingPasswordReset})');
        
        // If user just authenticated and we haven't checked yet, check for password reset
        // This handles the case when app opens from password reset link
        // Only check once to prevent infinite loop
        // Note: We removed the automatic re-check here to prevent infinite loops
        // The initial check in _checkPasswordResetOnInit() and the auth state listener
        // should be sufficient to detect password reset flows
        
        // Final check - use both flags, but prioritize provider flag
        // If provider flag is false and we're not checking, don't show reset screen
        final finalShouldShowReset = authProvider.isPasswordResetFlow || 
            (_shouldShowPasswordReset && (_isCheckingPasswordReset || authProvider.isCheckingPasswordReset));
        
        if (finalShouldShowReset) {
          debugPrint('*** SHOWING RESET PASSWORD SCREEN ***');
          debugPrint('Local flag: $_shouldShowPasswordReset, Provider flag: ${authProvider.isPasswordResetFlow}');
          debugPrint('Authenticated: ${authProvider.isAuthenticated}');
          
          // Clear any existing navigation stack to prevent ForgotPasswordScreen from appearing
          // This ensures ResetPasswordScreen is shown without any other screens on top
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final navigationModel = Provider.of<NavigationModel>(context, listen: false);
            // Pop all routes until we're at the root (AuthGate)
            navigationModel.popToRoot();
          });
          
          // Force show reset password screen - this replaces the entire navigation stack
          // since AuthGate is the home widget
          // The screen will handle its own navigation and prevent going back
          return const ResetPasswordScreen();
        }

        // Check if email is verified (for email/password signups)
        // OAuth users are automatically verified
        if (!authProvider.isEmailVerified) {
          return const EmailVerificationView();
        }

        // User is authenticated and verified
        _loadProfileIfAuthenticated();
        return const MainNavigationView();
      },
    );
  }
}