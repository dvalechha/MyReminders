import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

/// Splash screen shown during logout process
/// Shows for ~1 second, then automatically finishes
class LogoutSplashScreen extends StatefulWidget {
  const LogoutSplashScreen({super.key});

  @override
  State<LogoutSplashScreen> createState() => _LogoutSplashScreenState();
}

class _LogoutSplashScreenState extends State<LogoutSplashScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint('LogoutSplashScreen: initState called');
    // Automatically finish after 1 second
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        debugPrint('LogoutSplashScreen: Auto-popping after 1 second');
        // Ensure auth state is refreshed before popping
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        authProvider.refreshSession();
        // Pop this screen - AuthGate will detect null session and route to LoginScreen
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('LogoutSplashScreen: build called');
    return PopScope(
      canPop: false, // Disable back button during logout
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                SizedBox(height: 24),
                Text(
                  'Logging out…',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

