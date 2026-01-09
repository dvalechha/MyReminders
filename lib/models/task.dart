import 'package:uuid/uuid.dart';
import 'appointment.dart';

enum TaskPriority {
  low('Low'),
  medium('Medium'),
  high('High');

  const TaskPriority(this.value);
  final String value;

  static TaskPriority fromString(String value) {
    return TaskPriority.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TaskPriority.medium,
    );
  }
}

class Task {
  final String id;
  final String title;
  final String? category;
  final DateTime? dueDate;
  final TaskPriority? priority;
  final String? notes;
  final ReminderOffset reminderOffset;
  final String? notificationId;
  final DateTime createdDate;
  final bool isCompleted;

  Task({
    String? id,
    required this.title,
    this.category,
    this.dueDate,
    this.priority,
    this.notes,
    this.reminderOffset = ReminderOffset.none,
    this.notificationId,
    DateTime? createdDate,
    this.isCompleted = false,
  })  : id = id ?? const Uuid().v4(),
        createdDate = createdDate ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'dueDate': dueDate?.toIso8601String(),
      'priority': priority?.value,
      'notes': notes,
      'reminderOffset': reminderOffset.minutes,
      'notificationId': notificationId,
      'createdDate': createdDate.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    // Handle isCompleted - SQLite stores booleans as integers (0 or 1)
    bool isCompleted = false;
    if (map['isCompleted'] != null) {
      if (map['isCompleted'] is bool) {
        isCompleted = map['isCompleted'] as bool;
      } else if (map['isCompleted'] is int) {
        isCompleted = (map['isCompleted'] as int) != 0;
      }
    }
    
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      category: map['category'] as String?,
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'] as String)
          : null,
      priority: map['priority'] != null
          ? TaskPriority.fromString(map['priority'] as String)
          : null,
      notes: map['notes'] as String?,
      reminderOffset: ReminderOffset.values.firstWhere(
        (e) => e.minutes == (map['reminderOffset'] as int),
        orElse: () => ReminderOffset.none,
      ),
      notificationId: map['notificationId'] as String?,
      createdDate: DateTime.parse(map['createdDate'] as String),
      isCompleted: isCompleted,
    );
  }

  Task copyWith({
    String? id,
    String? title,
    String? category,
    DateTime? dueDate,
    TaskPriority? priority,
    String? notes,
    ReminderOffset? reminderOffset,
    String? notificationId,
    DateTime? createdDate,
    bool? isCompleted,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      notes: notes ?? this.notes,
      reminderOffset: reminderOffset ?? this.reminderOffset,
      notificationId: notificationId ?? this.notificationId,
      createdDate: createdDate ?? this.createdDate,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  // Convert to Supabase format
  Map<String, dynamic> toSupabaseMap({
    required String userId,
    String? categoryId,
  }) {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'title': title,
      'due_date': dueDate?.toIso8601String(),
      'priority': priority?.value.toLowerCase(),
      'notes': notes,
      'reminder_offset_minutes': reminderOffset.minutes,
      'is_completed': isCompleted,
    };
  }

  // Create from Supabase format
  factory Task.fromSupabaseMap(Map<String, dynamic> map, {String? categoryName}) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      category: categoryName, // Use looked-up category name instead of category_id
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      priority: map['priority'] != null
          ? TaskPriority.fromString(map['priority'] as String)
          : null,
      notes: map['notes'] as String?,
      reminderOffset: ReminderOffset.values.firstWhere(
        (e) => e.minutes == (map['reminder_offset_minutes'] as int? ?? 0),
        orElse: () => ReminderOffset.none,
      ),
      createdDate: DateTime.parse(map['created_at'] as String),
      isCompleted: map['is_completed'] as bool? ?? false,
    );
  }
}

