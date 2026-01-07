import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_reminder/views/subscriptions_list_view.dart';
import 'package:provider/provider.dart';
import 'package:my_reminder/providers/subscription_provider.dart';
import 'package:my_reminder/providers/navigation_model.dart';
import 'package:my_reminder/models/subscription.dart';
import '../helpers/test_setup.dart';

class MockSubscriptionProvider extends ChangeNotifier implements SubscriptionProvider {
  @override
  bool isLoading = false;
  @override
  List<Subscription> subscriptions = [];
  @override
  double totalMonthlySpend = 0.0;

  @override
  Future<void> loadSubscriptions() async {}

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

  testWidgets('SubscriptionsListView shows empty state initially', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SubscriptionProvider>(create: (_) => MockSubscriptionProvider()),
          ChangeNotifierProvider<NavigationModel>(create: (_) => NavigationModel()),
        ],
        child: const MaterialApp(
          home: SubscriptionsListView(),
        ),
      ),
    );

    // Verify Title
    expect(find.text('My Subscriptions'), findsOneWidget);

    // Verify Empty State
    expect(find.text('No Subscriptions'), findsOneWidget);
    expect(find.text('Tap the + button to add your first subscription'), findsOneWidget);

    // Verify FAB/Add button (in AppBar actions)
    expect(find.byIcon(Icons.add), findsOneWidget);

    // Verify Search Field
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Search subscriptions...'), findsOneWidget);
  });
}
