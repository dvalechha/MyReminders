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
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
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
    );
  }
}

