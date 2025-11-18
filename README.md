# My Reminder - Flutter App

A cross-platform subscription tracking app built with Flutter, ported from the iOS SubscriptionTracker app.

## Features

✅ **Subscription Management**
- Add, edit, and delete subscriptions
- Track service name, category, amount, currency
- Set renewal dates and billing cycles

✅ **Custom Reminders**
- Preset options: 1 day, 3 days, 7 days before renewal
- Custom reminder picker: 1-29 days before renewal
- Notifications scheduled at 7:00 PM local time

✅ **Smart Features**
- Empty state welcome screen
- Total monthly spend calculation
- Swipe-to-delete functionality
- Reminder date display in list view

✅ **Cross-Platform**
- Works on both iOS and Android
- Material Design UI with adaptive elements

## Project Structure

```
lib/
├── models/
│   └── subscription.dart          # Data models and enums
├── database/
│   └── database_helper.dart       # SQLite database layer
├── services/
│   └── notification_service.dart  # Local notifications
├── providers/
│   └── subscription_provider.dart # State management (Provider)
└── views/
    ├── subscriptions_list_view.dart    # Main list view
    ├── subscription_form_view.dart     # Add/Edit form
    └── custom_reminder_modal.dart      # Custom reminder picker
```

## Dependencies

- **provider**: State management
- **sqflite**: Local database (SQLite)
- **flutter_local_notifications**: Local notifications
- **intl**: Date formatting
- **uuid**: Unique ID generation
- **timezone**: Timezone support for notifications

## Setup Instructions

1. **Install Flutter** (if not already installed):
   ```bash
   brew install --cask flutter
   ```

2. **Get dependencies**:
   ```bash
   cd /Users/deepakvalechha/MyReminder
   flutter pub get
   ```

3. **Run on iOS**:
   ```bash
   flutter run -d ios
   ```

4. **Run on Android**:
   ```bash
   flutter run -d android
   ```

## Permissions

### Android
- `POST_NOTIFICATIONS` - For scheduling reminders
- `SCHEDULE_EXACT_ALARM` - For precise notification timing
- `USE_EXACT_ALARM` - For exact alarm scheduling

### iOS
- Notification permissions are requested at runtime via the `flutter_local_notifications` plugin

## Database Schema

The app uses SQLite with the following table structure:

```sql
CREATE TABLE subscriptions (
  id TEXT PRIMARY KEY,
  serviceName TEXT NOT NULL,
  category TEXT NOT NULL,
  amount REAL NOT NULL,
  currency TEXT NOT NULL,
  renewalDate TEXT NOT NULL,
  billingCycle TEXT NOT NULL,
  reminder TEXT NOT NULL,
  reminderType TEXT NOT NULL,
  reminderDaysBefore INTEGER NOT NULL,
  notificationId TEXT,
  notes TEXT,
  paymentMethod TEXT
)
```

## Migration from iOS App

This Flutter app ports all features from the iOS SubscriptionTracker app:

- ✅ Data models (Subscription, enums)
- ✅ Core Data → SQLite migration
- ✅ NotificationManager → NotificationService
- ✅ ViewModels → Provider pattern
- ✅ SwiftUI Views → Flutter Widgets
- ✅ All UI features (empty state, swipe-to-delete, custom reminders)

## Notes

- Notifications are scheduled at 7:00 PM local time
- Custom reminders support 1-29 days before renewal
- The app automatically reschedules reminders on app start
- Data persists locally using SQLite

## Development

To analyze the code:
```bash
flutter analyze
```

To run tests:
```bash
flutter test
```

## License

This project is a port of the SubscriptionTracker iOS app.
# MyReminders
