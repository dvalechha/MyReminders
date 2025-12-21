import 'package:flutter/material.dart';

/// Splash screen shown during logout process
/// Navigation is handled by LogoutService after all cleanup operations complete
class LogoutSplashScreen extends StatelessWidget {
  const LogoutSplashScreen({super.key});

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

