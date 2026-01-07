import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_reminder/services/intent_parser_service.dart';

void main() {
  late IntentParserService service;

  setUp(() {
    service = IntentParserService();
  });

  group('IntentParserService', () {
    test('extracts "create" action and "task" category', () {
      final result = service.parse('create task Buy milk');
      expect(result.action, 'create');
      expect(result.category, 'task');
      expect(result.originalText, 'create task Buy milk');
    });

    test('extracts "show" action and "appointment" category', () {
      final result = service.parse('show my appointments');
      expect(result.action, 'show');
      expect(result.category, 'appointment');
    });

    test('defaults to "create" action when only category is present', () {
      final result = service.parse('Appointment with Dr. Smith');
      expect(result.action, 'create');
      expect(result.category, 'appointment');
    });

    test('extracts relative date "tomorrow"', () {
      final result = service.parse('create task Buy milk tomorrow');
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1);

      expect(result.dateTime?.year, tomorrow.year);
      expect(result.dateTime?.month, tomorrow.month);
      expect(result.dateTime?.day, tomorrow.day);
    });

    test('extracts specific date and time', () {
      // Note: This test depends on the current year.
      // Ideally, we should mock the current time in the service, but for now we check logic.
      final result = service.parse('Meeting Dec 15th at 6pm');

      expect(result.dateTime?.month, 12);
      expect(result.dateTime?.day, 15);
      expect(result.dateTime?.hour, 18); // 6pm is 18:00
      expect(result.dateTime?.minute, 0);
    });

    test('extracts "subscription" category', () {
      final result = service.parse('add new subscription Netflix');
      expect(result.category, 'subscription');
      expect(result.action, 'create');
    });

    test('extracts "reminder" category', () {
      final result = service.parse('remind me to call mom');
      expect(result.category, 'reminder');
    });

    test('identifies show action from "what are my"', () {
      final result = service.parse('what are my tasks');
      expect(result.action, 'show');
      expect(result.category, 'task');
    });

    test('extracts time only', () {
      final result = service.parse('Lunch at 12:30pm');
      final now = DateTime.now();

      expect(result.dateTime?.year, now.year);
      expect(result.dateTime?.month, now.month);
      expect(result.dateTime?.day, now.day);
      expect(result.dateTime?.hour, 12);
      expect(result.dateTime?.minute, 30);
    });
  });
}
