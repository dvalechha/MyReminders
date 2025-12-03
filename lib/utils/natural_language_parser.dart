import 'package:flutter/material.dart';

enum ParsedReminderType {
  subscription,
  appointment,
  task,
  unknown,
}

class ParsedReminder {
  final ParsedReminderType type;
  final String? title;
  final DateTime? date;
  final String? location;
  final TimeOfDay? time;
  final double? amount; // For subscriptions only
  final String? currencyCode; // For subscriptions only (usd/cad/eur/inr)

  ParsedReminder({
    required this.type,
    this.title,
    this.date,
    this.location,
    this.time,
    this.amount,
    this.currencyCode,
  });
}

class NaturalLanguageParser {
  // Keywords that indicate subscription reminders
  static const List<String> _subscriptionKeywords = [
    'subscription',
    'subscriptions',
    'renewal',
    'renew',
    'billing',
    'payment',
  ];

  // Keywords that indicate appointment reminders
  static const List<String> _appointmentKeywords = [
    'appointment',
    'appointments',
    'meeting',
    'meetings',
    'doctor',
    'dentist',
    'visit',
  ];

  // Keywords that indicate task reminders
  static const List<String> _taskKeywords = [
    'task',
    'tasks',
    'todo',
    'todos',
    'to-do',
    'to do',
    'reminder',
    'remind',
  ];

