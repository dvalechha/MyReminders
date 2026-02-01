import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/subscription.dart';
import '../providers/subscription_provider.dart';
import '../services/notification_service.dart';
import '../widgets/modern_form_field.dart';
import '../utils/snackbar.dart';

class SubscriptionFormView extends StatefulWidget {
  final Subscription? subscription;
  final String? initialServiceName;
  final DateTime? initialRenewalDate;
  final String? initialNotes;
  final double? initialAmount;
  final Currency? initialCurrency;

  const SubscriptionFormView({
    super.key,
    this.subscription,
    this.initialServiceName,
    this.initialRenewalDate,
    this.initialNotes,
    this.initialAmount,
    this.initialCurrency,
  });

  @override
  State<SubscriptionFormView> createState() => _SubscriptionFormViewState();
}

class _SubscriptionFormViewState extends State<SubscriptionFormView> {
  final _formKey = GlobalKey<FormState>();
  final _serviceNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  
  // Logic state
  SubscriptionCategory _selectedCategory = SubscriptionCategory.entertainment;
  Currency _selectedCurrency = Currency.usd;
  DateTime _selectedDateTime = DateTime.now();
  BillingCycle _selectedBillingCycle = BillingCycle.monthly;
  ReminderTime _selectedReminder = ReminderTime.none;
  int _customReminderDays = 0;
  
  bool _isSaving = false;
  String? _renewalDateTimeError;

  @override
  void initState() {
    super.initState();
    _checkNotificationPermission();
    
    // Default to current time
    _selectedDateTime = DateTime.now();

    if (widget.subscription != null) {
      _loadSubscriptionData();
    } else {
      if (widget.initialServiceName != null) _serviceNameController.text = widget.initialServiceName!;
      if (widget.initialAmount != null) _amountController.text = widget.initialAmount!.toStringAsFixed(2);
      if (widget.initialRenewalDate != null) _selectedDateTime = widget.initialRenewalDate!;
      if (widget.initialNotes != null) _notesController.text = widget.initialNotes!;
      if (widget.initialCurrency != null) _selectedCurrency = widget.initialCurrency!;
    }
    _updateDateTimeControllers();
  }

  Future<void> _checkNotificationPermission() async {
    final notificationService = NotificationService.instance;
    await notificationService.initialize();
    await notificationService.checkAuthorizationStatus();
  }

  void _loadSubscriptionData() {
    final sub = widget.subscription!;
    _serviceNameController.text = sub.serviceName;
    _amountController.text = sub.amount.toStringAsFixed(2);
    _selectedCategory = sub.category;
    _selectedCurrency = sub.currency;
    _selectedDateTime = sub.renewalDate.toLocal();
    _selectedBillingCycle = sub.billingCycle;
    _selectedReminder = sub.reminder;
    _customReminderDays = sub.reminderDaysBefore;
    _notesController.text = sub.notes ?? '';
    _updateDateTimeControllers();
  }

  void _updateDateTimeControllers() {
    _dateController.text = DateFormat('MMM d, yyyy').format(_selectedDateTime);
    _timeController.text = DateFormat('h:mm a').format(_selectedDateTime);
    _validateRenewalDateTime();
  }

  void _validateRenewalDateTime() {
    if (_selectedDateTime.isBefore(DateTime.now())) {
      setState(() {
        _renewalDateTimeError = 'Renewal date cannot be in the past.';
      });
    } else {
      setState(() {
        _renewalDateTimeError = null;
      });
    }
  }

