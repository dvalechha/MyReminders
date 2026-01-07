import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_reminder/widgets/omnibox.dart';
import '../helpers/test_setup.dart';

void main() {
  setUpAll(() async {
    await setupSupabaseForTests();
  });

  tearDownAll(() async {
    await teardownSupabaseForTests();
  });

  testWidgets('Omnibox renders correctly', (WidgetTester tester) async {
    // Variables to capture callbacks
    String? capturedSearch;
    String? capturedCreate;
    bool cleared = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Omnibox(
            onSearch: (query) => capturedSearch = query,
            onCreate: (query) => capturedCreate = query,
            onClear: () => cleared = true,
          ),
        ),
      ),
    );

    // Verify Hint Text
    expect(find.text('Ask, schedule, or search…'), findsOneWidget);

    // Verify Initial Icon (Search)
    expect(find.byIcon(Icons.search), findsOneWidget);

    // Enter text to trigger state change
    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.pump();

    // Verify Clear Button appears
    expect(find.byIcon(Icons.clear), findsOneWidget);

    // Tap Clear
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump();

    expect(cleared, isTrue);
    expect(find.text('Hello'), findsNothing);
  });

  testWidgets('Omnibox detects create intent', (WidgetTester tester) async {
    String? capturedCreate;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Omnibox(
            onSearch: (_) {},
            onCreate: (query) => capturedCreate = query,
          ),
        ),
      ),
    );

    // Enter "Create task"
    await tester.enterText(find.byType(TextField), 'Create task');
    await tester.pump();

    // Verify Icon changes to Add
    // Note: The icon is inside an AnimatedSwitcher, finding by key is reliable
    // In the code: key: ValueKey(_currentIntent)
    // IntentType.create is an enum, we can't easily import it without the file,
    // but we can check if Icons.add is present.
    expect(find.byIcon(Icons.add), findsOneWidget);

    // Submit
    await tester.testTextInput.receiveAction(TextInputAction.go);

    expect(capturedCreate, 'Create task');
  });
}