  // Month abbreviations and full names
  static const Map<String, int> _months = {
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

  /// Parse natural language input to extract reminder type, title, and date
  static ParsedReminder parse(String input) {
    final originalInput = input.trim();
    final lowerInput = originalInput.toLowerCase();
    
    // Determine type
    final type = _determineType(lowerInput);
    
    // Extract date
    final date = _extractDate(lowerInput);
    
    // Extract time
    final time = _extractTime(lowerInput);
    
    // Extract title/description (preserve original casing for readability)
    final title = _extractTitle(originalInput, type);
    
    // Extract location (for appointments) from original input, but avoid time/date phrases
    final location = type == ParsedReminderType.appointment 
      ? _extractLocation(originalInput) 
      : null;
    
    // Extract amount and currency for subscriptions
    double? amount;
    String? currencyCode;
    if (type == ParsedReminderType.subscription) {
      final amountCurrency = _extractAmountAndCurrency(originalInput);
      amount = amountCurrency.$1;
      currencyCode = amountCurrency.$2;
    }

    return ParsedReminder(
      type: type,
      title: title,
      date: date,
      location: location,
      time: time,
      amount: amount,
      currencyCode: currencyCode,
    );
  }

  static ParsedReminderType _determineType(String input) {
    // Check for subscription keywords
    for (final keyword in _subscriptionKeywords) {
      if (input.contains(keyword)) {
        return ParsedReminderType.subscription;
      }
    }
    
    // Check for appointment keywords
    for (final keyword in _appointmentKeywords) {
      if (input.contains(keyword)) {
        return ParsedReminderType.appointment;
      }
    }
    
    // Check for task keywords
    for (final keyword in _taskKeywords) {
      if (input.contains(keyword)) {
        return ParsedReminderType.task;
      }
    }
    
    return ParsedReminderType.unknown;
  }

  static DateTime? _extractDate(String input) {
    final now = DateTime.now();
    final currentYear = now.year;
    
    // Pattern 1: "Dec 15th", "December 15th", "Dec 15", "December 15"
    // Pattern 2: "on Dec 15th", "coming up on Dec 15th"
    // Pattern 3: "Dec 15, 2024" or "December 15, 2024"
    
    // Try to find month and day patterns
    for (final entry in _months.entries) {
      final monthName = entry.key;
      final monthNum = entry.value;
      
      // Pattern 1: "month day" or "month dayth" or "month day, year"
      // e.g., "Dec 15th", "December 15", "Dec 15, 2024"
      final pattern1 = RegExp(
        '\\b$monthName\\s+(\\d{1,2})(?:st|nd|rd|th)?(?:,\\s*(\\d{4}))?\\b',
        caseSensitive: false,
      );
      
      // Pattern 2: "day month" or "dayth month" or "day month, year"
      // e.g., "15th Dec", "15 December", "15 Dec, 2024"
      final pattern2 = RegExp(
        '\\b(\\d{1,2})(?:st|nd|rd|th)?\\s+$monthName(?:,\\s*(\\d{4}))?\\b',
        caseSensitive: false,
      );
      
      for (final pattern in [pattern1, pattern2]) {
        final match = pattern.firstMatch(input);
        if (match != null) {
          final day = int.tryParse(match.group(1) ?? '');
          final yearStr = match.group(2);
          final year = yearStr != null ? int.tryParse(yearStr) : null;
          
          if (day != null && day >= 1 && day <= 31) {
            try {
              final targetYear = year ?? currentYear;
              final date = DateTime(targetYear, monthNum, day);
              // If the date is in the past for this year, assume next year
              if (date.isBefore(now) && year == null) {
                return DateTime(currentYear + 1, monthNum, day);
              }
              return date;
            } catch (e) {
              // Invalid date (e.g., Feb 30), continue trying
              continue;
            }
          }
        }
      }
    }
    
    // Try relative dates
    if (input.contains(RegExp(r'\btomorrow\b', caseSensitive: false))) {
      return now.add(const Duration(days: 1));
    }
    if (input.contains(RegExp(r'\btoday\b', caseSensitive: false))) {
      return now;
    }
    if (input.contains(RegExp(r'\bnext\s+week\b', caseSensitive: false))) {
      return now.add(const Duration(days: 7));
    }
    if (input.contains(RegExp(r'\bnext\s+month\b', caseSensitive: false))) {
      final nextMonth = now.month == 12 ? 1 : now.month + 1;
      final nextYear = now.month == 12 ? now.year + 1 : now.year;
      return DateTime(nextYear, nextMonth, now.day);
    }
    
    return null;
  }

  static String? _extractTitle(String input, ParsedReminderType type) {
    // Start from original input; we'll strip out time/date and filler phrases
    String cleaned = input;

    // Remove common setup/action phrases
    final setupPhrases = <RegExp>[
      RegExp(r'\bsetup\s+(?:an?\s+)?', caseSensitive: false),
      RegExp(r'\bcreate\s+(?:an?\s+)?', caseSensitive: false),
      RegExp(r'\badd\s+(?:an?\s+)?', caseSensitive: false),
      RegExp(r'\bnew\s+', caseSensitive: false),
      RegExp(r'\breminder\s+for\s+(?:an?\s+)?', caseSensitive: false),
    ];
    for (final r in setupPhrases) {
      cleaned = cleaned.replaceAll(r, '');
    }

    // Remove explicit appointment filler/action phrases first (order matters)
    final appointmentFiller = <RegExp>[
      RegExp(r'\bappointment\s+to\s+meet\b', caseSensitive: false),
      RegExp(r'\bappointment\s+with\b', caseSensitive: false),
      RegExp(r'\bmeeting\s+with\b', caseSensitive: false),
      RegExp(r'\bto\s+meet\b', caseSensitive: false),
      RegExp(r'\bwith\b', caseSensitive: false),
      RegExp(r'\bappointments?\b', caseSensitive: false),
    ];

    // Strip date and time phrases to avoid them polluting title
    cleaned = _stripDateTimePhrases(cleaned);

    // Remove trailing location phrases from title (e.g., "at his clinic", "in his clinic", "@ his clinic")
    if (type == ParsedReminderType.appointment) {
      cleaned = cleaned.replaceAll(RegExp(r'\s+(?:at|in)\s+[^,]+$', caseSensitive: false), '');
      cleaned = cleaned.replaceAll(RegExp(r'\s+@\s+[^,]+$', caseSensitive: false), '');
    }

    if (type == ParsedReminderType.appointment) {
      for (final r in appointmentFiller) {
        cleaned = cleaned.replaceAll(r, ' ');
      }
    } else if (type == ParsedReminderType.task) {
      cleaned = cleaned
          .replaceAll(RegExp(r'\btasks?\b', caseSensitive: false), ' ')
          .replaceAll(RegExp(r'\btodos?\b', caseSensitive: false), ' ')
          .replaceAll(RegExp(r'\bto-?do\b', caseSensitive: false), ' ')
          .replaceAll(RegExp(r'\breminder\b', caseSensitive: false), ' ');
    } else if (type == ParsedReminderType.subscription) {
      // Light cleanup for subscriptions
      cleaned = cleaned.replaceAll(RegExp(r'\bsubscriptions?\b', caseSensitive: false), ' ');
      cleaned = cleaned.replaceAll(RegExp(r'\brenew(al)?\b', caseSensitive: false), ' ');
      cleaned = cleaned.replaceAll(RegExp(r'\bbilling\b', caseSensitive: false), ' ');
      cleaned = cleaned.replaceAll(RegExp(r'\bpayment\b', caseSensitive: false), ' ');
      cleaned = cleaned.replaceAll(RegExp(r'\bfor\b', caseSensitive: false), ' ');
      // Remove currency/amount tokens to avoid polluting title
      cleaned = cleaned.replaceAll(RegExp(r'\$\s*\d+(?:\.\d{1,2})?', caseSensitive: false), ' ');
      cleaned = cleaned.replaceAll(RegExp(r'\b\d+(?:\.\d{1,2})?\s*(usd|cad|eur|inr)\b', caseSensitive: false), ' ');
      // Remove standalone currency codes that might trail (e.g., 'CAD')
      cleaned = cleaned.replaceAll(RegExp(r'\b(usd|cad|eur|inr)\b', caseSensitive: false), ' ');
    }

    // Final common fillers
    cleaned = cleaned
        .replaceAll(RegExp(r'\bon\b', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\bat\b', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\bin\b', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\bthe\b', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\ban?\b', caseSensitive: false), ' ');

    // Normalize whitespace and punctuation
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    cleaned = cleaned.replaceAll(RegExp(r'^[:,-]+|[:,-]+$'), '').trim();

    if (cleaned.isEmpty) return null;

    // For appointments, optionally prepend a verb for consistency
    if (type == ParsedReminderType.appointment) {
      final titled = _titleCase(cleaned);
      return titled.startsWith(RegExp(r'Meet\b')) ? titled : 'Meet $titled';
    }

    return _cleanTitle(cleaned);
  }

  static String _stripDateTimePhrases(String input) {
    String s = input;

    // Month and date patterns
    final monthDay = RegExp(
      r'\b(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\s+\d{1,2}(?:st|nd|rd|th)?(?:\s*,\s*\d{4})?\b',
      caseSensitive: false,
    );
    final dayMonth = RegExp(
      r'\b\d{1,2}(?:st|nd|rd|th)?\s+(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*(?:\s*,\s*\d{4})?\b',
      caseSensitive: false,
    );
    // Relative date words
    final relatives = RegExp(r'\b(tomorrow|today|next\s+(week|month))\b', caseSensitive: false);
    // Time expressions
    final timeAt = RegExp(r'\bat\s+\d{1,2}(?::\d{2})?\s*(am|pm)\b', caseSensitive: false);
    final timeStandalone = RegExp(r'\b\d{1,2}(:\d{2})?\s*(am|pm)\b', caseSensitive: false);

    for (final r in [monthDay, dayMonth, relatives, timeAt, timeStandalone]) {
      s = s.replaceAll(r, ' ');
    }

    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static TimeOfDay? _extractTime(String input) {
    // Pattern: "at 7pm", "at 7:00 pm", "at 7:00pm", "at 7 am", etc.
    final timePattern = RegExp(
      r'\bat\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)\b',
      caseSensitive: false,
    );
    
    final match = timePattern.firstMatch(input);
    if (match != null) {
      final hour = int.tryParse(match.group(1) ?? '');
      final minute = int.tryParse(match.group(2) ?? '0');
      
      if (hour != null && hour >= 1 && hour <= 12) {
        final isPm = (match.group(3) ?? '').toLowerCase() == 'pm';
        var hour24 = hour;
        if (isPm && hour != 12) {
          hour24 = hour + 12;
        } else if (!isPm && hour == 12) {
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

  static String? _extractLocation(String input) {
    // Only treat explicit location keywords as locations
    // and ensure captured text is not a time/date phrase
    final candidates = <RegExp>[
      RegExp(r'\bat\s+([^,]+?)(?=\s+(?:on|at|in|@)\b|\s+coming\b|\s*$)', caseSensitive: false),
      RegExp(r'\bin\s+([^,]+?)(?=\s+(?:on|at|in|@)\b|\s+coming\b|\s*$)', caseSensitive: false),
      RegExp(r'(?:^|\s)@\s*([^,]+?)(?=\s+(?:on|at|in|@)\b|\s+coming\b|\s*$)', caseSensitive: false),
    ];

    for (final pattern in candidates) {
      final matches = pattern.allMatches(input).toList();
      for (final match in matches) {
        final phrase = match.group(1)?.trim();
        if (phrase == null || phrase.isEmpty) continue;

        // If the phrase is a known date/time expression, ignore as location
        if (_isDateOrTimePhrase(phrase)) {
          continue;
        }

        // Otherwise treat as location
        var loc = phrase.replaceAll(RegExp(r'\s+'), ' ').trim();
        // Skip obvious handle/email-like tokens when no spaces
        if (RegExp(r'^[\w.@-]+$').hasMatch(loc) && !loc.contains(' ')) {
          continue;
        }
        // Remove leading articles for cleanliness
        loc = loc.replaceFirst(RegExp(r'^(the|a|an)\s+', caseSensitive: false), '');
        if (loc.isNotEmpty && loc.length < 100) {
          return loc;
        }
      }
    }

    return null;
  }

  static bool _isDateOrTimePhrase(String phrase) {
    final p = phrase.trim();
    // Time patterns
    if (RegExp(r'^\d{1,2}(:\d{2})?\s*(am|pm)$', caseSensitive: false).hasMatch(p)) return true;
    if (RegExp(r'^at\s+\d{1,2}(:\d{2})?\s*(am|pm)$', caseSensitive: false).hasMatch(p)) return true;
    if (RegExp(r'^@\s*\d{1,2}(:\d{2})?\s*(am|pm)$', caseSensitive: false).hasMatch(p)) return true;
    // Relative day words
    if (RegExp(r'\b(tomorrow|today|tonight|next\s+(week|month))\b', caseSensitive: false).hasMatch(p)) return true;
    // Parts of day as time-like phrases
    if (RegExp(r'\b(morning|afternoon|evening|noon|midnight)\b', caseSensitive: false).hasMatch(p)) return true;
    // Month-date combos
    if (RegExp(r'(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\s+\d{1,2}(?:st|nd|rd|th)?', caseSensitive: false).hasMatch(p)) return true;
    if (RegExp(r'\d{1,2}(?:st|nd|rd|th)?\s+(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*', caseSensitive: false).hasMatch(p)) return true;
    return false;
  }

  static String _cleanTitle(String title) {
    return title
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _titleCase(String input) {
    final words = input.split(RegExp(r'\s+'));
    return words
        .map((w) => w.isEmpty
            ? w
            : (w[0].toUpperCase() + (w.length > 1 ? w.substring(1) : '')))
        .join(' ')
        .trim();
  }

  static (double?, String?) _extractAmountAndCurrency(String input) {
    // Patterns: "20 USD", "20.50 cad", "EUR 19.99"
    final amountThenCode = RegExp(r'\b(\d+(?:\.\d{1,2})?)\s*(usd|cad|eur|inr)\b', caseSensitive: false).firstMatch(input);
    if (amountThenCode != null) {
      final amt = double.tryParse(amountThenCode.group(1)!);
      final code = amountThenCode.group(2)!.toLowerCase();
      return (amt, code);
    }
    final codeThenAmount = RegExp(r'\b(usd|cad|eur|inr)\s*(\d+(?:\.\d{1,2})?)\b', caseSensitive: false).firstMatch(input);
    if (codeThenAmount != null) {
      final code = codeThenAmount.group(1)!.toLowerCase();
      final amt = double.tryParse(codeThenAmount.group(2)!);
      return (amt, code);
    }
    // Dollar-prefixed: "$ 20" or "$20.00"; assume USD
    final dollarPrefixed = RegExp(r'\$\s*(\d+(?:\.\d{1,2})?)').firstMatch(input);
    if (dollarPrefixed != null) {
      final amt = double.tryParse(dollarPrefixed.group(1)!);
      return (amt, 'usd');
    }
    return (null, null);
  }
}

