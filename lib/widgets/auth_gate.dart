import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_profile_provider.dart';
import '../views/login_screen.dart';
import '../views/welcome_view.dart';
import '../views/email_verification_view.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          authProvider.refreshSession();
          // Also refresh profile
          final profileProvider = Provider.of<UserProfileProvider>(context, listen: false);
          profileProvider.loadProfile();
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
          profileProvider.loadProfile();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading while checking auth state
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Check if user is authenticated
        if (!authProvider.isAuthenticated) {
          return const LoginScreen();
        }

        // Check if email is verified (for email/password signups)
        // OAuth users are automatically verified
        if (!authProvider.isEmailVerified) {
          return const EmailVerificationView();
        }

        // User is authenticated and verified
        _loadProfileIfAuthenticated();
        return const WelcomeView();
      },
    );
  }
}