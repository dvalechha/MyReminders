import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_reminder/views/reset_password_screen.dart';
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

  testWidgets('ResetPasswordScreen has password fields', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => MockAuthProvider()),
        ],
        child: const MaterialApp(
          home: ResetPasswordScreen(),
        ),
      ),
    );

    // Verify header
    expect(find.text('Set New Password'), findsOneWidget);

    // Verify password fields
    expect(find.widgetWithText(TextFormField, 'New Password'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Confirm New Password'), findsOneWidget);

    // Verify button
    expect(find.widgetWithText(ElevatedButton, 'Reset Password'), findsOneWidget);
  });
}
