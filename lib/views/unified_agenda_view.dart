import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/appointment_provider.dart';
import '../providers/task_provider.dart';
import '../models/subscription.dart';
import '../models/appointment.dart';
import '../models/task.dart';

class UnifiedAgendaView extends StatefulWidget {
  const UnifiedAgendaView({super.key});

  @override
  State<UnifiedAgendaView> createState() => _UnifiedAgendaViewState();
}

class _UnifiedAgendaViewState extends State<UnifiedAgendaView> {
  @override
  Widget build(BuildContext context) {
    final subscriptions = context.watch<SubscriptionProvider>().subscriptions;
    final appointments = context.watch<AppointmentProvider>().appointments;
    final tasks = context.watch<TaskProvider>().tasks;

    final items = _buildAgendaItems(subscriptions, appointments, tasks);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Agenda'),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: items.isEmpty
          ? const Center(child: Text('No upcoming items'))
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  leading: Icon(item.icon, color: item.color),
                  title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(item.subtitle),
                  trailing: Text(item.timeLabel, style: const TextStyle(fontSize: 12)),
                );
              },
            ),
    );
  }

  List<_AgendaItem> _buildAgendaItems(
    List<Subscription> subscriptions,
    List<Appointment> appointments,
    List<Task> tasks,
  ) {
    final List<_AgendaItem> agenda = [];

    for (final sub in subscriptions) {
      agenda.add(
        _AgendaItem(
          type: 'subscription',
          title: sub.serviceName,
          date: sub.renewalDate,
          subtitle: 'Renews • ${sub.currency.value} ${sub.amount.toStringAsFixed(2)}',
          icon: Icons.autorenew,
          color: Colors.deepOrange,
        ),
      );
    }

    for (final appt in appointments) {
      agenda.add(
        _AgendaItem(
          type: 'appointment',
          title: appt.title,
          date: appt.dateTime,
          subtitle: appt.location ?? 'Appointment',
          icon: Icons.calendar_today,
          color: Colors.blueAccent,
        ),
      );
    }

    for (final task in tasks) {
      if (task.dueDate == null) continue;
      agenda.add(
        _AgendaItem(
          type: 'task',
          title: task.title,
          date: task.dueDate!,
          subtitle: task.priority?.value ?? 'Task',
          icon: Icons.check_box_outlined,
          color: Colors.green,
        ),
      );
    }

    agenda.sort((a, b) => a.date.compareTo(b.date));
    return agenda;
  }
}

class _AgendaItem {
  final String type;
  final String title;
  final DateTime date;
  final String subtitle;
  final IconData icon;
  final Color color;

  _AgendaItem({
    required this.type,
    required this.title,
    required this.date,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  String get timeLabel {
    final dateLabel = DateFormat('EEE, MMM d').format(date);
    final timeLabel = DateFormat('h:mm a').format(date);
    return '$dateLabel • $timeLabel';
  }
}
