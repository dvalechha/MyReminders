import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_model.dart';
import 'appointment_add_view.dart';

class AppointmentsListView extends StatelessWidget {
  const AppointmentsListView({super.key});

  @override
  Widget build(BuildContext context) {
    final navigationModel = Provider.of<NavigationModel>(context, listen: false);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
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
                  builder: (context) => const AppointmentAddView(),
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
                Icons.calendar_today,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No Appointments',
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

