import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/auth_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/appointment_provider.dart';
import 'providers/task_provider.dart';
import 'providers/user_profile_provider.dart';
import 'providers/navigation_model.dart';
import 'utils/environment_config.dart';
import 'widgets/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Determine which .env file to load
  final envFile = '.env.${EnvironmentConfig.current}';

  // Load environment variables
  try {
    await dotenv.load(fileName: envFile);
    debugPrint('Loaded environment: ${EnvironmentConfig.displayName} ($envFile)');
  } catch (e) {
    // Fallback to default .env file
    try {
      await dotenv.load(fileName: ".env");
      debugPrint('Fallback: Loaded default .env file');
    } catch (fallbackError) {
      debugPrint('Warning: Could not load .env file: $e');
      debugPrint('Fallback also failed: $fallbackError');
      debugPrint('Make sure .env or .env.dev file exists with SUPABASE_URL and SUPABASE_ANON_KEY');
    }
  }

  // Initialize Supabase
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw Exception(
      'Missing Supabase configuration. '
      'Please ensure SUPABASE_URL and SUPABASE_ANON_KEY are set in $envFile file.',
    );
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const MyReminderApp());
}

class MyReminderApp extends StatelessWidget {
  const MyReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => NavigationModel()),
      ],
      child: Consumer<NavigationModel>(
        builder: (context, navigationModel, child) {
          return MaterialApp(
            title: 'Custos',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
              useMaterial3: true,
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.red),
                ),
              ),
            ),
            navigatorKey: navigationModel.navigatorKey,
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}
