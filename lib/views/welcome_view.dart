import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/appointment_provider.dart';
import '../providers/task_provider.dart';
import '../providers/custom_reminder_provider.dart';
import 'subscription_form_view.dart';
import 'subscriptions_list_view.dart';
import 'appointment_form_view.dart';
import 'appointments_list_view.dart';
import 'task_form_view.dart';
import 'tasks_list_view.dart';
import 'custom_reminder_form_view.dart';
import 'custom_reminders_list_view.dart';

class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Choose what you\'d like to set up first.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  _buildCategoryList(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryList(BuildContext context) {
    return Column(
      children: [
        Consumer<SubscriptionProvider>(
          builder: (context, subscriptionProvider, child) {
            return _buildCategoryCardRow(
              context,
              title: 'Subscriptions',
              icon: Icons.credit_card,
              onTap: () {
                if (subscriptionProvider.subscriptions.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SubscriptionsListView(),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SubscriptionFormView(),
                    ),
                  );
                }
              },
            );
          },
        ),
        const SizedBox(height: 12),
        Consumer<AppointmentProvider>(
          builder: (context, appointmentProvider, child) {
            return _buildCategoryCardRow(
              context,
              title: 'Appointments',
              icon: Icons.calendar_today,
              onTap: () {
                if (appointmentProvider.appointments.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AppointmentsListView(),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AppointmentFormView(),
                    ),
                  );
                }
              },
            );
          },
        ),
        const SizedBox(height: 12),
        Consumer<TaskProvider>(
          builder: (context, taskProvider, child) {
            return _buildCategoryCardRow(
              context,
              title: 'Tasks',
              icon: Icons.check_circle_outline,
              onTap: () {
                if (taskProvider.tasks.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TasksListView(),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TaskFormView(),
                    ),
                  );
                }
              },
            );
          },
        ),
        const SizedBox(height: 12),
        Consumer<CustomReminderProvider>(
          builder: (context, customReminderProvider, child) {
            return _buildCategoryCardRow(
              context,
              title: 'Custom',
              icon: Icons.notifications_outlined,
              onTap: () {
                if (customReminderProvider.customReminders.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CustomRemindersListView(),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CustomReminderFormView(),
                    ),
                  );
                }
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryCardRow(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final iconColor = theme.colorScheme.primary;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey[300]!.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
              spreadRadius: 0,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: iconColor,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

