import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Service to manage notification preferences for different reminder types
class NotificationPreferencesService {
  static final NotificationPreferencesService instance = NotificationPreferencesService._init();
  static SharedPreferences? _prefs;

  NotificationPreferencesService._init();

  Future<void> _ensureInitialized() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Keys for storing preferences
  static const String _subscriptionNotificationsKey = 'subscription_notifications_enabled';
  static const String _taskNotificationsKey = 'task_notifications_enabled';
  static const String _appointmentNotificationsKey = 'appointment_notifications_enabled';

  /// Get subscription notifications enabled status (default: true)
  Future<bool> areSubscriptionNotificationsEnabled() async {
    await _ensureInitialized();
    return _prefs?.getBool(_subscriptionNotificationsKey) ?? true;
  }

  /// Set subscription notifications enabled status
  Future<void> setSubscriptionNotificationsEnabled(bool enabled) async {
    await _ensureInitialized();
    await _prefs?.setBool(_subscriptionNotificationsKey, enabled);
    debugPrint('📱 [NotificationPreferences] Subscription notifications: ${enabled ? "enabled" : "disabled"}');
  }

  /// Get task notifications enabled status (default: true)
  Future<bool> areTaskNotificationsEnabled() async {
    await _ensureInitialized();
    return _prefs?.getBool(_taskNotificationsKey) ?? true;
  }

  /// Set task notifications enabled status
  Future<void> setTaskNotificationsEnabled(bool enabled) async {
    await _ensureInitialized();
    await _prefs?.setBool(_taskNotificationsKey, enabled);
    debugPrint('📱 [NotificationPreferences] Task notifications: ${enabled ? "enabled" : "disabled"}');
  }

  /// Get appointment notifications enabled status (default: true)
  Future<bool> areAppointmentNotificationsEnabled() async {
    await _ensureInitialized();
    return _prefs?.getBool(_appointmentNotificationsKey) ?? true;
  }

  /// Set appointment notifications enabled status
  Future<void> setAppointmentNotificationsEnabled(bool enabled) async {
    await _ensureInitialized();
    await _prefs?.setBool(_appointmentNotificationsKey, enabled);
    debugPrint('📱 [NotificationPreferences] Appointment notifications: ${enabled ? "enabled" : "disabled"}');
  }
}

