import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/subscription.dart';
import '../providers/subscription_provider.dart';
import '../services/notification_service.dart';
import 'custom_reminder_modal.dart';

class SubscriptionFormView extends StatefulWidget {
  final Subscription? subscription;

  const SubscriptionFormView({
    super.key,
    this.subscription,
  });

  @override
  State<SubscriptionFormView> createState() => _SubscriptionFormViewState();
}

class _SubscriptionFormViewState extends State<SubscriptionFormView> {
  final _formKey = GlobalKey<FormState>();
  final _serviceNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _paymentMethodController = TextEditingController();

  SubscriptionCategory _selectedCategory = SubscriptionCategory.entertainment;
  Currency _selectedCurrency = Currency.usd;
  DateTime _selectedRenewalDate = DateTime.now();
  BillingCycle _selectedBillingCycle = BillingCycle.monthly;
  ReminderTime _selectedReminder = ReminderTime.none;
  int _customReminderDays = 0;
  bool _showAdditionalInfo = false;

  bool _isAuthorized = false;

  @override
  void initState() {
    super.initState();
    _checkNotificationPermission();
    if (widget.subscription != null) {
      _loadSubscriptionData();
    }
  }

  Future<void> _checkNotificationPermission() async {
    final notificationService = NotificationService.instance;
    await notificationService.initialize();
    final authorized = await notificationService.checkAuthorizationStatus();
    setState(() {
      _isAuthorized = authorized;
    });
  }

  void _loadSubscriptionData() {
    final sub = widget.subscription!;
    _serviceNameController.text = sub.serviceName;
    _amountController.text = sub.amount.toStringAsFixed(2);
    _selectedCategory = sub.category;
    _selectedCurrency = sub.currency;
    _selectedRenewalDate = sub.renewalDate;
    _selectedBillingCycle = sub.billingCycle;
    _selectedReminder = sub.reminder;
    _customReminderDays = sub.reminderDaysBefore;
    _notesController.text = sub.notes ?? '';
    _paymentMethodController.text = sub.paymentMethod ?? '';
  }

  @override
  void dispose() {
    _serviceNameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _paymentMethodController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _serviceNameController.text.trim().isNotEmpty &&
        (double.tryParse(_amountController.text) ?? 0.0) > 0;
  }

  String get _reminderDisplayText {
    if (_selectedReminder == ReminderTime.custom && _customReminderDays > 0) {
      final dayText = _customReminderDays == 1 ? 'day' : 'days';
      return 'Custom (${_customReminderDays} $dayText before)';
    }
    return _selectedReminder.value;
  }

  int get _reminderDaysBefore {
    if (_selectedReminder == ReminderTime.custom) {
      return _customReminderDays;
    }
    switch (_selectedReminder) {
      case ReminderTime.oneDay:
        return 1;
      case ReminderTime.threeDays:
        return 3;
      case ReminderTime.sevenDays:
        return 7;
      default:
        return 0;
    }
  }

  String get _reminderType {
    if (_selectedReminder == ReminderTime.none) {
      return 'none';
    } else if (_selectedReminder == ReminderTime.custom) {
      return 'custom';
    } else {
      return 'preset';
    }
  }

