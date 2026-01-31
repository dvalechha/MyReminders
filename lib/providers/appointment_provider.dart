import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/appointment.dart';
import '../database/database_helper.dart';
import '../services/notification_service.dart';
import '../services/notification_preferences_service.dart';
import '../repositories/appointment_repository.dart';
import '../repositories/category_repository.dart';
import '../models/category.dart' as models;

class AppointmentProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final NotificationService _notificationService = NotificationService.instance;
  final NotificationPreferencesService _notificationPrefs = NotificationPreferencesService.instance;
  final AppointmentRepository _supabaseRepository = AppointmentRepository();
  final CategoryRepository _categoryRepository = CategoryRepository();

  List<Appointment> _appointments = [];
  bool _isLoading = false;
  final Set<String> _selectedIds = {};

  List<Appointment> get appointments => _appointments;
  
  List<Appointment> get activeItems => _appointments.where((a) => !a.isCompleted).toList();
  List<Appointment> get completedItems => _appointments.where((a) => a.isCompleted).toList();
  
  bool get isLoading => _isLoading;
  bool get isSelectionMode => _selectedIds.isNotEmpty;
  Set<String> get selectedIds => _selectedIds;

  Future<void> toggleCompletion(String id, bool status) async {
    try {
      final appointment = _appointments.firstWhere((a) => a.id == id);
      final updatedAppointment = appointment.copyWith(isCompleted: status);
      
      // Optimistic Update
      final index = _appointments.indexWhere((a) => a.id == id);
      if (index != -1) {
        _appointments[index] = updatedAppointment;
        notifyListeners();
      }
      
      // Update DB via updateAppointment
      await updateAppointment(updatedAppointment);
    } catch (e) {
      debugPrint('Error toggling appointment completion: $e');
    }
  }

  void toggleSelection(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedIds.clear();
    notifyListeners();
  }

  Future<void> deleteSelected() async {
    if (_selectedIds.isEmpty) return;

    final idsToDelete = _selectedIds.toList();
    // Optimistic Update
    _appointments.removeWhere((a) => idsToDelete.contains(a.id));
    _selectedIds.clear();
    notifyListeners();

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await _supabaseRepository.deleteIds(idsToDelete);
      }
      
      // Delete from local DB
      for (final id in idsToDelete) {
        await _dbHelper.deleteAppointment(id);
      }
    } catch (e) {
      debugPrint('Error deleting selected appointments: $e');
      await loadAppointments(forceRefresh: true);
      rethrow;
    }
  }

  AppointmentProvider() {
    // Defer initialization to avoid blocking app startup
    // Data will be loaded when the AppointmentsListView is actually shown
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

  Future<void> loadAppointments({bool forceRefresh = false}) async {
    // Don't reload if already loading to prevent duplicate requests
    if (_isLoading && !forceRefresh) {
      return;
    }
    
    // Don't load if already loaded and not forcing refresh
    if (_appointments.isNotEmpty && !forceRefresh) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Clear existing appointments before loading new data to prevent stale data
      _appointments.clear();

      // Check authentication before attempting to load
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        // Not authenticated - try loading from local database only
        try {
          final localAppointments = await _dbHelper.getAllAppointments();
          _appointments = localAppointments;
        } catch (e) {
          debugPrint('Warning: Failed to load appointments from local database: $e');
          _appointments = [];
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
          // Map to Appointment objects to dedupe by ID
          final Map<String, Appointment> mapped = {};
          for (final row in supabaseRows) {
            final categoryId = row['category_id'] as String?;
            String? categoryName;
            if (categoryId != null && categoryMap.containsKey(categoryId)) {
              categoryName = categoryMap[categoryId]!.name;
            }
            final appt = Appointment.fromSupabaseMap(row, categoryName: categoryName);
            mapped[appt.id] = appt;
          }

          // Convert to list and sort
          final items = mapped.values.toList();
          items.sort((a, b) => a.dateTime.compareTo(b.dateTime));
          
          debugPrint('📅 [AppointmentProvider] Loaded ${items.length} appointments from Supabase');
          
          _appointments = items;
        } catch (e) {
          debugPrint('Warning: Failed to fetch appointments from Supabase, falling back to local: $e');
          _appointments = await _dbHelper.getAllAppointments();
          debugPrint('📅 [AppointmentProvider] Loaded ${_appointments.length} appointments from Local DB');
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

      // Optimistic Update
      _appointments.add(updatedAppointment);
      _appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      notifyListeners();

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
              final defaultCategory = await _categoryRepository.getByName('Appointment');
              categoryId = defaultCategory?.id;
            }
            
            if (categoryId != null) {
              debugPrint('✅ [AppointmentProvider] Found category ID: $categoryId');
            }
          } else {
            debugPrint('🏷️ [AppointmentProvider] No category specified, using "Appointment" as default');
            final defaultCategory = await _categoryRepository.getByName('Appointment');
            categoryId = defaultCategory?.id;
            if (categoryId != null) {
              debugPrint('✅ [AppointmentProvider] Using default category ID: $categoryId');
            }
          }

          debugPrint('🏷️ [AppointmentProvider] Final categoryId for save: $categoryId');
          
          final supabaseData = updatedAppointment.toSupabaseMap(
            userId: user.id,
            categoryId: categoryId,
          );
          debugPrint('🏷️ [AppointmentProvider] Supabase data: $supabaseData');
          
          final existing = await _supabaseRepository.getById(updatedAppointment.id);
          if (existing != null) {
            await _supabaseRepository.update(updatedAppointment.id, supabaseData);
            debugPrint('Appointment updated in Supabase: ${updatedAppointment.title}');
          } else {
            await _supabaseRepository.create(supabaseData);
            debugPrint('Appointment saved to Supabase: ${updatedAppointment.title}');
          }

          // Also save to local DB for offline cache consistency
          try {
            await _dbHelper.insertAppointment(updatedAppointment);
          } catch (_) {}

        } catch (e) {
          debugPrint('❌ [AppointmentProvider] Failed to save appointment to Supabase: $e');
          rethrow; // Fail hard
        }
      } else {
        // Save locally when not authenticated
        await _dbHelper.insertAppointment(updatedAppointment);
      }

      if (updatedAppointment.reminderOffset != ReminderOffset.none &&
          updatedAppointment.notificationId != null) {
        await _scheduleAppointmentReminder(updatedAppointment);
      }

      // No reload to prevent UI flash
      return updatedAppointment.id;
    } catch (e) {
      print('Error adding appointment: $e');
      // Rollback optimistic update
      _appointments.removeWhere((a) => a.id == appointment.id);
      notifyListeners();
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

      // Optimistic Update
      final index = _appointments.indexWhere((a) => a.id == appointment.id);
      if (index != -1) {
        _appointments[index] = updatedAppointment;
        _appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
        notifyListeners();
      }

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

          final supabaseData = updatedAppointment.toSupabaseMap(
            userId: user.id,
            categoryId: categoryId,
          );
          
          await _supabaseRepository.update(updatedAppointment.id, supabaseData);
          debugPrint('Appointment updated in Supabase: ${updatedAppointment.title}');
          
          // Also update local DB
          try {
            await _dbHelper.updateAppointment(updatedAppointment);
          } catch (_) {}

        } catch (e) {
          debugPrint('❌ [AppointmentProvider] Failed to update appointment in Supabase: $e');
          rethrow; // Fail hard
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

      // No reload
    } catch (e) {
      print('Error updating appointment: $e');
      // Rollback: reload
      await loadAppointments(forceRefresh: true);
      rethrow;
    }
  }

  Future<void> deleteAppointment(String id) async {
    try {
      final appointment = _appointments.firstWhere((a) => a.id == id, orElse: () => Appointment(title: 'Unknown', dateTime: DateTime.now()));
      
      // Optimistic Delete
      _appointments.removeWhere((a) => a.id == id);
      notifyListeners();

      if (appointment.notificationId != null) {
        await _notificationService.cancelReminder(appointment.notificationId!);
      } else if (appointment.id != 'Unknown') {
         // Try checking local DB if not in memory
         final dbAppt = await _dbHelper.getAppointmentById(id);
         if (dbAppt != null && dbAppt.notificationId != null) {
            await _notificationService.cancelReminder(dbAppt.notificationId!);
         }
      }

      // Delete from Supabase if authenticated, otherwise delete from local SQLite
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        try {
          await _supabaseRepository.delete(id);
          debugPrint('Appointment deleted from Supabase: ${appointment.title}');
          // Also delete from local DB to maintain consistency
          try { await _dbHelper.deleteAppointment(id); } catch (_) {}
        } catch (e) {
          debugPrint('❌ [AppointmentProvider] Failed to delete appointment from Supabase: $e');
          rethrow; // Fail hard
        }
      } else {
        // Delete locally when not authenticated
        await _dbHelper.deleteAppointment(id);
      }

      // No reload
    } catch (e) {
      print('Error deleting appointment: $e');
      // Rollback: reload
      await loadAppointments(forceRefresh: true);
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

