import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Global test setup for Supabase initialization
/// Call this in setUpAll() of your test files
Future<void> setupSupabaseForTests() async {
  // Mock platform channels for shared_preferences
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/shared_preferences'),
    (MethodCall methodCall) async {
      if (methodCall.method == 'getAll') {
        return <String, dynamic>{}; // Return empty map
      }
      return null;
    },
  );

  // Mock platform channels for flutter_secure_storage
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
    (MethodCall methodCall) async {
      // Handle FlutterSecureStorage methods
      switch (methodCall.method) {
        case 'read':
          return null; // Return null for any read
        case 'write':
        case 'delete':
        case 'deleteAll':
          return null; // Return success (void/null)
        case 'readAll':
          return <String, String>{}; // Return empty map
        case 'containsKey':
          return false;
        default:
          return null;
      }
    },
  );

  // Initialize Supabase with test credentials
  try {
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      anonKey: 'test-anon-key-for-testing-only',
    );
    debugPrint('✅ Supabase initialized for tests');
  } catch (e) {
    // If initialization fails, log but don't throw
    // Some tests might handle this differently
    debugPrint('⚠️ Supabase initialization failed in test setup: $e');
  }
}

/// Global test teardown for Supabase cleanup
/// Call this in tearDownAll() of your test files
Future<void> teardownSupabaseForTests() async {
  // Clean up platform channel mocks
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/shared_preferences'),
    null,
  );

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
    null,
  );

  // Dispose Supabase instance
  try {
    await Supabase.instance.dispose();
    debugPrint('✅ Supabase disposed after tests');
  } catch (e) {
    // Ignore disposal errors in tests
    debugPrint('⚠️ Error disposing Supabase: $e');
  }
}
