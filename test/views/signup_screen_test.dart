import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_reminder/views/signup_screen.dart';
import 'package:provider/provider.dart';
import 'package:my_reminder/providers/auth_provider.dart';
import '../helpers/test_setup.dart';

class MockAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  bool isLoading = false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    await setupSupabaseForTests();
  });

  tearDownAll(() async {
    await teardownSupabaseForTests();
  });

  testWidgets('SignupScreen has all required fields', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => MockAuthProvider()),
        ],
        child: const MaterialApp(
          home: SignupScreen(),
        ),
      ),
    );

    // Verify fields exist
    expect(find.widgetWithText(TextFormField, 'Display Name'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Confirm Password'), findsOneWidget);

    // Verify button exists
    expect(find.widgetWithText(ElevatedButton, 'Create Account'), findsOneWidget);

    // Verify Google sign up button
    expect(find.text('Continue with Google'), findsOneWidget);

    // Verify login link
    expect(find.text('Already have an account? Log in'), findsOneWidget);
  });
}
