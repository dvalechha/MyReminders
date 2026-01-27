import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../widgets/modern_form_field.dart';
import '../utils/snackbar.dart';
import '../models/task.dart';
import '../models/appointment.dart';
import '../providers/task_provider.dart';

class TaskFormView extends StatefulWidget {
  final Task? task;
  final String? initialTitle;
  final DateTime? initialDueDate;
  final String? initialNotes;

  const TaskFormView({
    super.key,
    this.task,
    this.initialTitle,
    this.initialDueDate,
    this.initialNotes,
  });

  @override
  State<TaskFormView> createState() => _TaskFormViewState();
}

class _TaskFormViewState extends State<TaskFormView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _dueDateController = TextEditingController();

  DateTime? _selectedDueDate;
  TaskPriority? _selectedPriority;
  ReminderOffset _selectedReminder = ReminderOffset.none;
  bool _isSaving = false; // Guard against double-submission

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _loadTaskData();
    } else if (widget.initialTitle != null ||
               widget.initialDueDate != null ||
               widget.initialNotes != null) {
      // Pre-populate with initial values
      if (widget.initialTitle != null) {
        _titleController.text = widget.initialTitle!;
      }
      if (widget.initialDueDate != null) {
        _selectedDueDate = widget.initialDueDate;
      }
      if (widget.initialNotes != null) {
        _notesController.text = widget.initialNotes!;
      }
    }
    _updateDueDateController();
  }

  void _updateDueDateController() {
    if (_selectedDueDate != null) {
      _dueDateController.text = DateFormat('MMM d, yyyy  •  h:mm a').format(_selectedDueDate!);
    } else {
      _dueDateController.text = '';
    }
  }

  void _loadTaskData() {
    final task = widget.task!;
    _titleController.text = task.title;
    _notesController.text = task.notes ?? '';
    _selectedDueDate = task.dueDate?.toLocal();
    _selectedPriority = task.priority;
    _selectedReminder = task.reminderOffset;
    _updateDueDateController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _titleController.text.trim().isNotEmpty;
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: _selectedDueDate != null
            ? TimeOfDay.fromDateTime(_selectedDueDate!)
            : TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _selectedDueDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
          _updateDueDateController();
        });
      } else {
        // If time picker is cancelled but date was selected, set time to current time
        setState(() {
          final now = DateTime.now();
          _selectedDueDate = DateTime(
            date.year,
            date.month,
            date.day,
            now.hour,
            now.minute,
          );
          _updateDueDateController();
        });
      }
    }
  }

  Future<void> _saveTask() async {
    // Prevent double-submission
    if (_isSaving) {
      debugPrint('⚠️ [TaskForm] Save already in progress, ignoring duplicate call');
      return;
    }

    if (!_formKey.currentState!.validate() || !_isFormValid) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final provider = Provider.of<TaskProvider>(context, listen: false);

    final task = Task(
      id: widget.task?.id,
      title: _titleController.text.trim(),
      category: widget.task?.category,
      dueDate: _selectedDueDate,
      priority: _selectedPriority,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      reminderOffset: _selectedReminder,
      notificationId: widget.task?.notificationId,
    );

    try {
      if (widget.task == null) {
        await provider.addTask(task);
      } else {
        await provider.updateTask(task);
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
          SnackBar(content: Text('Error saving task: $e')),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task?'),
        content: const Text(
          'Are you sure you want to delete this task? This action cannot be undone.',
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
      await _deleteTask();
    }
  }

  Future<void> _deleteTask() async {
    try {
      final provider = Provider.of<TaskProvider>(context, listen: false);
      await provider.deleteTask(widget.task!.id);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error deleting task: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Add Task' : 'Edit Task'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: widget.task != null
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
                    // Card 1: Task Core
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
                        _buildDropdownField<TaskPriority>(
                          label: 'Priority',
                          value: _selectedPriority,
                          items: TaskPriority.values,
                          onChanged: (value) {
                            setState(() => _selectedPriority = value);
                          },
                          displayText: (val) => val.value,
                          hint: 'Select priority',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Card 2: Execution
                    _buildSectionCard(
                      children: [
                        ModernFormField(
                          label: 'Due Date & Time *',
                          controller: _dueDateController,
                          readOnly: true,
                          onTap: _selectDueDate,
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(left: 12, right: 8),
                            child: Icon(Icons.calendar_today_rounded, size: 20, color: Color(0xFF2D62ED)),
                          ),
                          hint: 'Select date and time',
                        ),
                        const SizedBox(height: 16),
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
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Card 3: Context
                    _buildSectionCard(
                      children: [
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
                onPressed: (_isFormValid && !_isSaving) ? _saveTask : null,
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
                        widget.task == null ? 'Save Task' : 'Update Task',
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
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required String Function(T) displayText,
    String? hint,
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
              hint: hint != null ? Text(hint, style: TextStyle(color: Colors.grey[600])) : null,
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

