import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/appointment_provider.dart';
import 'providers/task_provider.dart';
import 'providers/custom_reminder_provider.dart';
import 'providers/navigation_model.dart';
import 'views/welcome_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyReminderApp());
}

class MyReminderApp extends StatelessWidget {
  const MyReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => CustomReminderProvider()),
        ChangeNotifierProvider(create: (_) => NavigationModel()),
      ],
      child: Consumer<NavigationModel>(
        builder: (context, navigationModel, child) {
          return MaterialApp(
            title: 'My Reminder',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
              useMaterial3: true,
            ),
            navigatorKey: navigationModel.navigatorKey,
            home: const WelcomeView(),
          );
        },
      ),
    );
  }
}
