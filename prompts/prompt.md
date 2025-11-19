You are modifying an iOS SwiftUI app with a Welcome screen and multiple module-specific List screens 
(e.g., SubscriptionsListView, AppointmentsListView, TasksListView).

Goal:
When the user finishes adding an item (like a Subscription), the app currently navigates back to the 
respective List screen. This behavior should remain unchanged.

But I need a consistent way for the user to return to the main Welcome screen at any time.

Make the following changes:

1. Add a top-level NavigationStack architecture where WelcomeView is the root.
2. Include a global navigation path managed via an ObservableObject (e.g. NavigationModel).
3. On each List screen (SubscriptionsListView, AppointmentsListView, TasksListView, etc.),
   add a toolbar button titled “Home” or use a small Material icon (house shape) that navigates 
   the user back to WelcomeView.
4. Ensure that tapping the “Home” button resets the navigation path (pop to root).
5. Do NOT break the following flows:
   - Welcome → SubscriptionsList → AddSubscription → Save → SubscriptionsList
   - Same behavior for Appointments, Tasks, and Custom Categories.
6. Make the implementation minimal, clean, and aligned with SwiftUI best practices.
7. Refactor as needed so the project keeps a single source of truth for navigation.

Provide the following:
- A NavigationModel with a navigationPath property.
- Updated WelcomeView as the root of the NavigationStack.
- Updated List views with the “Home” button in the navigation toolbar.
- Code changes only — no placeholder text, no explanations unless necessary.
- Ensure everything compiles.

Implement these updates now.