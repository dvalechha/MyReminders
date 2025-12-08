import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/subscription.dart';
import '../models/appointment.dart';
import '../models/task.dart';

class TodaysSnapshotView extends StatelessWidget {
  final List<Subscription> subscriptions;
  final List<Appointment> appointments;
  final List<Task> tasks;
  final VoidCallback onTap;

  const TodaysSnapshotView({
    super.key,
    required this.subscriptions,
    required this.appointments,
    required this.tasks,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final upNext = _selectUpNextAppointment(today);
    final dueToday = _selectDueTodayTask(today);
    final renewingSoon = _selectRenewingSoon(today);

    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 2,
        clipBehavior: Clip.hardEdge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Today's Snapshot",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 140),
                    child: TextButton(
                      onPressed: onTap,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'View Full Agenda →',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _SnapshotRow(
                icon: Icons.calendar_today,
                color: Colors.blueAccent,
                label: 'Up Next',
                value: upNext ?? 'No appointments today',
              ),
              const SizedBox(height: 8),
              _SnapshotRow(
                icon: Icons.check_box_outlined,
                color: Colors.green,
                label: 'Due Today',
                value: dueToday ?? 'No tasks due today',
              ),
              const SizedBox(height: 8),
              _SnapshotRow(
                icon: Icons.autorenew,
                color: Colors.deepOrange,
                label: 'Renewing Soon',
                value: renewingSoon ?? 'No renewals today or tomorrow',
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _selectUpNextAppointment(DateTime today) {
    final sameDay = appointments
        .where((a) => _isSameDay(a.dateTime, today) && a.dateTime.isAfter(DateTime.now()))
        .toList();
    if (sameDay.isEmpty) return null;
    sameDay.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final next = sameDay.first;
    final time = DateFormat('h:mm a').format(next.dateTime);
    return '${next.title} • $time';
  }

  String? _selectDueTodayTask(DateTime today) {
    final todaysTasks = tasks
        .where((t) => t.dueDate != null && _isSameDay(t.dueDate!, today))
        .toList();
    if (todaysTasks.isEmpty) return null;
    todaysTasks.sort((a, b) {
      final priA = _priorityScore(a.priority);
      final priB = _priorityScore(b.priority);
      if (priA != priB) return priB.compareTo(priA); // higher priority first
      final dueA = a.dueDate ?? DateTime.now();
      final dueB = b.dueDate ?? DateTime.now();
      return dueA.compareTo(dueB);
    });
    final task = todaysTasks.first;
    final time = task.dueDate != null ? ' • ${DateFormat('h:mm a').format(task.dueDate!)}' : '';
    return '${task.title}$time';
  }

  String? _selectRenewingSoon(DateTime today) {
    final windowEnd = today.add(const Duration(days: 1));
    final upcoming = subscriptions
        .where((s) => _isSameDay(s.renewalDate, today) || _isSameDay(s.renewalDate, windowEnd))
        .toList();
    if (upcoming.isEmpty) return null;
    upcoming.sort((a, b) => a.renewalDate.compareTo(b.renewalDate));
    final sub = upcoming.first;
    final dayLabel = _isSameDay(sub.renewalDate, today) ? 'Today' : 'Tomorrow';
    return '${sub.serviceName} • $dayLabel';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  int _priorityScore(TaskPriority? priority) {
    switch (priority) {
      case TaskPriority.high:
        return 3;
      case TaskPriority.medium:
        return 2;
      case TaskPriority.low:
        return 1;
      default:
        return 0;
    }
  }
}

class _SnapshotRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _SnapshotRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
