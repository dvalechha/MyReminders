import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/navigation_model.dart';
import '../providers/custom_reminder_provider.dart';
import '../models/custom_reminder.dart';
import 'custom_reminder_form_view.dart';

class CustomRemindersListView extends StatefulWidget {
  const CustomRemindersListView({super.key});

  @override
  State<CustomRemindersListView> createState() => _CustomRemindersListViewState();
}

class _CustomRemindersListViewState extends State<CustomRemindersListView> {
  String _searchText = '';

  List<CustomReminder> _filterCustomReminders(
      List<CustomReminder> reminders, String searchText) {
    if (searchText.isEmpty) {
      return reminders;
    }

    final lowerSearchText = searchText.toLowerCase();
    return reminders.where((reminder) {
      final title = reminder.title.toLowerCase();
      final category = (reminder.category ?? '').toLowerCase();
      final notes = (reminder.notes ?? '').toLowerCase();

      return title.contains(lowerSearchText) ||
          category.contains(lowerSearchText) ||
          notes.contains(lowerSearchText);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final navigationModel = Provider.of<NavigationModel>(context, listen: false);
    
    return Consumer<CustomReminderProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('My Custom Reminders'),
              leading: IconButton(
                icon: const Icon(Icons.home),
                onPressed: () => navigationModel.popToRoot(),
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final filteredReminders =
            _filterCustomReminders(provider.customReminders, _searchText);

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Custom Reminders'),
            leading: IconButton(
              icon: const Icon(Icons.home),
              onPressed: () => navigationModel.popToRoot(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CustomReminderFormView(),
                    ),
                  );
                },
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchText = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search reminders...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchText.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              setState(() {
                                _searchText = '';
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: provider.customReminders.isEmpty
              ? _buildEmptyState(context)
              : _buildCustomRemindersList(context, provider, filteredReminders),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No Custom Reminders',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add your first reminder',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomRemindersList(
      BuildContext context, CustomReminderProvider provider, List<CustomReminder> filteredReminders) {
    return filteredReminders.isEmpty
        ? Padding(
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: Text(
                'No reminders found',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
          )
        : ListView.builder(
            itemCount: filteredReminders.length,
            itemBuilder: (context, index) {
              final reminder = filteredReminders[index];
              return _buildCustomReminderRow(context, reminder, provider);
            },
          );
  }

  Widget _buildCustomReminderRow(
    BuildContext context,
    CustomReminder reminder,
    CustomReminderProvider provider,
  ) {
    return Dismissible(
      key: Key(reminder.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Reminder'),
            content: Text('Are you sure you want to delete ${reminder.title}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        provider.deleteCustomReminder(reminder.id);
      },
      child: ListTile(
        title: Text(
          reminder.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (reminder.category != null)
              Text(
                reminder.category!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w400,
                ),
              ),
            if (reminder.dateTime != null) ...[
              const SizedBox(height: 4),
              Text(
                '${DateFormat('MMM d, yyyy').format(reminder.dateTime!)} at ${DateFormat('h:mm a').format(reminder.dateTime!)}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CustomReminderFormView(
                customReminder: reminder,
              ),
            ),
          );
        },
      ),
    );
  }
}

