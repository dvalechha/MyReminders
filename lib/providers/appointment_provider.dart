import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/appointment.dart';
import '../database/database_helper.dart';
import '../services/notification_service.dart';
import '../services/notification_preferences_service.dart';
import '../repositories/appointment_repository.dart';
import '../repositories/category_repository.dart';

class AppointmentProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final NotificationService _notificationService = NotificationService.instance;
  final NotificationPreferencesService _notificationPrefs = NotificationPreferencesService.instance;
  final AppointmentRepository _supabaseRepository = AppointmentRepository();
  final CategoryRepository _categoryRepository = CategoryRepository();

  List<Appointment> _appointments = [];
  bool _isLoading = false;

  List<Appointment> get appointments => _appointments;
  bool get isLoading => _isLoading;

  AppointmentProvider() {
    loadAppointments();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
    await _notificationService.checkAuthorizationStatus();
  }

  Future<void> loadAppointments() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Clear existing appointments before loading new data to prevent stale data
      _appointments.clear();

      // Always attempt to fetch latest from Supabase when available
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        try {
          final supabaseRows = await _supabaseRepository.getAllForUser(user.id);
          // Map category_id to category name using CategoryRepository
          // Map and dedupe appointments by id and by (title + date) to avoid duplicates
          final Map<String, Appointment> mapped = {};
          for (final row in supabaseRows) {
            final categoryId = row['category_id'] as String?;
            String? categoryName;
            if (categoryId != null) {
              try {
                final category = await _categoryRepository.getById(categoryId);
                categoryName = category?.name;
              } catch (_) {}
            }
            final appt = Appointment.fromSupabaseMap(row, categoryName: categoryName);
            mapped[appt.id] = appt;
          }

          // Further dedupe by title + date (date only) keeping earliest time
          final items = mapped.values.toList();
          items.sort((a, b) => a.dateTime.compareTo(b.dateTime));
          final seen = <String>{};
          final deduped = <Appointment>[];
          for (final a in items) {
            final key = '${a.title.toLowerCase().trim()}|${a.dateTime.toIso8601String().split('T')[0]}';
            if (!seen.contains(key)) {
              seen.add(key);
              deduped.add(a);
            }
          }
          _appointments = deduped;
        } catch (e) {
          debugPrint('Warning: Failed to fetch appointments from Supabase, falling back to local: $e');
          _appointments = await _dbHelper.getAllAppointments();
        }
      } else {
        // Fallback to local when user not authenticated
        _appointments = await _dbHelper.getAllAppointments();
      }
      await _rescheduleAllReminders();
    } catch (e) {
      print('Error loading appointments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _rescheduleAllReminders() async {
    debugPrint('📅 [AppointmentProvider] Rescheduling all reminders...');
    debugPrint('📅 [AppointmentProvider] Total appointments: ${_appointments.length}');
    
    if (!_notificationService.isAuthorized) {
      debugPrint('⚠️ [AppointmentProvider] Notifications not authorized, skipping reschedule');
      return;
    }

    // Check if appointment notifications are enabled
    final appointmentNotificationsEnabled = await _notificationPrefs.areAppointmentNotificationsEnabled();
    debugPrint('📅 [AppointmentProvider] Appointment notifications enabled: $appointmentNotificationsEnabled');
    if (!appointmentNotificationsEnabled) {
      debugPrint('⚠️ [AppointmentProvider] Appointment notifications disabled in settings, skipping reschedule');
      return;
    }

    int scheduledCount = 0;
    for (final appointment in _appointments) {
      if (appointment.reminderOffset != ReminderOffset.none &&
          appointment.notificationId != null) {
        await _scheduleAppointmentReminder(appointment);
        scheduledCount++;
      }
    }
    debugPrint('📅 [AppointmentProvider] Rescheduled $scheduledCount appointment reminders');
    
    // Debug: List all pending notifications
    await _notificationService.getPendingNotifications();
  }

  Future<void> _scheduleAppointmentReminder(Appointment appointment) async {
    debugPrint('📅 [AppointmentProvider] Scheduling reminder for: ${appointment.title}');
    debugPrint('📅 [AppointmentProvider] Appointment time: ${appointment.dateTime}');
    debugPrint('📅 [AppointmentProvider] Reminder offset: ${appointment.reminderOffset.minutes} minutes');
    debugPrint('📅 [AppointmentProvider] Notification ID: ${appointment.notificationId}');
    
    if (!_notificationService.isAuthorized) {
      debugPrint('⚠️ [AppointmentProvider] Notifications not authorized, skipping');
      return;
    }
    
    if (appointment.reminderOffset == ReminderOffset.none) {
      debugPrint('⚠️ [AppointmentProvider] Reminder offset is none, skipping');
      return;
    }
    
    if (appointment.notificationId == null) {
      debugPrint('⚠️ [AppointmentProvider] Notification ID is null, skipping');
      return;
    }
    
    // Check if appointment notifications are enabled
    final appointmentNotificationsEnabled = await _notificationPrefs.areAppointmentNotificationsEnabled();
    debugPrint('📅 [AppointmentProvider] Appointment notifications enabled: $appointmentNotificationsEnabled');
    if (!appointmentNotificationsEnabled) {
      debugPrint('⚠️ [AppointmentProvider] Appointment notifications disabled in settings, skipping');
      return;
    }

    try {
      await _notificationService.scheduleTimeBasedReminder(
        notificationId: appointment.notificationId!,
        title: 'Upcoming Appointment',
        body: appointment.title,
        eventDateTime: appointment.dateTime,
        minutesBefore: appointment.reminderOffset.minutes,
      );
      debugPrint('✅ [AppointmentProvider] Successfully scheduled reminder for: ${appointment.title}');
    } catch (e) {
      debugPrint('❌ [AppointmentProvider] Error scheduling reminder: $e');
      rethrow;
    }
  }

  Future<String> addAppointment(Appointment appointment) async {
    try {
      String? notificationId = appointment.notificationId;
      if (appointment.reminderOffset != ReminderOffset.none) {
        notificationId ??= appointment.id;
      }

      final updatedAppointment = appointment.copyWith(
        notificationId: notificationId,
      );

      // Save to Supabase if authenticated, otherwise save to local SQLite
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        try {
          // Get category ID if category is specified
          String? categoryId;
          debugPrint('🏷️ [AppointmentProvider] Appointment category value: "${appointment.category}"');
          
          if (appointment.category != null && appointment.category!.isNotEmpty) {
            debugPrint('🏷️ [AppointmentProvider] Looking up category: "${appointment.category}"');
            final category = await _categoryRepository.getByName(appointment.category!);
            categoryId = category?.id;
            
            if (categoryId == null) {
              debugPrint('⚠️ [AppointmentProvider] Category "${appointment.category}" not found, using "Appointment" category');
              // Fallback to "Appointment" category if specified category not found
              final defaultCategory = await _categoryRepository.getByName('Appointment');
              categoryId = defaultCategory?.id;
            }
            
            if (categoryId != null) {
              debugPrint('✅ [AppointmentProvider] Found category ID: $categoryId');
            }
          } else {
            debugPrint('🏷️ [AppointmentProvider] No category specified, using "Appointment" as default');
            // Default to "Appointment" category for appointments
            final defaultCategory = await _categoryRepository.getByName('Appointment');
            categoryId = defaultCategory?.id;
            if (categoryId != null) {
              debugPrint('✅ [AppointmentProvider] Using default category ID: $categoryId');
            }
          }

          debugPrint('🏷️ [AppointmentProvider] Final categoryId for save: $categoryId');
          
          // Convert to Supabase format and save
          final supabaseData = updatedAppointment.toSupabaseMap(
            userId: user.id,
            categoryId: categoryId,
          );
          debugPrint('🏷️ [AppointmentProvider] Supabase data: $supabaseData');
          
          // If an appointment with the same id exists in Supabase, update it instead of creating
          final existing = await _supabaseRepository.getById(updatedAppointment.id);
          if (existing != null) {
            await _supabaseRepository.update(updatedAppointment.id, supabaseData);
            debugPrint('Appointment updated in Supabase: ${updatedAppointment.title}');
          } else {
            await _supabaseRepository.create(supabaseData);
            debugPrint('Appointment saved to Supabase: ${updatedAppointment.title}');
          }

          // Remove any local copy with the same id to avoid duplicate listings
          try {
            await _dbHelper.deleteAppointment(updatedAppointment.id);
          } catch (_) {}
        } catch (e) {
          // If Supabase fails, fall back to local save
          debugPrint('Warning: Failed to save appointment to Supabase: $e');
          debugPrint('Falling back to local save.');
          await _dbHelper.insertAppointment(updatedAppointment);
        }
      } else {
        // Save locally when not authenticated
        await _dbHelper.insertAppointment(updatedAppointment);
      }

      if (updatedAppointment.reminderOffset != ReminderOffset.none &&
          updatedAppointment.notificationId != null) {
        await _scheduleAppointmentReminder(updatedAppointment);
      }

      await loadAppointments();
      return updatedAppointment.id;
    } catch (e) {
      print('Error adding appointment: $e');
      rethrow;
    }
  }

  Future<void> updateAppointment(Appointment appointment) async {
    try {
      final existing = await _dbHelper.getAppointmentById(appointment.id);
      if (existing != null && existing.notificationId != null) {
        await _notificationService.cancelReminder(existing.notificationId!);
      }

      String? notificationId = appointment.notificationId;
      if (appointment.reminderOffset != ReminderOffset.none) {
        notificationId ??= appointment.id;
      }

      final updatedAppointment = appointment.copyWith(
        notificationId: notificationId,
      );

      // Update in Supabase if authenticated, otherwise update local SQLite
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        try {
          // Get category ID if category is specified
          String? categoryId;
          debugPrint('🏷️ [AppointmentProvider] Update - Appointment category value: "${appointment.category}"');
          
          if (appointment.category != null && appointment.category!.isNotEmpty) {
            debugPrint('🏷️ [AppointmentProvider] Update - Looking up category: "${appointment.category}"');
            final category = await _categoryRepository.getByName(appointment.category!);
            categoryId = category?.id;
            
            if (categoryId == null) {
              debugPrint('⚠️ [AppointmentProvider] Update - Category "${appointment.category}" not found, using "Appointment" category');
              final defaultCategory = await _categoryRepository.getByName('Appointment');
              categoryId = defaultCategory?.id;
            }
            
            if (categoryId != null) {
              debugPrint('✅ [AppointmentProvider] Update - Found category ID: $categoryId');
            }
          } else {
            debugPrint('🏷️ [AppointmentProvider] Update - No category specified, using "Appointment" as default');
            final defaultCategory = await _categoryRepository.getByName('Appointment');
            categoryId = defaultCategory?.id;
            if (categoryId != null) {
              debugPrint('✅ [AppointmentProvider] Update - Using default category ID: $categoryId');
            }
          }

          // Convert to Supabase format and update
          final supabaseData = updatedAppointment.toSupabaseMap(
            userId: user.id,
            categoryId: categoryId,
          );
          
          await _supabaseRepository.update(updatedAppointment.id, supabaseData);
          debugPrint('Appointment updated in Supabase: ${updatedAppointment.title}');
        } catch (e) {
          // If Supabase fails, fall back to local update
          debugPrint('Warning: Failed to update appointment in Supabase: $e');
          debugPrint('Falling back to local update.');
          await _dbHelper.updateAppointment(updatedAppointment);
        }
      } else {
        // Update locally when not authenticated
        await _dbHelper.updateAppointment(updatedAppointment);
      }

      debugPrint('📅 [AppointmentProvider] Checking if reminder should be scheduled (update)...');
      debugPrint('📅 [AppointmentProvider] Reminder offset: ${updatedAppointment.reminderOffset.minutes} minutes');
      debugPrint('📅 [AppointmentProvider] Notification ID: ${updatedAppointment.notificationId}');
      
      if (updatedAppointment.reminderOffset != ReminderOffset.none &&
          updatedAppointment.notificationId != null) {
        debugPrint('📅 [AppointmentProvider] Scheduling reminder (update)...');
        await _scheduleAppointmentReminder(updatedAppointment);
      } else if (updatedAppointment.notificationId != null) {
        debugPrint('📅 [AppointmentProvider] Cancelling reminder (reminder disabled)...');
        await _notificationService.cancelReminder(updatedAppointment.notificationId!);
      }

      await loadAppointments();
    } catch (e) {
      print('Error updating appointment: $e');
      rethrow;
    }
  }

  Future<void> deleteAppointment(String id) async {
    try {
      final appointment = await _dbHelper.getAppointmentById(id);
      if (appointment != null && appointment.notificationId != null) {
        await _notificationService.cancelReminder(appointment.notificationId!);
      }

      // Delete from Supabase if authenticated, otherwise delete from local SQLite
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        try {
          await _supabaseRepository.delete(id);
          debugPrint('Appointment deleted from Supabase: ${appointment?.title ?? "Unknown"}');
        } catch (e) {
          // If Supabase fails, fall back to local delete
          debugPrint('Warning: Failed to delete appointment from Supabase: $e');
          debugPrint('Falling back to local delete.');
          await _dbHelper.deleteAppointment(id);
        }
      } else {
        // Delete locally when not authenticated
        await _dbHelper.deleteAppointment(id);
      }

      await loadAppointments();
    } catch (e) {
      print('Error deleting appointment: $e');
      rethrow;
    }
  }

  Future<Appointment?> getAppointmentById(String id) async {
    return await _dbHelper.getAppointmentById(id);
  }

  /// Clear all in-memory state (for logout)
  void clearState() {
    _appointments = [];
    _isLoading = false;
    notifyListeners();
  }
}

