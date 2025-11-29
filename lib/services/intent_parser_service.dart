import 'package:flutter/material.dart';
import '../models/parsed_intent.dart';

/// Service class for parsing natural language input to extract user intent
/// 
/// This service extracts:
/// - Action: The user's primary goal (e.g., 'create', 'setup', 'add')
/// - Category: The type of item (e.g., 'appointment', 'reminder')
/// - Date & Time: The specific date and time for the item
class IntentParserService {
  // Keywords for action 'create'
  static const List<String> _createActionKeywords = [
    'create',
    'setup',
    'add',
    'make',
    'need',
    'set up',
    'schedule',
    'new',
  ];

  // Keywords for category 'appointment'
  static const List<String> _appointmentCategoryKeywords = [
    'appointment',
    'appt',
    'meeting',
    'meet',
    'doctor',
    'dentist',
    'visit',
  ];

  // Keywords for category 'reminder'
  static const List<String> _reminderCategoryKeywords = [
    'reminder',
    'remind me',
    'remind',
  ];

  // Keywords for category 'subscription'
  static const List<String> _subscriptionCategoryKeywords = [
    'subscription',
    'subscriptions',
    'renewal',
    'renew',
    'billing',
    'payment',
  ];

  // Keywords for category 'task'
  static const List<String> _taskCategoryKeywords = [
    'task',
    'tasks',
    'todo',
    'todos',
    'to-do',
    'to do',
  ];

  /// Parse natural language text to extract intent information
  /// 
  /// Returns a [ParsedIntent] object containing:
  /// - action: The detected action (e.g., 'create')
  /// - category: The detected category (e.g., 'appointment', 'reminder')
  /// - dateTime: The parsed date and time
  /// - originalText: The original input text
  ParsedIntent parse(String text) {
    final originalText = text.trim();
    final lowerText = text.toLowerCase().trim();

    // Extract date and time first (to remove from text for keyword matching)
    final dateTime = _extractDateTime(lowerText);
    
    // Remove date/time phrases from text for cleaner keyword matching
    String textForKeywords = _removeDateTimePhrases(lowerText);

    // Extract action
    final action = _extractAction(textForKeywords);

    // Extract category
    final category = _extractCategory(textForKeywords);

    return ParsedIntent(
      action: action,
      category: category,
      dateTime: dateTime,
      originalText: originalText,
    );
  }

  /// Extract action from text using keyword matching
  String? _extractAction(String text) {
    for (final keyword in _createActionKeywords) {
      if (text.contains(keyword)) {
        return 'create';
      }
    }
    return null;
  }

  /// Extract category from text using keyword matching
  String? _extractCategory(String text) {
    // Check for appointment keywords
    for (final keyword in _appointmentCategoryKeywords) {
      if (text.contains(keyword)) {
        return 'appointment';
      }
    }

    // Check for reminder keywords
    for (final keyword in _reminderCategoryKeywords) {
      if (text.contains(keyword)) {
        return 'reminder';
      }
    }

    // Check for subscription keywords
    for (final keyword in _subscriptionCategoryKeywords) {
      if (text.contains(keyword)) {
        return 'subscription';
      }
    }

    // Check for task keywords
    for (final keyword in _taskCategoryKeywords) {
      if (text.contains(keyword)) {
        return 'task';
      }
    }

    return null;
  }

