import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_reminder/views/appointments_list_view.dart';
import 'package:provider/provider.dart';
import 'package:my_reminder/providers/appointment_provider.dart';
import 'package:my_reminder/providers/navigation_model.dart';
import 'package:my_reminder/models/appointment.dart';
import '../helpers/test_setup.dart';

class MockAppointmentProvider extends ChangeNotifier implements AppointmentProvider {
  @override
  bool isLoading = false;
  @override
  List<Appointment> appointments = [];

  @override
  Future<void> loadAppointments({bool forceRefresh = false}) async {}

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

  testWidgets('AppointmentsListView shows empty state initially', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppointmentProvider>(create: (_) => MockAppointmentProvider()),
          ChangeNotifierProvider<NavigationModel>(create: (_) => NavigationModel()),
        ],
        child: const MaterialApp(
          home: AppointmentsListView(),
        ),
      ),
    );

    // Verify Title
    expect(find.text('My Appointments'), findsOneWidget);

    // Verify Empty State
    expect(find.text('No Appointments'), findsOneWidget);
    expect(find.text('Tap the + button to add your first appointment'), findsOneWidget);

    // Verify Add button
    expect(find.byIcon(Icons.add), findsOneWidget);

    // Verify Search
    expect(find.text('Search appointments...'), findsOneWidget);
  });
}
