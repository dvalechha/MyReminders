import 'package:flutter/material.dart';
import '../models/subscription.dart';

/// Helper functions for determining subscription status colors and progress
/// 
/// Traffic Light Mental Model Strategy:
/// - Orange/Amber: "Warning/Attention" - Used for subscriptions renewing soon (0-7 days).
/// - Green: "Safe/Flow" - Used for subscriptions with more time until renewal (> 7 days).
/// 
/// Note: Past renewal dates are automatically advanced assuming successful charge.

/// Advance renewal date if it's in the past (assuming charge succeeded)
/// Returns the next renewal date based on billing cycle
DateTime _advanceRenewalDateIfPast(DateTime renewalDate, BillingCycle billingCycle) {
  final now = DateTime.now();
  
  // If renewal date is today or in the past, advance it
  if (renewalDate.isBefore(now) || 
      (renewalDate.year == now.year && 
       renewalDate.month == now.month && 
       renewalDate.day == now.day)) {
    
    // Calculate days to add based on billing cycle
    int daysToAdd;
    switch (billingCycle) {
      case BillingCycle.weekly:
        daysToAdd = 7;
        break;
      case BillingCycle.monthly:
        daysToAdd = 30;
        break;
      case BillingCycle.quarterly:
        daysToAdd = 90;
        break;
      case BillingCycle.yearly:
        daysToAdd = 365;
        break;
      case BillingCycle.custom:
        daysToAdd = 30; // Default fallback
        break;
    }
    
    // Keep advancing until we're in the future
    var nextRenewal = renewalDate;
    while (nextRenewal.isBefore(now) || 
           (nextRenewal.year == now.year && 
            nextRenewal.month == now.month && 
            nextRenewal.day == now.day)) {
      nextRenewal = nextRenewal.add(Duration(days: daysToAdd));
    }
    
    return nextRenewal;
  }
  
  return renewalDate;
}

/// Get status color based on renewal date
/// Automatically advances past renewal dates assuming charge succeeded
Color getSubscriptionStatusColor(
  DateTime renewalDate, {
  required BillingCycle billingCycle,
}) {
  final now = DateTime.now();
  
  // Auto-advance renewal date if it's in the past
  final effectiveRenewalDate = _advanceRenewalDateIfPast(renewalDate, billingCycle);
  final daysUntilRenewal = effectiveRenewalDate.difference(now).inDays;
  
  // Renews soon (0-7 days) = Orange/Amber (warning)
  // This gives users a heads-up for upcoming renewals, including "today"
  if (daysUntilRenewal >= 0 && daysUntilRenewal <= 7) {
    return Colors.deepOrange.shade400;
  }
  
  // Not urgent (> 7 days) = Green (safe)
  return Colors.greenAccent;
}

/// Calculate progress through billing cycle (0.0 to 1.0)
/// Returns progress from last renewal to next renewal
double getBillingCycleProgress({
  required DateTime renewalDate,
  required BillingCycle billingCycle,
}) {
  final now = DateTime.now();
  
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
    case BillingCycle.custom:
      cycleDays = 30; // Default fallback
      break;
  }
  
  // Calculate last renewal date (renewalDate - cycleDays)
  final lastRenewal = renewalDate.subtract(Duration(days: cycleDays));
  
  // Calculate days since last renewal
  final daysSinceLastRenewal = now.difference(lastRenewal).inDays;
  
  // Calculate progress (clamp between 0.0 and 1.0)
  final progress = (daysSinceLastRenewal / cycleDays).clamp(0.0, 1.0);
  
  return progress;
}

/// Get renewal text (e.g., "Renews in 5 days" or "Renews today")
/// Automatically advances past renewal dates assuming charge succeeded
String getRenewalText(DateTime renewalDate, {required BillingCycle billingCycle}) {
  final now = DateTime.now();
  
  // Auto-advance renewal date if it's in the past
  final effectiveRenewalDate = _advanceRenewalDateIfPast(renewalDate, billingCycle);
  final daysUntilRenewal = effectiveRenewalDate.difference(now).inDays;
  
  if (daysUntilRenewal == 0) {
    return 'Renews today';
  } else if (daysUntilRenewal == 1) {
    return 'Renews tomorrow';
  } else {
    return 'Renews in $daysUntilRenewal days';
  }
}
