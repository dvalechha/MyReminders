import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subscription.dart';
import '../database/database_helper.dart';
import '../services/notification_service.dart';
import '../services/notification_preferences_service.dart';
import '../repositories/subscription_repository.dart';
import '../repositories/category_repository.dart';
import '../services/subscription_service.dart';
import '../models/category.dart' as models;

class SubscriptionProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final NotificationService _notificationService = NotificationService.instance;
  final NotificationPreferencesService _notificationPrefs = NotificationPreferencesService.instance;
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
    // Defer initialization to avoid blocking app startup
    // Data will be loaded when the SubscriptionsListView is actually shown
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

  // Load all subscriptions from database
  Future<void> loadSubscriptions({bool forceRefresh = false}) async {
    // Don't reload if already loading to prevent duplicate requests
    if (_isLoading && !forceRefresh) {
      return;
    }
    
    // Don't load if already loaded and not forcing refresh
    if (_subscriptions.isNotEmpty && !forceRefresh) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Clear existing subscriptions before loading new data to prevent stale data
      _subscriptions.clear();

      // Check authentication before attempting to load
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        // Not authenticated - try loading from local database only
        try {
          final localSubscriptions = await _dbHelper.getAllSubscriptions();
          _subscriptions = localSubscriptions;
        } catch (e) {
          debugPrint('Warning: Failed to load subscriptions from local database: $e');
          _subscriptions = [];
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
          // Map category_id to enum using pre-fetched category map
          // Map rows to Subscription objects and deduplicate by id
          final Map<String, Subscription> mapped = {};
          for (final row in supabaseRows) {
            final categoryId = row['category_id'] as String?;
            SubscriptionCategory categoryEnum = SubscriptionCategory.other;
            if (categoryId != null && categoryMap.containsKey(categoryId)) {
              final category = categoryMap[categoryId]!;
              categoryEnum = SubscriptionCategory.fromString(category.name);
            }
            final sub = Subscription.fromSupabaseMap(row, categoryEnum);
            mapped[sub.id] = sub; // last-one-wins, removes duplicates by id
          }
          
          final items = mapped.values.toList()
            ..sort((a, b) => a.renewalDate.compareTo(b.renewalDate));
          
          debugPrint('💳 [SubscriptionProvider] Loaded ${items.length} subscriptions from Supabase');
            
          _subscriptions = items;
        } catch (e) {
          debugPrint('Warning: Failed to fetch subscriptions from Supabase, falling back to local: $e');
          _subscriptions = await _dbHelper.getAllSubscriptions();
          debugPrint('💳 [SubscriptionProvider] Loaded ${_subscriptions.length} subscriptions from Local DB');
        }
      
      // Reschedule all reminders on app start
      await _notificationService.rescheduleAllReminders(_subscriptions);
    } catch (e) {
      print('Error loading subscriptions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Renew subscription
  Future<void> renewSubscription(String id, Subscription currentSubscription) async {
    try {
      final SubscriptionService service = SubscriptionService();
      
      // 1. Calculate
      final newRenewalDate = service.calculateNextRenewalDate(
        currentSubscription.renewalDate,
        currentSubscription.billingCycle,
      );

      final updatedSub = currentSubscription.copyWith(
         renewalDate: newRenewalDate,
         isRenewed: true,
      );

      // 2. Supabase Update
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
         final updates = {
           'renewal_date': newRenewalDate.toUtc().toIso8601String(),
           'is_renewed': true,
         };
         await _supabaseRepository.update(id, updates);
      }

      // Update local DB
      try {
        await _dbHelper.updateSubscription(updatedSub);
      } catch (e) {
        debugPrint('Warning: Failed to update local subscription renewal: $e');
      }

      // 3. State Refresh (Optimistic)
      final index = _subscriptions.indexWhere((s) => s.id == id);
      if (index != -1) {
        _subscriptions[index] = updatedSub;
        notifyListeners();
      }
      
      // Reschedule notification
      if (updatedSub.notificationId != null) {
         await _notificationService.cancelReminder(updatedSub.notificationId!);
         if (updatedSub.reminderType != 'none' && updatedSub.reminderDaysBefore > 0) {
             await _notificationService.scheduleReminder(
               subscription: updatedSub,
               renewalDate: newRenewalDate,
               reminderDaysBefore: updatedSub.reminderDaysBefore,
               notificationId: updatedSub.notificationId!,
             );
         }
      }
    } catch (e) {
      debugPrint('Error renewing subscription: $e');
      rethrow;
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

      // Only save to local SQLite if user is not authenticated (offline mode)
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        await _dbHelper.insertSubscription(updatedSubscription);
      }

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
            categoryId: categoryId!,
          );
          
          // If a subscription with the same id already exists in Supabase, update it instead
          final existing = await _supabaseRepository.getById(updatedSubscription.id);
          if (existing != null) {
            await _supabaseRepository.update(updatedSubscription.id, supabaseData);
            debugPrint('Subscription updated in Supabase: ${updatedSubscription.serviceName}');
          } else {
            await _supabaseRepository.create(supabaseData);
            debugPrint('Subscription saved to Supabase: ${updatedSubscription.serviceName}');
          }

          // Remove any local copy with the same id to avoid duplicate listings
          try {
            await _dbHelper.deleteSubscription(updatedSubscription.id);
          } catch (_) {}
        }
      } catch (e) {
        // Log error but don't fail - subscription is already saved locally
        debugPrint('Warning: Failed to save subscription to Supabase: $e');
        debugPrint('Subscription saved locally only. Will sync when connection is available.');
      }

      // Schedule notification if reminder is set and subscription notifications are enabled
      final subscriptionNotificationsEnabled = await _notificationPrefs.areSubscriptionNotificationsEnabled();
      if (subscriptionNotificationsEnabled &&
          updatedSubscription.reminderType != 'none' &&
          updatedSubscription.reminderDaysBefore > 0 &&
          updatedSubscription.notificationId != null) {
        await _notificationService.scheduleReminder(
          subscription: updatedSubscription,
          renewalDate: updatedSubscription.renewalDate,
          reminderDaysBefore: updatedSubscription.reminderDaysBefore,
          notificationId: updatedSubscription.notificationId!,
        );
      }

      await loadSubscriptions(forceRefresh: true);
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

      // Only update in Supabase if user is authenticated, otherwise use local SQLite
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        try {
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
        } catch (e) {
          // Log error but don't fail - subscription is already updated locally
          debugPrint('Warning: Failed to update subscription in Supabase: $e');
          throw e; // Rethrow to indicate failure
        }
      } else {
        // User not authenticated, update local SQLite only
        await _dbHelper.updateSubscription(updatedSubscription);
      }

      // Schedule notification if reminder is set and subscription notifications are enabled
      final subscriptionNotificationsEnabled = await _notificationPrefs.areSubscriptionNotificationsEnabled();
      if (subscriptionNotificationsEnabled &&
          updatedSubscription.reminderType != 'none' &&
          updatedSubscription.reminderDaysBefore > 0 &&
          updatedSubscription.notificationId != null) {
        await _notificationService.scheduleReminder(
          subscription: updatedSubscription,
          renewalDate: updatedSubscription.renewalDate,
          reminderDaysBefore: updatedSubscription.reminderDaysBefore,
          notificationId: updatedSubscription.notificationId!,
        );
      } else if (updatedSubscription.notificationId != null) {
        // Cancel notification if reminder is set to none or notifications are disabled
        await _notificationService.cancelReminder(updatedSubscription.notificationId!);
      }

      await loadSubscriptions(forceRefresh: true);
    } catch (e) {
      print('Error updating subscription: $e');
      rethrow;
    }
  }

  // Delete subscription
  Future<void> deleteSubscription(String id) async {
    try {
      // Get subscription to cancel notification (check both sources)
      final user = Supabase.instance.client.auth.currentUser;
      Subscription? subscription;
      
      if (user != null) {
        // When authenticated, fetch from current in-memory list
        subscription = _subscriptions.firstWhere(
          (s) => s.id == id,
          orElse: () => throw Exception('Subscription not found'),
        );
      } else {
        subscription = await _dbHelper.getSubscriptionById(id);
      }
      
      if (subscription != null && subscription.notificationId != null) {
        await _notificationService.cancelReminder(subscription.notificationId!);
      }

      // Delete from appropriate source based on auth status
      if (user != null) {
        try {
          await _supabaseRepository.delete(id);
          debugPrint('Subscription deleted from Supabase: ${subscription?.serviceName ?? "Unknown"}');
        } catch (e) {
          debugPrint('Warning: Failed to delete subscription from Supabase: $e');
          throw e; // Rethrow to indicate failure
        }
      } else {
        // User not authenticated, delete from local SQLite only
        await _dbHelper.deleteSubscription(id);
      }

      await loadSubscriptions(forceRefresh: true);
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

