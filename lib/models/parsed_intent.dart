/// Data class to hold extracted information from natural language input
class ParsedIntent {
  /// The user's primary goal (e.g., 'create', 'setup', 'add')
  final String? action;

  /// The type of item the user is referring to (e.g., 'appointment', 'reminder')
  final String? category;

  /// The specific date and time for the item
  final DateTime? dateTime;

  /// The original input text
  final String originalText;

  ParsedIntent({
    this.action,
    this.category,
    this.dateTime,
    required this.originalText,
  });

  /// Returns a string representation of the parsed intent
  @override
  String toString() {
    return 'ParsedIntent(action: $action, category: $category, dateTime: $dateTime, originalText: $originalText)';
  }

  /// Returns true if the intent has all required information
  bool get isComplete => action != null && category != null && dateTime != null;

  /// Returns true if both action and category are not null
  /// This is the primary flag for determining if the parsing was successful
  bool get isSuccess => action != null && category != null;
}


