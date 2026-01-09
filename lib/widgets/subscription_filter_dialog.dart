import 'package:flutter/material.dart';
import '../models/subscription.dart';

class SubscriptionFilterDialog extends StatefulWidget {
  final SubscriptionCategory? initialCategory;

  const SubscriptionFilterDialog({
    super.key,
    this.initialCategory,
  });

  @override
  State<SubscriptionFilterDialog> createState() => _SubscriptionFilterDialogState();
}

class _SubscriptionFilterDialogState extends State<SubscriptionFilterDialog> {
  SubscriptionCategory? _selectedCategory;
  bool _renewingSoon = false; // Renews within 7 days

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Subscriptions'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Filter
            const Text(
              'Category',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildCategoryChip(null, 'All'),
                ...SubscriptionCategory.values.map(
                  (category) => _buildCategoryChip(category, category.value),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Quick Filters
            const Text(
              'Quick Filters',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: const Text('Renewing Soon (within 7 days)'),
              value: _renewingSoon,
              onChanged: (value) {
                setState(() {
                  _renewingSoon = value ?? false;
                });
              },
              contentPadding: EdgeInsets.zero,
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
              'category': null,
              'renewingSoon': false,
            });
          },
          child: const Text('Clear All'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop({
              'category': _selectedCategory,
              'renewingSoon': _renewingSoon,
            });
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(SubscriptionCategory? category, String label) {
    final isSelected = _selectedCategory == category;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategory = selected ? category : null;
        });
      },
    );
  }
}
