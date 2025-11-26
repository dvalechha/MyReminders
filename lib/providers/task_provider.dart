import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../models/appointment.dart';
import '../database/database_helper.dart';
import '../services/notification_service.dart';

class TaskProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final NotificationService _notificationService = NotificationService.instance;

  List<Task> _tasks = [];
  bool _isLoading = false;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;

  TaskProvider() {
    loadTasks();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
    await _notificationService.checkAuthorizationStatus();
  }

  Future<void> loadTasks() async {
    _isLoading = true;
    notifyListeners();

    try {
      _tasks = await _dbHelper.getAllTasks();
      await _rescheduleAllReminders();
    } catch (e) {
      print('Error loading tasks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _rescheduleAllReminders() async {
    if (!_notificationService.isAuthorized) return;

    for (final task in _tasks) {
      if (task.reminderOffset != ReminderOffset.none &&
          task.dueDate != null &&
          task.notificationId != null) {
        await _scheduleTaskReminder(task);
      }
    }
  }

  Future<void> _scheduleTaskReminder(Task task) async {
    if (!_notificationService.isAuthorized) return;
    if (task.reminderOffset == ReminderOffset.none) return;
    if (task.dueDate == null) return;
    if (task.notificationId == null) return;

    await _notificationService.scheduleTimeBasedReminder(
      notificationId: task.notificationId!,
      title: 'Task Reminder',
      body: task.title,
      eventDateTime: task.dueDate!,
      minutesBefore: task.reminderOffset.minutes,
    );
  }

  Future<String> addTask(Task task) async {
    try {
      String? notificationId = task.notificationId;
      if (task.reminderOffset != ReminderOffset.none && task.dueDate != null) {
        notificationId ??= task.id;
      }

      final updatedTask = task.copyWith(
        notificationId: notificationId,
      );

      await _dbHelper.insertTask(updatedTask);

      if (updatedTask.reminderOffset != ReminderOffset.none &&
          updatedTask.dueDate != null &&
          updatedTask.notificationId != null) {
        await _scheduleTaskReminder(updatedTask);
      }

      await loadTasks();
      return updatedTask.id;
    } catch (e) {
      print('Error adding task: $e');
      rethrow;
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      final existing = await _dbHelper.getTaskById(task.id);
      if (existing != null && existing.notificationId != null) {
        await _notificationService.cancelReminder(existing.notificationId!);
      }

      String? notificationId = task.notificationId;
      if (task.reminderOffset != ReminderOffset.none && task.dueDate != null) {
        notificationId ??= task.id;
      }

      final updatedTask = task.copyWith(
        notificationId: notificationId,
      );

      await _dbHelper.updateTask(updatedTask);

      if (updatedTask.reminderOffset != ReminderOffset.none &&
          updatedTask.dueDate != null &&
          updatedTask.notificationId != null) {
        await _scheduleTaskReminder(updatedTask);
      } else if (updatedTask.notificationId != null) {
        await _notificationService.cancelReminder(updatedTask.notificationId!);
      }

      await loadTasks();
    } catch (e) {
      print('Error updating task: $e');
      rethrow;
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      final task = await _dbHelper.getTaskById(id);
      if (task != null && task.notificationId != null) {
        await _notificationService.cancelReminder(task.notificationId!);
      }

      await _dbHelper.deleteTask(id);
      await loadTasks();
    } catch (e) {
      print('Error deleting task: $e');
      rethrow;
    }
  }

  Future<Task?> getTaskById(String id) async {
    return await _dbHelper.getTaskById(id);
  }

  /// Clear all in-memory state (for logout)
  void clearState() {
    _tasks = [];
    _isLoading = false;
    notifyListeners();
  }
}

