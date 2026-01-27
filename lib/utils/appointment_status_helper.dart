import 'package:flutter/material.dart';

/// Helper functions for determining appointment status colors
/// 
/// Traffic Light Mental Model Strategy:
/// - Orange: "Caution/Active" - Used for appointments happening today.
/// - Blue: "Safe/Flow" - Used for future appointments.

/// Check if two dates are on the same day
bool isAppointmentSameDay(DateTime date1, DateTime date2) {
  return date1.year == date2.year &&
      date1.month == date2.month &&
      date1.day == date2.day;
}

/// Get status color based on appointment date
Color getAppointmentStatusColor(DateTime appointmentDateTime) {
  final now = DateTime.now();
  
  // Happening today = Orange (attention needed)
  if (isAppointmentSameDay(appointmentDateTime, now)) {
    return Colors.orangeAccent;
  }
  
  // Future = Blue (normal flow)
  return Colors.blueAccent;
}

/// Format time for display (e.g., "3:00\nPM")
String formatAppointmentTime(DateTime dateTime) {
  final hour = dateTime.hour;
  final minute = dateTime.minute;
  final period = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
  final minuteStr = minute.toString().padLeft(2, '0');
  
  return '$displayHour:$minuteStr\n$period';
}
