import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/custom_reminder.dart';
import '../models/appointment.dart';
import '../database/database_helper.dart';
import '../services/notification_service.dart';
import '../repositories/custom_reminder_repository.dart';
import '../repositories/category_repository.dart';

class CustomReminderProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final NotificationService _notificationService = NotificationService.instance;
  final CustomReminderRepository _supabaseRepository = CustomReminderRepository();
  final CategoryRepository _categoryRepository = CategoryRepository();

  List<CustomReminder> _customReminders = [];
  bool _isLoading = false;

  List<CustomReminder> get customReminders => _customReminders;
  bool get isLoading => _isLoading;

  CustomReminderProvider() {
    loadCustomReminders();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
    await _notificationService.checkAuthorizationStatus();
  }

  Future<void> loadCustomReminders() async {
    _isLoading = true;
    notifyListeners();

    try {
      _customReminders = await _dbHelper.getAllCustomReminders();
      await _rescheduleAllReminders();
    } catch (e) {
      print('Error loading custom reminders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _rescheduleAllReminders() async {
    if (!_notificationService.isAuthorized) return;

    for (final reminder in _customReminders) {
      if (reminder.reminderOffset != ReminderOffset.none &&
          reminder.dateTime != null &&
          reminder.notificationId != null) {
        await _scheduleCustomReminder(reminder);
      }
    }
  }

  Future<void> _scheduleCustomReminder(CustomReminder reminder) async {
    if (!_notificationService.isAuthorized) return;
    if (reminder.reminderOffset == ReminderOffset.none) return;
    if (reminder.dateTime == null) return;
    if (reminder.notificationId == null) return;

    await _notificationService.scheduleTimeBasedReminder(
      notificationId: reminder.notificationId!,
      title: 'Reminder',
      body: reminder.title,
      eventDateTime: reminder.dateTime!,
      minutesBefore: reminder.reminderOffset.minutes,
    );
  }

  Future<String> addCustomReminder(CustomReminder reminder) async {
    try {
      String? notificationId = reminder.notificationId;
      if (reminder.reminderOffset != ReminderOffset.none && reminder.dateTime != null) {
        notificationId ??= reminder.id;
      }

      final updatedReminder = reminder.copyWith(
        notificationId: notificationId,
      );

      // Save to local SQLite first (for offline support)
      await _dbHelper.insertCustomReminder(updatedReminder);

      // Also save to Supabase if user is authenticated
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          // Get category ID if category is specified
          String? categoryId;
          if (reminder.category != null && reminder.category!.isNotEmpty) {
            final category = await _categoryRepository.getByName(reminder.category!);
            categoryId = category?.id;
            
            if (categoryId == null) {
              debugPrint('Warning: Category "${reminder.category}" not found in Supabase.');
            }
          }

          // Convert to Supabase format and save
          final supabaseData = updatedReminder.toSupabaseMap(
            userId: user.id,
            categoryId: categoryId,
          );
          
          await _supabaseRepository.create(supabaseData);
          debugPrint('Custom reminder saved to Supabase: ${updatedReminder.title}');
        }
      } catch (e) {
        // Log error but don't fail - reminder is already saved locally
        debugPrint('Warning: Failed to save custom reminder to Supabase: $e');
        debugPrint('Custom reminder saved locally only. Will sync when connection is available.');
      }

      if (updatedReminder.reminderOffset != ReminderOffset.none &&
          updatedReminder.dateTime != null &&
          updatedReminder.notificationId != null) {
        await _scheduleCustomReminder(updatedReminder);
      }

      await loadCustomReminders();
      return updatedReminder.id;
    } catch (e) {
      print('Error adding custom reminder: $e');
      rethrow;
    }
  }

  Future<void> updateCustomReminder(CustomReminder reminder) async {
    try {
      final existing = await _dbHelper.getCustomReminderById(reminder.id);
      if (existing != null && existing.notificationId != null) {
        await _notificationService.cancelReminder(existing.notificationId!);
      }

      String? notificationId = reminder.notificationId;
      if (reminder.reminderOffset != ReminderOffset.none && reminder.dateTime != null) {
        notificationId ??= reminder.id;
      }

      final updatedReminder = reminder.copyWith(
        notificationId: notificationId,
      );

      // Update local SQLite first
      await _dbHelper.updateCustomReminder(updatedReminder);

      // Also update in Supabase if user is authenticated
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          // Get category ID if category is specified
          String? categoryId;
          if (reminder.category != null && reminder.category!.isNotEmpty) {
            final category = await _categoryRepository.getByName(reminder.category!);
            categoryId = category?.id;
            
            if (categoryId == null) {
              debugPrint('Warning: Category "${reminder.category}" not found in Supabase.');
            }
          }

          // Convert to Supabase format and update
          final supabaseData = updatedReminder.toSupabaseMap(
            userId: user.id,
            categoryId: categoryId,
          );
          
          await _supabaseRepository.update(updatedReminder.id, supabaseData);
          debugPrint('Custom reminder updated in Supabase: ${updatedReminder.title}');
        }
      } catch (e) {
        // Log error but don't fail - reminder is already updated locally
        debugPrint('Warning: Failed to update custom reminder in Supabase: $e');
        debugPrint('Custom reminder updated locally only. Will sync when connection is available.');
      }

      if (updatedReminder.reminderOffset != ReminderOffset.none &&
          updatedReminder.dateTime != null &&
          updatedReminder.notificationId != null) {
        await _scheduleCustomReminder(updatedReminder);
      } else if (updatedReminder.notificationId != null) {
        await _notificationService.cancelReminder(updatedReminder.notificationId!);
      }

      await loadCustomReminders();
    } catch (e) {
      print('Error updating custom reminder: $e');
      rethrow;
    }
  }

  Future<void> deleteCustomReminder(String id) async {
    try {
      final reminder = await _dbHelper.getCustomReminderById(id);
      if (reminder != null && reminder.notificationId != null) {
        await _notificationService.cancelReminder(reminder.notificationId!);
      }

      // Delete from local SQLite first
      await _dbHelper.deleteCustomReminder(id);

      // Also delete from Supabase if user is authenticated
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          await _supabaseRepository.delete(id);
          debugPrint('Custom reminder deleted from Supabase: ${reminder?.title ?? "Unknown"}');
        }
      } catch (e) {
        // Log error but don't fail - reminder is already deleted locally
        debugPrint('Warning: Failed to delete custom reminder from Supabase: $e');
        debugPrint('Custom reminder deleted locally only. Will sync when connection is available.');
      }

      await loadCustomReminders();
    } catch (e) {
      print('Error deleting custom reminder: $e');
      rethrow;
    }
  }

  Future<CustomReminder?> getCustomReminderById(String id) async {
    return await _dbHelper.getCustomReminderById(id);
  }

  /// Clear all in-memory state (for logout)
  void clearState() {
    _customReminders = [];
    _isLoading = false;
    notifyListeners();
  }
}