  Future<void> _selectCustomReminder() async {
    final result = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (context) => CustomReminderModal(
          initialDays: _customReminderDays > 0 ? _customReminderDays : 1,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _customReminderDays = result;
        if (result < 1 || result > 29) {
          _selectedReminder = ReminderTime.none;
          _customReminderDays = 0;
        }
      });
    } else {
      // User cancelled - reset if no valid days
      if (_customReminderDays < 1 || _customReminderDays > 29) {
        setState(() {
          _selectedReminder = ReminderTime.none;
          _customReminderDays = 0;
        });
      }
    }
  }

  Future<void> _saveSubscription() async {
    if (!_formKey.currentState!.validate() || !_isFormValid) {
      return;
    }

    final provider = Provider.of<SubscriptionProvider>(context, listen: false);

    final subscription = Subscription(
      id: widget.subscription?.id,
      serviceName: _serviceNameController.text.trim(),
      category: _selectedCategory,
      amount: double.parse(_amountController.text),
      currency: _selectedCurrency,
      renewalDate: _selectedRenewalDate,
      billingCycle: _selectedBillingCycle,
      reminder: _selectedReminder,
      reminderType: _reminderType,
      reminderDaysBefore: _reminderDaysBefore,
      notificationId: widget.subscription?.notificationId,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      paymentMethod: _paymentMethodController.text.trim().isEmpty
          ? null
          : _paymentMethodController.text.trim(),
    );

    try {
      if (widget.subscription == null) {
        await provider.addSubscription(subscription);
      } else {
        await provider.updateSubscription(subscription);
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving subscription: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subscription == null
            ? 'Add Subscription'
            : 'Edit Subscription'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Notification warning banner
                  if (!_isAuthorized)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.notifications_off,
                              color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Notifications are turned off. Enable them in Settings.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Subscription Details Section
                  const Text(
                    'SUBSCRIPTION DETAILS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _serviceNameController,
                    decoration: const InputDecoration(
                      labelText: 'Service Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a service name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<SubscriptionCategory>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: SubscriptionCategory.values.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category.value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCategory = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _amountController,
                          decoration: const InputDecoration(
                            labelText: 'Amount',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value == null ||
                                double.tryParse(value) == null ||
                                double.parse(value) <= 0) {
                              return 'Please enter a valid amount';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 100,
                        child: DropdownButtonFormField<Currency>(
                          value: _selectedCurrency,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                          items: Currency.values.map((currency) {
                            return DropdownMenuItem(
                              value: currency,
                              child: Text(currency.value),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedCurrency = value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Renewal & Reminder Section
                  const Text(
                    'RENEWAL & REMINDER',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    title: const Text('Renewal Date'),
                    subtitle: Text(DateFormat('MMM d, yyyy').format(_selectedRenewalDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedRenewalDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (date != null) {
                        setState(() => _selectedRenewalDate = date);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<BillingCycle>(
                    value: _selectedBillingCycle,
                    decoration: const InputDecoration(
                      labelText: 'Billing Cycle',
                      border: OutlineInputBorder(),
                    ),
                    items: BillingCycle.values.map((cycle) {
                      return DropdownMenuItem(
                        value: cycle,
                        child: Text(cycle.value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedBillingCycle = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  // Reminder Picker
                  ListTile(
                    title: const Text('Reminder'),
                    subtitle: Text(_reminderDisplayText),
                    trailing: const Icon(Icons.arrow_drop_down),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => _buildReminderPicker(),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  // Additional Info Section
                  if (_showAdditionalInfo) ...[
                    const Text(
                      'ADDITIONAL INFO',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _paymentMethodController,
                      decoration: const InputDecoration(
                        labelText: 'Payment Method',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ] else
                    ListTile(
                      leading: const Icon(Icons.add_circle, color: Colors.blue),
                      title: const Text('Add more details'),
                      onTap: () {
                        setState(() => _showAdditionalInfo = true);
                      },
                    ),
                ],
              ),
            ),
            // Bottom Save Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.2),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isFormValid ? _saveSubscription : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _isFormValid ? Colors.blue : Colors.grey,
                  ),
                  child: Text(
                    widget.subscription == null
                        ? 'Save Subscription'
                        : 'Update Subscription',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderPicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: ReminderTime.values.map((reminder) {
          final isSelected = _selectedReminder == reminder;
          return ListTile(
            title: Text(reminder == ReminderTime.custom ? 'Custom' : reminder.value),
            trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
            onTap: () {
              setState(() {
                _selectedReminder = reminder;
                if (reminder == ReminderTime.custom) {
                  Navigator.pop(context);
                  _selectCustomReminder();
                } else {
                  Navigator.pop(context);
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }
}

