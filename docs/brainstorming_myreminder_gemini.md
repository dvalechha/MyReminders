# Project: MyReminder App - Brainstorming & Progress Log

**Goal:** Build a production-grade Flutter application for managing subscriptions with a modern, "Soft Depth" design language.

---

## 1. Design System ("Modern Soft")
We moved away from standard Material Design to a custom, premium aesthetic.

* **Color Palette:**
    * **Background:** `Colors.grey[50]` (Light, airy foundation).
    * **Surface (Cards):** `Colors.white` with `BorderRadius.circular(16-20)`.
    * **Primary Brand:** **Blue** (approx `#2D62ED`). Used for totals, active states, and primary buttons.
    * **Urgency:** **Orange** for "Renewing Soon" or "Today".
    * **Safe:** **Green** for items with ample time remaining.
    * **Text:** Dark Grey (`Colors.grey[900]`) for headings, lighter grey for labels.
* **Shadows & Depth:**
    * We use soft, diffused shadows (`BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: Offset(0, 4))`) to make cards "float" rather than using harsh outlines.
* **Input Style:**
    * **Fields:** Filled `Colors.grey[100]` containers with no visible border strokes.
    * **Labels:** Located **outside and above** the field (bold, small text) for better scannability.
    * **Radius:** `BorderRadius.circular(12)` for inputs.
    * **ModernFormField:** A reusable widget encapsulating this style.

---

## 2. Core Screens Built

### A. Dashboard (Main Screen)
* **Header:** "Total Monthly Spend" with a large, hero-sized number.
* **Bar Chart Visualization:**
    * **Logic:** Dynamic Y-Axis scaling based on spend.
    * **Visuals:** Clean grid lines, no overlapping labels.
* **Subscription List:**
    * **Squircle Icons:** Initials on a soft colored background.
    * **Progress Track:** A subtle grey line behind the colored urgency bar.
* **Unified Agenda View:**
    * A consolidated list of subscriptions, appointments, and tasks sorted chronologically.
    * **Empty State:** Custom `EmptyStateView` with inviting graphics when no items are scheduled.

### B. Add/Edit Forms (Refactored)
* **Subscription Form:**
    * Grouped into "Essentials", "Timing", and "Details" cards.
    * Uses `ModernFormField` for consistent input styling.
* **Appointment Form:**
    * Grouped into "Event Details", "Timing" (Date/Time pickers), and "Notes".
    * Uses `ModernFormField`.
* **Task Form:**
    * Grouped into "Task Core" (Title, Priority), "Execution" (Due Date, Reminder), and "Context" (Notes).
    * Uses `ModernFormField`.

### C. List Views (Refactored)
* **Features:**
    * **Multi-Selection:** Long-press to enter selection mode, allowing batch deletion.
    * **Selection App Bar:** Custom app bar showing count and actions (Clear, Delete).
    * **Optimistic UI:** Immediate feedback for add, update, delete, and completion toggle.
    * **Completion Logic:** Active items shown by default; completed items filtered out (can be toggled).
* **Subscription List:**
    * Shows renewal status with traffic light colors.
* **Appointment List:**
    * Grouped by date (Today, Tomorrow, Specific Date).
    * Left-aligned time display.
    * "Mark Finished" button.
* **Task List:**
    * Leading checkbox for completion.
    * Strikethrough for completed items.

---

## 3. Technical Implementation Details
* **State Management:** Provider pattern with `ChangeNotifier` for all core data models.
* **Data Persistence:**
    * **Supabase:** Remote PostgreSQL database with RLS.
    * **SQLite:** Local offline cache for robust performance.
    * **Optimistic Updates:** UI updates immediately; background sync handles remote/local DBs. Rollbacks on error.
* **Authentication:** Supabase Auth (Email/Password, Google).
* **Notifications:** Local notifications for reminders.

---

## 4. Current Status
* **Completed:**
    * Visual Polish (Modern Soft design applied to all forms and lists).
    * Form Refactoring (Grouped cards, consistent inputs).
    * Multi-Selection & Batch Deletion.
    * Task/Appointment Completion Logic.
    * Empty States.
    * Logout Bug Fix (Clean navigation stack reset).
    * Appointment "Reappearing" Bug Fix (Optimistic update logic correction).
* **Pending / Next Up:**
    * **"List Subscription" Feature:** (User is currently brainstorming this).
    * **Recurring Appointments/Tasks:** Advanced recurrence logic.
    * **Calendar Sync:** Integration with device calendar.
