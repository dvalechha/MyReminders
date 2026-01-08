# Brainstorm: Personal Assistant App (Custos)

## Purpose
This document captures ongoing ideas, decisions, and implementation status for the Personal Assistant app so we can pick up the discussion in future sessions.

---

## Current Implementation Status

### ✅ Completed Features

#### 1. Authentication System (Supabase)
- **Email/Password Signup** with email verification requirement
- **Email/Password Login** with user-friendly error messages
- **Google OAuth Login** with automatic profile creation
- **Forgot Password Flow**:
  - Send password reset email
  - Deep link handling to open app from email
  - Dedicated Reset Password screen
  - Prevents navigation issues with `WillPopScope`
- **Email Verification Flow**:
  - After signup, users must verify email before accessing the app
  - Upon clicking email confirmation link, user is **signed out and required to re-login** (security feature)
  - Success message displayed on login screen after verification
- **Account Deletion**:
  - Supabase Edge Function (`delete-account`) handles secure deletion
  - Explicitly deletes all related data (subscriptions, tasks, appointments, user_profile)
  - Then deletes the auth user (CASCADE as backup)
- **Session Management**:
  - Auth state listener for reactive UI updates
  - Session refresh on app resume
  - Logout service with complete cleanup

#### 2. Data Models
- **Subscriptions**: Track recurring payments (title, amount, currency, billing cycle, renewal date, reminders)
- **Appointments**: Calendar events (title, start time, location, notes, reminders)
- **Tasks**: To-do items (title, due date, priority, notes, reminders)
- **Categories**: Shared category system for organization
- **User Profile**: Display name, email, linked to auth user

#### 3. Database (Supabase PostgreSQL)
- Row Level Security (RLS) enabled on all tables
- Users can only access their own data
- `ON DELETE CASCADE` for automatic cleanup when user is deleted
- Indexes for performance on common queries
- Automatic `updated_at` triggers

#### 4. UI Components
- **Auth Gate**: Central routing based on auth state (login, email verification, password reset, main app)
- **Welcome View**: Main dashboard with omnibox and snapshot
- **Today's Snapshot Widget**: Glanceable summary of day's items
- **Unified Agenda View**: Chronological list of all upcoming items
- **Omnibox**: Natural language command input with intent detection
- **Navigation Drawer**: Access to all app sections
- **Settings View**: Account management, password change, delete account

#### 5. Natural Language Processing
- **Intent Parser Service**: Rule-based extraction of:
  - Action: create, show, view
  - Category: appointment, task, subscription, reminder
  - Date/Time: Relative (tomorrow, today) and absolute (Dec 15th at 6pm)
- **Intent Types**: Search vs Create detection based on keywords

#### 6. State Management (Provider)
- `AuthProvider`: Authentication state, login/logout, password reset
- `SubscriptionProvider`: CRUD for subscriptions
- `AppointmentProvider`: CRUD for appointments
- `TaskProvider`: CRUD for tasks
- `UserProfileProvider`: User profile management
- `NavigationModel`: App-wide navigation state

#### 7. Services
- **Logout Service**: Complete cleanup on logout (cancel listeners, clear cache, sign out)
- **Local Cache Service**: Local data persistence
- **State Reset Service**: Reset all providers on logout
- **Notification Service**: Local notifications (scaffold)

---

## Architecture Overview

```
lib/
├── main.dart                 # App entry, Supabase init, Provider setup
├── database/
│   └── database_helper.dart  # SQLite helper (local cache)
├── models/
│   ├── appointment.dart
│   ├── category.dart
│   ├── intent_type.dart
│   ├── parsed_intent.dart
│   ├── subscription.dart
│   ├── task.dart
│   └── user_profile.dart
├── providers/
│   ├── auth_provider.dart    # Auth state, login, signup, password reset
│   ├── appointment_provider.dart
│   ├── subscription_provider.dart
│   ├── task_provider.dart
│   ├── user_profile_provider.dart
│   └── navigation_model.dart
├── repositories/
│   ├── appointment_repository.dart  # Supabase CRUD
│   ├── subscription_repository.dart
│   ├── task_repository.dart
│   ├── category_repository.dart
│   └── user_profile_repository.dart
├── services/
│   ├── intent_parser_service.dart   # NLP parsing
│   ├── logout_service.dart
│   ├── local_cache_service.dart
│   ├── state_reset_service.dart
│   └── notification_service.dart
├── utils/
│   ├── auth_error_helper.dart       # User-friendly error messages
│   ├── environment_config.dart      # Dev/Prod environment handling
│   ├── natural_language_parser.dart
│   ├── snackbar.dart
│   └── supabase_user_helper.dart
├── views/
│   ├── login_screen.dart
│   ├── signup_screen.dart
│   ├── forgot_password_screen.dart
│   ├── reset_password_screen.dart
│   ├── email_verification_view.dart
│   ├── welcome_view.dart
│   ├── unified_agenda_view.dart
│   ├── settings_view.dart
│   ├── account_profile_view.dart
│   ├── change_password_view.dart
│   ├── delete_account_view.dart
│   ├── subscriptions_list_view.dart
│   ├── subscription_form_view.dart
│   ├── appointments_list_view.dart
│   ├── appointment_form_view.dart
│   ├── tasks_list_view.dart
│   ├── task_form_view.dart
│   └── ...
└── widgets/
    ├── auth_gate.dart              # Main auth routing
    ├── omnibox.dart                # Command input
    ├── todays_snapshot_view.dart   # Dashboard widget
    ├── app_navigation_drawer.dart
    └── ...
```

