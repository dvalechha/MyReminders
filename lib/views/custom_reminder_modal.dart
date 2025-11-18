import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomReminderModal extends StatefulWidget {
  final int initialDays;

  const CustomReminderModal({
    super.key,
    required this.initialDays,
  });

  @override
  State<CustomReminderModal> createState() => _CustomReminderModalState();
}

class _CustomReminderModalState extends State<CustomReminderModal> {
  late int _tempDays;
  late TextEditingController _daysController;

  final List<int> _quickOptions = [1, 3, 7];
  final int _minDays = 1;
  final int _maxDays = 29;

  @override
  void initState() {
    super.initState();
    _tempDays = widget.initialDays.clamp(_minDays, _maxDays);
    _daysController = TextEditingController(text: _tempDays.toString());
  }

  @override
  void dispose() {
    _daysController.dispose();
    super.dispose();
  }

  void _updateDays(int days) {
    setState(() {
      _tempDays = days.clamp(_minDays, _maxDays);
      _daysController.text = _tempDays.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Reminder'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, _tempDays);
            },
            child: const Text(
              'Done',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Options
            const Text(
              'Quick Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: _quickOptions.map((days) {
                final isSelected = _tempDays == days;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ElevatedButton(
                      onPressed: () => _updateDays(days),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected
                            ? Colors.blue
                            : Colors.blue.withValues(alpha: 0.1),
                        foregroundColor: isSelected ? Colors.white : Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        '$days',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            // Custom Days Picker
            const Text(
              'Custom Days',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _daysController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isEmpty) {
                        _updateDays(_minDays);
                        return;
                      }
                      final intValue = int.tryParse(value);
                      if (intValue != null) {
                        _updateDays(intValue);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'days before renewal',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        if (_tempDays > _minDays) {
                          _updateDays(_tempDays - 1);
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        if (_tempDays < _maxDays) {
                          _updateDays(_tempDays + 1);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Reminder will be sent $_tempDays day${_tempDays == 1 ? '' : 's'} before renewal',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Choose how many days before renewal you\'d like to be notified. The notification will be sent at 7:00 PM local time.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

