import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/subscription_provider.dart';
import 'views/subscriptions_list_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyReminderApp());
}

class MyReminderApp extends StatelessWidget {
  const MyReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SubscriptionProvider(),
      child: MaterialApp(
        title: 'My Reminder',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const SubscriptionsListView(),
      ),
    );
  }
}
