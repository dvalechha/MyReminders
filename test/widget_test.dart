import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_reminder/main.dart';

void main() {
  testWidgets('App starts correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyReminderApp());

    // Verify that the app title is displayed
    expect(find.text('My Subscriptions'), findsOneWidget);
  });
}
