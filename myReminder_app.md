# My Reminder – Context Notes

## Overview
- Flutter app that tracks subscriptions/reminders, ported from the native iOS SubscriptionTracker.
- Targets iOS, Android, and desktop form factors with Material 3 UI and Provider state management.
- Local data stored in SQLite (via `sqflite`), Supabase provides auth/back-end sync, and notifications are handled with `flutter_local_notifications` plus the timezone package.

## Core Features
- CRUD for subscriptions (service name, category, cost, currency, billing cycle, renewal date, notes, payment method).
- Reminder scheduling with preset (1/3/7 days) or custom (1–29 days) lead times; notifications fire at 7 PM local time and reschedule on app start.
- Dashboard behaviors: empty-state welcome, total monthly spend calculation, swipe-to-delete with reminder date display.

## Key Modules (see `lib/`)
- `models/` – data types like `subscription.dart`.
- `database/` – SQLite helper `database_helper.dart`.
- `services/` – `notification_service.dart` integrates `flutter_local_notifications`.
- `providers/` – Provider-based state (auth, subscriptions, appointments, tasks, custom reminders, navigation).
- `views/` – UI screens such as subscription list/form and reminder modal.
- `utils/environment_config.dart` – compile-time environment selector using `String.fromEnvironment('ENV', defaultValue: 'dev')`.

## Environment & Secrets
- `.env.dev`, `.env.test`, `.env.prod` hold Supabase credentials and other secrets.
- `main.dart` loads `.env.<ENV>` (falls back to `.env`) using `flutter_dotenv`.
- Pass defines at runtime, e.g. `flutter run --dart-define=ENV=dev` or `flutter test --dart-define=ENV=prod`.
- Keep `.env` paths listed under `flutter.assets` in `pubspec.yaml`.

## Supabase Auth Setup Highlights
- Enable email/password and Google OAuth providers in Supabase; supply Google OAuth client ID/secret.
- Redirect scheme: `myreminders://auth-callback`. Add matching intent-filter in `android/app/src/main/AndroidManifest.xml` and URL type in `ios/Runner/Info.plist`.
- Supabase callback URI example: `https://sutjrivsvzikhibqwvqu.supabase.co/auth/v1/callback`.

## Build/Test Commands
- `flutter pub get` – install deps.
- `flutter analyze` – static analysis; keep clean.
- `flutter test` (optionally `--coverage`) – unit/widget tests mirror `lib/` structure.
- `flutter run -d ios` / `flutter run -d android` – launch platforms; include `--dart-define=ENV=<env>` to choose env file.

## Notifications & Permissions
- Android uses `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM`.
- iOS requests notification permissions at runtime via `flutter_local_notifications`.

## Database Schema Snapshot
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
);
```

## Contribution Tips
- Follow 2-space indentation, trailing commas, and run `dart format lib test` before commits.
- Tests live in `test/<feature>/` with `_test.dart` suffix, mirroring the production path.
- Commit messages are short, imperative (e.g., `Add reminder scheduling`); PRs should include summary, `flutter analyze` + `flutter test` evidence, screenshots for UI changes, and mention migrations or permission updates.
