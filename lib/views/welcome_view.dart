import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/appointment_provider.dart';
import '../providers/task_provider.dart';
import '../providers/custom_reminder_provider.dart';
import '../widgets/omnibox.dart';
import '../widgets/pulsing_gradient_placeholder.dart';

class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key});

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> {
  String? _currentInput;

  // TODO: In future iterations, populate this with actual items from providers
  List<String> _getExistingItems() {
    final items = <String>[];
    
    // Collect items from all providers
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final customReminderProvider = Provider.of<CustomReminderProvider>(context, listen: false);
    
    // Add subscription titles
    for (final subscription in subscriptionProvider.subscriptions) {
      items.add(subscription.serviceName);
    }
    
    // Add appointment titles
    for (final appointment in appointmentProvider.appointments) {
      items.add(appointment.title);
    }
    
    // Add task titles
    for (final task in taskProvider.tasks) {
      items.add(task.title);
    }
    
    // Add custom reminder titles
    for (final reminder in customReminderProvider.customReminders) {
      items.add(reminder.title);
    }
    
    return items;
  }

  void _handleSearch(String query) {
    setState(() {
      _currentInput = query;
    });
    
    // TODO: In next iteration, implement search results view
    // This will show matching items from subscriptions, appointments, tasks, and custom reminders
    debugPrint('Search triggered: $query');
  }

  void _handleCreate(String query) {
    setState(() {
      _currentInput = query;
    });
    
    // TODO: In next iteration, implement create form view
    // This will parse the query and show appropriate form (task, appointment, subscription, etc.)
    debugPrint('Create triggered: $query');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Omnibox at the top
              Omnibox(
                onSearch: _handleSearch,
                onCreate: _handleCreate,
                existingItems: _getExistingItems(),
              ),
              const SizedBox(height: 24),
              // Placeholder visualization that reacts to input
              PulsingGradientPlaceholder(
                inputText: _currentInput,
              ),
              const SizedBox(height: 24),
              // TODO: Dynamic content area
              // This area will be populated based on user input in future updates:
              // - Search results when search intent is detected
              // - Create form when create intent is detected
              // - Suggestions when input is empty
              Expanded(
                child: Container(
                  // Placeholder for future dynamic content
                  // Will be replaced with actual search results or create forms
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
