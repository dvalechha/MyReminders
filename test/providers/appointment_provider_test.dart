import 'package:flutter_test/flutter_test.dart';
import 'package:my_reminder/providers/appointment_provider.dart';
import '../helpers/test_setup.dart';

void main() {
  setUpAll(() async {
    await setupSupabaseForTests();
  });

  tearDownAll(() async {
    await teardownSupabaseForTests();
  });

  group('AppointmentProvider', () {
    late AppointmentProvider provider;

    setUp(() {
      provider = AppointmentProvider();
    });

    test('initial state has empty appointments', () {
      expect(provider.appointments, isEmpty);
      expect(provider.isLoading, false);
    });
  });
}
