import 'package:flutter/material.dart';
import '../models/task.dart';

/// Helper functions for determining task status colors
/// 
/// Traffic Light Mental Model Strategy:
/// - Red: "Stop/Critical" - Used for High Priority or Overdue items to grab immediate attention.
/// - Orange: "Caution/Active" - Used for Medium Priority or tasks due Today.
/// - Blue/Green: "Safe/Flow" - Used for Future items or Low priority.

/// Check if two dates are on the same day
bool isSameDay(DateTime? date1, DateTime? date2) {
  if (date1 == null || date2 == null) return false;
  return date1.year == date2.year &&
      date1.month == date2.month &&
      date1.day == date2.day;
}

/// Get status color based on task priority and due date
Color getTaskStatusColor({
  required TaskPriority? priority,
  required DateTime? dueDate,
}) {
  final now = DateTime.now();
  
  // High priority or overdue = Red (urgent)
  if (priority == TaskPriority.high || 
      (dueDate != null && dueDate.isBefore(now) && !isSameDay(dueDate, now))) {
    return Colors.redAccent;
  }
  
  // Medium priority or due today = Orange (attention needed)
  if (priority == TaskPriority.medium || 
      (dueDate != null && isSameDay(dueDate, now))) {
    return Colors.orangeAccent;
  }
  
  // Low priority or future = Blue (normal flow)
  return Colors.blueAccent;
}

/// Format due date for display
String formatTaskDueDate(DateTime? dueDate) {
  if (dueDate == null) return '';
  
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
  
  if (due == today) {
    return 'Today';
  } else if (due == tomorrow) {
    return 'Tomorrow';
  } else if (due.isBefore(today)) {
    return 'Overdue';
  } else {
    // Format as "MMM d, yyyy"
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dueDate.month - 1]} ${dueDate.day}, ${dueDate.year}';
  }
}
