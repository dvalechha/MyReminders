import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_reminder/views/forgot_password_screen.dart';
import 'package:provider/provider.dart';
import 'package:my_reminder/providers/auth_provider.dart';
import '../helpers/test_setup.dart';

class MockAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  bool isLoading = false;
  @override
  bool isPasswordResetFlow = false;

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

  testWidgets('ForgotPasswordScreen has email field', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => MockAuthProvider()),
        ],
        child: const MaterialApp(
          home: ForgotPasswordScreen(),
        ),
      ),
    );

    // Verify header
    expect(find.text('Forgot Password?'), findsOneWidget);

    // Verify email field
    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);

    // Verify button
    expect(find.widgetWithText(ElevatedButton, 'Send Reset Link'), findsOneWidget);

    // Verify back button
    expect(find.text('Back to Login'), findsOneWidget);
  });
}
