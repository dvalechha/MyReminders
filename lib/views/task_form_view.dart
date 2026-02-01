import 'package:flutter/cupertino.dart';
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
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();

  DateTime _selectedDateTime = DateTime.now();
  TaskPriority _selectedPriority = TaskPriority.medium;
  ReminderOffset _selectedReminder = ReminderOffset.none;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Default to medium priority if new
    _selectedPriority = widget.task?.priority ?? TaskPriority.medium;
    
    // Default to current time if new
    if (widget.task == null && widget.initialDueDate == null) {
      _selectedDateTime = DateTime.now();
    }

    if (widget.task != null) {
      _loadTaskData();
    } else {
      if (widget.initialTitle != null) _titleController.text = widget.initialTitle!;
      if (widget.initialDueDate != null) _selectedDateTime = widget.initialDueDate!;
      if (widget.initialNotes != null) _notesController.text = widget.initialNotes!;
    }
    _updateDateTimeControllers();
  }

  void _updateDateTimeControllers() {
    _dateController.text = DateFormat('MMM d, yyyy').format(_selectedDateTime);
    _timeController.text = DateFormat('h:mm a').format(_selectedDateTime);
  }

  void _loadTaskData() {
    final task = widget.task!;
    _titleController.text = task.title;
    _notesController.text = task.notes ?? '';
    _selectedDateTime = task.dueDate?.toLocal() ?? DateTime.now();
    _selectedPriority = task.priority ?? TaskPriority.medium;
    _selectedReminder = task.reminderOffset;
    _updateDateTimeControllers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
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

  Future<void> _saveTask() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final provider = Provider.of<TaskProvider>(context, listen: false);

      final task = Task(
        id: widget.task?.id,
        title: _titleController.text.trim(),
        category: widget.task?.category,
        dueDate: _selectedDateTime,
        priority: _selectedPriority,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        reminderOffset: _selectedReminder,
        notificationId: widget.task?.notificationId,
        isCompleted: widget.task?.isCompleted ?? false,
      );

      if (widget.task == null) {
        await provider.addTask(task);
      } else {
        await provider.updateTask(task);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        SnackbarHelper.showError(context, 'Error saving: $e');
      }
    }
  }

  Widget _buildPriorityChips() {
    const brandBlue = Color(0xFF2D62ED);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8.0, left: 4.0),
          child: Text(
            'Priority',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        Row(
          children: TaskPriority.values.map((priority) {
            final isSelected = _selectedPriority == priority;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(
                  priority.value,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedPriority = priority);
                  }
                },
                selectedColor: brandBlue,
                backgroundColor: Colors.grey[200],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? brandBlue : Colors.transparent,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                showCheckmark: false,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const brandBlue = Color(0xFF2D62ED);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.task == null ? 'Add Task' : 'Edit Task',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.grey[50],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.task != null)
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
                  await Provider.of<TaskProvider>(context, listen: false).deleteTask(widget.task!.id);
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
                    // Title
                    ModernFormField(
                      label: 'Title',
                      controller: _titleController,
                      validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 20),

                    // Split Row for Date and Time
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ModernFormField(
                            label: 'Due Date',
                            controller: _dateController,
                            readOnly: true,
                            onTap: _showDatePicker,
                            suffixIcon: const Icon(Icons.calendar_today_rounded, color: brandBlue, size: 20),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ModernFormField(
                            label: 'Time',
                            controller: _timeController,
                            readOnly: true,
                            onTap: _showTimePicker,
                            suffixIcon: const Icon(Icons.access_time_rounded, color: brandBlue, size: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Priority Chips
                    _buildPriorityChips(),
                    const SizedBox(height: 20),

                    // Reminder Dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8.0, left: 4.0),
                          child: Text(
                            'Reminder',
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
                            child: DropdownButton<ReminderOffset>(
                              value: _selectedReminder,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                              items: ReminderOffset.values.map((val) {
                                return DropdownMenuItem(
                                  value: val,
                                  child: Text(val.value, style: const TextStyle(fontWeight: FontWeight.w500)),
                                );
                              }).toList(),
                              onChanged: (v) => setState(() => _selectedReminder = v!),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Notes
                    ModernFormField(
                      label: 'Notes (Optional)',
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
                  onPressed: _isSaving ? null : _saveTask,
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
                          'Save Task',
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