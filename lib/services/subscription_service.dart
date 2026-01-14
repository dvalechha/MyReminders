import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subscription.dart';
import '../utils/subscription_status_helper.dart';

class SubscriptionService {
  final SupabaseClient _client;

  SubscriptionService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<Map<String, dynamic>> renewSubscription(String id) async {
    try {
      // Fetch current details to calculate next date
      final response = await _client
          .from('subscriptions')
          .select('renewal_date, billing_cycle')
          .eq('id', id)
          .single();

      final currentRenewal = DateTime.parse(response['renewal_date'] as String);
      final cycleStr = response['billing_cycle'] as String;
      
      // Map string to enum
      final cycle = BillingCycle.values.firstWhere(
        (e) => e.value.toLowerCase() == cycleStr.toLowerCase(),
        orElse: () => BillingCycle.monthly,
      );

      // Calculate next renewal
      final nextRenewal = calculateNextRenewal(currentRenewal, cycle);

      // Update in DB
      await _client
          .from('subscriptions')
          .update({
            'renewal_date': nextRenewal.toUtc().toIso8601String(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', id);

      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
