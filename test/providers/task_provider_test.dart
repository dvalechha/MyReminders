import 'package:flutter_test/flutter_test.dart';
import 'package:my_reminder/providers/task_provider.dart';
import '../helpers/test_setup.dart';

void main() {
  setUpAll(() async {
    await setupSupabaseForTests();
  });

  tearDownAll(() async {
    await teardownSupabaseForTests();
  });

  group('TaskProvider', () {
    late TaskProvider provider;

    setUp(() {
      provider = TaskProvider();
    });

    test('initial state has empty tasks', () {
      expect(provider.tasks, isEmpty);
      expect(provider.isLoading, false);
    });

    // Add more tests as needed when mocking strategy for repositories is established
  });
}
