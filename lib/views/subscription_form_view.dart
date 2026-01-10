import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/subscription.dart';
import '../providers/subscription_provider.dart';
import '../services/notification_service.dart';
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
  final _paymentMethodController = TextEditingController();
  
  final _amountFocusNode = FocusNode();
  
  static const String _paymentPrefix = 'XXXX-XXXX-XXXX-';
  
  String _getPaymentMethodLast4() {
    return _paymentMethodController.text.trim();
  }
  
  void _setPaymentMethodLast4(String last4) {
    _paymentMethodController.text = last4;
  }

  SubscriptionCategory _selectedCategory = SubscriptionCategory.entertainment;
  Currency _selectedCurrency = Currency.usd;
  DateTime _selectedRenewalDate = DateTime.now();
  BillingCycle _selectedBillingCycle = BillingCycle.monthly;
  ReminderTime _selectedReminder = ReminderTime.none;
  int _customReminderDays = 0;
  bool _showAdditionalInfo = false;

  bool _isAuthorized = false;
  bool _isSaving = false; // Guard against double-submission

  @override
  void initState() {
    super.initState();
    
    // Add listeners to update button state when fields change
    _serviceNameController.addListener(() {
      setState(() {});
    });
    _amountController.addListener(() {
      setState(() {});
    });
    
    _checkNotificationPermission();
    if (widget.subscription != null) {
      _loadSubscriptionData();
    } else if (widget.initialServiceName != null ||
               widget.initialRenewalDate != null ||
               widget.initialNotes != null ||
               widget.initialAmount != null) {
      // Pre-populate with initial values (for new subscriptions from parser)
      if (widget.initialServiceName != null) {
        _serviceNameController.text = widget.initialServiceName!;
      }
      if (widget.initialRenewalDate != null) {
        _selectedRenewalDate = widget.initialRenewalDate!;
      }
      if (widget.initialNotes != null) {
        _notesController.text = widget.initialNotes!;
      }
      if (widget.initialAmount != null && widget.initialAmount! > 0) {
        _amountController.text = widget.initialAmount!.toStringAsFixed(2);
      }
      if (widget.initialCurrency != null) {
        _selectedCurrency = widget.initialCurrency!;
      }
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
    if (sub.paymentMethod != null && sub.paymentMethod!.isNotEmpty) {
      _setPaymentMethodLast4(sub.paymentMethod!);
    }
  }

  @override
  void dispose() {
    _serviceNameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _paymentMethodController.dispose();
    _amountFocusNode.dispose();
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
    final TextEditingController daysController = TextEditingController(
      text: _customReminderDays > 0 ? _customReminderDays.toString() : '1',
    );
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    
    final result = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Custom Reminder'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Days before renewal',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                TextFormField(
                  controller: daysController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a number';
                    }
                    final days = int.tryParse(value);
                    if (days == null || days < 1 || days > 29) {
                      return 'Enter 1-29 days';
                    }
                    return null;
                  },
                  autofocus: true,
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter a number between 1 and 29 days',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final days = int.parse(daysController.text);
                  Navigator.of(context).pop(days);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D62ED),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
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
    // Prevent double-submission
    if (_isSaving) {
      debugPrint('⚠️ [SubscriptionForm] Save already in progress, ignoring duplicate call');
      return;
    }
    
    if (!_formKey.currentState!.validate() || !_isFormValid) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

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
      paymentMethod: _getPaymentMethodLast4().isEmpty
          ? null
          : _getPaymentMethodLast4(),
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
        setState(() {
          _isSaving = false; // Reset on error so user can retry
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving subscription: $e')),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subscription?'),
        content: const Text(
          'Are you sure you want to delete this subscription? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _deleteSubscription();
    }
  }

  Future<void> _deleteSubscription() async {
    try {
      final provider = Provider.of<SubscriptionProvider>(context, listen: false);
      await provider.deleteSubscription(widget.subscription!.id);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error deleting subscription: $e');
      }
    }
  }

  Widget _buildRequiredLabel(String text) {
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
        const Text(
          ' *',
          style: TextStyle(
            color: Colors.red,
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
        ),
      ],
    );
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
        actions: widget.subscription != null
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _showDeleteConfirmation,
                ),
              ]
            : null,
      ),
      backgroundColor: Colors.grey[50],
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
                        borderRadius: BorderRadius.circular(12),
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
                  Container(
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
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Service Name *',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        TextFormField(
                          controller: _serviceNameController,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.sentences,
                          onFieldSubmitted: (_) {
                            FocusScope.of(context).requestFocus(_amountFocusNode);
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a service name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Category *',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 56,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<SubscriptionCategory>(
                                value: _selectedCategory,
                                isExpanded: true,
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
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Amount *',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 56,
                                child: TextFormField(
                                  controller: _amountController,
                                  focusNode: _amountFocusNode,
                                  textInputAction: TextInputAction.done,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.grey[100],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.red),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.red),
                                    ),
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
                            ),
                            const SizedBox(width: 12),
                            Container(
                              height: 56,
                              width: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<Currency>(
                                  value: _selectedCurrency,
                                  isExpanded: true,
                                  items: Currency.values.map((currency) {
                                    return DropdownMenuItem(
                                      value: currency,
                                      child: Text(
                                        currency.value,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _selectedCurrency = value);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Renewal & Reminder Section
                  Container(
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
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Renewal Date *',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        InkWell(
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
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('MMM d, yyyy').format(_selectedRenewalDate),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                                Icon(
                                  Icons.calendar_today_rounded,
                                  color: Colors.grey[600],
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 16),
                          child: Text(
                            'If you\'re not sure, an approximate date is fine - you can update it anytime.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Billing Cycle *',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 56,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<BillingCycle>(
                                value: _selectedBillingCycle,
                                isExpanded: true,
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
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Reminder',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                              ),
                              builder: (context) => _buildReminderPicker(),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _reminderDisplayText,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.grey[600],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Additional Info Section
                  if (_showAdditionalInfo)
                    Container(
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
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Notes',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                          TextFormField(
                            controller: _notesController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red),
                              ),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Card Number (Last 4)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                          TextFormField(
                            controller: _paymentMethodController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              prefixText: _paymentPrefix,
                              prefixStyle: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                              counterText: '',
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ],
                      ),
                    )
                  else
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() => _showAdditionalInfo = true);
                        },
                        icon: const Icon(Icons.add_circle, color: Color(0xFF2D62ED)),
                        label: const Text(
                          'Add more details',
                          style: TextStyle(color: Color(0xFF2D62ED)),
                        ),
                      ),
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
                  onPressed: (_isFormValid && !_isSaving) ? _saveSubscription : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (_isFormValid && !_isSaving)
                        ? const Color(0xFF2D62ED)
                        : Colors.grey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: (_isFormValid && !_isSaving) ? 4 : 0,
                    minimumSize: const Size(double.infinity, 56),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: ReminderTime.values.map((reminder) {
          final isSelected = _selectedReminder == reminder;
          return ListTile(
            title: Text(reminder == ReminderTime.custom ? 'Custom' : reminder.value),
            trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF2D62ED)) : null,
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

