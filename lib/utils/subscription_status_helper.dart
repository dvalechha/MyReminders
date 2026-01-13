import 'package:flutter/material.dart';
import '../models/subscription.dart';

enum SubscriptionStatus { overdue, dueToday, normal }

/// Get the status of a subscription based on its renewal date
SubscriptionStatus getSubscriptionStatus(DateTime renewalDate) {
  final nowUtc = DateTime.now().toUtc();
  final todayUtc = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day);
  
  final renewalUtc = renewalDate.toUtc();
  final renewalDayUtc = DateTime.utc(renewalUtc.year, renewalUtc.month, renewalUtc.day);

  if (renewalDayUtc.isBefore(todayUtc)) {
    return SubscriptionStatus.overdue;
  } else if (renewalDayUtc.isAtSameMomentAs(todayUtc)) {
    return SubscriptionStatus.dueToday;
  } else {
    return SubscriptionStatus.normal;
  }
}

/// Calculate the next renewal date based on the current renewal date and billing cycle
/// Handles month-end edge cases (e.g., Jan 31st -> Feb 28th)
DateTime calculateNextRenewal(DateTime currentRenewal, BillingCycle cycle) {
  // Logic remains date-math based, safe to preserve as is, usually date math is timezone agnostic if we just add days/months
  switch (cycle) {
    case BillingCycle.weekly:
      return currentRenewal.add(const Duration(days: 7));
    case BillingCycle.monthly:
      return _addMonths(currentRenewal, 1);
    case BillingCycle.quarterly:
      return _addMonths(currentRenewal, 3);
    case BillingCycle.yearly:
      return _addMonths(currentRenewal, 12);
  }
}

/// Helper to add months while handling month-end edge cases
DateTime _addMonths(DateTime date, int monthsToAdd) {
  int nextYear = date.year;
  int nextMonth = date.month + monthsToAdd;
  
  while (nextMonth > 12) {
    nextMonth -= 12;
    nextYear++;
  }
  
  // Find the last day of the target month
  int lastDayOfNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
  int nextDay = date.day > lastDayOfNextMonth ? lastDayOfNextMonth : date.day;
  
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

/// Get status color based on renewal date
Color getSubscriptionStatusColor(
  DateTime renewalDate, {
  required BillingCycle billingCycle,
}) {
  final status = getSubscriptionStatus(renewalDate);
  
  switch (status) {
    case SubscriptionStatus.overdue:
    case SubscriptionStatus.dueToday:
      return Colors.red;
    case SubscriptionStatus.normal:
      final nowUtc = DateTime.now().toUtc();
      final renewalUtc = renewalDate.toUtc();
      final difference = renewalUtc.difference(nowUtc).inDays;
      if (difference >= 0 && difference <= 7) {
        return Colors.deepOrange.shade400;
      }
      return Colors.greenAccent;
  }
}

/// Calculate progress through billing cycle (0.0 to 1.0)
/// Returns progress from last renewal to next renewal
double getBillingCycleProgress({
  required DateTime renewalDate,
  required BillingCycle billingCycle,
}) {
  final nowUtc = DateTime.now().toUtc();
  final status = getSubscriptionStatus(renewalDate);
  
  if (status == SubscriptionStatus.overdue || status == SubscriptionStatus.dueToday) {
    return 1.0;
  }
  
  // Calculate the cycle length in days
  int cycleDays;
  switch (billingCycle) {
    case BillingCycle.weekly:
      cycleDays = 7;
      break;
    case BillingCycle.monthly:
      cycleDays = 30; // Approximate
      break;
    case BillingCycle.quarterly:
      cycleDays = 90;
      break;
    case BillingCycle.yearly:
      cycleDays = 365;
      break;
  }
  
  // Calculate last renewal date (renewalDate - cycleDays)
  // Ensure strict UTC calc
  final renewalUtc = renewalDate.toUtc();
  final lastRenewal = renewalUtc.subtract(Duration(days: cycleDays));
  
  // Calculate days since last renewal
  final daysSinceLastRenewal = nowUtc.difference(lastRenewal).inDays;
  
  // Calculate progress (clamp between 0.0 and 1.0)
  final progress = (daysSinceLastRenewal / cycleDays).clamp(0.0, 1.0);
  
  return progress;
}

/// Get renewal text (e.g., "Renews in 5 days" or "Renews today")
String getRenewalText(DateTime renewalDate, {required BillingCycle billingCycle}) {
  final nowUtc = DateTime.now().toUtc();
  final status = getSubscriptionStatus(renewalDate);
  
  // Normalizing to date-only for comparison (UTC)
  final renewalUtc = renewalDate.toUtc();
  final renewalDateOnlyUtc = DateTime.utc(renewalUtc.year, renewalUtc.month, renewalUtc.day);
  final nowDateOnlyUtc = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day);
  
  final daysDiff = renewalDateOnlyUtc.difference(nowDateOnlyUtc).inDays;
  
  if (status == SubscriptionStatus.overdue) {
    return 'Overdue by ${daysDiff.abs()} day${daysDiff.abs() == 1 ? '' : 's'}';
  } else if (status == SubscriptionStatus.dueToday) {
    return 'Due today';
  } else if (daysDiff == 1) {
    return 'Renews tomorrow';
  } else {
    return 'Renews in $daysDiff days';
  }
}
