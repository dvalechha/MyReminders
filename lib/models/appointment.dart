import 'package:uuid/uuid.dart';

enum ReminderOffset {
  none(0, 'None'),
  fiveMinutes(5, '5 min before'),
  fifteenMinutes(15, '15 min before'),
  thirtyMinutes(30, '30 min before'),
  oneHour(60, '1 hour before'),
  oneDay(1440, '1 day before');

  const ReminderOffset(this.minutes, this.value);
  final int minutes;
  final String value;

  static ReminderOffset fromString(String value) {
    return ReminderOffset.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReminderOffset.none,
    );
  }
}

class Appointment {
  final String id;
  final String title;
  final String? category;
  final DateTime dateTime;
  final String? location;
  final String? notes;
  final ReminderOffset reminderOffset;
  final String? notificationId;
  final DateTime createdDate;

  Appointment({
    String? id,
    required this.title,
    this.category,
    required this.dateTime,
    this.location,
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
      'dateTime': dateTime.toIso8601String(),
      'location': location,
      'notes': notes,
      'reminderOffset': reminderOffset.minutes,
      'notificationId': notificationId,
      'createdDate': createdDate.toIso8601String(),
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'] as String,
      title: map['title'] as String,
      category: map['category'] as String?,
      dateTime: DateTime.parse(map['dateTime'] as String),
      location: map['location'] as String?,
      notes: map['notes'] as String?,
      reminderOffset: ReminderOffset.values.firstWhere(
        (e) => e.minutes == (map['reminderOffset'] as int),
        orElse: () => ReminderOffset.none,
      ),
      notificationId: map['notificationId'] as String?,
      createdDate: DateTime.parse(map['createdDate'] as String),
    );
  }

  Appointment copyWith({
    String? id,
    String? title,
    String? category,
    DateTime? dateTime,
    String? location,
    String? notes,
    ReminderOffset? reminderOffset,
    String? notificationId,
    DateTime? createdDate,
  }) {
    return Appointment(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      reminderOffset: reminderOffset ?? this.reminderOffset,
      notificationId: notificationId ?? this.notificationId,
      createdDate: createdDate ?? this.createdDate,
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
      'start_time': dateTime.toUtc().toIso8601String(),
      'location': location,
      'notes': notes,
      'reminder_offset_minutes': reminderOffset.minutes,
    };
  }

  // Create from Supabase format
  factory Appointment.fromSupabaseMap(Map<String, dynamic> map, {String? categoryName}) {
    return Appointment(
      id: map['id'] as String,
      title: map['title'] as String,
      category: categoryName, // Use looked-up category name instead of category_id
      dateTime: DateTime.parse(map['start_time'] as String),
      location: map['location'] as String?,
      notes: map['notes'] as String?,
      reminderOffset: ReminderOffset.values.firstWhere(
        (e) => e.minutes == (map['reminder_offset_minutes'] as int? ?? 0),
        orElse: () => ReminderOffset.none,
      ),
      createdDate: DateTime.parse(map['created_at'] as String),
    );
  }
}

