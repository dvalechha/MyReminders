import '../database/database_helper.dart';
import 'notification_service.dart';

/// Service to clear all local cached data
class LocalCacheService {
  static final LocalCacheService instance = LocalCacheService._init();

  LocalCacheService._init();

  /// Clear all local cached data
  /// This includes:
  /// - SQLite database (subscriptions, appointments, tasks, custom reminders)
  /// - All scheduled notifications
  Future<void> clearAll() async {
    try {
      // Clear all database tables
      await _clearDatabase();

      // Cancel all scheduled notifications
      await _clearNotifications();
    } catch (e) {
      throw Exception('Failed to clear local cache: $e');
    }
  }

  /// Clear all data from SQLite database
  Future<void> _clearDatabase() async {
    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.database;

    // Delete all records from all tables
    await db.delete('subscriptions');
    await db.delete('appointments');
    await db.delete('tasks');
    await db.delete('custom_reminders');
  }

  /// Cancel all scheduled notifications
  Future<void> _clearNotifications() async {
    // Cancel all pending notifications
    // Note: We'll cancel all notifications using the notification service
    // The notification service will handle canceling all scheduled notifications
    final notificationService = NotificationService.instance;
    // Use the plugin's cancelAll method if available
    await notificationService.cancelAllNotifications();
  }
}

