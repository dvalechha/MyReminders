import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class UserProfileRepository {
  final SupabaseClient _supabase;

  UserProfileRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// Get user profile by ID (same as userId)
  Future<UserProfile?> getById(String id) async {
    try {
      final response = await _supabase
          .from('user_profile')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return UserProfile.fromMap(response);
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  /// Get user profile by userId (alias for getById)
  Future<UserProfile?> getByUserId(String userId) async {
    return getById(userId);
  }

  /// Create a new user profile
  Future<UserProfile> createProfile({
    required String userId,
    required String email,
    required String displayName,
  }) async {
    try {
      final response = await _supabase
          .from('user_profile')
          .insert({
            'id': userId,
            'email': email,
            'display_name': displayName,
          })
          .select()
          .single();

      return UserProfile.fromMap(response);
    } catch (e) {
      throw Exception('Failed to create user profile: $e');
    }
  }

  /// Upsert (insert or update) profile for current authenticated user
  Future<UserProfile> upsertProfileForCurrentUser({
    required String email,
    required String displayName,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user');
      }

      final response = await _supabase
          .from('user_profile')
          .upsert({
            'id': user.id,
            'email': email,
            'display_name': displayName,
          })
          .select()
          .single();

      return UserProfile.fromMap(response);
    } catch (e) {
      throw Exception('Failed to upsert user profile: $e');
    }
  }

  /// Get or create profile for current authenticated user
  Future<UserProfile> getOrCreateForCurrentUser({
    required String email,
    required String displayName,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user');
      }

      // Try to get existing profile
      final existing = await getById(user.id);
      if (existing != null) {
        return existing;
      }

      // Create new profile if it doesn't exist
      return await createProfile(
        userId: user.id,
        email: email,
        displayName: displayName,
      );
    } catch (e) {
      throw Exception('Failed to get or create user profile: $e');
    }
  }
}

