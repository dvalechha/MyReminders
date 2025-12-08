import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';
import '../models/appointment.dart';
import '../database/database_helper.dart';
import '../services/notification_service.dart';
import '../repositories/task_repository.dart';
import '../repositories/category_repository.dart';

class TaskProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final NotificationService _notificationService = NotificationService.instance;
  final TaskRepository _supabaseRepository = TaskRepository();
  final CategoryRepository _categoryRepository = CategoryRepository();

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
      // Clear existing tasks before loading new data to prevent stale data
      _tasks.clear();

      // Always attempt to fetch latest from Supabase when available
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        try {
          final supabaseRows = await _supabaseRepository.getAllForUser(user.id);
          // Map and dedupe tasks by id and by (title + dueDate)
          final Map<String, Task> mapped = {};
          for (final row in supabaseRows) {
            final t = Task.fromSupabaseMap(row);
            mapped[t.id] = t;
          }

          // Further dedupe by title + dueDate (date only)
          final items = mapped.values.toList();
          items.sort((a, b) {
            final da = a.dueDate ?? DateTime.fromMillisecondsSinceEpoch(0);
            final db = b.dueDate ?? DateTime.fromMillisecondsSinceEpoch(0);
            return da.compareTo(db);
          });
          final seen = <String>{};
          final deduped = <Task>[];
          for (final t in items) {
            final dateKey = t.dueDate != null ? t.dueDate!.toIso8601String().split('T')[0] : 'nodate';
            final key = '${t.title.toLowerCase().trim()}|$dateKey';
            if (!seen.contains(key)) {
              seen.add(key);
              deduped.add(t);
            }
          }
          _tasks = deduped;
        } catch (e) {
          debugPrint('Warning: Failed to fetch tasks from Supabase, falling back to local: $e');
          _tasks = await _dbHelper.getAllTasks();
        }
      } else {
        // Fallback to local when user not authenticated
        _tasks = await _dbHelper.getAllTasks();
      }
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

      // Save to Supabase if authenticated, otherwise save to local SQLite
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        try {
          // Get category ID if category is specified
          String? categoryId;
          if (task.category != null && task.category!.isNotEmpty) {
            final category = await _categoryRepository.getByName(task.category!);
            categoryId = category?.id;
            
            if (categoryId == null) {
              debugPrint('Warning: Category "${task.category}" not found in Supabase.');
            }
          }

          // Convert to Supabase format and save
          final supabaseData = updatedTask.toSupabaseMap(
            userId: user.id,
            categoryId: categoryId,
          );
          
          // If a task with the same id exists in Supabase, update it instead of creating
          final existing = await _supabaseRepository.getById(updatedTask.id);
          if (existing != null) {
            await _supabaseRepository.update(updatedTask.id, supabaseData);
            debugPrint('Task updated in Supabase: ${updatedTask.title}');
          } else {
            await _supabaseRepository.create(supabaseData);
            debugPrint('Task saved to Supabase: ${updatedTask.title}');
          }

          // Remove any local copy with the same id to avoid duplicate listings
          try {
            await _dbHelper.deleteTask(updatedTask.id);
          } catch (_) {}
        } catch (e) {
          // If Supabase fails, fall back to local save
          debugPrint('Warning: Failed to save task to Supabase: $e');
          debugPrint('Falling back to local save.');
          await _dbHelper.insertTask(updatedTask);
        }
      } else {
        // Save locally when not authenticated
        await _dbHelper.insertTask(updatedTask);
      }

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

      // Update in Supabase if authenticated, otherwise update local SQLite
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        try {
          // Get category ID if category is specified
          String? categoryId;
          if (task.category != null && task.category!.isNotEmpty) {
            final category = await _categoryRepository.getByName(task.category!);
            categoryId = category?.id;
            
            if (categoryId == null) {
              debugPrint('Warning: Category "${task.category}" not found in Supabase.');
            }
          }

          // Convert to Supabase format and update
          final supabaseData = updatedTask.toSupabaseMap(
            userId: user.id,
            categoryId: categoryId,
          );
          
          await _supabaseRepository.update(updatedTask.id, supabaseData);
          debugPrint('Task updated in Supabase: ${updatedTask.title}');
        } catch (e) {
          // If Supabase fails, fall back to local update
          debugPrint('Warning: Failed to update task in Supabase: $e');
          debugPrint('Falling back to local update.');
          await _dbHelper.updateTask(updatedTask);
        }
      } else {
        // Update locally when not authenticated
        await _dbHelper.updateTask(updatedTask);
      }

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

      // Delete from Supabase if authenticated, otherwise delete from local SQLite
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        try {
          await _supabaseRepository.delete(id);
          debugPrint('Task deleted from Supabase: ${task?.title ?? "Unknown"}');
        } catch (e) {
          // If Supabase fails, fall back to local delete
          debugPrint('Warning: Failed to delete task from Supabase: $e');
          debugPrint('Falling back to local delete.');
          await _dbHelper.deleteTask(id);
        }
      } else {
        // Delete locally when not authenticated
        await _dbHelper.deleteTask(id);
      }

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

