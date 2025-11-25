import 'package:flutter/foundation.dart';
import '../models/subscription.dart';
import '../database/database_helper.dart';
import '../services/notification_service.dart';

class SubscriptionProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final NotificationService _notificationService = NotificationService.instance;

  List<Subscription> _subscriptions = [];
  bool _isLoading = false;

  List<Subscription> get subscriptions => _subscriptions;
  bool get isLoading => _isLoading;

  // Calculate total monthly spend
  double get totalMonthlySpend {
    return _subscriptions.fold(0.0, (sum, subscription) => sum + subscription.amount);
  }

  SubscriptionProvider() {
    loadSubscriptions();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
    await _notificationService.checkAuthorizationStatus();
  }

  // Load all subscriptions from database
  Future<void> loadSubscriptions() async {
    _isLoading = true;
    notifyListeners();

    try {
      _subscriptions = await _dbHelper.getAllSubscriptions();
      // Reschedule all reminders on app start
      await _notificationService.rescheduleAllReminders(_subscriptions);
    } catch (e) {
      print('Error loading subscriptions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add new subscription
  Future<String> addSubscription(Subscription subscription) async {
    try {
      // Generate notification ID if reminder is set
      String? notificationId = subscription.notificationId;
      if (subscription.reminderType != 'none' &&
          subscription.reminderDaysBefore > 0) {
        notificationId ??= subscription.id;
      }

      final updatedSubscription = subscription.copyWith(
        notificationId: notificationId,
      );

      await _dbHelper.insertSubscription(updatedSubscription);

      // Schedule notification if reminder is set
      if (updatedSubscription.reminderType != 'none' &&
          updatedSubscription.reminderDaysBefore > 0 &&
          updatedSubscription.notificationId != null) {
        await _notificationService.scheduleReminder(
          subscription: updatedSubscription,
          renewalDate: updatedSubscription.renewalDate,
          reminderDaysBefore: updatedSubscription.reminderDaysBefore,
          notificationId: updatedSubscription.notificationId!,
        );
      }

      await loadSubscriptions();
      return updatedSubscription.id;
    } catch (e) {
      print('Error adding subscription: $e');
      rethrow;
    }
  }

  // Update existing subscription
  Future<void> updateSubscription(Subscription subscription) async {
    try {
      // Cancel existing notification if editing
      final existing = await _dbHelper.getSubscriptionById(subscription.id);
      if (existing != null && existing.notificationId != null) {
        await _notificationService.cancelReminder(existing.notificationId!);
      }

      // Generate notification ID if reminder is set
      String? notificationId = subscription.notificationId;
      if (subscription.reminderType != 'none' &&
          subscription.reminderDaysBefore > 0) {
        notificationId ??= subscription.id;
      }

      final updatedSubscription = subscription.copyWith(
        notificationId: notificationId,
      );

      await _dbHelper.updateSubscription(updatedSubscription);

      // Schedule notification if reminder is set
      if (updatedSubscription.reminderType != 'none' &&
          updatedSubscription.reminderDaysBefore > 0 &&
          updatedSubscription.notificationId != null) {
        await _notificationService.scheduleReminder(
          subscription: updatedSubscription,
          renewalDate: updatedSubscription.renewalDate,
          reminderDaysBefore: updatedSubscription.reminderDaysBefore,
          notificationId: updatedSubscription.notificationId!,
        );
      } else if (updatedSubscription.notificationId != null) {
        // Cancel notification if reminder is set to none
        await _notificationService.cancelReminder(updatedSubscription.notificationId!);
      }

      await loadSubscriptions();
    } catch (e) {
      print('Error updating subscription: $e');
      rethrow;
    }
  }

  // Delete subscription
  Future<void> deleteSubscription(String id) async {
    try {
      // Get subscription to cancel notification
      final subscription = await _dbHelper.getSubscriptionById(id);
      if (subscription != null && subscription.notificationId != null) {
        await _notificationService.cancelReminder(subscription.notificationId!);
      }

      await _dbHelper.deleteSubscription(id);
      await loadSubscriptions();
      print('🗑️ Deleted subscription: ${subscription?.serviceName ?? "Unknown"} - Notification cancelled');
    } catch (e) {
      print('❌ Error deleting subscription: $e');
      rethrow;
    }
  }

  // Get subscription by ID
  Future<Subscription?> getSubscriptionById(String id) async {
    return await _dbHelper.getSubscriptionById(id);
  }

  /// Clear all in-memory state (for logout)
  void clearState() {
    _subscriptions = [];
    _isLoading = false;
    notifyListeners();
  }
}

