import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/appointment_provider.dart';
import '../providers/task_provider.dart';
import '../providers/custom_reminder_provider.dart';
import '../widgets/omnibox.dart';
import '../widgets/pulsing_gradient_placeholder.dart';
import '../widgets/default_welcome_view.dart';
import '../widgets/success_intent_view.dart';
import '../widgets/help_suggestion_view.dart';
import '../utils/natural_language_parser.dart';
import '../services/intent_parser_service.dart';
import '../models/parsed_intent.dart';
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
  final IntentParserService _intentParser = IntentParserService();
  ParsedIntent? _parsedIntent;
  bool _hasSubmitted = false; // Track if user has pressed Enter
  final GlobalKey<OmniboxState> _omniboxKey = GlobalKey<OmniboxState>();

  @override
  void initState() {
    super.initState();
    // Listen to text changes in real-time for Success view updates
    _omniboxController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final query = _omniboxController.text;
    // Reset submitted flag when user starts typing again
    if (_hasSubmitted && query != _currentInput) {
      setState(() {
        _hasSubmitted = false;
      });
    }
    _handleInputChange(query);
  }

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
      _hasSubmitted = true; // User pressed Enter
      // Parse the input to determine UI state
      if (query.trim().isEmpty) {
        _parsedIntent = null;
      } else {
        _parsedIntent = _intentParser.parse(query);
      }
    });
    
    // If the parsed intent is successful, treat it as a create action and navigate
    // This handles the case where user selects a suggestion and hits enter
    if (_parsedIntent != null && _parsedIntent!.isSuccess) {
      _handleCreate(query);
      return;
    }
    
    // TODO: In next iteration, implement search results view
    // This will show matching items from subscriptions, appointments, tasks, and custom reminders
    debugPrint('Search triggered: $query');
  }

  void _handleInputChange(String query) {
    setState(() {
      _currentInput = query;
      // Parse the input to determine UI state
      if (query.trim().isEmpty) {
        _parsedIntent = null;
      } else {
        _parsedIntent = _intentParser.parse(query);
      }
    });
  }

  void _handleExampleTap(String example) {
    // Populate the TextField with the example text
    _omniboxController.text = example;
    _omniboxController.selection = TextSelection.fromPosition(
      TextPosition(offset: example.length),
    );
    // Reset submitted flag and update state immediately when user selects an example
    setState(() {
      _currentInput = example;
      _hasSubmitted = false;
      // Parse the example immediately
      _parsedIntent = _intentParser.parse(example);
    });
    // Request focus on the TextField to show keyboard and cursor
    // Use a longer delay to ensure the tap event completes and UI updates
    Future.delayed(const Duration(milliseconds: 100), () {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _omniboxKey.currentState?.requestTextFieldFocus();
      });
    });
  }

  void _handleCreate(String query) {
    // Ensure we're using the latest query from the controller
    final actualQuery = _omniboxController.text.trim();
    final queryToUse = actualQuery.isNotEmpty ? actualQuery : query;
    
    setState(() {
      _currentInput = queryToUse;
      _hasSubmitted = true; // User pressed Enter
      // Parse the input to determine UI state
      _parsedIntent = _intentParser.parse(queryToUse);
    });
    
    // Parse the natural language input using NaturalLanguageParser for navigation
    final parsed = NaturalLanguageParser.parse(queryToUse);
    
    if (parsed.type == ParsedReminderType.subscription) {
      // Navigate to subscription form with pre-populated data (using initial values, not edit mode)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubscriptionFormView(
            initialServiceName: parsed.title ?? 'New Subscription',
            initialRenewalDate: parsed.date ?? DateTime.now().add(const Duration(days: 30)),
            initialNotes: queryToUse, // Store the original query as notes for reference
          ),
        ),
      ).then((_) {
        // Clear input and omnibox text when returning from form
        if (mounted) {
          setState(() {
            _currentInput = null;
            _parsedIntent = null;
            _hasSubmitted = false;
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
            initialNotes: queryToUse, // Store the original query as notes for reference
          ),
        ),
      ).then((_) {
        // Clear input and omnibox text when returning from form
        if (mounted) {
          setState(() {
            _currentInput = null;
            _parsedIntent = null;
            _hasSubmitted = false;
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
            initialNotes: queryToUse, // Store the original query as notes for reference
          ),
        ),
      ).then((_) {
        // Clear input and omnibox text when returning from form
        if (mounted) {
          setState(() {
            _currentInput = null;
            _parsedIntent = null;
            _hasSubmitted = false;
          });
          // Clear the omnibox text
          _omniboxController.clear();
        }
      });
    } else {
      // Unknown type - Help view will already be displayed if parsing failed
      // No need to show a SnackBar, the Help view provides better guidance
      debugPrint('Could not determine reminder type from: $queryToUse');
    }
  }

  Widget _buildContentArea() {
    // Default view: when input is empty
    if (_currentInput == null || _currentInput!.trim().isEmpty) {
      return const DefaultWelcomeView();
    }

    // Parse the current input if not already parsed
    _parsedIntent ??= _intentParser.parse(_currentInput!);

    // Success view: when parsing was successful (show while typing or after submit)
    if (_parsedIntent!.isSuccess) {
      return SuccessIntentView(parsedIntent: _parsedIntent!);
    }

    // Help/Suggestion view: only show when user has submitted (pressed Enter) AND parsing failed
    if (_hasSubmitted) {
      return HelpSuggestionView(
        onExampleTap: _handleExampleTap,
      );
    }

    // While typing and not successful yet, show default view (don't show errors prematurely)
    return const DefaultWelcomeView();
  }

  @override
  void dispose() {
    _omniboxController.removeListener(_onTextChanged);
    _omniboxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Omnibox at the top
              Omnibox(
                key: _omniboxKey,
                controller: _omniboxController,
                onSearch: _handleSearch,
                onCreate: _handleCreate,
                onClear: () {
                  // Clear input when omnibox is cleared
                  setState(() {
                    _currentInput = null;
                    _parsedIntent = null;
                    _hasSubmitted = false; // Reset submitted flag
                  });
                },
                existingItems: _getExistingItems(),
              ),
              const SizedBox(height: 12),
              // Placeholder visualization that reacts to input
              Flexible(
                flex: 1,
                child: PulsingGradientPlaceholder(
                  inputText: _currentInput,
                ),
              ),
              const SizedBox(height: 12),
              // Dynamic content area based on parsing state
              Flexible(
                flex: 2,
                child: _buildContentArea(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
