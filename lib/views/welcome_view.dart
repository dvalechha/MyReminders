import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/subscription_provider.dart';
import '../providers/appointment_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/omnibox.dart';
import '../widgets/pulsing_gradient_placeholder.dart';
import '../widgets/default_welcome_view.dart';
import '../widgets/help_suggestion_view.dart';
import '../widgets/todays_snapshot_view.dart';
import '../utils/natural_language_parser.dart';
import '../services/intent_parser_service.dart';
import '../models/parsed_intent.dart';
import '../models/subscription.dart';
import 'unified_agenda_view.dart';
import 'subscription_form_view.dart';
import 'appointment_form_view.dart';
import 'task_form_view.dart';
import 'subscriptions_list_view.dart';
import 'appointments_list_view.dart';
import 'tasks_list_view.dart';

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
  bool _isTyping = false;

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
    if (_isTyping != query.isNotEmpty) {
      setState(() {
        _isTyping = query.isNotEmpty;
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
    
    // If the parsed intent is successful, handle based on action type
    // This handles cases where Omnibox detected it as search but it's actually a valid command
    if (_parsedIntent != null && _parsedIntent!.isSuccess) {
      _handleIntent(_parsedIntent!);
      return;
    }
    
    // TODO: In next iteration, implement search results view
    // This will show matching items from subscriptions, appointments, tasks, and custom reminders
    debugPrint('Search triggered: $query');
  }

  /// Central handler for parsed intents - routes to appropriate screens
  void _handleIntent(ParsedIntent intent) {
    final action = intent.action;
    final category = intent.category;

    if (action == 'show') {
      // Navigate to the appropriate list screen
      _navigateToListScreen(category);
    } else if (action == 'create') {
      // Navigate directly to the create form based on category
      _navigateToCreateScreen(intent.originalText, category);
    } else {
      // Unknown action - show help
      debugPrint('Unknown action: $action');
    }
  }

  /// Navigate to the appropriate create form based on category
  void _navigateToCreateScreen(String query, String? category) {
    // Parse the natural language input using NaturalLanguageParser for form data
    final parsed = NaturalLanguageParser.parse(query);
    
    // Determine which form to show based on category or parsed type
    ParsedReminderType typeToUse;
    if (category == 'appointment') {
      typeToUse = ParsedReminderType.appointment;
    } else if (category == 'task') {
      typeToUse = ParsedReminderType.task;
    } else if (category == 'subscription') {
      typeToUse = ParsedReminderType.subscription;
    } else {
      // Fallback to parsed type
      typeToUse = parsed.type;
    }
    
    // Navigate based on the determined type
    if (typeToUse == ParsedReminderType.subscription) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubscriptionFormView(
            initialServiceName: parsed.title ?? 'New Subscription',
            initialRenewalDate: parsed.date ?? DateTime.now().add(const Duration(days: 30)),
            initialAmount: parsed.amount,
            initialCurrency: _mapCurrencyCode(parsed.currencyCode),
            initialNotes: query,
          ),
        ),
      ).then((_) => _clearInputAfterNavigation());
    } else if (typeToUse == ParsedReminderType.appointment) {
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
        final now = DateTime.now();
        dateTime = DateTime(
          now.year,
          now.month,
          now.day,
          parsed.time!.hour,
          parsed.time!.minute,
        );
      } else {
        dateTime ??= DateTime.now().add(const Duration(days: 1));
      }
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AppointmentFormView(
            initialTitle: parsed.title ?? 'New Appointment',
            initialDateTime: dateTime,
            initialLocation: parsed.location,
            initialNotes: query,
          ),
        ),
      ).then((_) => _clearInputAfterNavigation());
    } else if (typeToUse == ParsedReminderType.task) {
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
        final now = DateTime.now();
        dueDate = DateTime(
          now.year,
          now.month,
          now.day,
          parsed.time!.hour,
          parsed.time!.minute,
        );
      }
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TaskFormView(
            initialTitle: parsed.title ?? 'New Task',
            initialDueDate: dueDate,
            initialNotes: query,
          ),
        ),
      ).then((_) => _clearInputAfterNavigation());
    } else {
      debugPrint('Could not determine form type from: $query');
    }
  }

  /// Clear input after returning from navigation
  void _clearInputAfterNavigation() {
    if (mounted) {
      setState(() {
        _currentInput = null;
        _parsedIntent = null;
        _hasSubmitted = false;
        _isTyping = false;
      });
      _omniboxController.clear();
    }
  }

  /// Navigate to the appropriate list screen based on category
  void _navigateToListScreen(String? category) {
    Widget? screen;
    
    switch (category) {
      case 'subscription':
        screen = const SubscriptionsListView();
        break;
      case 'appointment':
        screen = const AppointmentsListView();
        break;
      case 'task':
        screen = const TasksListView();
        break;
      case 'reminder':
        // Reminders can be shown as tasks or a dedicated screen
        screen = const TasksListView();
        break;
      default:
        debugPrint('Unknown category for show action: $category');
        return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen!),
    ).then((_) {
      // Clear input when returning from list screen
      if (mounted) {
        setState(() {
          _currentInput = null;
          _parsedIntent = null;
          _hasSubmitted = false;
          _isTyping = false;
        });
        _omniboxController.clear();
      }
    });
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
    
    // Parse the example to update the UI state
    final parsedIntent = _intentParser.parse(example);
    
    // Update state - don't navigate immediately, let user edit and hit GO
    setState(() {
      _currentInput = example;
      _hasSubmitted = false; // Reset so they can see the success view or edit
      _parsedIntent = parsedIntent;
      _isTyping = example.isNotEmpty;
    });
    
    // Request focus on the TextField to show keyboard and cursor
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
    
    // Parse using IntentParserService first
    final parsedIntent = _intentParser.parse(queryToUse);
    
    setState(() {
      _currentInput = queryToUse;
      _hasSubmitted = true; // User pressed Enter
      _parsedIntent = parsedIntent;
    });
    
    // If intent parsing was successful, use the intent-based routing
    if (parsedIntent.isSuccess) {
      _handleIntent(parsedIntent);
      return;
    }
    
    // Fallback to NaturalLanguageParser for backward compatibility
    final parsed = NaturalLanguageParser.parse(queryToUse);
    
    if (parsed.type == ParsedReminderType.subscription) {
      // Navigate to subscription form with pre-populated data (using initial values, not edit mode)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubscriptionFormView(
            initialServiceName: parsed.title ?? 'New Subscription',
            initialRenewalDate: parsed.date ?? DateTime.now().add(const Duration(days: 30)),
            initialAmount: parsed.amount,
            initialCurrency: _mapCurrencyCode(parsed.currencyCode),
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
            _isTyping = false;
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
            _isTyping = false;
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
            _isTyping = false;
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

  // Map parser currency code string to Subscription Currency enum
  Currency? _mapCurrencyCode(String? code) {
    switch (code?.toLowerCase()) {
      case 'usd':
        return Currency.usd;
      case 'cad':
        return Currency.cad;
      case 'eur':
        return Currency.eur;
      case 'inr':
        return Currency.inr;
      default:
        return null;
    }
  }

  Widget _buildContentArea(bool keyboardVisible) {
    // Default view: when input is empty
    if (_currentInput == null || _currentInput!.trim().isEmpty) {
      return AnimatedOpacity(
        opacity: keyboardVisible ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 250),
        child: IgnorePointer(
          ignoring: keyboardVisible,
          child: DefaultWelcomeView(
            onExampleTap: _handleExampleTap,
          ),
        ),
      );
    }

    // Parse the current input if not already parsed
    _parsedIntent ??= _intentParser.parse(_currentInput!);

    // Help/Suggestion view: only show when user has submitted (pressed Enter) AND parsing failed
    if (_hasSubmitted && !_parsedIntent!.isSuccess) {
      return HelpSuggestionView(
        onExampleTap: _handleExampleTap,
      );
    }

    // Show default view for all other cases (including when parsing is successful)
    // Hide suggestions when keyboard is visible
    return AnimatedOpacity(
      opacity: keyboardVisible ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 250),
      child: IgnorePointer(
        ignoring: keyboardVisible,
        child: DefaultWelcomeView(
          onExampleTap: _handleExampleTap,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _omniboxController.removeListener(_onTextChanged);
    _omniboxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Detect keyboard visibility
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    
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
                    _isTyping = false;
                  });
                },
                existingItems: _getExistingItems(),
              ),
              const SizedBox(height: 12),
                // Adaptive animation/preview box or Today's Snapshot
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          height: keyboardVisible
              ? 140.0
              : math.min(220.0, MediaQuery.of(context).size.height * 0.32),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isTyping
                ? PulsingGradientPlaceholder(
                    key: const ValueKey('placeholder'),
                    inputText: _currentInput,
                  )
                : SingleChildScrollView(
                    key: const ValueKey('snapshot_scroll'),
                    physics: const BouncingScrollPhysics(),
                    child: TodaysSnapshotView(
                      key: const ValueKey('snapshot'),
                      subscriptions: context.watch<SubscriptionProvider>().subscriptions,
                      appointments: context.watch<AppointmentProvider>().appointments,
                      tasks: context.watch<TaskProvider>().tasks,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const UnifiedAgendaView()),
                        );
                      },
                    ),
                  ),
          ),
        ),
              const SizedBox(height: 12),
              // Content area - scrollable when needed
              Expanded(
                child: _buildContentArea(keyboardVisible),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
