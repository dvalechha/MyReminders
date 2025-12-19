import 'package:supabase_flutter/supabase_flutter.dart';

/// Helper utility for parsing and converting authentication errors
/// to user-friendly messages
class AuthErrorHelper {
  /// Converts technical error messages to user-friendly messages
  static String getErrorMessage(dynamic error) {
    if (error == null) {
      return 'An unexpected error occurred. Please try again.';
    }

    final errorString = error.toString().toLowerCase();

    // Handle Supabase AuthApiException
    if (error is AuthException) {
      return _getAuthExceptionMessage(error);
    }

    // Handle string-based error messages
    if (errorString.contains('invalid_credentials') ||
        errorString.contains('invalid login credentials')) {
      return 'Invalid email or password. Please check your credentials and try again.';
    }

    if (errorString.contains('email not confirmed') ||
        errorString.contains('email_not_confirmed')) {
      return 'Please verify your email address before signing in. Check your inbox for a verification link.';
    }

    if (errorString.contains('user not found')) {
      return 'No account found with this email address. Please sign up first.';
    }

    if (errorString.contains('email already registered') ||
        errorString.contains('user_already_registered')) {
      return 'An account with this email already exists. Please sign in instead.';
    }

    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network error. Please check your internet connection and try again.';
    }

    if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }

    if (errorString.contains('too many requests') ||
        errorString.contains('rate limit')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }

    // Generic fallback - extract the actual error message if possible
    if (errorString.contains('exception:')) {
      // Try to extract a cleaner message
      final parts = errorString.split('exception:');
      if (parts.length > 1) {
        final message = parts[1].trim();
        // Remove technical details
        if (message.contains('authapiexception')) {
          return 'Invalid email or password. Please check your credentials and try again.';
        }
        return _cleanErrorMessage(message);
      }
    }

    // Last resort: return a generic message
    return 'Unable to sign in. Please check your credentials and try again.';
  }

  /// Handles Supabase AuthException specifically
  static String _getAuthExceptionMessage(AuthException error) {
    switch (error.statusCode) {
      case 400:
        if (error.message.toLowerCase().contains('invalid') ||
            error.message.toLowerCase().contains('credentials')) {
          return 'Invalid email or password. Please check your credentials and try again.';
        }
        return 'Invalid request. Please check your information and try again.';
      case 401:
        return 'Invalid email or password. Please check your credentials and try again.';
      case 403:
        return 'Access denied. Please verify your email address.';
      case 404:
        return 'Account not found. Please sign up first.';
      case 422:
        return 'Invalid email format. Please enter a valid email address.';
      case 429:
        return 'Too many attempts. Please wait a moment and try again.';
      case 500:
      case 502:
      case 503:
        return 'Server error. Please try again later.';
      default:
        return _cleanErrorMessage(error.message);
    }
  }

  /// Cleans up technical error messages
  static String _cleanErrorMessage(String message) {
    // Remove common technical prefixes
    String cleaned = message
        .replaceAll(RegExp(r'authapiexception\s*\(', caseSensitive: false), '')
        .replaceAll(RegExp(r'statuscode:\s*\d+', caseSensitive: false), '')
        .replaceAll(RegExp(r'code:\s*\w+', caseSensitive: false), '')
        .replaceAll(RegExp(r'\)', caseSensitive: false), '')
        .trim();

    // Capitalize first letter
    if (cleaned.isNotEmpty) {
      cleaned = cleaned[0].toUpperCase() + cleaned.substring(1);
    }

    return cleaned.isEmpty
        ? 'An error occurred. Please try again.'
        : cleaned;
  }
}
