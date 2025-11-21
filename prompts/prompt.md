Prompt:
Implement full multi-category reminder functionality in the app by adding Appointments, Tasks, and Custom reminder types. Match the UI, navigation structure, and styling already implemented for Subscriptions.

PART 1 — Create Add/Edit Screens for Each Category

Create the following new screens:

AppointmentFormView

TaskFormView

CustomReminderFormView

These screens must visually match the design and spacing of SubscriptionFormView.
Each screen must support both Add mode and Edit mode, showing:

“Save [Category]” in Add mode

“Update [Category]” in Edit mode

Appointments — Fields

Title* (TextField)

Category (freeform TextField, optional)

Date & Time* (DatePicker)

Location (optional TextField)

Notes (optional)

Reminder (time-based preset options: 5 min, 15 min, 30 min, 1 hour, 1 day before)

Tasks — Fields

Title* (TextField)

Category (freeform TextField, optional)

Due Date (optional DatePicker)

Priority (optional: Low, Medium, High — Picker)

Notes (optional TextField)

Reminder (time-based preset options: 5 min, 15 min, 30 min, 1 hour, 1 day before)

Custom — Fields

Title* (TextField)

Category (freeform TextField, optional)

Date & Time (optional DatePicker)

Notes (optional)

Reminder (time-based preset options: 5 min, 15 min, 30 min, 1 hour, 1 day before)

Mandatory Field Indicators

Just like the Subscription view, show a red * after mandatory field labels.

Reminder Implementation

Implement the time-based reminder system for all three categories using UNUserNotificationCenter.
Reminder should trigger at the correct offset before the selected date/time.

PART 2 — Create List Screens for Each Category

Add three new list views:

AppointmentsListView

TasksListView

CustomRemindersListView

Each must follow the same structure as SubscriptionsListView:

Navigation title = Category name (e.g., “Appointments”)

A search bar using .searchable(text:)

Search must filter by title, category, and notes (case-insensitive)

List of items with consistent card/list row styling

A top-right “+” button to add new items

PART 3 — Empty-State Navigation Logic

Match the logic implemented for Subscriptions:

When the user taps a category on the Welcome Screen:

If that category has existing items → go to the List screen

If that category has 0 items → go directly to the Add screen for that category

This must be implemented for:

Appointments

Tasks

Custom

PART 4 — Update Welcome Screen Navigation

On the Welcome Screen’s card-style list (Subscriptions, Appointments, Tasks, Custom):

Subscriptions → existing logic

Appointments → new empty-state logic, list screen, add/edit screens

Tasks → same

Custom → same

Use the same minimal SF Symbols icons:

Appointments → "calendar"

Tasks → "checkmark.circle"

Custom → "bell"

PART 5 — Data Model & Persistence

For each category, create separate Core Data entities matching the fields:

Appointment

Task

CustomReminder

Use types:

Title: String

Category: String?

Date/Time fields: Date?

Priority (for Tasks): String or Int

Notes: String?

ReminderOffset: Int (minutes before event)

CreatedDate: Date

Ensure Add/Edit screens load and save correctly.

PART 6 — Consistent UI/UX Across All Screens

Match spacing, titles, field styling, button styling from SubscriptionFormView

Use the same card-list-row style for list items

Apply red asterisk for mandatory fields

Use NavigationStack for all screens

Keep Search + List + Add flow consistent everywhere

GOAL:

Expand the app from a “Subscription Tracker” into a full “Reminder Manager” by implementing full feature parity across Appointments, Tasks, and Custom reminders—matching the quality, style, and behavior already built for Subscriptions.
This includes Add/Edit screens, list screens, navigation, reminders, search, field validation, Core Data models, and onboarding flow.