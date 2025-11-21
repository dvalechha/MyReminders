import 'package:uuid/uuid.dart';
import 'appointment.dart';

class CustomReminder {
  final String id;
  final String title;
  final String? category;
  final DateTime? dateTime;
  final String? notes;
  final ReminderOffset reminderOffset;
  final String? notificationId;
  final DateTime createdDate;

  CustomReminder({
    String? id,
    required this.title,
    this.category,
    this.dateTime,
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
      'dateTime': dateTime?.toIso8601String(),
      'notes': notes,
      'reminderOffset': reminderOffset.minutes,
      'notificationId': notificationId,
      'createdDate': createdDate.toIso8601String(),
    };
  }

  factory CustomReminder.fromMap(Map<String, dynamic> map) {
    return CustomReminder(
      id: map['id'] as String,
      title: map['title'] as String,
      category: map['category'] as String?,
      dateTime: map['dateTime'] != null
          ? DateTime.parse(map['dateTime'] as String)
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

  CustomReminder copyWith({
    String? id,
    String? title,
    String? category,
    DateTime? dateTime,
    String? notes,
    ReminderOffset? reminderOffset,
    String? notificationId,
    DateTime? createdDate,
  }) {
    return CustomReminder(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      dateTime: dateTime ?? this.dateTime,
      notes: notes ?? this.notes,
      reminderOffset: reminderOffset ?? this.reminderOffset,
      notificationId: notificationId ?? this.notificationId,
      createdDate: createdDate ?? this.createdDate,
    );
  }
}

