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

  ParsedReminder({
    required this.type,
    this.title,
    this.date,
    this.location,
    this.time,
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
    final lowerInput = input.toLowerCase().trim();
    
    // Determine type
    final type = _determineType(lowerInput);
    
    // Extract date
    final date = _extractDate(lowerInput);
    
    // Extract time
    final time = _extractTime(lowerInput);
    
    // Extract title/description
    final title = _extractTitle(lowerInput, type);
    
    // Extract location (for appointments)
    final location = type == ParsedReminderType.appointment 
        ? _extractLocation(lowerInput) 
        : null;
    
    return ParsedReminder(
      type: type,
      title: title,
      date: date,
      location: location,
      time: time,
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
    // Remove common setup phrases (be more careful to preserve words)
    // Use word boundaries to avoid partial word matches
    String cleaned = input
        .replaceAll(RegExp(r'\bsetup\s+(?:a\s+)?', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bcreate\s+(?:a\s+)?', caseSensitive: false), '')
        .replaceAll(RegExp(r'\badd\s+(?:a\s+)?', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bnew\s+', caseSensitive: false), '')
        .replaceAll(RegExp(r'\breminder\s+for\s+(?:a\s+)?', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bcoming\s+up\s+on\s+', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bon\s+', caseSensitive: false), '');
    
    // Note: We don't remove "reminder with" here because "with" is needed for location extraction
    
    // Remove date patterns (e.g., "Dec 15th", "December 15")
    cleaned = cleaned.replaceAll(
      RegExp(r'\b(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\s+\d{1,2}(?:st|nd|rd|th)?(?:\s*,\s*\d{4})?', caseSensitive: false),
      '',
    );
    
    // Remove time patterns (e.g., "at 7pm", "at 7:00 pm", "at 7:00pm")
    cleaned = cleaned.replaceAll(
      RegExp(r'\bat\s+\d{1,2}(?::\d{2})?\s*(?:am|pm)\b', caseSensitive: false),
      '',
    );
    
    // Remove common filler words
    cleaned = cleaned
        .replaceAll(RegExp(r'\bthe\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\ba\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\ban\b', caseSensitive: false), '');
    
    // Extract the main description based on type
    if (type == ParsedReminderType.subscription || type == ParsedReminderType.task) {
      // For subscriptions, look for phrases like "subscriptions renewal" or service names
      // Try to find text that includes subscription keywords
      for (final keyword in _subscriptionKeywords) {
        if (cleaned.contains(keyword)) {
          // Extract a meaningful phrase around the keyword
          final index = cleaned.indexOf(keyword);
          // Get context before and after the keyword
          final beforeContext = index > 0 
              ? cleaned.substring(0, index).trim().split(' ').take(3).join(' ')
              : '';
          final afterContext = (index + keyword.length) < cleaned.length
              ? cleaned.substring(index + keyword.length).trim().split(' ').take(3).join(' ')
              : '';
          
          // Combine context
          final parts = [beforeContext, keyword, afterContext]
              .where((p) => p.isNotEmpty)
              .toList();
          final extracted = parts.join(' ').trim();
          
          if (extracted.isNotEmpty) {
            return _cleanTitle(extracted);
          }
        }
      }
    } else if (type == ParsedReminderType.appointment) {
      // For appointments, look for phrases like "doctor appointment" or "meeting with X"
      // Remove "appointment" keyword if it appears, and extract the meaningful part
      String appointmentTitle = cleaned;
      
      // Remove standalone "appointment" or "appointments" word (but preserve context)
      // Pattern: "appointment reminder" -> "reminder", "appointment with X" -> "with X"
      appointmentTitle = appointmentTitle.replaceAll(
        RegExp(r'\bappointments?\s+', caseSensitive: false),
        '',
      );
      
      // Also remove "reminder" if it's still there
      appointmentTitle = appointmentTitle.replaceAll(
        RegExp(r'\breminder\s+', caseSensitive: false),
        '',
      );
      
      // Try to find other appointment keywords and extract context
      for (final keyword in _appointmentKeywords) {
        if (keyword != 'appointment' && keyword != 'appointments' && appointmentTitle.contains(keyword)) {
          // Extract a meaningful phrase around the keyword
          final index = appointmentTitle.indexOf(keyword);
          // Get context before and after the keyword
          final beforeContext = index > 0 
              ? appointmentTitle.substring(0, index).trim().split(' ').take(3).join(' ')
              : '';
          final afterContext = (index + keyword.length) < appointmentTitle.length
              ? appointmentTitle.substring(index + keyword.length).trim().split(' ').take(3).join(' ')
              : '';
          
          // Combine context
          final parts = [beforeContext, keyword, afterContext]
              .where((p) => p.isNotEmpty)
              .toList();
          final extracted = parts.join(' ').trim();
          
          if (extracted.isNotEmpty) {
            return _cleanTitle(extracted);
          }
        }
      }
      
      // If no keyword found, use the cleaned appointment title
      appointmentTitle = appointmentTitle.trim();
      if (appointmentTitle.isNotEmpty) {
        return _cleanTitle(appointmentTitle);
      }
    } else if (type == ParsedReminderType.task) {
      // For tasks, remove task-related keywords and extract the meaningful part
      String taskTitle = cleaned;
      
      // Remove standalone "task", "tasks", "todo", "reminder" words
      taskTitle = taskTitle.replaceAll(RegExp(r'\btasks?\s+', caseSensitive: false), '');
      taskTitle = taskTitle.replaceAll(RegExp(r'\btodos?\s+', caseSensitive: false), '');
      taskTitle = taskTitle.replaceAll(RegExp(r'\bto-do\s+', caseSensitive: false), '');
      taskTitle = taskTitle.replaceAll(RegExp(r'\bto\s+do\s+', caseSensitive: false), '');
      taskTitle = taskTitle.replaceAll(RegExp(r'\breminder\s+', caseSensitive: false), '');
      
      // Try to find other task keywords and extract context
      for (final keyword in _taskKeywords) {
        if (keyword != 'task' && keyword != 'tasks' && keyword != 'todo' && 
            keyword != 'todos' && keyword != 'to-do' && keyword != 'to do' && 
            keyword != 'reminder' && taskTitle.contains(keyword)) {
          // Extract a meaningful phrase around the keyword
          final index = taskTitle.indexOf(keyword);
          final beforeContext = index > 0 
              ? taskTitle.substring(0, index).trim().split(' ').take(3).join(' ')
              : '';
          final afterContext = (index + keyword.length) < taskTitle.length
              ? taskTitle.substring(index + keyword.length).trim().split(' ').take(3).join(' ')
              : '';
          
          final parts = [beforeContext, keyword, afterContext]
              .where((p) => p.isNotEmpty)
              .toList();
          final extracted = parts.join(' ').trim();
          
          if (extracted.isNotEmpty) {
            return _cleanTitle(extracted);
          }
        }
      }
      
      // If no keyword found, use the cleaned task title
      taskTitle = taskTitle.trim();
      if (taskTitle.isNotEmpty) {
        return _cleanTitle(taskTitle);
      }
    }
    
    // Fallback: use the cleaned input (first 50 chars)
    final title = cleaned.trim();
    if (title.length > 50) {
      return title.substring(0, 50).trim();
    }
    return title.isNotEmpty ? title : null;
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
    // Look for location indicators like "at", "with", "in"
    final locationPatterns = [
      RegExp(r'with\s+([^,]+?)(?:\s+coming|\s+on|$)', caseSensitive: false),
      RegExp(r'at\s+([^,]+?)(?:\s+coming|\s+on|$)', caseSensitive: false),
      RegExp(r'in\s+([^,]+?)(?:\s+coming|\s+on|$)', caseSensitive: false),
    ];
    
    for (final pattern in locationPatterns) {
      final match = pattern.firstMatch(input);
      if (match != null) {
        final location = match.group(1)?.trim();
        if (location != null && location.isNotEmpty && location.length < 100) {
          return location;
        }
      }
    }
    
    return null;
  }

  static String _cleanTitle(String title) {
    return title
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

