import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/appointment_provider.dart';
import '../providers/task_provider.dart';
import '../providers/custom_reminder_provider.dart';
import '../widgets/omnibox.dart';
import '../widgets/pulsing_gradient_placeholder.dart';
import '../utils/natural_language_parser.dart';
import 'subscription_form_view.dart';
import 'appointment_form_view.dart';
import 'task_form_view.dart';

class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key});

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> {
  String? _currentInput;
  final TextEditingController _omniboxController = TextEditingController();

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
    
    // Parse the natural language input
    final parsed = NaturalLanguageParser.parse(query);
    
    if (parsed.type == ParsedReminderType.subscription) {
      // Navigate to subscription form with pre-populated data (using initial values, not edit mode)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubscriptionFormView(
            initialServiceName: parsed.title ?? 'New Subscription',
            initialRenewalDate: parsed.date ?? DateTime.now().add(const Duration(days: 30)),
            initialNotes: query, // Store the original query as notes for reference
          ),
        ),
      ).then((_) {
        // Clear input and omnibox text when returning from form
        if (mounted) {
          setState(() {
            _currentInput = null;
          });
          // Clear the omnibox text
          _omniboxController.clear();
        }
      });
    } else if (parsed.type == ParsedReminderType.appointment) {
      // Combine date and time if both are present
      DateTime? dateTime = parsed.date;
      if (dateTime != null && parsed.time != null) {
        dateTime = DateTime(
          dateTime.year,
          dateTime.month,
          dateTime.day,
          parsed.time!.hour,
          parsed.time!.minute,
        );
      } else if (parsed.time != null) {
        // If only time is provided, use today's date
        final now = DateTime.now();
        dateTime = DateTime(
          now.year,
          now.month,
          now.day,
          parsed.time!.hour,
          parsed.time!.minute,
        );
      } else {
        // Default to tomorrow if no date provided
        dateTime ??= DateTime.now().add(const Duration(days: 1));
      }
      
      // Navigate to appointment form with pre-populated data (using initial values, not edit mode)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AppointmentFormView(
            initialTitle: parsed.title ?? 'New Appointment',
            initialDateTime: dateTime,
            initialLocation: parsed.location,
            initialNotes: query, // Store the original query as notes for reference
          ),
        ),
      ).then((_) {
        // Clear input and omnibox text when returning from form
        if (mounted) {
          setState(() {
            _currentInput = null;
          });
          // Clear the omnibox text
          _omniboxController.clear();
        }
      });
    } else if (parsed.type == ParsedReminderType.task) {
      // Combine date and time if both are present
      DateTime? dueDate = parsed.date;
      if (dueDate != null && parsed.time != null) {
        dueDate = DateTime(
          dueDate.year,
          dueDate.month,
          dueDate.day,
          parsed.time!.hour,
          parsed.time!.minute,
        );
      } else if (parsed.time != null) {
        // If only time is provided, use today's date
        final now = DateTime.now();
        dueDate = DateTime(
          now.year,
          now.month,
          now.day,
          parsed.time!.hour,
          parsed.time!.minute,
        );
      }
      
      // Navigate to task form with pre-populated data (using initial values, not edit mode)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TaskFormView(
            initialTitle: parsed.title ?? 'New Task',
            initialDueDate: dueDate,
            initialNotes: query, // Store the original query as notes for reference
          ),
        ),
      ).then((_) {
        // Clear input and omnibox text when returning from form
        if (mounted) {
          setState(() {
            _currentInput = null;
          });
          // Clear the omnibox text
          _omniboxController.clear();
        }
      });
    } else {
      // Unknown type - show a message or default behavior
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not determine reminder type. Please specify "subscription", "appointment", or "task".'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _omniboxController.dispose();
    super.dispose();
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
                controller: _omniboxController,
                onSearch: _handleSearch,
                onCreate: _handleCreate,
                onClear: () {
                  // Clear input when omnibox is cleared
                  setState(() {
                    _currentInput = null;
                  });
                },
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
