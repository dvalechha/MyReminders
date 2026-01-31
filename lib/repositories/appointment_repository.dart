import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/supabase_user_helper.dart';

/// Repository for Appointment operations with Supabase
class AppointmentRepository {
  final SupabaseClient _client;

  AppointmentRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Get all appointments for the current user
  Future<List<Map<String, dynamic>>> getAllForUser(String userId) async {
    try {
      final response = await _client
          .from('appointments')
          .select()
          .eq('user_id', userId)
          .order('is_completed', ascending: true) // Sort active first
          .order('start_time', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch appointments: $e');
    }
  }

  /// Get an appointment by ID
  Future<Map<String, dynamic>?> getById(String id) async {
    try {
      final userId = SupabaseUserHelper.getCurrentUserIdOrThrow();
      final response = await _client
          .from('appointments')
          .select()
          .eq('id', id)
          .eq('user_id', userId)
          .maybeSingle();

      return response != null ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      throw Exception('Failed to fetch appointment: $e');
    }
  }

  /// Create a new appointment
  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    try {
      final userId = SupabaseUserHelper.getCurrentUserIdOrThrow();
      final appointmentData = {
        ...data,
        'user_id': userId,
      };

      final response = await _client
          .from('appointments')
          .insert(appointmentData)
          .select()
          .single();

      return Map<String, dynamic>.from(response);
    } catch (e) {
      throw Exception('Failed to create appointment: $e');
    }
  }

  /// Update an existing appointment
  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> data) async {
    try {
      final userId = SupabaseUserHelper.getCurrentUserIdOrThrow();
      final response = await _client
          .from('appointments')
          .update(data)
          .eq('id', id)
          .eq('user_id', userId)
          .select()
          .single();

      return Map<String, dynamic>.from(response);
    } catch (e) {
      throw Exception('Failed to update appointment: $e');
    }
  }

  /// Delete an appointment
  Future<void> delete(String id) async {
    try {
      final userId = SupabaseUserHelper.getCurrentUserIdOrThrow();
      await _client
          .from('appointments')
          .delete()
          .eq('id', id)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to delete appointment: $e');
    }
  }

  /// Delete multiple appointments by ID
  Future<void> deleteIds(List<String> ids) async {
    if (ids.isEmpty) return;
    try {
      final userId = SupabaseUserHelper.getCurrentUserIdOrThrow();
      await _client
          .from('appointments')
          .delete()
          .inFilter('id', ids)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to delete appointments: $e');
    }
  }
}

