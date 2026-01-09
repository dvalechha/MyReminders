import 'package:flutter/material.dart';
import '../models/task.dart';

class TaskFilterDialog extends StatefulWidget {
  final TaskPriority? initialPriority;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final bool? initialCompleted;

  const TaskFilterDialog({
    super.key,
    this.initialPriority,
    this.initialStartDate,
    this.initialEndDate,
    this.initialCompleted,
  });

  @override
  State<TaskFilterDialog> createState() => _TaskFilterDialogState();
}

class _TaskFilterDialogState extends State<TaskFilterDialog> {
  TaskPriority? _selectedPriority;
  DateTime? _startDate;
  DateTime? _endDate;
  bool? _completedFilter; // null = all, true = completed only, false = incomplete only

  @override
  void initState() {
    super.initState();
    _selectedPriority = widget.initialPriority;
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    _completedFilter = widget.initialCompleted;
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Tasks'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Priority Filter
            const Text(
              'Priority',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildPriorityChip(null, 'All'),
                _buildPriorityChip(TaskPriority.high, 'High'),
                _buildPriorityChip(TaskPriority.medium, 'Medium'),
                _buildPriorityChip(TaskPriority.low, 'Low'),
              ],
            ),
            const SizedBox(height: 24),
            // Completion Status Filter
            const Text(
              'Status',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildCompletionChip(null, 'All'),
                _buildCompletionChip(false, 'Incomplete'),
                _buildCompletionChip(true, 'Completed'),
              ],
            ),
            const SizedBox(height: 24),
            // Date Range Filter
            const Text(
              'Due Date Range',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _selectDate(context, true),
                    child: Text(
                      _startDate == null
                          ? 'Start Date'
                          : '${_startDate!.month}/${_startDate!.day}/${_startDate!.year}',
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('to'),
                ),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _selectDate(context, false),
                    child: Text(
                      _endDate == null
                          ? 'End Date'
                          : '${_endDate!.month}/${_endDate!.day}/${_endDate!.year}',
                    ),
                  ),
                ),
              ],
            ),
            if (_startDate != null || _endDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _startDate = null;
                      _endDate = null;
                    });
                  },
                  child: const Text('Clear Dates'),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(null);
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            // Clear all filters
            Navigator.of(context).pop({
              'priority': null,
              'startDate': null,
              'endDate': null,
              'completed': null,
            });
          },
          child: const Text('Clear All'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop({
              'priority': _selectedPriority,
              'startDate': _startDate,
              'endDate': _endDate,
              'completed': _completedFilter,
            });
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Widget _buildPriorityChip(TaskPriority? priority, String label) {
    final isSelected = _selectedPriority == priority;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedPriority = selected ? priority : null;
        });
      },
    );
  }

  Widget _buildCompletionChip(bool? completed, String label) {
    final isSelected = _completedFilter == completed;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _completedFilter = selected ? completed : null;
        });
      },
    );
  }
}
