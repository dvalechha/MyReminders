import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/supabase_user_helper.dart';

/// Repository for Subscription operations with Supabase
class SubscriptionRepository {
  final SupabaseClient _client;

  SubscriptionRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Get all subscriptions for the current user
  Future<List<Map<String, dynamic>>> getAllForUser(String userId) async {
    try {
      final response = await _client
          .from('subscriptions')
          .select()
          .eq('user_id', userId)
          .order('renewal_date');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch subscriptions: $e');
    }
  }

  /// Get a subscription by ID
  Future<Map<String, dynamic>?> getById(String id) async {
    try {
      final userId = SupabaseUserHelper.getCurrentUserIdOrThrow();
      final response = await _client
          .from('subscriptions')
          .select()
          .eq('id', id)
          .eq('user_id', userId)
          .maybeSingle();

      return response != null ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      throw Exception('Failed to fetch subscription: $e');
    }
  }

  /// Create a new subscription
  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    try {
      final userId = SupabaseUserHelper.getCurrentUserIdOrThrow();
      final subscriptionData = {
        ...data,
        'user_id': userId,
      };

      final response = await _client
          .from('subscriptions')
          .insert(subscriptionData)
          .select()
          .single();

      return Map<String, dynamic>.from(response);
    } catch (e) {
      throw Exception('Failed to create subscription: $e');
    }
  }

  /// Update an existing subscription
  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> data) async {
    try {
      final userId = SupabaseUserHelper.getCurrentUserIdOrThrow();
      final response = await _client
          .from('subscriptions')
          .update(data)
          .eq('id', id)
          .eq('user_id', userId)
          .select()
          .single();

      return Map<String, dynamic>.from(response);
    } catch (e) {
      throw Exception('Failed to update subscription: $e');
    }
  }

  /// Delete a subscription
  Future<void> delete(String id) async {
    try {
      final userId = SupabaseUserHelper.getCurrentUserIdOrThrow();
      await _client
          .from('subscriptions')
          .delete()
          .eq('id', id)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to delete subscription: $e');
    }
  }
}

