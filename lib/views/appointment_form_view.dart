import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../widgets/modern_form_field.dart';
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
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();

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
      // Pre-populate with initial values
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
    _updateDateTimeControllers();
  }

  void _updateDateTimeControllers() {
    _dateController.text = DateFormat('MMM d, yyyy').format(_selectedDateTime);
    _timeController.text = DateFormat('h:mm a').format(_selectedDateTime);
  }

  void _loadAppointmentData() {
    final apt = widget.appointment!;
    _titleController.text = apt.title;
    _locationController.text = apt.location ?? '';
    _notesController.text = apt.notes ?? '';
    _selectedDateTime = apt.dateTime.toLocal();
    _selectedReminder = apt.reminderOffset;
    _updateDateTimeControllers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _titleController.text.trim().isNotEmpty;
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
          _updateDateTimeControllers();
        });
      } else {
        // If time picker is cancelled but date was selected, preserve existing time or set to current?
        // Logic in original was: "set time to current time". Let's stick to original logic.
        setState(() {
          final now = DateTime.now();
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            now.hour,
            now.minute,
          );
          _updateDateTimeControllers();
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
      category: null, 
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
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Card 1: Event Details
                    _buildSectionCard(
                      children: [
                        ModernFormField(
                          label: 'Title *',
                          controller: _titleController,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.sentences,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a title';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        ModernFormField(
                          label: 'Location',
                          controller: _locationController,
                          textCapitalization: TextCapitalization.sentences,
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(left: 12, right: 8),
                            child: Icon(Icons.location_on_outlined, size: 20, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Card 2: Timing
                    _buildSectionCard(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ModernFormField(
                                label: 'Date',
                                controller: _dateController,
                                readOnly: true,
                                onTap: _selectDateTime,
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.only(left: 12, right: 8),
                                  child: Icon(Icons.calendar_today_rounded, size: 20, color: Color(0xFF2D62ED)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ModernFormField(
                                label: 'Time',
                                controller: _timeController,
                                readOnly: true,
                                onTap: _selectDateTime,
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.only(left: 12, right: 8),
                                  child: Icon(Icons.access_time_rounded, size: 20, color: Color(0xFF2D62ED)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Card 3: Notes & Reminders
                    _buildSectionCard(
                      children: [
                        _buildDropdownField<ReminderOffset>(
                          label: 'Reminder',
                          value: _selectedReminder,
                          items: ReminderOffset.values,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedReminder = value);
                            }
                          },
                          displayText: (val) => val.value,
                        ),
                        const SizedBox(height: 16),
                        ModernFormField(
                          label: 'Notes',
                          controller: _notesController,
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ],
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),

          // Save Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_isFormValid && !_isSaving) ? _saveAppointment : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_isFormValid && !_isSaving)
                      ? const Color(0xFF2D62ED)
                      : Colors.grey[300],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: (_isFormValid && !_isSaving) ? 4 : 0,
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
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required String Function(T) displayText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(displayText(item), style: const TextStyle(fontSize: 16)),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

