import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subscription.dart';
import '../database/database_helper.dart';
import '../services/notification_service.dart';
import '../repositories/subscription_repository.dart';
import '../repositories/category_repository.dart';

class SubscriptionProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final NotificationService _notificationService = NotificationService.instance;
  final SubscriptionRepository _supabaseRepository = SubscriptionRepository();
  final CategoryRepository _categoryRepository = CategoryRepository();

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
      // Clear existing subscriptions before loading new data to prevent stale data
      _subscriptions.clear();
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

      // Save to local SQLite first (for offline support)
      await _dbHelper.insertSubscription(updatedSubscription);

      // Also save to Supabase if user is authenticated
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          // Get category in Supabase by name
          final categoryName = updatedSubscription.category.value;
          var category = await _categoryRepository.getByName(categoryName);
          
          // If category doesn't exist, try to get "Other" as fallback
          String? categoryId = category?.id;
          if (categoryId == null) {
            // Try to get a default category (e.g., "Other")
            final defaultCategory = await _categoryRepository.getByName('Other');
            categoryId = defaultCategory?.id;
          }
          
          if (categoryId == null) {
            // Try to get any category as last resort
            final allCategories = await _categoryRepository.getAll();
            if (allCategories.isNotEmpty) {
              categoryId = allCategories.first.id;
              debugPrint('Warning: Category "$categoryName" not found. Using "${allCategories.first.name}" instead.');
            } else {
              // If no categories exist at all, we can't proceed
              debugPrint('Error: No categories found in Supabase. Please create categories first.');
              debugPrint('Subscription saved locally only.');
              // Continue with local save only
              await loadSubscriptions();
              return updatedSubscription.id;
            }
          }

          // Convert to Supabase format and save (categoryId is guaranteed to be non-null here)
          final supabaseData = updatedSubscription.toSupabaseMap(
            userId: user.id,
            categoryId: categoryId,
          );
          
          await _supabaseRepository.create(supabaseData);
          debugPrint('Subscription saved to Supabase: ${updatedSubscription.serviceName}');
        }
      } catch (e) {
        // Log error but don't fail - subscription is already saved locally
        debugPrint('Warning: Failed to save subscription to Supabase: $e');
        debugPrint('Subscription saved locally only. Will sync when connection is available.');
      }

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
      debugPrint('Error adding subscription: $e');
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

      // Update local SQLite first
      await _dbHelper.updateSubscription(updatedSubscription);

      // Also update in Supabase if user is authenticated
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          // Get category in Supabase by name
          final categoryName = updatedSubscription.category.value;
          var category = await _categoryRepository.getByName(categoryName);
          
          // If category doesn't exist, try to get "Other" as fallback
          String? categoryId = category?.id;
          if (categoryId == null) {
            final defaultCategory = await _categoryRepository.getByName('Other');
            categoryId = defaultCategory?.id;
          }
          
          if (categoryId == null) {
            // Try to get any category as last resort
            final allCategories = await _categoryRepository.getAll();
            if (allCategories.isNotEmpty) {
              categoryId = allCategories.first.id;
              debugPrint('Warning: Category "$categoryName" not found. Using "${allCategories.first.name}" instead.');
            } else {
              debugPrint('Error: No categories found in Supabase. Please create categories first.');
              debugPrint('Subscription updated locally only.');
              // Continue with local update only
            }
          }

          if (categoryId != null) {
            // Convert to Supabase format and update
            final supabaseData = updatedSubscription.toSupabaseMap(
              userId: user.id,
              categoryId: categoryId,
            );
            
            await _supabaseRepository.update(updatedSubscription.id, supabaseData);
            debugPrint('Subscription updated in Supabase: ${updatedSubscription.serviceName}');
          }
        }
      } catch (e) {
        // Log error but don't fail - subscription is already updated locally
        debugPrint('Warning: Failed to update subscription in Supabase: $e');
        debugPrint('Subscription updated locally only. Will sync when connection is available.');
      }

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

      // Delete from local SQLite first
      await _dbHelper.deleteSubscription(id);

      // Also delete from Supabase if user is authenticated
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          await _supabaseRepository.delete(id);
          debugPrint('Subscription deleted from Supabase: ${subscription?.serviceName ?? "Unknown"}');
        }
      } catch (e) {
        // Log error but don't fail - subscription is already deleted locally
        debugPrint('Warning: Failed to delete subscription from Supabase: $e');
        debugPrint('Subscription deleted locally only. Will sync when connection is available.');
      }

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

