import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/appointment.dart';
import '../database/database_helper.dart';
import '../services/notification_service.dart';
import '../repositories/appointment_repository.dart';
import '../repositories/category_repository.dart';

class AppointmentProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final NotificationService _notificationService = NotificationService.instance;
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
          // Map and dedupe appointments by id and by (title + date) to avoid duplicates
          final Map<String, Appointment> mapped = {};
          for (final row in supabaseRows) {
            final appt = Appointment.fromSupabaseMap(row);
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
    if (!_notificationService.isAuthorized) return;

    for (final appointment in _appointments) {
      if (appointment.reminderOffset != ReminderOffset.none &&
          appointment.notificationId != null) {
        await _scheduleAppointmentReminder(appointment);
      }
    }
  }

  Future<void> _scheduleAppointmentReminder(Appointment appointment) async {
    if (!_notificationService.isAuthorized) return;
    if (appointment.reminderOffset == ReminderOffset.none) return;
    if (appointment.notificationId == null) return;

    await _notificationService.scheduleTimeBasedReminder(
      notificationId: appointment.notificationId!,
      title: 'Upcoming Appointment',
      body: appointment.title,
      eventDateTime: appointment.dateTime,
      minutesBefore: appointment.reminderOffset.minutes,
    );
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
          if (appointment.category != null && appointment.category!.isNotEmpty) {
            final category = await _categoryRepository.getByName(appointment.category!);
            categoryId = category?.id;
            
            if (categoryId == null) {
              debugPrint('Warning: Category "${appointment.category}" not found in Supabase.');
            }
          }

          // Convert to Supabase format and save
          final supabaseData = updatedAppointment.toSupabaseMap(
            userId: user.id,
            categoryId: categoryId,
          );
          
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
          if (appointment.category != null && appointment.category!.isNotEmpty) {
            final category = await _categoryRepository.getByName(appointment.category!);
            categoryId = category?.id;
            
            if (categoryId == null) {
              debugPrint('Warning: Category "${appointment.category}" not found in Supabase.');
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

      if (updatedAppointment.reminderOffset != ReminderOffset.none &&
          updatedAppointment.notificationId != null) {
        await _scheduleAppointmentReminder(updatedAppointment);
      } else if (updatedAppointment.notificationId != null) {
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

