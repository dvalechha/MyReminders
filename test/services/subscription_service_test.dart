import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_reminder/models/subscription.dart';
import 'package:my_reminder/services/subscription_service.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  late SubscriptionService service;
  late MockSupabaseClient mockClient;

  setUp(() {
    mockClient = MockSupabaseClient();
    service = SubscriptionService(client: mockClient);
  });

  group('SubscriptionService - Sticky End-of-Month Logic', () {
    test('Normal date: Jan 15 -> Feb 15', () {
      final current = DateTime(2023, 1, 15);
      final expected = DateTime(2023, 2, 15);
      final result = service.calculateNextRenewalDate(current, BillingCycle.monthly);
      
      expect(result.year, expected.year);
      expect(result.month, expected.month);
      expect(result.day, expected.day);
    });

    test('Sticky End-of-Month: Jan 31 -> Feb 28 (Non-leap year)', () {
      final current = DateTime(2023, 1, 31);
      final expected = DateTime(2023, 2, 28); // Last day of Feb 2023
      final result = service.calculateNextRenewalDate(current, BillingCycle.monthly);
      
      expect(result.year, expected.year);
      expect(result.month, expected.month);
      expect(result.day, expected.day);
    });

    test('Sticky End-of-Month: Jan 31 -> Feb 29 (Leap year)', () {
      final current = DateTime(2024, 1, 31);
      final expected = DateTime(2024, 2, 29); // Last day of Feb 2024
      final result = service.calculateNextRenewalDate(current, BillingCycle.monthly);
      
      expect(result.year, expected.year);
      expect(result.month, expected.month);
      expect(result.day, expected.day);
    });

    test('Sticky End-of-Month: Feb 28 -> Mar 31 (Non-leap year)', () {
      final current = DateTime(2023, 2, 28);
      final expected = DateTime(2023, 3, 31); // Should stick to last day of next month
      final result = service.calculateNextRenewalDate(current, BillingCycle.monthly);
      
      expect(result.year, expected.year);
      expect(result.month, expected.month);
      expect(result.day, expected.day);
    });

    test('Sticky End-of-Month: Feb 29 -> Mar 31 (Leap year)', () {
      final current = DateTime(2024, 2, 29);
      final expected = DateTime(2024, 3, 31); // Should stick to last day of next month
      final result = service.calculateNextRenewalDate(current, BillingCycle.monthly);
      
      expect(result.year, expected.year);
      expect(result.month, expected.month);
      expect(result.day, expected.day);
    });

    test('Sticky End-of-Month: Apr 30 -> May 31', () {
      final current = DateTime(2023, 4, 30);
      final expected = DateTime(2023, 5, 31);
      final result = service.calculateNextRenewalDate(current, BillingCycle.monthly);
      
      expect(result.year, expected.year);
      expect(result.month, expected.month);
      expect(result.day, expected.day);
    });

    test('Non-Last Day Clamping: Jan 30 -> Feb 28 (Standard behavior, not sticky logic)', () {
      // Logic: Jan 30 is NOT the last day of Jan.
      // So it adds 1 month -> Feb 30 (Invalid) -> Feb 28 (Clamped)
      // Since it wasn't the last day of start month, it won't force last day of next month logic (though result is same here)
      // But let's verify logic flow: 
      // isLastDay(Jan 30) = false.
      // _addMonthsSticky calls internal logic.
      final current = DateTime(2023, 1, 30);
      final expected = DateTime(2023, 2, 28); 
      final result = service.calculateNextRenewalDate(current, BillingCycle.monthly);
      
      expect(result.year, expected.year);
      expect(result.month, expected.month);
      expect(result.day, expected.day);
    });
    
    test('Non-Sticky: Feb 27 -> Mar 27', () {
       // Feb 27 is not last day (usually).
       final current = DateTime(2023, 2, 27);
       final expected = DateTime(2023, 3, 27);
       final result = service.calculateNextRenewalDate(current, BillingCycle.monthly);
       
       expect(result.year, expected.year);
       expect(result.month, expected.month);
       expect(result.day, expected.day);
    });

    test('Yearly Cycle Sticky: Feb 29, 2024 -> Feb 28, 2025', () {
      // Leap day next year won't exist
      final current = DateTime(2024, 2, 29);
      final expected = DateTime(2025, 2, 28);
      final result = service.calculateNextRenewalDate(current, BillingCycle.yearly);
      
      expect(result.year, expected.year);
      expect(result.month, expected.month);
      expect(result.day, expected.day);
    });
    
    test('Yearly Cycle Sticky: Feb 28, 2023 -> Feb 29, 2024', () {
       // Last day of Feb 2023 -> Last day of Feb 2024
       final current = DateTime(2023, 2, 28);
       final expected = DateTime(2024, 2, 29);
       final result = service.calculateNextRenewalDate(current, BillingCycle.yearly);
       
       expect(result.year, expected.year);
       expect(result.month, expected.month);
       expect(result.day, expected.day);
    });
    
    test('Weekly Cycle: Jan 31 -> Feb 7', () {
      final current = DateTime(2023, 1, 31);
      final expected = DateTime(2023, 2, 7);
      final result = service.calculateNextRenewalDate(current, BillingCycle.weekly);
      
      expect(result.year, expected.year);
      expect(result.month, expected.month);
      expect(result.day, expected.day);
    });
  });
}
