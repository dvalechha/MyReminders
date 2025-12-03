import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/subscription.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _authorized = false;

  NotificationService._init();

  // Default reminder time: 7:00 PM local time
  static const int defaultReminderHour = 19;
  static const int defaultReminderMinute = 0;

  // Initialize notifications
  Future<bool> initialize() async {
    if (_initialized) return _authorized;

    // Initialize timezone
    tz.initializeTimeZones();

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    final bool? initialized = await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    if (initialized == true) {
      _initialized = true;
      _authorized = await checkAuthorizationStatus();
    }

    return _authorized;
  }

  // Check authorization status
  Future<bool> checkAuthorizationStatus() async {
    if (!_initialized) {
      await initialize();
    }

    if (Platform.isIOS) {
      // For iOS, request permissions
      final bool? authorized = await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );

      _authorized = authorized ?? false;
    } else if (Platform.isAndroid) {
      // For Android 13+, request notification permission
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        // Request permission for Android 13+ (API 33+)
        final bool? requested = await androidImplementation.requestNotificationsPermission();
        if (requested == true) {
          _authorized = true;
        } else {
          // Check if notifications are already enabled
          final bool? areNotificationsEnabled = 
              await androidImplementation.areNotificationsEnabled();
          _authorized = areNotificationsEnabled ?? true; // Default to true for older Android versions
        }
      } else {
        _authorized = true; // Fallback: assume authorized
      }
    } else {
      // For other platforms, assume authorized
      _authorized = true;
    }

    return _authorized;
  }

  bool get isAuthorized => _authorized;

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap if needed
    print('Notification tapped: ${response.payload}');
  }

  // Schedule reminder notification
  Future<void> scheduleReminder({
    required Subscription subscription,
    required DateTime renewalDate,
    required int reminderDaysBefore,
    required String notificationId,
  }) async {
    if (!_authorized) {
      print('Notifications not authorized, skipping schedule');
      return;
    }

    if (reminderDaysBefore <= 0) {
      return;
    }

    // Calculate trigger date: renewalDate - reminderDaysBefore
    final triggerDate = renewalDate.subtract(Duration(days: reminderDaysBefore));

    // Set time to 7:00 PM local time
    final scheduledDate = DateTime(
      triggerDate.year,
      triggerDate.month,
      triggerDate.day,
      defaultReminderHour,
      defaultReminderMinute,
    );

    // If trigger is in the past, schedule for next billing cycle
    final actualTriggerDate = scheduledDate.isBefore(DateTime.now())
        ? _calculateNextRenewalDate(
            renewalDate,
            subscription.billingCycle,
            reminderDaysBefore,
          )
        : scheduledDate;

    // Create notification content
    final androidDetails = AndroidNotificationDetails(
      'reminders',
      'Subscription Reminders',
      channelDescription: 'Notifications for upcoming subscription renewals',
      importance: Importance.high,
      priority: Priority.high,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Format renewal date for notification body
    final formattedDate = _formatRenewalDate(renewalDate);

    // Schedule notification (use hash code of notificationId)
    await _notifications.zonedSchedule(
      notificationId.hashCode.abs(),
      'Upcoming Renewal',
      'Your ${subscription.serviceName} subscription renews on $formattedDate.',
      tz.TZDateTime.from(actualTriggerDate, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    print('Notification scheduled for $actualTriggerDate (notificationId: $notificationId)');
  }

  // Cancel reminder notification
  Future<void> cancelReminder(String notificationId) async {
    if (notificationId.isEmpty) return;

    // Convert UUID to int for notification ID (use hash code)
    final id = notificationId.hashCode.abs();
    await _notifications.cancel(id);
  }

  // Cancel reminder for subscription
  Future<void> cancelReminderForSubscription(Subscription subscription) async {
    if (subscription.notificationId != null &&
        subscription.notificationId!.isNotEmpty) {
      await cancelReminder(subscription.notificationId!);
    }
  }

  // Calculate next renewal date based on billing cycle
  DateTime _calculateNextRenewalDate(
    DateTime currentRenewalDate,
    BillingCycle billingCycle,
    int reminderDaysBefore,
  ) {
    // Determine days to add based on billing cycle
    int daysToAdd;
    switch (billingCycle) {
      case BillingCycle.weekly:
        daysToAdd = 7;
        break;
      case BillingCycle.monthly:
        daysToAdd = 30;
        break;
      case BillingCycle.quarterly:
        daysToAdd = 90;
        break;
      case BillingCycle.yearly:
        daysToAdd = 365;
        break;
      default:
        daysToAdd = 30; // Default to monthly
    }

    // Find next renewal date
    var nextRenewal = currentRenewalDate;
    while (nextRenewal.isBefore(DateTime.now()) ||
        nextRenewal.isAtSameMomentAs(DateTime.now())) {
      nextRenewal = nextRenewal.add(Duration(days: daysToAdd));
    }

    // Calculate trigger date (nextRenewal - reminderDaysBefore)
    final triggerDate = nextRenewal.subtract(Duration(days: reminderDaysBefore));

    // Set time to 7:00 PM
    return DateTime(
      triggerDate.year,
      triggerDate.month,
      triggerDate.day,
      defaultReminderHour,
      defaultReminderMinute,
    );
  }

  // Format renewal date for display
  String _formatRenewalDate(DateTime date) {
    // Format as "MMM d, yyyy" (e.g., "Nov 15, 2024")
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // Reschedule all reminders (useful after app restart)
  Future<void> rescheduleAllReminders(List<Subscription> subscriptions) async {
    if (!_authorized) return;

    for (final subscription in subscriptions) {
      if (subscription.reminderType != 'none' &&
          subscription.reminderDaysBefore > 0 &&
          subscription.notificationId != null &&
          subscription.notificationId!.isNotEmpty) {
        await scheduleReminder(
          subscription: subscription,
          renewalDate: subscription.renewalDate,
          reminderDaysBefore: subscription.reminderDaysBefore,
          notificationId: subscription.notificationId!,
        );
      }
    }
  }

  // Schedule time-based reminder (for appointments, tasks, custom reminders)
  Future<void> scheduleTimeBasedReminder({
    required String notificationId,
    required String title,
    required String body,
    required DateTime eventDateTime,
    required int minutesBefore,
  }) async {
    if (!_authorized) {
      print('Notifications not authorized, skipping schedule');
      return;
    }

    if (minutesBefore <= 0) return;

    final reminderTime = eventDateTime.subtract(Duration(minutes: minutesBefore));

    if (reminderTime.isBefore(DateTime.now())) return;

    final androidDetails = AndroidNotificationDetails(
      'time_based_reminders',
      'Time-Based Reminders',
      channelDescription: 'Notifications for appointments, tasks, and custom reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      notificationId.hashCode.abs(),
      title,
      body,
      tz.TZDateTime.from(reminderTime, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    print('Time-based reminder scheduled for $reminderTime (notificationId: $notificationId)');
  }

  /// Cancel all pending notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}

