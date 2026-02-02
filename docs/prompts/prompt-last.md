**Title:** Implement a Dynamic "Today's Snapshot" Dashboard on the Welcome Screen

**Context:**
You are an expert Flutter/Dart developer. Your task is to transform the application's welcome screen from a simple input page into a dynamic, context-aware dashboard. This will provide immediate value to the user upon opening the app and improve engagement.

The screen should have two states:
1.  **Default State (No Input):** Display a "Today's Snapshot" widget summarizing the user's most important upcoming items.
2.  **Active State (User Typing):** When the user starts typing in the Omnibox, the snapshot will be replaced by the existing animation/preview box.

**Recent UX Updates (To be maintained):**
*   **Self-Explanatory Color Coding:** The app now uses a consistent color-coding system to indicate status/urgency:
    *   **Orange:** Today's items.
    *   **Brand Blue (#2D62ED):** Upcoming/Future items.
    *   **Grey:** Past items.
*   **Implementation Note:** Section headers in lists and the time/date text inside cards should use these specific colors to reinforce the meaning of the status indicators. Ensure the new `UnifiedAgendaView` and `TodaysSnapshotView` follow this pattern.

**Affected Files:**
*   `lib/views/welcome_view.dart` (Major modifications)
*   `lib/providers/subscription_provider.dart` (Data access)
*   `lib/providers/appointment_provider.dart` (Data access)
*   `lib/providers/task_provider.dart` (Data access)

**New Files to Create:**
*   `lib/widgets/todays_snapshot_view.dart` (The new summary card widget)
*   `lib/views/unified_agenda_view.dart` (A new screen for the full agenda)

**Instructions:**

**Part 1: Create the Unified Agenda View**

1.  Create a new file: `lib/views/unified_agenda_view.dart`.
2.  Implement a `StatefulWidget` called `UnifiedAgendaView`.
3.  The view should have an `AppBar` titled "Upcoming Agenda".
4.  In its state, fetch all data from the `SubscriptionProvider`, `AppointmentProvider`, and `TaskProvider`.
5.  Combine the items from all three sources into a single list.
6.  Sort this master list chronologically based on the relevant date (renewal date, appointment time, due date).
7.  Display the sorted items in a `ListView`, where each item is styled distinctly based on its type (e.g., using different icons and text formatting for subscriptions, appointments, and tasks). **Crucial:** Use the color-coding pattern (Orange/Blue/Grey) for section headers and date text as implemented in the Appointments list.

**Part 2: Create the "Today's Snapshot" Widget**

1.  Create a new file: `lib/widgets/todays_snapshot_view.dart`.
2.  Implement a `StatelessWidget` called `TodaysSnapshotView`.
3.  The widget should accept lists of subscriptions, appointments, and tasks as parameters.
4.  Implement logic to determine the most relevant items to display:
    *   **Up Next:** The soonest upcoming appointment for today.
    *   **Due Today:** The most important task due today.
    *   **Renewing Soon:** The next subscription that is renewing (today or tomorrow).
5.  Design the widget as a card (e.g., using `Card` or a `Container` with decoration).
6.  Display the selected items with appropriate icons (e.g., `Icons.calendar_today`, `Icons.check_box_outline_blank`, `Icons.autorenew`). Use appropriate colors for status reinforcement.
7.  Add a "View Full Agenda ->" `TextButton` or similar interactive element. Tapping anywhere on the card should navigate to the `UnifiedAgendaView`.

**Part 3: Update the Welcome View**

1.  Open `lib/views/welcome_view.dart`.
2.  In the `_WelcomeViewState`, add a listener to the `_omniboxController` to detect when the text is empty or not. A boolean state variable like `_isTyping` should be updated in `setState`.
3.  In the `build` method, locate the `AnimatedContainer` that currently holds the `PulsingGradientPlaceholder` (the animation box).
4.  Replace this static implementation with an `AnimatedSwitcher`.
    *   **`duration`:** Set a smooth duration, like `Duration(milliseconds: 300)`.
    *   **`child`:** Use a condition based on `_isTyping` (or `_omniboxController.text.isEmpty`).
        *   If the user **is typing**, the child should be the `PulsingGradientPlaceholder`.
        *   If the user **is not typing**, the child should be your new `TodaysSnapshotView` widget. You will need to fetch the data from the providers to pass into it.
5.  Ensure the transition between the two widgets is a fade (the default for `AnimatedSwitcher`).

**Summary of Desired User Experience:**

*   **On App Launch:** The user sees the Omnibox and the "Today's Snapshot" card, which gives them an instant, glanceable summary of their day.
*   **On Tapping the Snapshot:** The user is navigated to the `UnifiedAgendaView`, where they can see all their upcoming items in a sorted list.
*   **On Typing in Omnibox:** The "Today's Snapshot" card smoothly fades out and is replaced by the pulsing animation box, which reflects the text being typed.
*   **On Clearing Omnibox:** The animation box fades out and is replaced by the "Today's Snapshot" card.

Please implement this feature with clean, well-structured, and production-ready Dart code.
