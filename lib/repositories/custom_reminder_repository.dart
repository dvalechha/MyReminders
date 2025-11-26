import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/supabase_user_helper.dart';

/// Repository for CustomReminder operations with Supabase
class CustomReminderRepository {
  final SupabaseClient _client;

  CustomReminderRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Get all custom reminders for the current user
  Future<List<Map<String, dynamic>>> getAllForUser(String userId) async {
    try {
      final response = await _client
          .from('custom_reminder')
          .select()
          .eq('user_id', userId)
          .order('event_time', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch custom reminders: $e');
    }
  }

  /// Get a custom reminder by ID
  Future<Map<String, dynamic>?> getById(String id) async {
    try {
      final userId = SupabaseUserHelper.getCurrentUserIdOrThrow();
      final response = await _client
          .from('custom_reminder')
          .select()
          .eq('id', id)
          .eq('user_id', userId)
          .maybeSingle();

      return response != null ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      throw Exception('Failed to fetch custom reminder: $e');
    }
  }

  /// Create a new custom reminder
  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    try {
      final userId = SupabaseUserHelper.getCurrentUserIdOrThrow();
      final reminderData = {
        ...data,
        'user_id': userId,
      };

      final response = await _client
          .from('custom_reminder')
          .insert(reminderData)
          .select()
          .single();

      return Map<String, dynamic>.from(response);
    } catch (e) {
      throw Exception('Failed to create custom reminder: $e');
    }
  }

  /// Update an existing custom reminder
  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> data) async {
    try {
      final userId = SupabaseUserHelper.getCurrentUserIdOrThrow();
      final response = await _client
          .from('custom_reminder')
          .update(data)
          .eq('id', id)
          .eq('user_id', userId)
          .select()
          .single();

      return Map<String, dynamic>.from(response);
    } catch (e) {
      throw Exception('Failed to update custom reminder: $e');
    }
  }

  /// Delete a custom reminder
  Future<void> delete(String id) async {
    try {
      final userId = SupabaseUserHelper.getCurrentUserIdOrThrow();
      await _client
          .from('custom_reminder')
          .delete()
          .eq('id', id)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to delete custom reminder: $e');
    }
  }
}

