import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_reminder/views/tasks_list_view.dart';
import 'package:provider/provider.dart';
import 'package:my_reminder/providers/task_provider.dart';
import 'package:my_reminder/providers/navigation_model.dart';
import 'package:my_reminder/models/task.dart';
import '../helpers/test_setup.dart';

class MockTaskProvider extends ChangeNotifier implements TaskProvider {
  @override
  bool isLoading = false;
  @override
  List<Task> tasks = [];

  @override
  Future<void> loadTasks({bool forceRefresh = false}) async {}

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

  testWidgets('TasksListView shows empty state initially', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<TaskProvider>(create: (_) => MockTaskProvider()),
          ChangeNotifierProvider<NavigationModel>(create: (_) => NavigationModel()),
        ],
        child: const MaterialApp(
          home: TasksListView(),
        ),
      ),
    );

    // Verify Title
    expect(find.text('My Tasks'), findsOneWidget);

    // Verify Empty State
    expect(find.text('No Tasks'), findsOneWidget);
    expect(find.text('Tap the + button to add your first task'), findsOneWidget);

    // Verify Add button
    expect(find.byIcon(Icons.add), findsOneWidget);

    // Verify Search
    expect(find.text('Search tasks...'), findsOneWidget);
  });
}
