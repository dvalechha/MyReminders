import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subscription.dart';

class SubscriptionService {
  final SupabaseClient _client;

  SubscriptionService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Calculate the next renewal date based on the current renewal date and billing cycle.
  /// Enforces "Sticky End-of-Month" heuristic:
  /// 1. If current is last day of month, next is last day of next month.
  /// 2. Otherwise, standard addition (clamped).
  DateTime calculateNextRenewalDate(DateTime current, BillingCycle cycle) {
    if (cycle == BillingCycle.monthly) {
      return _addMonthsSticky(current, 1);
    } else if (cycle == BillingCycle.quarterly) {
      return _addMonthsSticky(current, 3);
    } else if (cycle == BillingCycle.yearly) {
      return _addMonthsSticky(current, 12);
    } else if (cycle == BillingCycle.weekly) {
      return current.add(const Duration(days: 7));
    }
    return current;
  }

  DateTime _addMonthsSticky(DateTime date, int monthsToAdd) {
    // 1. Check if "Last Day"
    final lastDayOfCurrentMonth = DateTime(date.year, date.month + 1, 0).day;
    final isLastDay = date.day == lastDayOfCurrentMonth;

    // Calculate target year and month
    int nextYear = date.year;
    int nextMonth = date.month + monthsToAdd;
    
    // Handle year overflow/underflow
    // (Note: standard loops are safer than mod arithmetic for month 1-12 range)
    while (nextMonth > 12) {
      nextMonth -= 12;
      nextYear++;
    }
    while (nextMonth < 1) {
      nextMonth += 12;
      nextYear--;
    }

    final lastDayOfNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;

    if (isLastDay) {
      // If YES (It is the last day): The new date must be the last valid day of the next month.
      return DateTime(
        nextYear,
        nextMonth,
        lastDayOfNextMonth,
        date.hour,
        date.minute,
        date.second,
        date.millisecond,
        date.microsecond,
      );
    } else {
      // If NO (It is not the last day): Perform standard date addition with clamping.
      final nextDay = date.day > lastDayOfNextMonth ? lastDayOfNextMonth : date.day;
       return DateTime(
        nextYear,
        nextMonth,
        nextDay,
        date.hour,
        date.minute,
        date.second,
        date.millisecond,
        date.microsecond,
      );
    }
  }
}