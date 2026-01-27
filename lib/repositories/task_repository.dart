import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/supabase_user_helper.dart';

/// Repository for Task operations with Supabase
class TaskRepository {
  final SupabaseClient _client;

  TaskRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Get all tasks for the current user
  Future<List<Map<String, dynamic>>> getAllForUser(String userId) async {
    try {
      final response = await _client
          .from('tasks')
          .select()
          .eq('user_id', userId)
          .order('is_completed', ascending: true) // Sort active first
          .order('due_date', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch tasks: $e');
    }
  }

  /// Get a task by ID
  Future<Map<String, dynamic>?> getById(String id) async {
    try {
      final userId = SupabaseUserHelper.getCurrentUserIdOrThrow();
      final response = await _client
          .from('tasks')
          .select()
          .eq('id', id)
          .eq('user_id', userId)
          .maybeSingle();

      return response != null ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      throw Exception('Failed to fetch task: $e');
    }
  }

  /// Create a new task
  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    try {
      final userId = SupabaseUserHelper.getCurrentUserIdOrThrow();
      final taskData = {
        ...data,
        'user_id': userId,
      };

      final response = await _client
          .from('tasks')
          .insert(taskData)
          .select()
          .single();

      return Map<String, dynamic>.from(response);
    } catch (e) {
      throw Exception('Failed to create task: $e');
    }
  }

  /// Update an existing task
  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> data) async {
    try {
      final userId = SupabaseUserHelper.getCurrentUserIdOrThrow();
      final response = await _client
          .from('tasks')
          .update(data)
          .eq('id', id)
          .eq('user_id', userId)
          .select()
          .single();

      return Map<String, dynamic>.from(response);
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  /// Delete a task
  Future<void> delete(String id) async {
    try {
      final userId = SupabaseUserHelper.getCurrentUserIdOrThrow();
      await _client
          .from('tasks')
          .delete()
          .eq('id', id)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  /// Delete multiple tasks by ID
  Future<void> deleteIds(List<String> ids) async {
    if (ids.isEmpty) return;
    try {
      final userId = SupabaseUserHelper.getCurrentUserIdOrThrow();
      await _client
          .from('tasks')
          .delete()
          .inFilter('id', ids)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to delete tasks: $e');
    }
  }
}