  @override
  void dispose() {
    _serviceNameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  int get _reminderDaysBefore {
    if (_selectedReminder == ReminderTime.custom) return _customReminderDays;
    switch (_selectedReminder) {
      case ReminderTime.oneDay: return 1;
      case ReminderTime.threeDays: return 3;
      case ReminderTime.sevenDays: return 7;
      default: return 0;
    }
  }

  String get _reminderType {
    if (_selectedReminder == ReminderTime.none) return 'none';
    if (_selectedReminder == ReminderTime.custom) return 'custom';
    return 'preset';
  }

  void _showDatePicker() {
    const brandBlue = Color(0xFF2D62ED);
    final minDate = DateTime.now().subtract(const Duration(days: 365));
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext builder) {
        return SizedBox(
          height: 300,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Select Date', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandBlue)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: _selectedDateTime,
                    minimumDate: minDate,
                    maximumDate: DateTime.now().add(const Duration(days: 3650)),
                    onDateTimeChanged: (newDate) {
                      setState(() {
                        _selectedDateTime = DateTime(
                          newDate.year,
                          newDate.month,
                          newDate.day,
                          _selectedDateTime.hour,
                          _selectedDateTime.minute,
                        );
                        _updateDateTimeControllers();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTimePicker() {
    const brandBlue = Color(0xFF2D62ED);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext builder) {
        return SizedBox(
          height: 300,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Select Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: brandBlue)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: _selectedDateTime,
                    use24hFormat: false,
                    onDateTimeChanged: (newTime) {
                      setState(() {
                        _selectedDateTime = DateTime(
                          _selectedDateTime.year,
                          _selectedDateTime.month,
                          _selectedDateTime.day,
                          newTime.hour,
                          newTime.minute,
                        );
                        _updateDateTimeControllers();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveSubscription() async {
    if (_isSaving) return;
    _validateRenewalDateTime();
    if (_renewalDateTimeError != null) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_renewalDateTimeError!), backgroundColor: Colors.red));
       return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final provider = Provider.of<SubscriptionProvider>(context, listen: false);
      final double amount = double.tryParse(_amountController.text) ?? 0.0;

      final subscription = Subscription(
        id: widget.subscription?.id,
        serviceName: _serviceNameController.text.trim(),
        category: _selectedCategory,
        amount: amount,
        currency: _selectedCurrency,
        renewalDate: _selectedDateTime,
        billingCycle: _selectedBillingCycle,
        reminder: _selectedReminder,
        reminderType: _reminderType,
        reminderDaysBefore: _reminderDaysBefore,
        notificationId: widget.subscription?.notificationId,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        paymentMethod: widget.subscription?.paymentMethod,
      );

      if (widget.subscription == null) {
        await provider.addSubscription(subscription);
      } else {
        await provider.updateSubscription(subscription);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        SnackbarHelper.showError(context, 'Error saving: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const brandBlue = Color(0xFF2D62ED);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.subscription == null ? 'Add Subscription' : 'Edit Subscription',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.grey[50],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.subscription != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete?'),
                    content: const Text('This cannot be undone.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirm == true && mounted) {
                  await Provider.of<SubscriptionProvider>(context, listen: false).deleteSubscription(widget.subscription!.id);
                  Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Service Name
                    ModernFormField(
                      label: 'Service Name',
                      hint: 'e.g. Netflix, Spotify',
                      controller: _serviceNameController,
                      validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 20),

                    // Amount Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: ModernFormField(
                            label: 'Cost',
                            hint: '0.00',
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (double.tryParse(v) == null) return 'Invalid';
                              return null;
                            },
                            prefixIcon: const Icon(Icons.attach_money, size: 20),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(bottom: 8.0, left: 4.0),
                                child: Text(
                                  'Currency',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              Container(
                                height: 56,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<Currency>(
                                    value: _selectedCurrency,
                                    isExpanded: true,
                                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                                    items: Currency.values.map((c) {
                                      return DropdownMenuItem(
                                        value: c,
                                        child: Text(c.value, style: const TextStyle(fontWeight: FontWeight.w500)),
                                      );
                                    }).toList(),
                                    onChanged: (v) => setState(() => _selectedCurrency = v!),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Billing Cycle (Full width)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8.0, left: 4.0),
                          child: Text(
                            'Billing Cycle',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<BillingCycle>(
                              value: _selectedBillingCycle,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                              items: BillingCycle.values.map((cycle) {
                                return DropdownMenuItem(
                                  value: cycle,
                                  child: Text(cycle.value, style: const TextStyle(fontWeight: FontWeight.w500)),
                                );
                              }).toList(),
                              onChanged: (v) => setState(() => _selectedBillingCycle = v!),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Split Row for Date and Time
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ModernFormField(
                            label: 'Renewal Date',
                            controller: _dateController,
                            readOnly: true,
                            suffixIcon: const Icon(Icons.calendar_today_rounded, color: brandBlue, size: 20),
                            onTap: _showDatePicker,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ModernFormField(
                            label: 'Time',
                            controller: _timeController,
                            readOnly: true,
                            suffixIcon: const Icon(Icons.access_time_rounded, color: brandBlue, size: 20),
                            onTap: _showTimePicker,
                          ),
                        ),
                      ],
                    ),
                    if (_renewalDateTimeError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 4),
                        child: Text(
                          _renewalDateTimeError!,
                          style: const TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ),
                    
                    const SizedBox(height: 20),
                    
                    // Notes
                    ModernFormField(
                      label: 'Notes (Optional)',
                      hint: 'Add any details...',
                      controller: _notesController,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveSubscription,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandBlue,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: brandBlue.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Save Subscription',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
