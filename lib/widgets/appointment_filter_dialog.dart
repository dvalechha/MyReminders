import 'package:flutter/material.dart';

class AppointmentFilterDialog extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  const AppointmentFilterDialog({
    super.key,
    this.initialStartDate,
    this.initialEndDate,
  });

  @override
  State<AppointmentFilterDialog> createState() => _AppointmentFilterDialogState();
}

class _AppointmentFilterDialogState extends State<AppointmentFilterDialog> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _todayOnly = false;
  bool _upcomingOnly = false;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
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
        // Clear quick filters when custom date is selected
        _todayOnly = false;
        _upcomingOnly = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Appointments'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Filters
            const Text(
              'Quick Filters',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text('Today Only'),
              value: _todayOnly,
              onChanged: (value) {
                setState(() {
                  _todayOnly = value ?? false;
                  if (_todayOnly) {
                    _upcomingOnly = false;
                    _startDate = null;
                    _endDate = null;
                  }
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: const Text('Upcoming Only'),
              value: _upcomingOnly,
              onChanged: (value) {
                setState(() {
                  _upcomingOnly = value ?? false;
                  if (_upcomingOnly) {
                    _todayOnly = false;
                    _startDate = null;
                    _endDate = null;
                  }
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
            // Date Range Filter
            const Text(
              'Date Range',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _todayOnly || _upcomingOnly
                        ? null
                        : () => _selectDate(context, true),
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
                    onPressed: _todayOnly || _upcomingOnly
                        ? null
                        : () => _selectDate(context, false),
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
              'startDate': null,
              'endDate': null,
              'todayOnly': false,
              'upcomingOnly': false,
            });
          },
          child: const Text('Clear All'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop({
              'startDate': _startDate,
              'endDate': _endDate,
              'todayOnly': _todayOnly,
              'upcomingOnly': _upcomingOnly,
            });
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
