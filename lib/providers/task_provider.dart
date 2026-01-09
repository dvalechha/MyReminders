import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';
import '../models/appointment.dart';
import '../database/database_helper.dart';
import '../services/notification_service.dart';
import '../services/notification_preferences_service.dart';
import '../repositories/task_repository.dart';
import '../repositories/category_repository.dart';
import '../models/category.dart' as models;

class TaskProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final NotificationService _notificationService = NotificationService.instance;
  final NotificationPreferencesService _notificationPrefs = NotificationPreferencesService.instance;
  final TaskRepository _supabaseRepository = TaskRepository();
  final CategoryRepository _categoryRepository = CategoryRepository();

  List<Task> _tasks = [];
  bool _isLoading = false;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;

  TaskProvider() {
    // Defer initialization to avoid blocking app startup
    // Data will be loaded when the TasksListView is actually shown
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    // Initialize notifications in background (non-blocking)
    Future.microtask(() async {
      try {
        await _notificationService.initialize();
        await _notificationService.checkAuthorizationStatus();
      } catch (e) {
        debugPrint('Warning: Failed to initialize notifications: $e');
      }
    });
  }

  Future<void> loadTasks({bool forceRefresh = false}) async {
    // Don't reload if already loading to prevent duplicate requests
    if (_isLoading && !forceRefresh) {
      return;
    }
    
    // Don't load if already loaded and not forcing refresh
    if (_tasks.isNotEmpty && !forceRefresh) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Clear existing tasks before loading new data to prevent stale data
      _tasks.clear();
      
      // Check authentication before attempting to load
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        // Not authenticated - try loading from local database only
        try {
          final localTasks = await _dbHelper.getAllTasks();
          _tasks = localTasks;
        } catch (e) {
          debugPrint('Warning: Failed to load tasks from local database: $e');
          _tasks = [];
        }
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Fetch latest from Supabase (user is already checked above)
      try {
          // PERFORMANCE OPTIMIZATION: Fetch all categories once instead of N queries
          final allCategories = await _categoryRepository.getAll();
          final categoryMap = <String, models.Category>{};
          for (final category in allCategories) {
            categoryMap[category.id] = category;
          }

          final supabaseRows = await _supabaseRepository.getAllForUser(user.id);
          // Map category_id to category name using pre-fetched category map
          // Map and dedupe tasks by id and by (title + dueDate)
          final Map<String, Task> mapped = {};
          for (final row in supabaseRows) {
            final categoryId = row['category_id'] as String?;
            String? categoryName;
            if (categoryId != null && categoryMap.containsKey(categoryId)) {
              categoryName = categoryMap[categoryId]!.name;
            }
            final t = Task.fromSupabaseMap(row, categoryName: categoryName);
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
    
    // Check if task notifications are enabled
    final taskNotificationsEnabled = await _notificationPrefs.areTaskNotificationsEnabled();
    if (!taskNotificationsEnabled) return;

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
          debugPrint('🏷️ [TaskProvider] Task category value: "${task.category}"');
          
          if (task.category != null && task.category!.isNotEmpty) {
            debugPrint('🏷️ [TaskProvider] Looking up category: "${task.category}"');
            final category = await _categoryRepository.getByName(task.category!);
            categoryId = category?.id;
            
            if (categoryId == null) {
              debugPrint('⚠️ [TaskProvider] Category "${task.category}" not found, using "Task" category');
              // Fallback to "Task" category if specified category not found
              final defaultCategory = await _categoryRepository.getByName('Task');
              categoryId = defaultCategory?.id;
            }
            
            if (categoryId != null) {
              debugPrint('✅ [TaskProvider] Found category ID: $categoryId');
            }
          } else {
            debugPrint('🏷️ [TaskProvider] No category specified, using "Task" as default');
            // Default to "Task" category for tasks
            final defaultCategory = await _categoryRepository.getByName('Task');
            categoryId = defaultCategory?.id;
            if (categoryId != null) {
              debugPrint('✅ [TaskProvider] Using default category ID: $categoryId');
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
          debugPrint('🏷️ [TaskProvider] Update - Task category value: "${task.category}"');
          
          if (task.category != null && task.category!.isNotEmpty) {
            debugPrint('🏷️ [TaskProvider] Update - Looking up category: "${task.category}"');
            final category = await _categoryRepository.getByName(task.category!);
            categoryId = category?.id;
            
            if (categoryId == null) {
              debugPrint('⚠️ [TaskProvider] Update - Category "${task.category}" not found, using "Task" category');
              final defaultCategory = await _categoryRepository.getByName('Task');
              categoryId = defaultCategory?.id;
            }
            
            if (categoryId != null) {
              debugPrint('✅ [TaskProvider] Update - Found category ID: $categoryId');
            }
          } else {
            debugPrint('🏷️ [TaskProvider] Update - No category specified, using "Task" as default');
            final defaultCategory = await _categoryRepository.getByName('Task');
            categoryId = defaultCategory?.id;
            if (categoryId != null) {
              debugPrint('✅ [TaskProvider] Update - Using default category ID: $categoryId');
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

  Future<void> toggleTaskCompletion(String taskId) async {
    try {
      final task = _tasks.firstWhere((t) => t.id == taskId);
      final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
      await updateTask(updatedTask);
    } catch (e) {
      print('Error toggling task completion: $e');
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

