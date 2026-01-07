import 'package:flutter_test/flutter_test.dart';
import 'package:my_reminder/providers/subscription_provider.dart';
import '../helpers/test_setup.dart';

void main() {
  setUpAll(() async {
    await setupSupabaseForTests();
  });

  tearDownAll(() async {
    await teardownSupabaseForTests();
  });

  group('SubscriptionProvider', () {
    late SubscriptionProvider provider;

    setUp(() {
      provider = SubscriptionProvider();
    });

    test('initial state has empty subscriptions', () {
      expect(provider.subscriptions, isEmpty);
      expect(provider.isLoading, false);
    });
  });
}
