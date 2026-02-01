import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../widgets/empty_state_view.dart';
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
          ? EmptyStateView(
              icon: Icons.event_available_rounded,
              title: 'No Upcoming Items',
              description: 'You are all caught up! Enjoy your free time.',
              buttonText: 'Add New Item',
              onPressed: () {
                // Navigate back to Home (WelcomeView) where the Omnibox is
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  if (item.type == 'subscription') {
                    return _AgendaSubscriptionCard(item: item);
                  }
                  return _AgendaItemCard(item: item);
                },
              ),
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
          id: sub.id,
          type: 'subscription',
          title: sub.serviceName,
          date: sub.renewalDate,
          subtitle: sub.billingCycle.value,
          icon: Icons.autorenew,
          color: Colors.deepOrange,
          amount: sub.amount,
        ),
      );
    }

    for (final appt in appointments) {
      agenda.add(
        _AgendaItem(
          id: appt.id,
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
          id: task.id,
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
  final String id;
  final String type;
  final String title;
  final DateTime date;
  final String subtitle;
  final IconData icon;
  final Color color;
  final double? amount;

  _AgendaItem({
    required this.id,
    required this.type,
    required this.title,
    required this.date,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.amount,
  });
}

class _AgendaItemCard extends StatelessWidget {
  final _AgendaItem item;

  const _AgendaItemCard({required this.item});

  String _getInitials(String title) {
    if (title.isEmpty) return '?';
    final words = title.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else {
      final word = words[0];
      if (word.length >= 2) {
        return word.substring(0, 2).toUpperCase();
      }
      return word[0].toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(item.title);
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
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
}

class _AgendaSubscriptionCard extends StatelessWidget {
  final _AgendaItem item;

  const _AgendaSubscriptionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, provider, child) {
        final isPendingRenewal = provider.pendingRenewals.contains(item.id);

        if (isPendingRenewal) {
          return _buildGhostCard(context, provider);
        }

        return Dismissible(
          key: Key('sub_${item.id}'),
          direction: DismissDirection.startToEnd,
          background: Container(
            margin: const EdgeInsets.only(bottom: 12),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.autorenew, color: Colors.green),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              provider.startRenewSubscription(item.id);
              return false;
            }
            return false;
          },
          child: _AgendaItemCard(item: item),
        );
      },
    );
  }

  Widget _buildGhostCard(BuildContext context, SubscriptionProvider provider) {
    final duration = provider.pendingRenewalDurations[item.id] ?? const Duration(seconds: 10);
    final isEarly = duration.inSeconds == 30;
    final totalSeconds = duration.inSeconds.toDouble();

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: totalSeconds, end: 0.0),
      duration: duration,
      builder: (context, value, child) {
        final remainingSeconds = value.ceil();
        final progress = value / totalSeconds;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Renewing ${item.title}...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isEarly)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Text(
                        'Early',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                    ),
                  TextButton(
                    onPressed: () {
                      provider.undoRenewSubscription(item.id);
                    },
                    child: Text('Undo (${remainingSeconds}s)', style: const TextStyle(color: Colors.green)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.green.shade100,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ],
          ),
        );
      },
    );
  }
}
