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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Upcoming Agenda'),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: items.isEmpty
          ? const Center(child: Text('No upcoming items'))
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _buildAgendaCard(item);
                },
              ),
            ),
    );
  }

  Widget _buildAgendaCard(_AgendaItem item) {
    // Get service initials for CircleAvatar
    final initials = _getInitials(item.title);
    
    // Format date without time
    final formattedDate = DateFormat('MMM d').format(item.date);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Leading: CircleAvatar
          CircleAvatar(
            radius: 24,
            backgroundColor: item.color.withOpacity(0.1),
            child: Text(
              initials,
              style: TextStyle(
                color: item.color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Middle: Title and Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                // Subtitle
                Text(
                  item.subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // Trailing: Price (for subscriptions) and Date
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Price (only for subscriptions)
              if (item.type == 'subscription' && item.amount != null)
                Text(
                  '\$${item.amount!.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                )
              else
                const SizedBox.shrink(),
              const SizedBox(height: 4),
              // Date
              Text(
                formattedDate,
                style: TextStyle(
                  color: item.color,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getInitials(String title) {
    if (title.isEmpty) return '?';
    final words = title.trim().split(' ');
    if (words.length >= 2) {
      // Take first letter of first two words
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else {
      // Take first letter, or first two if single word
      final word = words[0];
      if (word.length >= 2) {
        return word.substring(0, 2).toUpperCase();
      }
      return word[0].toUpperCase();
    }
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
          subtitle: sub.billingCycle.value, // Show billing cycle (e.g., "Monthly")
          icon: Icons.autorenew,
          color: Colors.deepOrange,
          amount: sub.amount,
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
  final double? amount; // For subscriptions

  _AgendaItem({
    required this.type,
    required this.title,
    required this.date,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.amount,
  });
}
