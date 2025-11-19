import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_model.dart';
import 'custom_reminder_add_view.dart';

class CustomRemindersListView extends StatelessWidget {
  const CustomRemindersListView({super.key});

  @override
  Widget build(BuildContext context) {
    final navigationModel = Provider.of<NavigationModel>(context, listen: false);
    
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
                  builder: (context) => const CustomReminderAddView(),
                ),
              );
            },
          ),
        ],
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_outlined,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No Custom Reminders',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'This feature is coming soon!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

