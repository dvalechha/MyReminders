import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/appointment.dart';
import '../providers/task_provider.dart';

class TaskFormView extends StatefulWidget {
  final Task? task;

  const TaskFormView({
    super.key,
    this.task,
  });

  @override
  State<TaskFormView> createState() => _TaskFormViewState();
}

class _TaskFormViewState extends State<TaskFormView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedDueDate;
  TaskPriority? _selectedPriority;
  ReminderOffset _selectedReminder = ReminderOffset.none;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _loadTaskData();
    }
  }

  void _loadTaskData() {
    final task = widget.task!;
    _titleController.text = task.title;
    _categoryController.text = task.category ?? '';
    _notesController.text = task.notes ?? '';
    _selectedDueDate = task.dueDate;
    _selectedPriority = task.priority;
    _selectedReminder = task.reminderOffset;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
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
        });
      }
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate() || !_isFormValid) {
      return;
    }

    final provider = Provider.of<TaskProvider>(context, listen: false);

    final task = Task(
      id: widget.task?.id,
      title: _titleController.text.trim(),
      category: _categoryController.text.trim().isEmpty
          ? null
          : _categoryController.text.trim(),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving task: $e')),
        );
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
                    'TASK DETAILS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildRequiredLabel('Title'),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildRequiredLabel('Due Date & Time'),
                  const SizedBox(height: 4),
                  ListTile(
                    title: _selectedDueDate != null
                        ? Text(DateFormat('MMM d, yyyy').format(_selectedDueDate!))
                        : const Text('No date set'),
                    subtitle: _selectedDueDate != null
                        ? Text(DateFormat('h:mm a').format(_selectedDueDate!))
                        : null,
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _selectDueDate,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<TaskPriority>(
                    value: _selectedPriority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                    ),
                    hint: const Text('Select priority'),
                    items: TaskPriority.values.map((priority) {
                      return DropdownMenuItem(
                        value: priority,
                        child: Text(priority.value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedPriority = value);
                    },
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
                  onPressed: _isFormValid ? _saveTask : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _isFormValid ? Colors.blue : Colors.grey,
                  ),
                  child: Text(
                    widget.task == null ? 'Save Task' : 'Update Task',
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

