import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_reminder/views/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:my_reminder/providers/auth_provider.dart';
import 'package:my_reminder/providers/navigation_model.dart';
import 'package:my_reminder/providers/user_profile_provider.dart';

// Mock Provider if needed, but for simple widget finding we might not need full mocks if we wrap in Provider
class MockAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  bool isLoading = false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('LoginScreen has email and password fields', (WidgetTester tester) async {
    // We need to wrap the widget with required providers
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => MockAuthProvider()),
          ChangeNotifierProvider<NavigationModel>(create: (_) => NavigationModel()),
          ChangeNotifierProvider<UserProfileProvider>(create: (_) => UserProfileProvider()),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    // Verify email field exists
    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);

    // Verify password field exists
    expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);

    // Verify login button exists
    expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);

    // Verify forgot password button exists
    expect(find.text('Forgot Password?'), findsOneWidget);
  });
}
