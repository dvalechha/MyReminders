**Title:** Critical Bug Fix: List Views Must Fetch Fresh Data on Every Load

**Context:**
You are AntiGravity, an expert Flutter/Dart developer. A critical bug persists in the application: the list views for Tasks, Subscriptions, and Appointments are displaying stale data. They fetch data from the Supabase backend only once and then show a cached version from the in-memory provider. This means recent changes (creations, updates, or deletions) are not visible until the app is fully restarted.

The goal is to permanently fix this by ensuring these list views **always** present the most current data from the database whenever the user visits them.

**Affected Files:**
*   **Views (UI):**
    *   `lib/views/tasks_list_view.dart`
    *   `lib/views/subscriptions_list_view.dart`
    *   `lib/views/appointments_list_view.dart`
*   **Providers (State Management & Business Logic):**
    *   `lib/providers/task_provider.dart`
    *   `lib/providers/subscription_provider.dart`
    *   `lib/providers/appointment_provider.dart`

**Instructions:**

Your task is to modify the data fetching logic to guarantee a data refresh from the Supabase backend every single time a list view becomes visible to the user.

1.  **Modify Provider Fetch Logic (The Core Problem):**
    *   In each of the three providers (`..._provider.dart`), locate the data fetching method (e.g., `fetchTasks`, `fetchSubscriptions`).
    *   These methods likely contain a guard clause that prevents re-fetching if the local list is already populated (e.g., `if (_tasks.isNotEmpty) return;`).
    *   **You must remove this guard clause.** The method should **always** proceed to call the repository and fetch the latest data from Supabase.
    *   At the beginning of the fetch method, ensure you clear the existing in-memory list (e.g., `_tasks.clear();`). This is crucial to prevent duplicating data.

2.  **Ensure Fetch is Called on View Entry:**
    *   In each of the three list views (`..._list_view.dart`), ensure the data fetching method from the provider is being called when the view is initialized. The best practice for this is within the `initState` method.
    *   The call should look like this, using `listen: false`:
        ```dart
        @override
        void initState() {
          super.initState();
          // Use a PostFrameCallback to ensure the context is available
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Provider.of<TaskProvider>(context, listen: false).fetchTasks();
          });
        }
        ```
    *   By fixing the provider (Step 1), this call will now correctly refresh the data every time the view is created and loaded.

**Summary of Desired User Experience:**

*   **Current (Buggy) Behavior:** A user edits a task, navigates back to the `TasksListView`, and the old, unedited task information is still displayed.
*   **Target (Correct) Behavior:** A user edits a task, navigates back to the `TasksListView`, and the view immediately displays the updated task information, reflecting the changes made. This correct behavior must apply to all create, update, and delete operations across all three modules.

Please implement this data refresh logic consistently across Tasks, Subscriptions, and Appointments to resolve this critical stale data issue.
