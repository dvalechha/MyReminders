import 'package:flutter_test/flutter_test.dart';
import 'package:my_reminder/providers/auth_provider.dart';
import '../helpers/test_setup.dart';

void main() {
  // Use the existing helper to setup Supabase for tests
  setUpAll(() async {
    await setupSupabaseForTests();
  });

  tearDownAll(() async {
    await teardownSupabaseForTests();
  });

  group('AuthProvider', () {
    late AuthProvider authProvider;

    setUp(() {
      authProvider = AuthProvider();
    });

    test('initial state is loading', () {
      // Create a fresh instance to check initial state
      // Note: AuthProvider constructor starts async initialization
      final provider = AuthProvider();
      expect(provider.isLoading, true);
    });

    test('isAuthenticated returns false when user is null', () {
      expect(authProvider.isAuthenticated, false);
    });

    // Note: Since AuthProvider does async initialization and uses singletons (Supabase.instance),
    // comprehensive unit testing requires more extensive mocking of the Supabase static instance
    // or dependency injection which might require refactoring the provider.
    // For now, we verified the basic state properties.
  });
}
