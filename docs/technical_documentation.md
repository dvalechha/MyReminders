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
- **Forgot Password Flow** & **Email Verification Flow**
- **Account Deletion** (Edge Function)
- **Session Management**: Robust handling with `LogoutService` ensuring clean state reset.

#### 2. Data Models
- **Subscriptions**: `renewal_date`, `is_renewed`, `billing_cycle`.
- **Appointments**: `start_time`, `is_completed`, `location`.
- **Tasks**: `due_date`, `is_completed`, `priority`.
- **Categories**: Shared category system.
- **User Profile**: Display name, email.

#### 3. Database (Supabase PostgreSQL & Local SQLite)
- **Hybrid Sync**: Data is stored in Supabase (primary) and SQLite (offline cache).
- **Optimistic UI**: Providers update local state immediately, then sync to DB. Failures trigger rollback.
- **RLS**: Row Level Security enabled on all tables.
- **Migrations**: Added `is_completed` columns to tasks and appointments.

#### 4. UI Components ("Modern Soft" Design)
- **Design System**:
    - **Background**: `Colors.grey[50]`
    - **Brand Blue**: `Color(0xFF2D62ED)`
    - **Cards**: White surface, rounded corners (16-20), soft diffused shadows.
    - **Inputs**: `ModernFormField` (filled grey background, no border stroke).
- **Empty States**: Polished `EmptyStateView` with large circular icons and CTA buttons.
- **Forms**:
    - Refactored `SubscriptionFormView`, `AppointmentFormView`, and `TaskFormView`.
    - Grouped fields into logical cards ("Essentials", "Timing", "Details").
- **List Views**:
    - **Multi-Selection**: Long-press to select, batch delete via `SelectionAppBar`.
    - **Tasks**: Leading checkbox, strikethrough for completed.
    - **Appointments**: Grouped by date, trailing checkmark for completion.
    - **Unified Agenda**: Chronological dashboard of all items.

#### 5. Logic & Business Rules
- **Renewal Logic**: "Sticky End-of-Month" heuristic (Jan 31 -> Feb 28 -> Mar 31).
- **Completion**: Tasks and Appointments can be marked complete; lists filter active items by default.
- **Notifications**: Local notification service for reminders.

---

## Architecture Overview

```
lib/
├── main.dart
├── widgets/
│   ├── modern_form_field.dart    # Reusable styled input
│   ├── empty_state_view.dart     # Standard empty state
│   ├── selection_app_bar.dart    # Multi-select toolbar
│   └── smart_list_tile.dart      # Base card with visuals
├── views/
│   ├── subscription_form_view.dart # Grouped card layout
│   ├── appointment_form_view.dart  # Grouped card layout
│   ├── task_form_view.dart         # Grouped card layout
│   ├── appointments_list_view.dart # Date-grouped list
│   └── tasks_list_view.dart        # Priority/Date sorted list
├── providers/
│   ├── task_provider.dart        # Optimistic CRUD, Batch delete
│   ├── appointment_provider.dart # Optimistic CRUD, Batch delete
│   └── subscription_provider.dart
├── services/
│   ├── logout_service.dart       # Clean navigation stack reset
│   └── subscription_service.dart # Renewal calculation logic
└── repositories/                 # Supabase interactions
```

---

## Recent Session Work

### 1. Visual Overhaul
- Established "Modern Soft" design system.
- Created `ModernFormField` and refactored all input forms to use grouped cards.
- Implemented `EmptyStateView` for better user guidance.

### 2. Core Functionality
- **Multi-Selection**: Added `SelectionAppBar` and logic in providers to handle batch deletion.
- **Completion Status**: Added `is_completed` field to Tasks and Appointments, enabling "Mark Done" workflows.
- **Optimistic Updates**: Rewrote providers to update UI instantly, fixing "flickering" and "reappearing item" bugs.

### 3. Stability Fixes
- **Logout**: Fixed navigation stack issue where the logout spinner would hang or show the wrong screen.
- **Data Integrity**: Enforced safer error handling in providers (rethrow errors instead of silently failing to local DB when online).

---

## Notes for Future Sessions

1. **Calendar Sync**: No external calendar integration yet.
2. **Recurring Tasks**: Logic exists for Subscriptions but not yet for Tasks/Appointments.
3. **Voice Input**: Omnibox intent parser exists but needs voice-to-text integration.
