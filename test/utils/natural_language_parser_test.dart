import 'package:flutter_test/flutter_test.dart';
import 'package:my_reminder/utils/natural_language_parser.dart';

void main() {
  group('NaturalLanguageParser - Subscriptions', () {
    test('Parses Netflix with amount and currency from "\$20 CAD"', () {
      final input = 'Create subscription for Netflix renewal next month for \$20 CAD';
      final parsed = NaturalLanguageParser.parse(input);
      expect(parsed.type, ParsedReminderType.subscription);
      expect(parsed.title, 'Netflix');
      expect(parsed.amount, 20.0);
      expect(parsed.currencyCode, 'cad');
    });

    test('Parses Adobe with amount and currency from "19.99 USD"', () {
      final input = 'Create subscription for Adobe Creative Cloud for 19.99 USD';
      final parsed = NaturalLanguageParser.parse(input);
      expect(parsed.type, ParsedReminderType.subscription);
      expect(parsed.title, 'Adobe Creative Cloud');
      expect(parsed.amount, 19.99);
      expect(parsed.currencyCode, 'usd');
    });

    test('Parses Spotify with amount from "\$9.99" defaulting USD', () {
      final input = 'Create subscription for Spotify for \$9.99';
      final parsed = NaturalLanguageParser.parse(input);
      expect(parsed.type, ParsedReminderType.subscription);
      expect(parsed.title, 'Spotify');
      expect(parsed.amount, 9.99);
      expect(parsed.currencyCode, 'usd');
    });
  });

  group('NaturalLanguageParser - Appointments', () {
    // Location extraction is disabled - users fill it manually
    // All location tests now expect null
    
    test('Parses appointment with time and person, location is null', () {
      final input = 'Create an appointment to meet Dr Smith at 5pm tomorrow at his clinic';
      final parsed = NaturalLanguageParser.parse(input);
      expect(parsed.type, ParsedReminderType.appointment);
      expect(parsed.title, 'Meet Dr Smith');
      expect(parsed.location, isNull); // Location extraction disabled
    });

    test('Parses appointment with location keyword "in", location is null', () {
      final input = 'Create an appointment to meet Dr Smith at 5pm tomorrow in his clinic';
      final parsed = NaturalLanguageParser.parse(input);
      expect(parsed.type, ParsedReminderType.appointment);
      expect(parsed.title, 'Meet Dr Smith');
      expect(parsed.location, isNull); // Location extraction disabled
    });

    test('Parses appointment with @ symbol, location is null', () {
      final input1 = 'Create an appointment to meet Dr Smith @ his clinic';
      final parsed1 = NaturalLanguageParser.parse(input1);
      expect(parsed1.type, ParsedReminderType.appointment);
      expect(parsed1.location, isNull); // Location extraction disabled

      final input2 = 'Create an appointment to meet Dr Smith @ 5pm';
      final parsed2 = NaturalLanguageParser.parse(input2);
      expect(parsed2.type, ParsedReminderType.appointment);
      expect(parsed2.location, isNull);
    });

    test('Parses complex appointment, location is null', () {
      final input = 'Create an appointment for tomorrow at 5pm with Dr. Smith at his Clinic';
      final parsed = NaturalLanguageParser.parse(input);
      expect(parsed.type, ParsedReminderType.appointment);
      expect(parsed.location, isNull); // Location extraction disabled
    });

    test('Parses meeting appointment, location is null', () {
      final input = 'Meeting with John at the coffee shop on Friday';
      final parsed = NaturalLanguageParser.parse(input);
      expect(parsed.type, ParsedReminderType.appointment);
      expect(parsed.location, isNull); // Location extraction disabled
    });

    test('Parses simple appointment, location is null', () {
      final input = 'Appointment for 3pm at home';
      final parsed = NaturalLanguageParser.parse(input);
      expect(parsed.type, ParsedReminderType.appointment);
      expect(parsed.location, isNull); // Location extraction disabled
    });

    test('Parses room meeting, location is null', () {
      final input = 'Schedule a meeting in room 201';
      final parsed = NaturalLanguageParser.parse(input);
      expect(parsed.type, ParsedReminderType.appointment);
      expect(parsed.location, isNull); // Location extraction disabled
    });

    test('Parses dentist appointment, location is null', () {
      final input = 'Dentist appointment at 10 AM with Dr. Lee';
      final parsed = NaturalLanguageParser.parse(input);
      expect(parsed.type, ParsedReminderType.appointment);
      expect(parsed.location, isNull);
    });
  });
}
