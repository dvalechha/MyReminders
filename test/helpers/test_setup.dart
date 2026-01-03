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

  // Dispose Supabase instance
  try {
    await Supabase.instance.dispose();
    debugPrint('✅ Supabase disposed after tests');
  } catch (e) {
    // Ignore disposal errors in tests
    debugPrint('⚠️ Error disposing Supabase: $e');
  }
}

