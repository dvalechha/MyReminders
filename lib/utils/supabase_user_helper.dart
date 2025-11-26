import 'package:supabase_flutter/supabase_flutter.dart';

/// Helper utility for Supabase authentication operations
class SupabaseUserHelper {
  /// Get the current authenticated user ID
  /// Throws an exception if no user is authenticated
  static String getCurrentUserIdOrThrow() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found. Please sign in.');
    }
    return user.id;
  }

  /// Get the current authenticated user ID
  /// Returns null if no user is authenticated
  static String? getCurrentUserId() {
    return Supabase.instance.client.auth.currentUser?.id;
  }

  /// Check if a user is currently authenticated
  static bool isAuthenticated() {
    return Supabase.instance.client.auth.currentUser != null;
  }

  /// Get the current authenticated user
  /// Returns null if no user is authenticated
  static User? getCurrentUser() {
    return Supabase.instance.client.auth.currentUser;
  }
}


