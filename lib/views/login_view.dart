import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../utils/auth_error_helper.dart';
import '../services/secure_storage_service.dart';
import '../utils/app_config.dart';
import 'forgot_password_screen.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSignUp = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    // Check if user just verified their email and show success message
    _checkEmailVerificationSuccess();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Check if email was just verified and show success message
  Future<void> _checkEmailVerificationSuccess() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final emailVerified = prefs.getBool('email_verified_success') ?? false;
      
      if (emailVerified && mounted) {
        // Clear the flag
        await prefs.remove('email_verified_success');
        
        // Show success message after the widget is built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Email verified successfully! Please sign in to continue.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 5),
              ),
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Error checking email verification success: $e');
    }
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (_isSignUp) {
        await authProvider.signUp(_emailController.text, _passwordController.text);
        // Show success message for sign up
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sign up successful! Please check your email to verify your account.'),
            ),
          );
        }
      } else {
        await authProvider.signInWithPassword(_emailController.text, _passwordController.text);
        
        // Handle "Remember Me" checkbox for email/password login
        if (_rememberMe) {
          debugPrint('📝 [LoginView] Remember Me checked - saving tokens to Keychain...');
          // Save session tokens and set the flag
          try {
            final supabase = Supabase.instance.client;
            final session = supabase.auth.currentSession;
            if (session != null) {
              final email = session.user.email ?? _emailController.text.trim();
              debugPrint('📝 [LoginView] Saving tokens for email: $email');
              await SecureStorageService.instance.saveSessionTokens(
                email: email,
                accessToken: session.accessToken,
                refreshToken: session.refreshToken ?? '',
              );
              await SecureStorageService.instance.setRememberMeEnabled(true);
              debugPrint('✅ [LoginView] Remember Me enabled - tokens saved to Keychain');
            } else {
              debugPrint('⚠️ [LoginView] No session available to save tokens');
            }
          } catch (e) {
            debugPrint('❌ [LoginView] Error saving session tokens to Keychain: $e');
            // Silently fail - don't break login flow if token storage fails
          }
        } else {
          debugPrint('📝 [LoginView] Remember Me NOT checked - clearing Keychain tokens...');
          // Clear flag and delete any existing tokens if "Remember Me" is unchecked
          try {
            await SecureStorageService.instance.setRememberMeEnabled(false);
            await SecureStorageService.instance.deleteSessionTokens();
            debugPrint('✅ [LoginView] Remember Me disabled - tokens cleared from Keychain');
          } catch (e) {
            debugPrint('❌ [LoginView] Error clearing Remember Me flag from Keychain: $e');
          }
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = AuthErrorHelper.getErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signInWithGoogle();
      
      // Handle "Remember Me" checkbox for Google OAuth
      // Note: For Google OAuth, we need to wait for the session to be established
      // The session will be available after the OAuth callback completes
      if (_rememberMe) {
        debugPrint('📝 [LoginView] Remember Me checked (Google OAuth) - waiting for session, then saving to Keychain...');
        // Poll for session with timeout (more reliable than fixed delay)
        bool sessionReady = false;
        int attempts = 0;
        const maxAttempts = 20; // 20 attempts * 250ms = 5 seconds max wait
        
        while (!sessionReady && attempts < maxAttempts && mounted) {
          await Future.delayed(const Duration(milliseconds: 250));
          final supabase = Supabase.instance.client;
          final session = supabase.auth.currentSession;
          
          if (session != null) {
            try {
              final email = session.user.email ?? _emailController.text.trim();
              debugPrint('📝 [LoginView] Google OAuth session ready - saving tokens for: $email');
              await SecureStorageService.instance.saveSessionTokens(
                email: email,
                accessToken: session.accessToken,
                refreshToken: session.refreshToken ?? '',
              );
              await SecureStorageService.instance.setRememberMeEnabled(true);
              debugPrint('✅ [LoginView] Remember Me enabled (Google OAuth) - tokens saved to Keychain');
              sessionReady = true;
            } catch (e) {
              debugPrint('❌ [LoginView] Error saving session tokens to Keychain (Google OAuth): $e');
              // Silently fail - don't break login flow if token storage fails
              sessionReady = true; // Exit loop even on error
            }
          }
          attempts++;
        }
        
        if (!sessionReady && mounted) {
          debugPrint('⚠️ [LoginView] Timeout waiting for Google OAuth session - tokens not saved to Keychain');
        }
      } else {
        debugPrint('📝 [LoginView] Remember Me NOT checked (Google OAuth) - clearing Keychain tokens...');
        // Clear flag and delete tokens if "Remember Me" is unchecked
        try {
          await SecureStorageService.instance.setRememberMeEnabled(false);
          await SecureStorageService.instance.deleteSessionTokens();
          debugPrint('✅ [LoginView] Remember Me disabled (Google OAuth) - tokens cleared from Keychain');
        } catch (e) {
          debugPrint('❌ [LoginView] Error clearing Remember Me flag from Keychain (Google OAuth): $e');
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = AuthErrorHelper.getErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppConfig.appNameDisplay,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isSignUp ? 'Create your account' : 'Welcome back',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  // Only show Remember Me row when not in sign-up mode
                  if (!_isSignUp)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Remember Me checkbox on the left
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (bool? newValue) {
                                setState(() => _rememberMe = newValue ?? false);
                              },
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() => _rememberMe = !_rememberMe);
                              },
                              child: Text(
                                'Remember Me',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Forgot Password? link on the right
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            // Don't show "Forgot Password?" link if we're in a password reset flow
                            // This prevents navigation to ForgotPasswordScreen when ResetPasswordScreen should be shown
                            if (authProvider.isPasswordResetFlow) {
                              return const SizedBox.shrink();
                            }
                            return TextButton(
                              onPressed: _isLoading ? null : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ForgotPasswordScreen(
                                      initialEmail: _emailController.text.trim().isNotEmpty
                                          ? _emailController.text.trim()
                                          : null,
                                    ),
                                  ),
                                );
                              },
                              child: const Text('Forgot Password?'),
                            );
                          },
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (_errorMessage != null) const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleAuth,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isSignUp ? 'Sign Up' : 'Sign In'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _isLoading ? null : () => setState(() => _isSignUp = !_isSignUp),
                    child: Text(
                      _isSignUp
                          ? 'Already have an account? Sign In'
                          : 'Don\'t have an account? Sign Up',
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('or'),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    icon: const Icon(Icons.g_mobiledata, size: 24),
                    label: const Text('Continue with Google'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}