  /// Extract date and time from text
  /// 
  /// This is a simplified implementation. For production, consider using
  /// a dedicated date parsing package like 'any_date' or 'dateparser'
  DateTime? _extractDateTime(String text) {
    // Try to parse common date/time patterns
    // Pattern 1: "Dec 15th at 6pm", "December 15th at 6pm"
    // Pattern 2: "in a month's time on 15th at 6pm"
    // Pattern 3: "tomorrow at 3pm"
    // Pattern 4: "next week on Monday at 2pm"
    
    final now = DateTime.now();
    
    // Try relative dates first
    if (text.contains('tomorrow')) {
      final time = _extractTimeFromText(text);
      if (time != null) {
        return DateTime(
          now.year,
          now.month,
          now.day + 1,
          time.hour,
          time.minute,
        );
      }
      return DateTime(now.year, now.month, now.day + 1);
    }

    if (text.contains('today')) {
      final time = _extractTimeFromText(text);
      if (time != null) {
        return DateTime(
          now.year,
          now.month,
          now.day,
          time.hour,
          time.minute,
        );
      }
      return DateTime(now.year, now.month, now.day);
    }

    // Try to parse month names and dates
    final monthPattern = RegExp(
      r'\b(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\s+(\d{1,2})(?:st|nd|rd|th)?(?:\s*,\s*(\d{4}))?',
      caseSensitive: false,
    );

    final monthMatch = monthPattern.firstMatch(text);
    if (monthMatch != null) {
      final monthName = monthMatch.group(1)!.toLowerCase();
      final day = int.tryParse(monthMatch.group(2) ?? '');
      final yearStr = monthMatch.group(3);
      final year = yearStr != null ? int.tryParse(yearStr) : null;

      final monthMap = {
        'jan': 1, 'january': 1,
        'feb': 2, 'february': 2,
        'mar': 3, 'march': 3,
        'apr': 4, 'april': 4,
        'may': 5,
        'jun': 6, 'june': 6,
        'jul': 7, 'july': 7,
        'aug': 8, 'august': 8,
        'sep': 9, 'september': 9,
        'oct': 10, 'october': 10,
        'nov': 11, 'november': 11,
        'dec': 12, 'december': 12,
      };

      final month = monthMap[monthName];
      if (month != null && day != null) {
        final targetYear = year ?? now.year;
        var dateTime = DateTime(targetYear, month, day);
        
        // If date is in the past, assume next year
        if (dateTime.isBefore(now) && year == null) {
          dateTime = DateTime(targetYear + 1, month, day);
        }

        // Try to extract time
        final time = _extractTimeFromText(text);
        if (time != null) {
          return DateTime(
            dateTime.year,
            dateTime.month,
            dateTime.day,
            time.hour,
            time.minute,
          );
        }

        return dateTime;
      }
    }

    // Try to extract just time if no date found
    final time = _extractTimeFromText(text);
    if (time != null) {
      return DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );
    }

    return null;
  }

  /// Extract time from text (e.g., "6pm", "6:00 pm", "at 3pm")
  TimeOfDay? _extractTimeFromText(String text) {
    // Pattern: "at 6pm", "at 6:00 pm", "at 6:00pm", "6pm", etc.
    final timePattern = RegExp(
      r'(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)\b',
      caseSensitive: false,
    );

    final match = timePattern.firstMatch(text);
    if (match != null) {
      final hour = int.tryParse(match.group(1) ?? '');
      final minute = int.tryParse(match.group(2) ?? '0');
      final period = (match.group(3) ?? '').toLowerCase();

      if (hour != null && hour >= 1 && hour <= 12) {
        var hour24 = hour;
        if (period == 'pm' && hour != 12) {
          hour24 = hour + 12;
        } else if (period == 'am' && hour == 12) {
          hour24 = 0;
        }

        return TimeOfDay(
          hour: hour24,
          minute: minute ?? 0,
        );
      }
    }

    return null;
  }

  /// Remove date/time phrases from text to improve keyword matching
  String _removeDateTimePhrases(String text) {
    String cleaned = text;

    // Remove date patterns
    cleaned = cleaned.replaceAll(
      RegExp(
        r'\b(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\s+\d{1,2}(?:st|nd|rd|th)?(?:\s*,\s*\d{4})?',
        caseSensitive: false,
      ),
      '',
    );

    // Remove time patterns
    cleaned = cleaned.replaceAll(
      RegExp(r'(?:at\s+)?\d{1,2}(?::\d{2})?\s*(?:am|pm)\b', caseSensitive: false),
      '',
    );

    // Remove relative date words
    cleaned = cleaned.replaceAll(RegExp(r'\btomorrow\b', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'\btoday\b', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r'\bnext\s+week\b', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(RegExp(r"in\s+a\s+month'?s?\s+time", caseSensitive: false), '');

    return cleaned.trim();
  }
}