### Backend (Supabase)

```
supabase/
├── config.toml
└── functions/
    ├── _shared/
    │   └── cors.ts
    └── delete-account/
        └── index.ts    # Edge function for account deletion
```

---

## Database Schema (Supabase)

### Tables
1. **category** - Shared categories (read-only for users)
2. **subscriptions** - User subscriptions with `user_id` FK
3. **appointments** - User appointments with `user_id` FK
4. **tasks** - User tasks with `user_id` FK
5. **user_profile** - User display info, FK to `auth.users`

### Key Features
- All user tables have `ON DELETE CASCADE` to auth.users
- RLS policies: Users can only access their own data
- Automatic `updated_at` timestamps via triggers

---

## Recent Session Work (Authentication Improvements)

### Issues Fixed
1. **Account Deletion Bug**: Related data (subscriptions, tasks, appointments) wasn't being deleted. Fixed by explicit deletion in edge function before user deletion.

2. **GitHub Secret Leak**: `node_modules/` was tracked in git. Added to `.gitignore` and removed from history.

3. **Technical Error Messages**: Raw exception messages shown to users. Created `AuthErrorHelper` utility for user-friendly messages.

4. **Password Reset Deep Link**: Clicking reset link didn't navigate to reset screen. Implemented:
   - SharedPreferences flags to track password reset initiation
   - Detection in `onAuthStateChange` listener
   - Detection on app resume via `didChangeAppLifecycleState`
   - Dedicated `ResetPasswordScreen` with back navigation protection

5. **Login After Password Reset**: After resetting password, logging in redirected back to reset screen. Fixed by clearing local flags when provider flag is false.

6. **Unverified Email Login**: Showed generic "invalid credentials" for unverified users. Updated `AuthErrorHelper` to detect and show specific message.

7. **Auto-Login After Email Verification (Security)**: Users were auto-logged in after clicking email confirmation. Now:
   - Tracks `just_signed_up` and `signup_email` flags
   - Detects email verification via `onAuthStateChange` and app resume
   - Signs out user and sets `email_verified_success` flag
   - Shows success message on login screen requiring re-login

---

## MVP Features (Original Plan)

1. ✅ Central natural-language command input (Omnibox implemented)
2. ✅ Unified agenda view combining calendar events, tasks, and subscriptions
3. 🔄 Time-based reminders (notification service scaffolded)
4. ✅ Task management basics (priorities, categories, notes)
5. ⏳ Integration with calendar providers (planned for post-MVP)
6. ⏳ Context-aware suggestions (planned)
7. ⏳ Persistent conversation history (planned)
8. ✅ Privacy controls and user data management

### MVP Feature 1 Details (Implemented)
- Single command/search bar (Omnibox) as default interaction
- Deterministic intent parsing extracts title, timing, and type
- Keywords detected: create/add/schedule vs show/view/list

### MVP Feature 2 Details (Implemented)
- Dynamic Welcome Screen with Today's Snapshot
- Two states: Default (snapshot) and Active (typing)
- Snapshot shows: Up Next, Due Today, Renewing Soon
- Tappable to navigate to full Unified Agenda View

---

## Post-MVP Ideas

1. Multi-step automation workflows and routines
2. Intelligent recommendations based on user habits
3. Proactive alerts (travel time, deadline warnings)
4. Voice assistant compatibility
5. Shared assistant spaces for households/teams
6. Insights dashboard with productivity analytics
7. Plugin/extension ecosystem

## Pro Features (Planned)

1. LLM Integration for advanced NLU
2. Advanced Notification Controls (DND, channels)
3. Calendar Integrations (Google, Microsoft, iCloud)
4. Third-party Integrations (Slack, project management)

---

## Environment Setup

### Required Files
- `.env.dev` - Development environment (Supabase dev project)
- `.env.prod` - Production environment

### Required Variables
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_REDIRECT_URL=myreminders://auth-callback
```

### Running the App
```bash
# Development
flutter run --dart-define=ENV=dev

# Production
flutter run --dart-define=ENV=prod
```

---

## Git Branches
- `main` - Production-ready code
- `feature/settings-menu-DV` - Current working branch with authentication improvements

---

## Notes for Future Sessions

1. **Notifications**: Service is scaffolded but not fully implemented. Need to integrate with platform-specific notification APIs.

2. **Calendar Sync**: No external calendar integration yet. Consider Google Calendar API or CalDAV.

3. **Voice Input**: Not implemented. Can use platform speech-to-text APIs feeding into existing parser.

4. **Testing**: Test files exist in `/test/` but need expansion for new auth flows.

5. **Error Handling**: `AuthErrorHelper` pattern could be extended to other error types.
