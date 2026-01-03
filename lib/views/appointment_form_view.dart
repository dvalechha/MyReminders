import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../utils/snackbar.dart';
import '../models/appointment.dart';
import '../providers/appointment_provider.dart';

class AppointmentFormView extends StatefulWidget {
  final Appointment? appointment;
  final String? initialTitle;
  final DateTime? initialDateTime;
  final String? initialLocation;
  final String? initialNotes;

  const AppointmentFormView({
    super.key,
    this.appointment,
    this.initialTitle,
    this.initialDateTime,
    this.initialLocation,
    this.initialNotes,
  });

  @override
  State<AppointmentFormView> createState() => _AppointmentFormViewState();
}

class _AppointmentFormViewState extends State<AppointmentFormView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDateTime = DateTime.now();
  ReminderOffset _selectedReminder = ReminderOffset.none;
  bool _isSaving = false; // Guard against double-submission

  @override
  void initState() {
    super.initState();
    if (widget.appointment != null) {
      _loadAppointmentData();
    } else if (widget.initialTitle != null || 
               widget.initialDateTime != null || 
               widget.initialLocation != null ||
               widget.initialNotes != null) {
      // Pre-populate with initial values (for new appointments from parser)
      if (widget.initialTitle != null) {
        _titleController.text = widget.initialTitle!;
      }
      if (widget.initialDateTime != null) {
        _selectedDateTime = widget.initialDateTime!;
      }
      if (widget.initialLocation != null) {
        _locationController.text = widget.initialLocation!;
      }
      if (widget.initialNotes != null) {
        _notesController.text = widget.initialNotes!;
      }
    }
  }

  void _loadAppointmentData() {
    final apt = widget.appointment!;
    _titleController.text = apt.title;
    _locationController.text = apt.location ?? '';
    _notesController.text = apt.notes ?? '';
    _selectedDateTime = apt.dateTime;
    _selectedReminder = apt.reminderOffset;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _titleController.text.trim().isNotEmpty;
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

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );
      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      } else {
        // If time picker is cancelled but date was selected, set time to current time
        setState(() {
          final now = DateTime.now();
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            now.hour,
            now.minute,
          );
        });
      }
    }
  }

  Future<void> _saveAppointment() async {
    // Prevent double-submission
    if (_isSaving) {
      debugPrint('⚠️ [AppointmentForm] Save already in progress, ignoring duplicate call');
      return;
    }

    if (!_formKey.currentState!.validate() || !_isFormValid) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final provider = Provider.of<AppointmentProvider>(context, listen: false);

    debugPrint('💾 [AppointmentForm] Saving appointment...');

    final appointment = Appointment(
      id: widget.appointment?.id,
      title: _titleController.text.trim(),
      category: null, // Category is automatically set to "Appointment" by provider
      dateTime: _selectedDateTime,
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      reminderOffset: _selectedReminder,
      notificationId: widget.appointment?.notificationId,
    );

    try {
      if (widget.appointment == null) {
        await provider.addAppointment(appointment);
      } else {
        await provider.updateAppointment(appointment);
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
          SnackBar(content: Text('Error saving appointment: $e')),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Appointment?'),
        content: const Text(
          'Are you sure you want to delete this appointment? This action cannot be undone.',
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
      await _deleteAppointment();
    }
  }

  Future<void> _deleteAppointment() async {
    try {
      final provider = Provider.of<AppointmentProvider>(context, listen: false);
      await provider.deleteAppointment(widget.appointment!.id);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error deleting appointment: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appointment == null
            ? 'Add Appointment'
            : 'Edit Appointment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: widget.appointment != null
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _showDeleteConfirmation,
                ),
              ]
            : null,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'APPOINTMENT DETAILS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title *',
                      border: OutlineInputBorder(),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Date & Time *'),
                    subtitle: Text(DateFormat('MMM d, yyyy').format(_selectedDateTime)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _selectDateTime,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'REMINDER',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<ReminderOffset>(
                    value: _selectedReminder,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: ReminderOffset.values.map((offset) {
                      return DropdownMenuItem(
                        value: offset,
                        child: Text(offset.value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedReminder = value);
                      }
                    },
                  ),
                ],
              ),
            ),
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
                  onPressed: (_isFormValid && !_isSaving) ? _saveAppointment : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: (_isFormValid && !_isSaving) ? Colors.blue : Colors.grey,
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
                          widget.appointment == null
                              ? 'Save Appointment'
                              : 'Update Appointment',
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
}

