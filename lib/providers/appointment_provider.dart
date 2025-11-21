import 'package:flutter/foundation.dart';
import '../models/appointment.dart';
import '../database/database_helper.dart';
import '../services/notification_service.dart';

class AppointmentProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final NotificationService _notificationService = NotificationService.instance;

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
      _appointments = await _dbHelper.getAllAppointments();
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

      await _dbHelper.insertAppointment(updatedAppointment);

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

      await _dbHelper.updateAppointment(updatedAppointment);

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

      await _dbHelper.deleteAppointment(id);
      await loadAppointments();
    } catch (e) {
      print('Error deleting appointment: $e');
      rethrow;
    }
  }

  Future<Appointment?> getAppointmentById(String id) async {
    return await _dbHelper.getAppointmentById(id);
  }
}

